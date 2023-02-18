#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"

// Armory logic

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("armory");
	this.Tag("truck");

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
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-26.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }


	this.getShape().SetOffset(Vec2f(-4, 0)); //0,8

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
	this.set_Vec2f("shop menu size", Vec2f(9, 2));
	this.set_string("shop description", "Buy Equipment");
	this.set_u8("shop icon", 25);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);

	{
		ShopItem@ s = addShopItem(this, "Frag Grenade", "$grenade$", "grenade", "Press SPACE while holding to arm, ~4 seconds until boom.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Land Mine", "$mine$", "mine", "Takes a while to arm, once activated it will expode upon contact with the enemy.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Tank Trap", "$tanktrap$", "tanktrap", "Czech hedgehog, will harm any enemy vehicle that collides with it.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press E to heal. 6 uses.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 2);
	}
	{
		ShopItem@ s = addShopItem(this, "Burger", "$food$", "food", "Heal to full health instantly.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 1);
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
	}
	{
		ShopItem@ s = addShopItem(this, "7mm Rounds", "$mat_7mmround$", "mat_7mmround", "Used by all small arms guns, and vehicle machineguns.", false);
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
		ShopItem@ s = addShopItem(this, "HEAT War Heads", "$mat_heatwarhead$", "mat_heatwarhead", "Ammunition for anti-tank guns, helis, javelins, etc..", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "M22 Binoculars", "$binoculars$", "binoculars", "A pair of glasses with optical zooming.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy MachineGun", "$icon_mg$", "heavygun", "Heavy machinegun.\nOpen nearby a tank to attach on its turret.\n\nUses 7.62mm.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher. ", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Bomber Bomb", "$mat_smallbomb$", "mat_smallbomb", "Bombs for bomber planes.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);

		s.customButton = true;

		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	//{
	//	ShopItem@ s = addShopItem(this, "Nuke", "$mat_nuke$", "mat_nuke", "The best way to destroy enemy facilities.\nNo area pollutions included!", false);
	//	AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 375);
//
	//	s.customButton = true;
//
	//	s.buttonwidth = 1;
	//	s.buttonheight = 1;
	//}
	

	this.SetFacingLeft(this.getTeamNum() == 1 ? true : false);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f(-18, 0));

	this.set_bool("shop available", true);


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
	if (tents.length == 0) this.set_u16("capture time", 0);
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
}


f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "missile_javelin" || hitterBlob.getName() == "ballista_bolt")
	{
		return damage * 1.25f;
	}
	if (hitterBlob.hasTag("grenade"))
	{
		return damage * 0.5f;
	}
	if (hitterBlob.hasTag("bullet") && hitterBlob.hasTag("strong"))
	{
		return damage *= 1.5f;
	}
	return damage;
}