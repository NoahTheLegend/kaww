#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "VehiclesParams.as"

void onInit(CBlob@ this)
{
	InitCosts(); //read from cfg

	//this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-150); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(6, 4));
	this.set_string("shop description", "Craft Equipment");
	this.set_u8("shop icon", 21);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_ft$", "IconFT.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_barge$","IconBarge.png", Vec2f(32, 32), 0, 2);
}

void InitShop(CBlob@ this)
{
	bool isCTF = getBlobByName("pointflag") !is null || getBlobByName("pointflagt2") !is null;
	if (isCTF) this.set_Vec2f("shop menu size", Vec2f(7, 4));

	{
		ShopItem@ s = addShopItem(this, "Standard Ammo", "$ammo$", "ammo", "Used by all small arms guns, and vehicle machineguns.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Special Ammunition", "$specammo$", "specammo", "Special ammunition for advanced weapons.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "14mm Rounds", "$mat_14mmround$", "mat_14mmround", "Used by APCs", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "105mm Rounds", "$mat_bolts$", "mat_bolts", "Ammunition for tank main guns.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
	}
	{
		ShopItem@ s = addShopItem(this, "HEAT War Heads", "$mat_heatwarhead$", "mat_heatwarhead", "HEAT Rockets, used with RPG or different vehicles", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Frag Grenade", "$grenade$", "grenade", "Press SPACE while holding to arm, ~4 seconds until boom.\nIneffective against armored vehicles.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	if (isCTF)
	{
		ShopItem@ s = addShopItem(this, "5 ton Bomb", "$mat_5tbomb$", "mat_5tbomb", "The best way to destroy enemy facilities.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 300);
		AddRequirement(s.requirements, "gametime", "", "Unlocks at", 30*30 * 60); // 45th min
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 4;
	}
	{
		ShopItem@ s = addShopItem(this, "Anti-Tank Grenade", "$atgrenade$", "mat_atgrenade", "Press SPACE while holding to arm, ~5 seconds until boom.\nEffective against vehicles.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Land Mine", "$mine$", "mine", "Takes a while to arm, once activated it will expode upon contact with the enemy.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
	}
	{
		ShopItem@ s = addShopItem(this, "Burger", "$food$", "food", "Heal to full health instantly.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press E to heal. 6 uses.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 2);
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
		ShopItem@ s = addShopItem(this, "Tank Trap", "$tanktrap$", "tanktrap", "Czech hedgehog, will harm any enemy vehicle that collides with it.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", "A source of light.", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Sponge", "$sponge$", "sponge", "Commonly used for washing vehicles.", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Sticky Frag Grenade", "$sgrenade$", "sgrenade", "Press SPACE while holding to arm, ~4 seconds until boom.\nSticky to vehicles, bodies and blocks.", false);
		AddRequirement(s.requirements, "blob", "grenade", "Grenade", 1);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
		AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "M22 Binoculars", "$binoculars$", "binoculars", "A pair of glasses with optical zooming.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Bomb", "$mat_smallbomb$", "mat_smallbomb", "Small explosive bombs.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);

		s.customButton = true;

		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Firethrower", "$icon_ft$", "firethrower", "Fire thrower.\nCan be attached to and detached from some vehicles.\n\nUses Special Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher. ", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Barge", "$icon_barge$", "barge", "An armored boat for transporting vehicles across the water.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	
	{string[] params = {n_apsniper,t_apsniper,bn_apsniper,d_apsniper,b,s,ds};
	makeShopItem(this,params,c_apsniper, Vec2f(2,1), false, false);}
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1) InitShop(this);
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
