// Yard script

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "ProgressBar.as";

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

	{
		ShopItem@ s = addShopItem(this, "Quarters", "$quarters$", "quarters", "Two beds for rest and healing.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Outpost", "$outpost$", "outpost", "An outpost that llows your team to respawn here, but with shorter spawn immunity time.\nHas limited uses.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Bunker", "$bunker$", "bunker", "A tough encampment, great for holding important areas.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 300);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Bunker", "$heavybunker$", "heavybunker", "A terrifying reinforcement, ideal for holding landmarks.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 300);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Quarry", "$quarry$", "quarry", "A quarry to generate stone in exchange of wood.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 350);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 350);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 4;
	}
	{
		ShopItem@ s = addShopItem(this, "Repair Station", "$repairstation$", "repairstation", "Build in an open area, it will repair friendly vehicles nearby it.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 150);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Refinery", "$refinery$", "refinery", "Supply it with stone to produce scrap, which is used to build vehicles at the vehicle builder.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Advanced Refinery", "$advancedrefinery$", "advancedrefinery", "An improved refinery for increased output.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Ammo Factory", "$ammofactory$", "ammofactory", "Produce all types of ammunition with metals.", false, false, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
}

void onTick(CBlob@ this)
{
	barTick(this);
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

	if (this.isOverlapping(caller))
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
			this.getSprite().PlaySound("/Construct.ogg");
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