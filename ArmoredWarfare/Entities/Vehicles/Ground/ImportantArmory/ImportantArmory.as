#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "PlayerRankInfo.as"

// Armory logic

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("armory");
	this.Tag("importantarmory");
	this.Tag("truck");
	
	this.set_u16("extra_no_heal", 15);
	
	if (getRules() !is null) getRules().set_u32("iarmory_warn"+this.getTeamNum(), 0);

	this.addCommandID("separate");
	this.addCommandID("pick_10");
	this.addCommandID("pick_5");
	this.addCommandID("pick_2");
	this.addCommandID("pick_1");

	AddIconToken("$icon_10%$", "Scrap.png", Vec2f(16, 16), 3);
	AddIconToken("$icon_5%$", "Scrap.png", Vec2f(16, 16), 2);
	AddIconToken("$icon_2%$", "Scrap.png", Vec2f(16, 16), 1);
	AddIconToken("$icon_1$", "Scrap.png", Vec2f(16, 16), 0);

	Vehicle_Setup(this,
	              5000.0f, // move speed  //103
	              0.4f,  // turn speed
	              Vec2f(0.0f, 0.57f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_SetupGroundSound(this, v, "ArmoryEngine",  // movement sound
	                         0.35f, // movement sound volume modifier   0.0f = no manipulation
	                         0.5f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(17.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(15.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-26.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-27.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	this.getShape().SetOffset(Vec2f(-4, 2)); //0,8

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 80, 80);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 1, 2 };
		front.animation.AddFrames(frames);
		front.SetRelativeZ(0.8f);
		front.SetOffset(Vec2f(0.0f, 0.0f));
	}

	//INIT COSTS
	InitCosts();

	CBlob@[] tents;
    getBlobsByName("tent", @tents);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(10, 5));
	this.set_string("shop description", "Buy Equipment");
	this.set_u8("shop icon", 25);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_ft$", "IconFT.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_barge$","IconBarge.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_importantarmoryt2$", "ImportantArmoryT2.png", Vec2f(32, 32), 25, this.getTeamNum());

	bool t1 = this.getName() == "importantarmory";
	bool t2 = this.getName() == "importantarmoryt2";

	{
		ShopItem@ s = addShopItem(this, "Ammuniton", "$ammo$", "ammo", "Ammo for machine guns and infantry.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 3);
	}
	if (t2)
	{
		ShopItem@ s = addShopItem(this, "Special Ammuniton", "$specammo$", "specammo", "Special Ammo for advanced weapons.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "14.5mm Rounds", "$mat_14mmround$", "mat_14mmround", "Ammo for an APC.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "105mm Shells", "$mat_bolts$", "mat_bolts", "Ammo for a tank's main gun.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press [E] to heal. Has 4 uses total. Bonus: allows medics to perform healing faster.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 12);
	}
	{
		ShopItem@ s = addShopItem(this, "Binoculars", "$binoculars$", "binoculars", "A pair of zooming binoculars that allow you to see much further. Carry them and hold [RIGHT MOUSE] ", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Pipe Wrench", "$pipewrench$", "pipewrench", "Left click on vehicles to repair them. Limited uses.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Grenade", "$grenade$", "grenade", "Very effective against vehicles or in close quarter rooms.\nPress [SPACEBAR] to pull the pin, [C] to throw.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Sticky Frag Grenade", "$sgrenade$", "sgrenade", "Press SPACE while holding to arm, ~4 seconds until boom.\nSticky to vehicles, bodies and blocks.", false);
		AddRequirement(s.requirements, "blob", "grenade", "Grenade", 1);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
		//AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Molotov", "$mat_molotov$", "mat_molotov", "A home-made cocktail with highly flammable liquid.\nPress [SPACEBAR] before throwing", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "HEAT Warheads", "$mat_heatwarhead$", "mat_heatwarhead", "Ammo for RPGs.\nHas a small explosion radius.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nPROS: Very fast, medium firerate\nCONS: Very fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nPROS: Fast, good firerate\nCONS: Weak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nPROS: Good engine power, fast, good elevation angles\nCONS: Medium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 45);
	}
	if (t2)
	{
		{
			ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy MachineGun.\nCan be attached to some tanks.\n\nUses Ammunition.", false, true);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
		}
		{
			ShopItem@ s = addShopItem(this, "Firethrower", "$icon_ft$", "firethrower", "Fire thrower.\nCan be attached to some tanks.\n\nUses Ammunition.", false, true);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
		}
		
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nPROS: Thick armor, big cannon damage.\nCONS: Slow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 65);
	}
	if (t1)
	{
		ShopItem@ s = addShopItem(this, "Upgrade the Armory!", "$icon_importantarmoryt2$", "importantarmoryt2", "Reinforced variant of the armory, with better protection and crafting tools");
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 200);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 45);
	}
	if (t1)
	{
		{
			ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy MachineGun.\nCan be attached to some tanks.\n\nUses Ammunition.", false, true);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
		}
		{
			ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
		}
		{
			ShopItem@ s = addShopItem(this, "Bomber Bomb", "$mat_smallbomb$", "mat_smallbomb", "Bombs for bomber planes.", false);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);

			s.customButton = true;

			s.buttonwidth = 1;
			s.buttonheight = 1;
		}
		{
			ShopItem@ s = addShopItem(this, "C-4 Explosive", "$c4$", "c4", "C-4\nA strong explosive, very effective against blocks and doors.\n\nTakes 10 seconds after activation to explode.\nYou can deactivate it as well.", false, false);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
			//AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
		}
	}

	if (t2)
	{
		this.set_Vec2f("shop menu size", Vec2f(11, 7));
		{
			ShopItem@ s = addShopItem(this, "Build Bomber Plane", "$bomberplane$", "bomberplane", "A bomber plane.\nUses bomber bombs.");
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 70);
		}

		{
			ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
		}
		{
			ShopItem@ s = addShopItem(this, "Barge", "$icon_barge$", "barge", "An armored boat for transporting vehicles across the water.", false, true);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
		}

		{
			ShopItem@ s = addShopItem(this, "Build a Maus", "$maus$", "maus", "Super heavy tank.\n\nThick armor, best turret armor, big cannon damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm");
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
		}
		{
			ShopItem@ s = addShopItem(this, "Build Artillery", "$artillery$", "artillery", "A long-range, slow and fragile artillery.\n\nUses Bomber Bombs.");
			s.customButton = true;
			s.buttonwidth = 3;
			s.buttonheight = 2;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 50);
		}
		{
			ShopItem@ s = addShopItem(this, "Build UH1 Helicopter", "$uh1$", "uh1", "A helicopter with heavy machinegun.\nPress SPACEBAR to launch HEAT warheads.");
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 50);
		}
		{
			ShopItem@ s = addShopItem(this, "Bomber Bomb", "$mat_smallbomb$", "mat_smallbomb", "Bombs for bomber planes.", false);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);

			s.customButton = true;

			s.buttonwidth = 1;
			s.buttonheight = 1;
		}
		{
			ShopItem@ s = addShopItem(this, "C-4 Explosive", "$c4$", "c4", "C-4\nA strong explosive, very effective against blocks and doors.\n\nTakes 10 seconds after activation to explode.\nYou can deactivate it as well.", false, false);
			s.customButton = true;
			s.buttonwidth = 1;
			s.buttonheight = 1;
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
			//AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
		}
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.SetFacingLeft(this.getTeamNum() == teamright);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f(-18, 0));

	this.set_bool("shop available", true);

	if (!canSeeButtons(this, caller)) return;

	if (this.getDistanceTo(caller) < this.getRadius())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton(24, Vec2f(-9, -10), this, this.getCommandID("separate"), "Pick scrap", params);
	}

	// button for runner
	// create menu for class change
	if (caller.getTeamNum() == this.getTeamNum())
	{
		caller.CreateGenericButton("$change_class$", Vec2f(10, 0), this, buildSpawnMenu, getTranslatedString("Swap Class"));
		caller.CreateGenericButton("$change_perk$", Vec2f(0, -10), this, buildPerkMenu, getTranslatedString("Switch Perk"));
	}
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 60)
	{
		this.Tag("respawn");
		CBlob@[] tents;
   		getBlobsByName("tent", @tents);
		for (u8 i = 0; i < tents.length; i++)
		{
			if (tents[i] !is null && tents[i].getTeamNum() == this.getTeamNum())
			{
				this.Untag("respawn");
				break;
			}
		}
		
		InitClasses(this);
	}
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		CSprite@ sprite = this.getSprite();
		if (getNet().isClient())
		{
			CPlayer@ p = getLocalPlayer();
			if (p !is null)
			{
				CBlob@ local = p.getBlob();
				if (local !is null)
				{
					CSpriteLayer@ front = sprite.getSpriteLayer("front layer");
					if (front !is null)
					{
						//front.setVisible(!local.isAttachedTo(this));
					}
				}
			}
		}

		Vec2f vel = this.getVelocity();
		if (!this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(Vec2f(vel.x * 0.995, vel.y));
		}
		else if (Maths::Abs(vel.x) > 2.0f)
		{
			if (getGameTime() % 4 == 0)
			{
				if (isClient())
				{
					Vec2f pos = this.getPosition();
					CMap@ map = getMap();
					
					ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(18) - 9 + (this.isFacingLeft() ? 30 : -30), XORRandom(18) - 3), getRandomVelocity(0.0f, 0.5f + XORRandom(60) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.1f), float(XORRandom(360)), 0.7f + XORRandom(70) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
				}
			}
		}
	}

	Vehicle_LevelOutInAir(this);

	CBlob@[] tents;
	getBlobsByName("tent", @tents);
	if (tents.length == 0) this.set_u16("capture time", 0);
}

// Lose
void onDie(CBlob@ this)
{
	if (this.hasTag("upgrade")) return;
    Explode(this, 64.0f, 1.0f);

	bool dont_end = false;

	CBlob@[] iarmories;
	getBlobsByTag("importantarmory", @iarmories);

	for (u8 i = 0; i < iarmories.length; i++)
	{
		CBlob@ iarmory = iarmories[i];
		if (iarmory.getTeamNum() != this.getTeamNum()) continue;
		if (iarmory is this) continue;
		dont_end = true;
	}
	
	if (dont_end) return;
	CBlob@[] tents;
	getBlobsByName("tent", @tents);

	if (tents.length == 0)
	{
		u8 teamleft = getRules().get_u8("teamleft");
		u8 teamright = getRules().get_u8("teamright");
		u8 team = (this.getTeamNum() == teamleft ? teamright : teamleft);
		getRules().SetTeamWon(team);
		getRules().SetCurrentState(GAME_OVER);
		CTeam@ teamis = getRules().getTeam(team);
		if (teamis !is null) getRules().SetGlobalMessage(teamis.getName() + " destroyed the enemy Truck!\n\nLoading next map..." );
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	return false;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{
	//.	
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle"))
	{
		return false;
	}

	if (blob.hasTag("flesh") && !blob.isAttached())
	{
		return true;
	}
	else
	{
		return Vehicle_doesCollideWithBlob_ground(this, blob);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		if (blob.hasTag("material") && !blob.hasTag("no_armory_pickup") && !blob.isAttached() && !blob.isInInventory())
		{
			if (isServer()) this.server_PutInInventory(blob);
			//else this.getSprite().PlaySound("BridgeOpen.ogg", 1.0f);
		}
		TryToAttachVehicle(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	attachedPoint.offsetZ = 1.0f;
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

bool isOverlapping(CBlob@ this, CBlob@ blob)
{
	Vec2f tl, br, _tl, _br;
	this.getShape().getBoundingRect(tl, br);
	blob.getShape().getBoundingRect(_tl, _br);
	return br.x > _tl.x
	       && br.y > _tl.y
	       && _br.x > tl.x
	       && _br.y > tl.y;
}

void PackerMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer() && caller.getControls() !is null)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(caller.getControls().getMouseScreenPos() + Vec2f(0.0f, 0.0f), this, Vec2f(4, 1), "Take amount");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = false;

			CGridButton@ button1 = menu.AddButton("$icon_1$", "Pick 1", this.getCommandID("pick_1"), Vec2f(1, 1), params);
			CGridButton@ button2 = menu.AddButton("$icon_2%$", "Pick 2", this.getCommandID("pick_2"), Vec2f(1, 1), params);
			CGridButton@ button5 = menu.AddButton("$icon_5%$", "Pick 5", this.getCommandID("pick_5"), Vec2f(1, 1), params);
			CGridButton@ button10 = menu.AddButton("$icon_10%$", "Pick 10", this.getCommandID("pick_10"), Vec2f(1, 1), params);
			
			for (u8 i = 0; i < 4; i++)
			{
				CGridButton@ button;
				if (i == 0) @button = @button1;
				else if (i == 1) @button = @button2;
				else if (i == 2) @button = @button5;
				else if (i == 3) @button = @button10;

				if (button !is null)
				{
					CInventory@ inv = this.getInventory();
					if (inv !is null)
					{
						if (inv.getItem("mat_scrap") is null || inv.getItem("mat_scrap").getQuantity() <= (i==0?1:i==1?2:i==2?5:10)) button.SetEnabled(false);
					}
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);

	if (cmd == this.getCommandID("shop made item"))
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
			CBlob@ purchase = getBlobByNetworkID(item);

			purchase.setPosition(this.getPosition());

			if (callerBlob is null || purchase is null)
			{
				return;
			}

			if (purchase.getName() == "maus")
			{
				if (callerBlob.getPlayer() !is null && callerBlob.getPlayer().getSex() == 1)
				{
					purchase.Tag("pink");
					CBitStream params;
					params.write_bool(true);
					purchase.SendCommand(purchase.getCommandID("sync_color"), params);
				}
			}
			else if (purchase.getName() == "importantarmoryt2")
			{
				purchase.server_SetHealth(purchase.getInitialHealth()*(this.getHealth()/this.getInitialHealth()));

				this.getSprite().PlaySound("/UpgradeT2.ogg", 1.0f, 0.85f);
				this.Tag("upgrade");
				this.server_Die();
			}
		}
	}
	else if (cmd == this.getCommandID("separate"))
	{
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (this !is null && blob !is null)
		{
			PackerMenu(this, blob);
		}
	}
	else if (isServer() && cmd == this.getCommandID("pick_1") || cmd == this.getCommandID("pick_2")
	|| cmd == this.getCommandID("pick_5") || cmd == this.getCommandID("pick_10"))
	{
		u16 blobid;
		if (!params.saferead_u16(blobid)) return;
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (blob !is null)
		{
			if (this !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					CBlob@ item = inv.getItem("mat_scrap");
					if (item !is null)
					{
						u8 amount = 0;
						u16 count = item.getQuantity();

						if (cmd == this.getCommandID("pick_1"))
							amount = 1;
						else if (cmd == this.getCommandID("pick_2"))
							amount = 2;
						else if (cmd == this.getCommandID("pick_5"))
							amount = 5;
						else if (cmd == this.getCommandID("pick_10"))
							amount = 10;

						if (isServer() && count > 0)
						{
							if ((0.0f+count)-amount >= 0)
							{
								item.server_SetQuantity(count-amount);
								CBlob@ drop = server_CreateBlob(item.getName(), item.getTeamNum(), this.getPosition());
								drop.server_SetQuantity(amount);
								if (!blob.server_PutInInventory(drop))
								{
									drop.setPosition(this.getPosition());
								}
							}
						}
					}
				}
			}
		}
	}
}


f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("plane")) return damage*0.075f;

	if (customData == Hitters::fire) return damage / 4;

	if (getRules() !is null && isServer() && hitterBlob.getTeamNum() != this.getTeamNum()
	&& getRules().get_u32("iarmory_warn"+this.getTeamNum()) <= getGameTime())
	{
		this.set_u32("iarmory_warn"+this.getTeamNum(), getGameTime()+150);

		CBitStream params;
		params.write_u8(this.getTeamNum());
		getRules().SendCommand(getRules().getCommandID("iarmorywarn"), params);
	}
	if (hitterBlob.getName() == "mat_smallbomb" && hitterBlob.getQuantity() > 0)
	{
		return damage / hitterBlob.getQuantity();
	}
	if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 0.7f;
	}
	if (hitterBlob.getName() == "ballista_bolt")
	{
		if (hitterBlob.hasTag("rpg")) return damage * 1.1f;
		return damage * 1.5f;
	}
	if (hitterBlob.hasTag("grenade"))
	{
		return damage * 0.75f;
	}
	if (hitterBlob.getName() == "c4")
	{
		return damage * 0.25f;
	}
	if (hitterBlob.hasTag("bullet"))
	{
		if (hitterBlob.hasTag("aircraft_bullet")) return damage * 0.3f;
		else if (hitterBlob.hasTag("strong")) return damage *= 1.5f;
		return damage;
	}
	return damage;
}