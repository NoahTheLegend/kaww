// Yard script

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "ProgressBar.as";
#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	AddIconToken("$stonequarry$", "../Mods/Entities/Industry/CTFShops/Quarry/Quarry.png", Vec2f(40, 24), 4);
	//this.getSprite().getConsts().accurateLighting = true;

	//this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-100); //background
	this.getShape().getConsts().mapCollisions = false;

	//INIT COSTS
	InitCosts();

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(10, 4));
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 12);
	this.Tag("builder always hit");
	this.Tag("structure");
	this.Tag(SHOP_AUTOCLOSE);

	this.set_u32("step", XORRandom(4));

	{
		ShopItem@ s = addShopItem(this, "Quarters", "$quarters$", "quarters", "Two beds for rest and healing.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Outpost", "$outpost$", "outpost", "An outpost for distant respawn, with small workbench and short invulnerability.\nUses are limited.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Bunker", "$bunker$", "bunker", "A tough encampment, great for holding important areas.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Bunker", "$heavybunker$", "heavybunker", "A terrifying reinforcement, ideal for holding landmarks.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Quarry", "$quarry$", "quarry", "Produces stone.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 350);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 350);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Repair Station", "$repairstation$", "repairstation", "Repairs nearby vehicles if they weren't hurt recently.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 150);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Refinery", "$refinery$", "refinery", "Stone smeltery.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Advanced Refinery", "$advancedrefinery$", "advancedrefinery", "Gold smeltery.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Ammo Factory", "$ammofactory$", "ammofactory", "Produces ammunition with scrap.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Storage", "$storage$", "storage", "A room for storing your materials.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
}

void onTick(CBlob@ this)
{
	barTick(this);
	if (this.get_bool("constructing") && getMap() !is null)
	{
		CBlob@[] overlapping;
		getMap().getBlobsInRadius(this.getPosition(), 4.0f, @overlapping);

		bool has_caller = false;
		s8 caller_team = -1;
		s8 count = -1;
		for (u16 i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			if (blob is null || blob.isAttached() || blob.hasTag("dead"))
					continue;

			if (blob.getNetworkID() == this.get_u16("builder_id"))
			{
				has_caller = true;
				caller_team = blob.getTeamNum();
			}
		}

		for (u16 i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			if (blob is null || blob.isAttached() || blob.hasTag("dead"))
					continue;

			if (caller_team == blob.getTeamNum() && blob.getName() == "mechanic")
			{
				count++;
			}
		}

		if (has_caller)
		{
			if (isClient() && getGameTime()%25==0)
			{
				this.add_u32("step", 1);
				if (this.get_u32("step") > 3) this.set_u32("step", 0);

				if (XORRandom(4)==0) this.set_u32("step", XORRandom(4));

				//this.getSprite().Gib();

				u8 rand = XORRandom(5);
				for (u8 i = 0; i < rand; i++)
				{
					MakeDustParticle(this.getPosition()+Vec2f(XORRandom(24)-12, XORRandom(16)), XORRandom(5)<2?"Smoke.png":"dust2.png");
					
					if (XORRandom(3) != 0)
					{
						CParticle@ p = makeGibParticle("WoodenGibs.png", this.getPosition()+Vec2f(XORRandom(24)-12, XORRandom(16)), Vec2f(0, (-1-XORRandom(3))).RotateBy(XORRandom(61)-30.0f), XORRandom(16), 0, Vec2f(8, 8), 1.0f, 0, "", 7);
					}
				}

				this.getSprite().PlaySound("Construct"+this.get_u32("step"), 0.6f+XORRandom(11)*0.01f, 0.95f+XORRandom(6)*0.01f);
			}
		}
		this.add_f32("construct_time", has_caller || this.get_f32("construct_time") / this.get_u32("construct_endtime") > 0.975f ? 1 + count : -1);
		
		if (this.get_f32("construct_time") <= 0)
		{
			this.set_f32("construct_time", 0);
			this.set_string("constructing_name", "");
			this.set_s8("constructing_index", 0);
			this.set_bool("constructing", false);

			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				if (hasBar(bars, "construct"))
				{
					bars.RemoveBar("construct", false);
				}
			}
		}
	}

	if (getGameTime() % 90 == 0)
	{
		if (getMap() !is null
		&& !getMap().hasSupportAtPos(this.getPosition()+Vec2f(0,8))
		&& !getMap().hasSupportAtPos(this.getPosition()+Vec2f(8,8))
		&& !getMap().hasSupportAtPos(this.getPosition()+Vec2f(-8,8)))
		{
			this.server_Die();
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (this.isOverlapping(caller) && caller.getName() == "mechanic")
		this.set_bool("shop available", true);
	else
		this.set_bool("shop available", false);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	if (cmd == this.getCommandID("shop made item"))
	{
		this.Tag("shop disabled"); //no double-builds

		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ item = getBlobByNetworkID(params.read_netid());
		if (item !is null && caller !is null)
		{
			this.getSprite().PlaySound("/ConstructShort.ogg");
			this.getSprite().getVars().gibbed = true;
			this.server_Die();
			caller.ClearMenus();
		}
	}
}

void onRender(CSprite@ this)
{
	barRender(this);
}