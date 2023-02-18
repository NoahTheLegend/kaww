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
	if (map !is null)
	{
		if (map.tilemapwidth < 200)
		{
			this.set_Vec2f("shop menu size", Vec2f(5, 1));
		}
	}
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 12);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);

	{
		ShopItem@ s = addShopItem(this, "7.62mm Bullets", "$mat_7mmround$", "mat_7mmround", "Ammo for machine guns and infantry.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "14.5mm Rounds", "$mat_14mmround$", "mat_14mmround", "Ammo for an APC.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "105mm Shells", "$mat_bolts$", "mat_bolts", "Ammo for a tank's main gun.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press [E] to heal. Has 4 uses total. Bonus: allows medics to perform healing faster.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		if (map !is null)
		{
			u8 cost = map.tilemapwidth > 200 ? 30 : 50;
			ShopItem@ s = addShopItem(this, "Grenade", "$grenade$", "grenade", "Very effective against vehicles or in close quarter rooms.\nPress [SPACEBAR] to pull the pin, [C] to throw.", false);
			AddRequirement(s.requirements, "coin", "", "Coins", cost);
		}
	}
	if (map !is null)
	{
		if (map.tilemapwidth > 200)
		{
			{
				ShopItem@ s = addShopItem(this, "Molotov", "$mat_molotov$", "mat_molotov", "A home-made cocktail with highly flammable liquid.\nPress [SPACEBAR] before throwing", false);
				AddRequirement(s.requirements, "coin", "", "Coins", 15);
			}
			{
				ShopItem@ s = addShopItem(this, "HEAT Warheads", "$mat_heatwarhead$", "mat_heatwarhead", "Ammo for RPGs.\nHas an small explosion radius.", false);
				AddRequirement(s.requirements, "coin", "", "Coins", 50);
			}
			{
				ShopItem@ s = addShopItem(this, "Binoculars", "$binoculars$", "binoculars", "A pair of zooming binoculars that allow you to see much further. Carry them and hold [RIGHT MOUSE] ", false);
				AddRequirement(s.requirements, "coin", "", "Coins", 40);
			}
		}
	}
	
	/*
	{
		ShopItem@ s = addShopItem(this, "Drill", "$drill$", "drill", Descriptions::drill, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Steak", "$steak$", "steak", "Slab of meat to keep you fighting.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Mine", "$mine$", "mine", "A dangerous trap for infantry.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 13);
	}
	{
		ShopItem@ s = addShopItem(this, "Tank Trap", "$tanktrap$", "tanktrap", "A crippling trap for vehicles.", false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 75);
	}
	{
		ShopItem@ s = addShopItem(this, "Keg", "$keg$", "keg", "Huge explosive, can seriously damage vehicles and infantry.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 28);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy an Btr82a APC", "$crate$", "btr82a", "APC.\n\nUses 14.5mm.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy an M60 Tank", "$crate$", "m60", "Heavy tank.\n\nUses 105mm & 7.62mm.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy an T-10 Tank", "$crate$", "t10", "Heavy tank w/ tough armor.\n\nUses 105mm & 7.62mm.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	}
	*/
	/*
	{
		ShopItem@ s = addShopItem(this, "Binoculars", "$binoculars$", "binoculars", "Binoculars that magnify vision range.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 45);
	}
	{
		ShopItem@ s = addShopItem(this, "Binocular Tripod", "$binoculartripod$", "binoculartripod", "Binoculars on a tripod that magnify vision range greatly.", false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	*/
	/*
	{
		ShopItem@ s = addShopItem(this, "Sell Stone", "$COIN$", "coin-45", "Sell 250 stone for 45 coins.", false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Wood", "$COIN$", "coin-35", "Sell 250 wood for 35 coins.", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
	}
	*/
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
		if (this.get_u32("next_tick") > getGameTime()) return;
		this.set_u32("next_tick", getGameTime()+1);
		this.getSprite().PlaySound("/ChaChing.ogg");

		if (!getNet().isServer()) return; /////////////////////// server only past here

        u16 caller, item;
        if (!params.saferead_netid(caller) || !params.saferead_netid(item))
        {
            return;
        }
        string name = params.read_string();
        CBlob@ callerBlob = getBlobByNetworkID(caller);
        if (callerBlob is null){
            return;
        }
        string[] spl = name.split("-");
        if (spl[0] == "coin")
        {
            CPlayer@ callerPlayer = callerBlob.getPlayer();
            if (callerPlayer is null){
                return;
            }
            callerPlayer.server_setCoins(callerPlayer.getCoins() + parseInt(spl[1]));
        }
	}
}
