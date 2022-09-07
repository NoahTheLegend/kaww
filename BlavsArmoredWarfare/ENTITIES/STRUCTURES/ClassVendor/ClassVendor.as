#include "Requirements.as"
#include "ShopCommon.as"

ConfigFile cfg_playertechs;

void onInit(CBlob@ this)
{
	if ( !cfg_playertechs.loadFile("../Cache/KAWW_Techs.cfg") )
    {
        cfg_playertechs = ConfigFile("KAWW_Techs.cfg");
    }

	AddIconToken("$shotgun_class_icon$", "Class.png", Vec2f(32, 32), 4);
	AddIconToken("$sniper_class_icon$", "Class.png", Vec2f(32, 32), 24);
	AddIconToken("$antitank_class_icon$", "Class.png", Vec2f(32, 32), 16);
	AddIconToken("$medic_class_icon$", "Class.png", Vec2f(32, 32), 28);
	AddIconToken("$lmg_class_icon$", "Class.png", Vec2f(32, 32), 28);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(6, 4)); //3,2
	this.set_string("shop description", "UNLOCK CLASS");
	this.set_u8("shop icon", 23);

	{
		ShopItem@ s = addShopItem(this, "Unlock: Shotgunner", "$shotgun_class_icon$", "Shotgun", "---- Unlock: Shotgunner ----\n\nDeadly at close range.\nLMB: Shotgun\nRMB: Knife", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Unlock: Sniper", "$sniper_class_icon$", "Sniper", "---- Unlock: Sniper ----\n\nLong range sniper.\nLMB: Rifle\nRMB: Knife", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Unlock: Anti", "$antitank_class_icon$", "Anti", "---- Unlock: Anti-Tank ----\n\nEliminate tanks onfoot.\nLMB: RPG\nRMB: Knife", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Unlock: Medic", "$medic_class_icon$", "Medic", "---- Unlock: Medic ----\n\nHeal nearby teammates.\nLMB: MP5\nRMB: Knife", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 160);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Unlock: Lmg", "$lmg_class_icon$", "Lmg", "---- Unlock: LMG ----\n\nExtreme firepower.\nLMB: LMG\nRMB: ADS", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 160);
		s.spawnNothing = true;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("shop made item"))
    {
        if(!isServer())//Is client?
        {
            return;//Don't go any further
        }
        
        //Server only past here
        u16 caller, item;
        if(!params.saferead_netid(caller) || !params.saferead_netid(item))
        {
            return;
        }

        string name = params.read_string();
        CBlob@ callerBlob = getBlobByNetworkID(caller);
        if (callerBlob is null)
        {
            return;
        }

        bool bought_class = false;

        CPlayer@ player = callerBlob.getPlayer();

        if (player is null)
        {
        	return;
        }

        if (name == "Shotgun") 
        {
        	if (!player.hasTag("Shotgun"))
        	{
        		cfg_playertechs.add_bool(player.getUsername() + "_shotgun", true);
        		player.Tag("Shotgun");
        		player.Sync("Shotgun", true);
        		bought_class = true;
        	}
        	else
        	{
        		player.server_setCoins(player.getCoins() + 15);
        	}
        }
		if (name == "Sniper") 
		{
			if (!player.hasTag("Sniper"))
			{
				cfg_playertechs.add_bool(player.getUsername() + "_sniper", true);
				player.Tag("Sniper");
				player.Sync("Sniper", true);
				bought_class = true;
			}
			else
			{
				player.server_setCoins(player.getCoins() + 50);
			}
		}
		if (name == "Anti")
		{
			if (!player.hasTag("Anti"))
			{
				cfg_playertechs.add_bool(player.getUsername() + "_anti", true);
				player.Tag("Anti");
				player.Sync("Anti", true);
				bought_class = true;
			}
			else
			{
				player.server_setCoins(player.getCoins() + 50);
			}
		}
		if (name == "Medic") 
		{
			if (!player.hasTag("Medic"))
			{
				cfg_playertechs.add_bool(player.getUsername() + "_medic", true);
				player.Tag("Medic");
				player.Sync("Medic", true);
				bought_class = true;
			}
			else
			{
				player.server_setCoins(player.getCoins() + 160);
			}
		}
		if (name == "Lmg")
		{
			if (!player.hasTag("Lmg"))
			{
				cfg_playertechs.add_bool(player.getUsername() + "_lmg", true);
				player.Tag("Lmg");
				player.Sync("Lmg", true);
				bought_class = true;
			}
			else
			{
				player.server_setCoins(player.getCoins() + 160);
			}
		}

		if (bought_class)
		{
			this.getSprite().PlaySound("UnlockClass");

			if (player.isMyPlayer())
			{
				client_AddToChat(name + " class has been unlocked!");
			}
		}
		else
		{
			this.getSprite().PlaySound("NoAmmo");

			if (player.isMyPlayer())
			{
				client_AddToChat(name + " is already unlocked - coins refunded.");
			}
		}

        cfg_playertechs.saveFile("KAWW_Techs.cfg");
    }
}