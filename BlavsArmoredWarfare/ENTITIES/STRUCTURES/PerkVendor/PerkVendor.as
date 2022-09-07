#include "Requirements.as"
#include "ShopCommon.as"

ConfigFile cfg_playertechs;

void onInit(CBlob@ this)
{
	if ( !cfg_playertechs.loadFile("../Cache/KAWW_Techs.cfg") )
    {
        cfg_playertechs = ConfigFile("KAWW_Techs.cfg");
    }

    AddIconToken("$kevlar_class_icon$", "PerkIcon.png", Vec2f(48, 48), 0);
    AddIconToken("$conditioning_class_icon$", "PerkIcon.png", Vec2f(48, 48), 1);
	AddIconToken("$bloodthirst_class_icon$", "PerkIcon.png", Vec2f(48, 48), 2);
	AddIconToken("$commando_class_icon$", "PerkIcon.png", Vec2f(48, 48), 3);
	AddIconToken("$sharpshooter_class_icon$", "PerkIcon.png", Vec2f(48, 48), 4);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(10, 2));
	this.set_string("shop description", "PERKS");
	this.set_u8("shop icon", 23);

	{
		ShopItem@ s = addShopItem(this, "Perk: Kevlar", "$kevlar_class_icon$", "Kevlar", "---- Perk: Kevlar ----\n\nResistence to explosives and bullets.\n\nCOST: 30 coins", false);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Perk: Conditioning", "$conditioning_class_icon$", "Conditioning", "---- Perk: Conditioning ----\n\nHigher stamina resulting in better running and jumping.\n\nCOST: 30 coins", false);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Perk: Blood Thirst", "$bloodthirst_class_icon$", "Blood Thirst", "---- Perk: Blood Thirst ----\n\nRegain all of your health on each kill.\n\nCOST: 240 coins", false);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Perk: Commando", "$commando_class_icon$", "Commando", "---- Perk: Commando ----\n\nYour bullets deal 35% more damage and stun at close range.\n\nCOST: 240 coins", false);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Perk: Sharpshooter", "$sharpshooter_class_icon$", "Sharpshooter", "---- Perk: Sharpshooter ----\n\nAccuracy is doubled when standing still\n\nCOST: 240 coins.", false);
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

        bool bought_perk = false;
        bool selected_perk = false;

        CPlayer@ player = callerBlob.getPlayer();

        if (player is null)
        {
        	return;
        }

        if (name == "Kevlar") 
        {
        	if (player.getCoins() >= 30 || cfg_playertechs.exists(player.getUsername() + "_kevlar"))
			{
				player.Untag("Conditioning");
	    		player.Sync("Conditioning", true);
	        	player.Untag("Blood Thirst");
	    		player.Sync("Blood Thirst", true);
	        	player.Untag("Commando");
	    		player.Sync("Commando", true);
	    		player.Untag("Sharpshooter");
	    		player.Sync("Sharpshooter", true);

	    		player.Tag("Kevlar");
	    		player.Sync("Kevlar", true);
	    		selected_perk = true;

	    		print("KEVLAR SELECTED");
    		}

        	if (!cfg_playertechs.exists(player.getUsername() + "_kevlar") && player.getCoins() >= 30)
        	{
        		cfg_playertechs.add_bool(player.getUsername() + "_kevlar", true);
        		
        		bought_perk = true;
        		player.server_setCoins(player.getCoins() - 30);

        		print("KEVLAR BOUGHT");
        	}
        }
        if (name == "Conditioning") 
        {
        	if (player.getCoins() >= 30 || cfg_playertechs.exists(player.getUsername() + "_conditioning"))
			{
				player.Untag("Kevlar");
	    		player.Sync("Kevlar", true);
	        	player.Untag("Blood Thirst");
	    		player.Sync("Blood Thirst", true);
	        	player.Untag("Commando");
	    		player.Sync("Commando", true);
	    		player.Untag("Sharpshooter");
	    		player.Sync("Sharpshooter", true);

	    		player.Tag("Conditioning");
	    		player.Sync("Conditioning", true);
	    		selected_perk = true;

	    		print("CONDITIONING SELECTED");
    		}

        	if (!cfg_playertechs.exists(player.getUsername() + "_conditioning") && player.getCoins() >= 30)
        	{
        		cfg_playertechs.add_bool(player.getUsername() + "_conditioning", true);
        		
        		bought_perk = true;
        		player.server_setCoins(player.getCoins() - 30);

        		print("CONDITIONING BOUGHT");
        	}
        }
        if (name == "Blood Thirst") 
        {
        	if (player.getCoins() >= 240 || cfg_playertechs.exists(player.getUsername() + "_bloodthirst"))
			{
	        	player.Untag("Kevlar");
	    		player.Sync("Kevlar", true);
	    		player.Untag("Conditioning");
	    		player.Sync("Conditioning", true);
	        	player.Untag("Commando");
	    		player.Sync("Commando", true);
	    		player.Untag("Sharpshooter");
	    		player.Sync("Sharpshooter", true);

	    		player.Tag("Blood Thirst");
	    		player.Sync("Blood Thirst", true);
	    		selected_perk = true;

	    		print("BLOOD THIRST SELECTED");
    		}

        	if (!cfg_playertechs.exists(player.getUsername() + "_bloodthirst") && player.getCoins() >= 240)
        	{
        		cfg_playertechs.add_bool(player.getUsername() + "_bloodthirst", true);
        		
        		bought_perk = true;
        		player.server_setCoins(player.getCoins() - 240);

        		print("BLOOD THIRST BOUGHT");
        	}
        }
        if (name == "Commando") 
		{
			if (player.getCoins() >= 240 || cfg_playertechs.exists(player.getUsername() + "_commando"))
			{
				player.Untag("Kevlar");
	    		player.Sync("Kevlar", true);
	    		player.Untag("Conditioning");
	    		player.Sync("Conditioning", true);
				player.Untag("Blood Thirst");
	    		player.Sync("Blood Thirst", true);
	    		player.Untag("Sharpshooter");
	    		player.Sync("Sharpshooter", true);

				player.Tag("Commando");
				player.Sync("Commando", true);
				selected_perk = true;

				print("COMMANDO SELECTED");
			}

			if (!cfg_playertechs.exists(player.getUsername() + "_commando") && player.getCoins() >= 240)
			{
				cfg_playertechs.add_bool(player.getUsername() + "_commando", true);

				bought_perk = true;
				player.server_setCoins(player.getCoins() - 240);

				print("COMMANDO BOUGHT");
			}
		}
		if (name == "Sharpshooter") 
		{
			if (player.getCoins() >= 240 || cfg_playertechs.exists(player.getUsername() + "_sharpshooter"))
			{
				player.Untag("Kevlar");
	    		player.Sync("Kevlar", true);
	    		player.Untag("Conditioning");
	    		player.Sync("Conditioning", true);
				player.Untag("Blood Thirst");
	    		player.Sync("Blood Thirst", true);
	    		player.Untag("Commando");
	    		player.Sync("Commando", true);
				
				player.Tag("Sharpshooter");
				player.Sync("Sharpshooter", true);
				selected_perk = true;

				print("SHARPSHOOTER SELECTED");
			}

			if (!cfg_playertechs.exists(player.getUsername() + "_sharpshooter") && player.getCoins() >= 240)
			{
				cfg_playertechs.add_bool(player.getUsername() + "_sharpshooter", true);

				bought_perk = true;
				player.server_setCoins(player.getCoins() - 240);

				print("SHARPSHOOTER BOUGHT");
			}
		}

		if (bought_perk)
		{
			print(">>bought perk");
			this.getSprite().PlaySound("UnlockClass");

			if (player.isMyPlayer())
			{
				client_AddToChat(name + " perk has been bought, and selected!");
			}
		}
		else
		{
			if (selected_perk)
			{
				print(">>selected perk");
				this.getSprite().PlaySound("SelectPerk");

				if (player.isMyPlayer())
				{
					client_AddToChat(name + " perk has been selected.");
				}
			}
		}

        cfg_playertechs.saveFile("KAWW_Techs.cfg");
    }
}