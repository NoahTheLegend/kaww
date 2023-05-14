#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	InitCosts(); //read from cfg

	//this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-150); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	CMap@ map = getMap();

	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);
	if (map is null) return;

	this.Tag("structure");
	this.Tag("trap");

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);

	if (map.tilemapwidth > 200) // normal maps
	{
		this.set_Vec2f("shop menu size", Vec2f(5, 3));
		{
			ShopItem@ s = addShopItem(this, "Ammuniton", "$ammo$", "ammo", "Ammo for machine guns and infantry.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 3);
		}
		{
			ShopItem@ s = addShopItem(this, "Special Ammunition", "$specammo$", "specammo", "Special ammo for advanced weapons.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 15);
		}
		{
			ShopItem@ s = addShopItem(this, "14.5mm Rounds", "$mat_14mmround$", "mat_14mmround", "Ammo for an APC.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 15);
		}
		{
			ShopItem@ s = addShopItem(this, "105mm Shells", "$mat_bolts$", "mat_bolts", "Ammo for a tank's main gun.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 35);
		}
		{
			ShopItem@ s = addShopItem(this, "HEAT Warheads", "$mat_heatwarhead$", "mat_heatwarhead", "Ammo for RPGs.\nHas a small explosion radius.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 45);
		}
		{
			ShopItem@ s = addShopItem(this, "Grenade", "$grenade$", "grenade", "Very effective against vehicles or in close quarter rooms.\nPress [SPACEBAR] to pull the pin, [C] to throw.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 30);
		}
		{
			ShopItem@ s = addShopItem(this, "Sticky Grenade", "$sgrenade$", "sgrenade", "An analogue for default grenades, but also\nsticks to flesh, bunkers and any type of vehicles.\nPress [SPACEBAR] to pull the pin, [C] to throw.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 35);
			//AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
		}
		{
			bool rebels_power = getRules().get_bool("enable_powers") && this.getTeamNum() == 3; // team 3 buff
        	u8 extra_amount = 0;
        	if (rebels_power) extra_amount = 5;

			ShopItem@ s = addShopItem(this, "Molotov", "$mat_molotov$", "mat_molotov", "A home-made cocktail with highly flammable liquid.\nPress [SPACEBAR] before throwing", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 15-extra_amount);
		}
		{
			ShopItem@ s = addShopItem(this, "Mine", "$mine$", "mine", "A dangerous trap for infantry.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 55);
		}
		{
			ShopItem@ s = addShopItem(this, "Helmet", "$helmet$", "helmet", "A must-have on the battlefield!", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 30);
		}
		{
			ShopItem@ s = addShopItem(this, "Pipe Wrench", "$pipewrench$", "pipewrench", "Left click on vehicles to repair them. Mechanics can detach machineguns from vehicles using this. Limited uses.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 40);
		}
		{
			ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press [E] to heal. Has 4 uses total. Bonus: allows medics to perform healing faster.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 15);
		}
		{
			ShopItem@ s = addShopItem(this, "Binoculars", "$binoculars$", "binoculars", "A pair of zooming binoculars that allow you to see much further. Carry them and hold [RIGHT MOUSE] ", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 40);
		}
		{
			ShopItem@ s = addShopItem(this, "Buy wood (250)", "$mat_wood$", "mat_wood", "Purchase 250 wood.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 15);
		}
		{
			ShopItem@ s = addShopItem(this, "Buy stone (250)", "$mat_stone$", "mat_stone", "Purchase 250 stone.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 35);
		}
	}
	else // tdm maps
	{
		this.set_Vec2f("shop menu size", Vec2f(4, 1));
		{
			ShopItem@ s = addShopItem(this, "Ammuniton", "$ammo$", "ammo", "Ammo for machine guns and infantry.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 3);
		}
		{
			ShopItem@ s = addShopItem(this, "Beer", "$heart$", "heart", "Leaf Lovers special", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 7);
		}
		{
			ShopItem@ s = addShopItem(this, "Food", "$food$", "food", "A tasty burger", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 12);
		}
		{
			ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press [E] to heal. Has 4 uses total.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", 25);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f_zero);

	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		//if (this.get_u32("next_tick") > getGameTime()) return;
		//this.set_u32("next_tick", getGameTime()+1);
		this.getSprite().PlaySound("/ChaChing.ogg");

		u16 caller, item;

		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);

		if (callerBlob is null) return;
	}
}
