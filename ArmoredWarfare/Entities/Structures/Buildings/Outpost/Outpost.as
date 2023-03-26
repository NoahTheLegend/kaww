#include "GenericButtonCommon.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "GenericButtonCommon.as";

const u16 MIN_RESPAWNS = 5;
const u8 ADD_RESPAWN_PER_PLAYERS = 2;
const u8 respawn_immunity_time = 30 * 1.5;

void onInit(CBlob@ this)
{
	this.Tag("respawn");
	this.Tag("builder always hit");
	this.Tag("vehicle"); // required for minimap
	this.addCommandID("class menu");
	this.addCommandID("lock_classchange");
	this.addCommandID("lock_perkchange");

	this.set_TileType("background tile", CMap::tile_wood_back);
	this.getSprite().getConsts().accurateLighting = true;
	this.getShape().getConsts().mapCollisions = false;

	this.SetLight(true);
	this.SetLightRadius(86.0f);
	this.SetLightColor(SColor(255, 255, 240, 155));

	this.inventoryButtonPos = Vec2f(-18.0f, 0);

	this.set_u16("max_respawns", MIN_RESPAWNS+(getPlayerCount()/ADD_RESPAWN_PER_PLAYERS));
	//printf(""+this.get_u16("max_respawns"));

	this.set_u8("custom respawn immunity", respawn_immunity_time); 

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ flag = sprite.addSpriteLayer("camp layer", "Outpost.png", 32, 32);
	if (flag !is null)
	{
		flag.addAnimation("default", 5, true);
		int[] frames = { 9, 10, 11 };
		flag.animation.AddFrames(frames);
		flag.SetRelativeZ(0.8f);
		flag.SetOffset(Vec2f(5.0f, -4.0f));
		flag.SetAnimation("default");
	}

	// SHOP
	InitCosts();
	InitClasses(this);

	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(2, 2));
	this.set_string("shop description", "Craft");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Burger", "$food$", "food", "Heal to full health instantly.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Helmet", "$helmet$", "helmet", "Standard issue helmet, take 40% less bullet damage, and occasionally bounce bullets.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Pipe Wrench", "$pipewrench$", "pipewrench", "Left click on vehicles to repair them. Limited uses.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", "A source of light.", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 20);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f(0, 0));

	this.set_bool("shop available", true);

	if (!canSeeButtons(this, caller)) return;

	// button for runner
	// create menu for class change
	if (canChangeClass(this, caller) && caller.getTeamNum() == this.getTeamNum())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		if (!caller.hasTag("lock_perkchange"))
			caller.CreateGenericButton("$change_perk$", Vec2f(0, -10), this, buildPerkMenu, getTranslatedString("Switch Perk"));
		if (!caller.hasTag("lock_classchange"))
			caller.CreateGenericButton("$change_class$", Vec2f(9, 0), this, this.getCommandID("class menu"), getTranslatedString("Change class"), params);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum() && customData != 0) return damage / 10.0f;
	return damage;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
	if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
		{
			BuildRespawnMenuFor(this, caller);
		}
	}
	else if (cmd == this.getCommandID("lock_classchange"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller !is null) caller.Tag("lock_classchange");
	}
	else if (cmd == this.getCommandID("lock_perkchange"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller !is null) caller.Tag("lock_perkchange");
	}
	else if (cmd == this.getCommandID("shop made item"))
	{
		if (this.get_u32("next_tick") > getGameTime()) return;
		this.set_u32("next_tick", getGameTime()+1);
		this.getSprite().PlaySound("/ArmoryBuy.ogg");

		if (!getNet().isServer()) return; /////////////////////// server only past here

		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
		{
			return;
		}
		string name = params.read_string();
		{
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob is null)
			{
				return;
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this) && canSeeButtons(this, forBlob));
}
