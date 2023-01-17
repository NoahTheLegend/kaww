#include "ClassSelectMenu.as"
#include "KnockedCommon.as"

void InitRespawnCommand(CBlob@ this)
{
	this.addCommandID("class menu");
}

bool canChangeClass(CBlob@ this, CBlob@ blob)
{
    if (blob.hasTag("switch class")) return false;

	Vec2f tl, br, _tl, _br;
	this.getShape().getBoundingRect(tl, br);
	blob.getShape().getBoundingRect(_tl, _br);
	return br.x > _tl.x
	       && br.y > _tl.y
	       && _br.x > tl.x
	       && _br.y > tl.y;
}

// default classes
void InitClasses(CBlob@ this)
{
	AddIconToken("$crewman_class_icon$", "ClassIcon.png", Vec2f(48, 48), 1);
	AddIconToken("$ranger_class_icon$", "ClassIcon.png", Vec2f(48, 48), 2);
	AddIconToken("$shotgun_class_icon$", "ClassIcon.png", Vec2f(48, 48), 3);
	AddIconToken("$sniper_class_icon$", "ClassIcon.png", Vec2f(48, 48), 4);
	AddIconToken("$antitank_class_icon$", "ClassIcon.png", Vec2f(48, 48), 5);
	AddIconToken("$medic_class_icon$", "ClassIcon.png", Vec2f(48, 48), 6);
	AddIconToken("$lmg_class_icon$", "ClassIcon.png", Vec2f(48, 48), 7);
	AddIconToken("$slave_class_icon$", "ClassIcon.png", Vec2f(48, 48), 0);
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	AddIconToken("$change_perk$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 11);
	
	addPlayerClass(this, "---- Mechanic ----", "$slave_class_icon$", "slave",
						"---- Mechanic ----\n\nBuild and break.\nCan't capture flags.\n\nHP: 225\nLMB: Build\nRMB: Mine");

	addPlayerClass(this, "---- Python ----", "$crewman_class_icon$", "revolver",
						"---- Python ----\n\nGreat headshot damage and HP.\n\nHP: 350\nLMB: Shoot\nRMB: Aim\nSPACEBAR: Knife");

	addPlayerClass(this, "---- AK-47 ----", "$ranger_class_icon$", "ranger",
						"---- AK-47 ----\n\nExcellent rate of fire.\n\nHP: 175\nLMB: Shoot\nRMB: Aim\nSPACEBAR: Buttstock");

	addPlayerClass(this, "---- Shotgun ----", "$shotgun_class_icon$", "shotgun",
						"---- Shotgun ----\n\nDeadly at close range.\n\nHP: 250\nLMB: Shoot\nRMB: Aim\nSPACEBAR: Dig");

	addPlayerClass(this, "---- Sniper ----", "$sniper_class_icon$", "sniper",
						"---- Sniper ----\n\nLong range sniper.\n\nHP: 175\nLMB: Shoot\nRMB: Scope in\nSPACEBAR: Knife");

	addPlayerClass(this, "---- Anti-Tank ----", "$antitank_class_icon$", "antitank",
						"---- Anti-Tank ----\n\nArmed with a powerful RPG launcher.\n\nHP: 225.\nLMB: RPG\nRMB: Aim\nSPACEBAR: Knife");

	addPlayerClass(this, "---- MP5 ----", "$medic_class_icon$", "mp5",
						"---- MP5 ----\n\nSpecializes in healing teammates.\nReceives only half healing value.\n\nHP: 175\nLMB: Shoot\nRMB: Aim\nSPACEBAR: Heal pack");

	//addPlayerClass(this, "---- LMG ----", "$lmg_class_icon$", "lmg", "---- LMG ----\n\nExtreme firepower.\nLMB: LMG\nRMB: ADS");
	
	AddIconToken("$0_class_icon$", "PerkIcon.png", Vec2f(36, 36), 0);
	AddIconToken("$1_class_icon$", "PerkIcon.png", Vec2f(36, 36), 1);
	AddIconToken("$2_class_icon$", "PerkIcon.png", Vec2f(36, 36), 2);
	AddIconToken("$3_class_icon$", "PerkIcon.png", Vec2f(36, 36), 3);
	AddIconToken("$4_class_icon$", "PerkIcon.png", Vec2f(36, 36), 4);
	AddIconToken("$5_class_icon$", "PerkIcon.png", Vec2f(36, 36), 5);
	AddIconToken("$6_class_icon$", "PerkIcon.png", Vec2f(36, 36), 6);
	AddIconToken("$7_class_icon$", "PerkIcon.png", Vec2f(36, 36), 7);

	addPlayerPerk(this, "No Perk", "$0_class_icon$", "No Perk", "---- No Perk ----");

	addPlayerPerk(this, "Death Incarnate", "$7_class_icon$", "Death Incarnate",
						"I am Death Incarnate!\n\n"+"$7_class_icon$"+"Bring em' on!"
						+"\n                   - Take twice as much damage     "
						+"\n                   - Enemy kill XP gain: 300%  "
						);

	addPlayerPerk(this, "Camouflage", "$6_class_icon$", "Camouflage",
						"Ghillie Suit:\n\n"+"$6_class_icon$"+"Ghillie suit"
						+"\n                   - Turn into a mobile bush!     "
						+"\n\n                   Flammable"
						+"\n                   - Fire is more deadly   "
						);	

	addPlayerPerk(this, "Sharp Shooter", "$1_class_icon$", "Sharp Shooter",
						"Bullseye:\n\n"+"$1_class_icon$"+"Marksman"
						+"\n                   - Headshot damage: 150%       "
						+"\n                   - Increased accuracy"
						+"\n\n                  Long reload"
						+"\n                   - Reload time: 150%     "
						);

	addPlayerPerk(this, "Bloodthirst", "$3_class_icon$", "Bloodthirsty",
						"Bloodthirst:\n\n"+"$3_class_icon$"+"Vampirism"
						+"\n                   - Regenerate health when killing     "
						+"\n\n                  Healing"
						+"\n                   - Faster rate of regeneration   "
						+"\n\n                  Silver bullets"
						+"\n                   - Take 133% damage from bullets       "
						);

	addPlayerPerk(this, "Operator", "$5_class_icon$", "Operator",
						"Operator:\n\n"+"$5_class_icon$"+"Crewman"
						+"\n                   - Improved vehicle handling"
						+"\n                   - Improved vehicle repair speed     "
						+"\n\n                   Gunner"
						+"\n                   - Less machine gun heat"
						+"\n                   - Improved vehicle aiming speed "
						+"\n\n                   Sluggish"
						+"\n                   - Can't sprint  "
						+"\n\n                   Vulnerability    "
						+"\n                   - Take 133% headshot damage"
						+"\n                   - Take 175% explosion damage"
						);

	addPlayerPerk(this, "Lucky", "$4_class_icon$", "Lucky",
						"Lucky:\n\n"+"$4_class_icon$"+"Fate's Friend"
						+"\n                   - Always survive on last-hit          "
						+"\n                   if damage is higher than 10.          "
						+"\n                   applies to vehicles as well          "
						+"\n\n                  Lucky Charm"
						+"\n                   - Must carry an Ace of Spades           "
						);

	addPlayerPerk(this, "Wealthy", "$2_class_icon$", "Supply Chain",
						"Wealthy:\n\n"+"$2_class_icon$"+"Highroller"
						+"\n                   - Twice as much money earned"
						+"\n\n                  Health Insurance"
						+"\n                   - Lose half of all money on death          "
						);	
}

void BuildRespawnMenuFor(CBlob@ this, CBlob @caller)
{
	PlayerClass[]@ classes;
	this.get("playerclasses", @classes);

	if (caller !is null && caller.isMyPlayer() && classes !is null)
	{
		CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0.0f, caller.getRadius() * 1.0f + 48.0f), this, Vec2f(classes.length * CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE), getTranslatedString("CHANGE CLASS"));
		if (menu !is null)
		{
			addClassesToMenu(this, menu, caller.getNetworkID());
		}
	}
}

void BuildPerkMenuFor(CBlob@ this, CBlob @caller)
{
	PlayerPerk[]@ perks;
	this.get("playerperks", @perks);

	if (caller !is null && caller.isMyPlayer() && perks !is null)
	{
		CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(-0.0f, caller.getRadius() * 1.0f + 48.0f), this, Vec2f(perks.length * PERK_BUTTON_SIZE, PERK_BUTTON_SIZE), getTranslatedString("CHOOSE A PERK"));
		if (menu !is null)
		{
			addPerksToMenu(this, menu, caller.getNetworkID());
		}
	}
}

void buildSpawnMenu(CBlob@ this, CBlob@ caller)
{
	BuildRespawnMenuFor(this, caller);
}

void buildPerkMenu(CBlob@ this, CBlob@ caller)
{
	BuildPerkMenuFor(this, caller);
}

void onRespawnCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	switch (cmd)
	{
		// build menus
		case SpawnCmd::buildMenu: 
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			BuildRespawnMenuFor(this, caller);
		}
		break;
		case SpawnCmd::buildPerkMenu: 
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			BuildPerkMenuFor(this, caller);
		}
		break;

		// not unlocked yet
		case SpawnCmd::lockedItem: 
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller.isMyPlayer())
			{
				this.getSprite().PlaySound("/NoAmmo", 0.5);
			}
		}
		break;

		// on change class
		case SpawnCmd::changeClass:
		{
			if (getNet().isServer())
			{
				// build menu for them
				CBlob@ caller = getBlobByNetworkID(params.read_u16());
				bool single_switch = this.getName() == "outpost";

				if (caller !is null)// && canChangeClass(this, caller))
				{
					string classconfig = params.read_string();
					CBlob @newBlob = server_CreateBlob(classconfig, caller.getTeamNum(), this.getRespawnPosition());

					if (newBlob !is null)
					{
						if (single_switch)
						{
							CBitStream stream;
							stream.write_u16(newBlob.getNetworkID());
							this.SendCommand(this.getCommandID("lock_classchange"), stream);
						}
						// copy health and inventory
						// make sack
						CInventory @inv = caller.getInventory();

						if (inv !is null)
						{
							if (this.hasTag("change class drop inventory"))
							{
								while (inv.getItemsCount() > 0)
								{
									CBlob @item = inv.getItem(0);
									caller.server_PutOutInventory(item);
								}
							}
							else if (this.hasTag("change class store inventory"))
							{
								if (this.getInventory() !is null)
								{
									caller.MoveInventoryTo(this);
								}
								else // find a storage
								{
									PutInvInStorage(caller);
								}
							}
							else
							{
								// keep inventory if possible
								caller.MoveInventoryTo(newBlob);
								if (caller.get_string("equipment_head") == "helmet")
								{
									newBlob.set_string("equipment_head", "helmet");
									addHead(newBlob, "helmet");
									//this.getCommandID("equip_head");
								}
							}
						}

						// set health to be same ratio
						float healthratio = caller.getHealth() / caller.getInitialHealth();
						newBlob.server_SetHealth(newBlob.getInitialHealth() * healthratio);

						// copy stun
						if (isKnockable(caller))
						{
							setKnocked(newBlob, getKnockedRemaining(caller));
						}

						// plug the soul
						newBlob.server_SetPlayer(caller.getPlayer());
						newBlob.setPosition(caller.getPosition());

						// no extra immunity after class change
						if (caller.exists("spawn immunity time"))
						{
							newBlob.set_u32("spawn immunity time", caller.get_u32("spawn immunity time"));
							newBlob.Sync("spawn immunity time", true);
						}

						caller.Tag("switch class");
						caller.server_SetPlayer(null);
						caller.server_Die();
					}
				}
			}
		}
		break;

		// on change perk
		case SpawnCmd::changePerk:
		{
			// build menu for them
			CBlob@ caller = getBlobByNetworkID(params.read_u16());

			string perkconfig = "";
			if (!params.saferead_string(perkconfig)) return;

			if (caller !is null)
			{
				CPlayer@ callerPlayer = caller.getPlayer();
				getRules().set_string(caller.getPlayer().getUsername() + "_perk", perkconfig);
				if (getNet().isServer())
				{
					// prevents doubling up on perks, although.. lucky + bloodthirsty is very fun
					if (caller.hasBlob("aceofspades", 1))
					{
						caller.TakeBlob("aceofspades", 1);
					}
				}
				//caller.Tag("reload_sprite");

				if (caller.isMyPlayer())
				{
					// sound
					this.getSprite().PlaySound("/SwitchPerk", 1.0, perkconfig == "No Ammo" ? 0.8 : 1.1);

					// chat message
					client_AddToChat("Perk switched to " + perkconfig, SColor(255, 42, 42, 42));
				}
			}
		}
		break;
	}
}

void addHead(CBlob@ playerblob, string headname)
{
	if (playerblob.get_string("equipment_head") == "")
	{
		if(playerblob.get_u8("override head") != 0)
			playerblob.set_u8("last head", playerblob.get_u8("override head"));
		else	
			playerblob.set_u8("last head", playerblob.getHeadNum());
	}

	{
		playerblob.Tag(headname);
		playerblob.set_string("reload_script", headname);
		playerblob.AddScript(headname+"_effect.as");
		playerblob.set_string("equipment_head", headname);
		playerblob.Tag("update head");
	}
}

void PutInvInStorage(CBlob@ blob)
{
	CBlob@[] storages;
	if (getBlobsByTag("storage", @storages))
		for (uint step = 0; step < storages.length; ++step)
		{
			CBlob@ storage = storages[step];
			if (storage.getTeamNum() == blob.getTeamNum())
			{
				blob.MoveInventoryTo(storage);
				return;
			}
		}
}

const bool enable_quickswap = false;
void CycleClass(CBlob@ this, CBlob@ blob)
{
	//get available classes
	PlayerClass[]@ classes;
	if (this.get("playerclasses", @classes))
	{
		CBitStream params;
		PlayerClass @newclass;

		//find current class
		for (uint i = 0; i < classes.length; i++)
		{
			PlayerClass @pclass = classes[i];
			if (pclass.name.toLower() == blob.getName())
			{
				//cycle to next class
				@newclass = classes[(i + 1) % classes.length];
				break;
			}
		}

		if (newclass is null)
		{
			//select default class
			@newclass = getDefaultClass(this);
		}

		//switch to class
		write_classchange(params, blob.getNetworkID(), newclass.configFilename);
		this.SendCommand(SpawnCmd::changeClass, params);
	}
}
