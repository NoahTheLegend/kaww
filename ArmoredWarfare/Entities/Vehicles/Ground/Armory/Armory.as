#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "VehiclesParams.as"

// Armory logic

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("armory");
	this.Tag("truck");

	AddIconToken("$icon_10%$", "Scrap.png", Vec2f(16, 16), 3);
	AddIconToken("$icon_5%$", "Scrap.png", Vec2f(16, 16), 2);
	AddIconToken("$icon_2%$", "Scrap.png", Vec2f(16, 16), 1);
	AddIconToken("$icon_1$", "Scrap.png", Vec2f(16, 16), 0);

	Vehicle_Setup(this,
	              4500.0f, // move speed  //103
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
	//CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 80, 80);
	//if (front !is null)
	//{
	//	front.addAnimation("default", 0, false);
	//	int[] frames = { 0, 1, 2 };
	//	front.animation.AddFrames(frames);
	//	front.SetRelativeZ(0.8f);
	//	front.SetOffset(Vec2f(0.0f, 0.0f));
	//}

	//INIT COSTS
	InitCosts();

	CBlob@[] tents;
    getBlobsByName("tent", @tents);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(7, 4));
	this.set_string("shop description", "Buy Equipment");
	this.set_u8("shop icon", 25);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_ft$", "IconFT.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_barge$","IconBarge.png", Vec2f(32, 32), 0, 2);
	
	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.SetFacingLeft(this.getTeamNum() == teamright);
}

void InitShop(CBlob@ this)
{
	bool isCTF = getBlobByName("pointflag") !is null || getBlobByName("pointflagt2") !is null;
	if (isCTF) this.set_Vec2f("shop menu size", Vec2f(8, 4));

	{
		ShopItem@ s = addShopItem(this, "Standard Ammo", "$ammo$", "ammo", "Used by all small arms guns, and vehicle machineguns.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
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
		ShopItem@ s = addShopItem(this, "Anti-Tank Grenade", "$atgrenade$", "mat_atgrenade", "Press SPACE while holding to arm, ~5 seconds until boom.\nEffective against vehicles.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Frag Grenade", "$grenade$", "grenade", "Press SPACE while holding to arm, ~4 seconds until boom.\nIneffective against armored vehicles.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	
	{
		ShopItem@ s = addShopItem(this, "907 Kilogram-trotile Bomb", "$mat_907kgbomb$", "mat_907kgbomb", "A good way to damage enemy facilities.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 50);
		AddRequirement(s.requirements, "gametime", "", "Unlocks at", 15*30 * 60);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 3;
	}
	if (isCTF)
	{
		ShopItem@ s = addShopItem(this, "5000 Kilogram-trotile Bomb", "$mat_5tbomb$", "mat_5tbomb", "The best way to destroy enemy facilities.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 300);
		AddRequirement(s.requirements, "gametime", "", "Unlocks at", 30*30 * 60);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 4;
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

		s.buttonwidth = 2;
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
	makeShopItem(this,params,c_apsniper, Vec2f(3,1), false, false);}

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

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f(-18, 0));

	this.set_bool("shop available", true);

	if (this.getDistanceTo(caller) < this.getRadius())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton(24, Vec2f(-9, -10), this, this.getCommandID("separate"), "Pick scrap", params);
	}

	if (!canSeeButtons(this, caller)) return;

	// button for runner
	// create menu for class change
	if (canChangeClass(this, caller) && caller.getTeamNum() == this.getTeamNum())
	{
		caller.CreateGenericButton("$change_class$", Vec2f(10, 0), this, buildSpawnMenu, getTranslatedString("Swap Class"));
		caller.CreateGenericButton("$change_perk$", Vec2f(0, -10), this, buildPerkMenu, getTranslatedString("Switch Perk"));
	}
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1) InitShop(this);

	if (this.getTickSinceCreated() == 60)
	{
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
	if (tents.length == 0) this.set_f32("capture time", 0);
}

// Lose
void onDie(CBlob@ this)
{
    Explode(this, 64.0f, 1.0f);
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
	if (cmd == this.getCommandID("separate"))
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
	else if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort.ogg");
		
		bool isServer = (getNet().isServer());
		if (!isServer) return;
			
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		CBlob@ blob = getBlobByNetworkID( caller );
		CBlob@ purchase = getBlobByNetworkID( item );
		Vec2f pos = this.getPosition();
		
		string name = params.read_string();
		if (name == "mat_5tbomb" || name == "mat_907kgbomb")
		{
			u8 teamleft = getRules().get_u8("teamleft");
			u8 teamright = getRules().get_u8("teamright");
			u8 id = (name == "mat_5tbomb" ? 1 : 0);
			CBitStream params;
			params.write_bool(this.getTeamNum() == teamleft);
			params.write_u8(id);
			this.SendCommand(this.getCommandID("warn_opposite_team"), params);
		}
	}
	else if (cmd == this.getCommandID("warn_opposite_team"))
	{
		if (isClient())
		{
			bool warn_team = params.read_bool(); // left is true
			u8 id = params.read_u8();

			if (getLocalPlayer() !is null)
			{
				u8 teamleft = getRules().get_u8("teamleft");
				u8 teamright = getRules().get_u8("teamright");
				//printf(""+(getLocalPlayer().getTeamNum())+" "+teamleft+" "+teamright+" "+warn_team);
				if ((getLocalPlayer().getTeamNum() == teamleft && !warn_team)
					|| (getLocalPlayer().getTeamNum() == teamright && warn_team))
				{
					Sound::Play("nuke_warn.ogg", getDriver().getWorldPosFromScreenPos(getDriver().getScreenCenterPos()), 500.0f, 0.825f);
					client_AddToChat("Enemy has constructed a "+(id==0?"907kg":"5 ton")+" bomb!", SColor(255, 255, 0, 0));

					error("debug: playing sound & sending bomb warn message");
				}
				else
				{
					client_AddToChat("Your team has constructed a "+(id==0?"907kg":"5 ton")+" bomb. Enemies see that.", SColor(255, 0, 150, 0));
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "missile_javelin" || hitterBlob.getName() == "ballista_bolt")
	{
		return damage * 1.25f;
	}
	if (hitterBlob.hasTag("atgrenade"))
	{
		return damage * 0.5f;
	}
	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet);
	if (is_bullet)
	{
		return damage *= 1.25f;
	}
	return damage;
}