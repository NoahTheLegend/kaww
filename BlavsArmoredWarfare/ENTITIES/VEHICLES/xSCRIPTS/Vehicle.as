#include "WarfareGlobal.as"
#include "AllHashCodes.as"
#include "SeatsCommon.as"
#include "VehicleCommon.as"
#include "VehicleAttachmentCommon.as"
#include "GenericButtonCommon.as"
#include "Hitters.as";
#include "Explosion.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

string[] smokes = 
{
	"LargeSmoke.png",
	"SmallSmoke1.png",
	"SmallSmoke2.png"
};

const string wheelsTurnAmountString = "wheelsTurnAmount";
const string engineRPMString = "engine_RPM";
const string engineRPMTargetString = "engine_RPMtarget";
const string engineThrottleString = "engine_throttle";

const u8 turretShowHPSeconds = 8;

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.addCommandID("jam_engine");

	s8 armorRating = 0;
	bool hardShelled = false;

	s8 weaponRating = 0;

	string blobName = this.getName();
	int blobHash = blobName.getHash();
	switch(blobHash)
	{
		case _mausturret: // MAUS Shell cannon
		{
			armorRating = 5;
			hardShelled = true;
		}
		break;

		case _maus: // maus
		case _t10: // T10
		case _t10turret: // T10 Shell cannon
		armorRating = 4; break;
			
		case _m60: // normal tank
		case _m60turret: // M60 Shell cannon
		armorRating = 3; break;

		case _transporttruck: // vanilla truck?
		case _armory: // shop truck
		case _importantarmory:
		case _btr82a: // big APC
		case _btrturret: // big APC cannon
		case _bradley:
		case _bradleyturret:
		case _pszh4: // smol APC
		case _pszh4turret: // smol APC cannon
		case _heavygun: // MG
		armorRating = 2; break;

		case _uh1: // heli
		case _techtruck: // MG truck
		case _gun: // light MG
		armorRating = 1; break;

		case _bf109: // plane
		case _bomberplane:
		case _civcar: // car
		armorRating = 0; break;

		case _motorcycle: // bike
		case _jourcop: // journalist
		armorRating = -1; break;

		default:
		{
			//print ("blobName: "+ blobName + " hash: "+blobHash);
			//print ("-");
		}
	}

	f32 linear_length = 4.0f;
	f32 scale_damage = 1.0f;
	switch(blobHash) // weapon rating and length of linear (map) and circled explosion damage
	{
		case _mausturret: // MAUS Shell cannon
		{
			weaponRating = 3;
			linear_length = 16.0f;
			scale_damage = 2.5f;
			break;
		}
		case _t10turret: // T10 Shell cannon
		{
			weaponRating = 3;
			linear_length = 14.0f;
			scale_damage = 2.0f;
			break;
		}
		case _m60turret: // M60 Shell cannon
		{
			weaponRating = 2;
			linear_length = 10.0f;
			scale_damage = 1.75f;
			break;
		}
		case _uh1: // heli
		{
			weaponRating = 1;
			break;
		}
		case _heavygun: // MG
		{
			weaponRating = 1;
			break;
		}
		case _pszh4turret: // smol APC cannon
		{
			weaponRating = 1;
			linear_length = 4.0f;
			scale_damage = 0.85f;
			break;
		}
		case _btrturret: // big APC cannon
		{
			weaponRating = 1;
			linear_length = 4.0f;
			scale_damage = 0.85f;
			break;
		}
		case _bradleyturret:
		{
			weaponRating = -1;
			linear_length = 8.0f;
			scale_damage = 1.33f;
			break;
		}
	}
	this.set_f32("linear_length", linear_length);
	this.set_f32("explosion_damage_scale", scale_damage);

	float backsideOffset = -1.0f;
	switch(blobHash) // backside vulnerability point
	{
		case _maus: // maus
		backsideOffset = 24.0f; break;

		case _t10: // T10
		backsideOffset = 20.0f; break;
		
		case _m60: // normal tank
		backsideOffset = 16.0f; break;

		case _btr82a: // big APC
		case _bradley:
		backsideOffset = 16.0f; break;

		case _pszh4: // smol APC
		backsideOffset = 16.0f; break;

		case _uh1: // heli
		backsideOffset = 48.0f; break;

		case _bf109: // plane
		backsideOffset = 8.0f; break;

		case _bomberplane: // plane
		backsideOffset = 8.0f; break;
	}

	// speedy stuff
	f32 intake = 0.0f;
	switch(blobHash) // backside vulnerability point
	{
		case _maus: // maus
		intake = -50.0f; break;

		case _t10: // T10
		intake = -25.0f;
		break;
		
		case _m60: // normal tank
		intake = 50.0f; break;

		case _btr82a: // big APC
		intake = 75.0f; break;

		case _pszh4: // smol APC
		case _bradley:
		intake = 100.0f; break;

		case _techtruck: // truck
		intake = 150.0f; break;

		case _armory: // armory
		case _importantarmory:
		intake = 100.0f; break;

		case _motorcycle: // bike!
		intake = 200.0f; break;
	}
	this.set_f32("add_gas_intake", intake);

	this.set_f32(backsideOffsetString, backsideOffset);

	this.set_s8(armorRatingString, armorRating);
	this.set_bool(hardShelledString, hardShelled);

	this.set_s8(weaponRatingString, weaponRating);


	this.set_f32(engineRPMString, 0.0f);
	this.set_f32(engineThrottleString, 0.0f);

	this.set_f32(wheelsTurnAmountString, 0.0f);

	this.set_u32("show_hp", 0);
	this.set_string("invname", this.getInventoryName());
}

void onTick(CBlob@ this)
{
	if (getGameTime() % 45 == 0 && !this.hasTag("gun"))
	{
		if ((this.getPosition()-this.getOldPosition()).Length() <= 0.1f)
		{
			CBlob@[] bushes;
			if (getMap() !is null) getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @bushes);
			int bushcount = 0;
			for (u16 i = 0; i < bushes.length; i++)
			{
				if (bushes[i] is null || bushes[i].getName() != "bush") continue;
				else bushcount ++;
			}
			if (bushcount > 4)
			{
				if (!this.hasTag("turret"))
				{
					this.setInventoryName("");
				}

				this.set_u32("disguise", getGameTime() + 90);
			}
			else if (!this.hasTag("turret"))
			{
				this.setInventoryName(this.get_string("invname"));
			}
		}
		else
		{
			this.set_u32("disguise", getGameTime());
			this.setInventoryName(this.get_string("invname"));
		}
	}
	if (!(isClient() && isServer()) && !this.hasTag("aerial") && getGameTime() < 60*30 && !this.hasTag("pass_60sec"))
	{
		if (isClient() && this.getSprite() !is null) this.getSprite().SetEmitSoundPaused(true);
		return; // turn engines off!
	}
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	if (this.hasTag("aerial") && getGameTime()%10==0)
	{
		if (getMap() !is null)
		{
			if (this.getPosition().x <= 8.0f || this.getPosition().x >= (getMap().tilemapwidth*8)-8.0f) this.server_Hit(this, this.getPosition(), this.getVelocity(), 1.0f, Hitters::fall);
		}
	}

	if (this.hasTag("turret") && this.getHealth() <= 0.01f)
	{
		if (this.hasTag("broken"))
		{
			if (isClient() && getGameTime()%(10+XORRandom(11)) == 0)
			{
				Vec2f pos = this.getPosition();
				CMap@ map = getMap();
				if (map is null) return;

				ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(30) - 20, XORRandom(25) - 25), getRandomVelocity(0.0f, XORRandom(100) * 0.01f, 90), float(XORRandom(360)), 0.25f + XORRandom(75) * 0.01f, 4 + XORRandom(2), XORRandom(25) * -0.00005f, true);
			}
		}
	}
	else if (this.hasTag("broken") && this.getHealth() >= this.getInitialHealth()*0.2f) this.Untag("broken");

	AttachmentPoint@ drv = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (drv !is null && drv.getOccupied() !is null)
	{
		if (isServer())
		{
			if (getGameTime() % 30 == 0 && this.hasTag("engine_can_get_stuck") && this.getHealth() <= this.getInitialHealth()/6 && XORRandom(15) == 0) // jam engine on low hp
			{
				this.set_bool("engine_stuck", true);
				this.set_u32("engine_stuck_time", getGameTime()+50+XORRandom(90));

				CBitStream params;
				params.write_u32(this.get_u32("engine_stuck_time"));
				this.SendCommand(this.getCommandID("jam_engine"), params);
			}
		}
		if (this.get_bool("engine_stuck") && this.get_u32("engine_stuck_time") <= getGameTime())
		{
			this.getSprite().PlaySound("EngineStart_tank", 2.5f, 1.0f + XORRandom(11)*0.01f);
			this.set_bool("engine_stuck", false);
		}
	}

	// wheels
	if (this.getShape().vellen > 0.11f && !this.isAttached())
	{
		UpdateWheels(this);
	}

	// reload
	if (this.hasAttached() && getGameTime() % 2 == 0)
	{
		f32 time_til_fire = Maths::Max((v.fire_time - getGameTime()), 1);
		if (time_til_fire < 2)
		{
			Vehicle_LoadAmmoIfEmpty(this, v);
		}
	}

	// update movement sounds
	f32 velx = Maths::Abs(this.getVelocity().x);

	// ground sound
	if (velx < 0.5f)
	{
		CSprite@ sprite = this.getSprite();
		f32 vol = sprite.getEmitSoundVolume();
		sprite.SetEmitSoundVolume(vol * 0.95f);
		if (vol < 0.05f)
		{
			sprite.SetEmitSoundPaused(true);
			sprite.SetEmitSoundVolume(1.0f);
		}
	}
	else
	{
		if (this.isOnGround() && !v.ground_sound.isEmpty())
		{
			CSprite@ sprite = this.getSprite();
			if ((this.getVelocity().x > 0.01f || this.getVelocity().x < -0.01f) && sprite.getEmitSoundPaused())
			{
				this.getSprite().SetEmitSound(v.ground_sound);
				sprite.SetEmitSoundPaused(false);
			}

			f32 volMod = v.ground_volume;
			f32 pitchMod = v.ground_pitch;

			if (volMod > 0.0f)
			{
				sprite.SetEmitSoundVolume(Maths::Min(velx * 0.667f * volMod, 1.0f));
			}

			if (pitchMod > 0.0f)
			{
				sprite.SetEmitSoundSpeed(Maths::Max(Maths::Min(Maths::Sqrt(0.5f * velx * pitchMod), 1.5f), 0.75f));
			}
		}
		if (!this.isOnGround() && !v.water_sound.isEmpty())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite.getEmitSoundPaused())
			{
				this.getSprite().SetEmitSound(v.water_sound);
				sprite.SetEmitSoundPaused(false);
			}

			f32 volMod = v.water_volume;
			f32 pitchMod = v.water_pitch;

			if (volMod > 0.0f)
			{
				sprite.SetEmitSoundVolume(Maths::Min(velx * 0.565f * volMod, 1.0f));
			}

			if (pitchMod > 0.0f)
			{
				sprite.SetEmitSoundSpeed(Maths::Max(Maths::Min(Maths::Sqrt(0.5f * velx * pitchMod), 1.5f), 0.75f));
			}
		}
	}


	this.set_f32("engine_RPMtarget", Maths::Clamp(this.get_f32("engine_RPMtarget"), 0, 30000) );

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (ap !is null && this.get_f32("engine_RPMtarget") > this.get_f32("engine_RPM"))
	{
		if (ap.getOccupied() is null) this.set_f32("engine_RPMtarget", 0); // turn engine off
		f32 custom_add = this.get_f32("add_gas_intake");
		if (custom_add == 0) custom_add = 1.0f;
		f32 gas_intake = 180 + custom_add + XORRandom(70+custom_add/3.5f); // gas flow variance  (needs equation)
		if (this.get_f32("engine_RPM") > 2000) {gas_intake += 150;}
		this.add_f32("engine_RPM", this.get_f32("engine_throttle") * gas_intake); 

		if (XORRandom(100) < 60)
		{
			if (isClient())
			{	
				Vec2f velocity = Vec2f(((this.get_f32("engine_throttle") - 0.453)*143), 0);
				velocity *= this.isFacingLeft() ? 0.25 : -0.25;
				velocity *= this.get_f32("engine_RPM")/3000;
				velocity += Vec2f(0, -0.35) + this.getVelocity()*0.35f;
				//print("ve" + velocity);
				ParticleAnimated("Smoke", this.getPosition() + Vec2f_lengthdir(this.isFacingLeft() ? this.getWidth()/2.2 : -this.getWidth()/2.2, this.getAngleDegrees()), velocity.RotateBy(this.getAngleDegrees()) + getRandomVelocity(0.0f, XORRandom(35) * 0.01f, 360), 45 + float(XORRandom(90)), 0.3f + XORRandom(50) * 0.01f, Maths::Round(7 - Maths::Clamp(this.get_f32("engine_RPM")/1000, 1, 6)) + XORRandom(2), -0.02 - XORRandom(30) * -0.0005f, false );
			}
		}
	}

	// angling
	CSprite@ sprite = this.getSprite();
	if (sprite !is null) 
	{
		bool fl = this.getVelocity().x < -1.0f;
		bool slow_down = Maths::Abs(this.getVelocity().x) < Maths::Abs(this.getOldVelocity().x);

		f32 speed = Maths::Abs(this.getVelocity().x);
		f32 max_speed = v.move_speed/20000;

		f32 max_diff = 1.0f;
		if (this.exists("max_angle_diff")) max_diff = this.get_f32("max_angle_diff");

		//if (Maths::Abs(max_diff) > 0.1f)
		{
			sprite.ResetTransform();
			sprite.RotateBy((this.getPosition().x - this.getOldPosition().x)*-max_speed*max_diff, Vec2f(this.isFacingLeft() ? 6 : -6, 0));

			//print("angle " + (this.getPosition().x - this.getOldPosition().x)*-max_speed);
		}
	}
	else if (sprite !is null) sprite.ResetTransform();

	if (this.get_f32("engine_RPM") > 2000 || (ap !is null && ap.getOccupied() is null))
	{
		if (this.get_f32("engine_RPM") <= 150)
			this.set_f32("engine_RPM", 0);
		else
		{
			this.sub_f32("engine_RPM", 50 + XORRandom(80)); // more variance
			if (isClient() && this !is null) this.Sync("engine_RPM", true);
		}
	}

	this.set_f32("engine_RPM", Maths::Clamp(this.get_f32("engine_RPM"), 0.0f, 30000.0f));
	//if (this.getName() == "t10" && getGameTime() % 30 == 0 && (isServer() || (getLocalPlayer() !is null && getLocalPlayer().getUsername() == "NoahTheLegend" && getLocalPlayer().isMyPlayer())))
	//	printf(""+this.get_f32("engine_RPM")); // crashing server?

	// Crippled
	if (!this.hasTag("turret") && this.getHealth() <= this.getInitialHealth() * 0.3f)
	{
		if (getGameTime() % 4 == 0 && XORRandom(5) == 0)
		{
			const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius()*0.4f, 360);
			CParticle@ p = ParticleAnimated("BlackParticle.png", pos, Vec2f(0,0), -0.5f, 1.0f, 5.0f, 0.0f, false);
			if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

			Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

			ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);
		}

		Vec2f vel = this.getVelocity();
		if (this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(vel * 0.98);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	/// LOAD AMMO
	if (isServer && cmd == this.getCommandID("load_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			array < CBlob@ > ammos;
			array < string > eligible_ammo_names;

			for (int i = 0; i < v.ammo_types.length(); ++i)
			{
				const string ammo = v.ammo_types[i].ammo_name;
				eligible_ammo_names.push_back(ammo);
			}

			CBlob@ carryObject = caller.getCarriedBlob();
			// if player has item in hand, we only put that item into vehicle's inventory
			if (carryObject !is null && eligible_ammo_names.find(carryObject.getName()) != -1)
			{
				ammos.push_back(carryObject);
			}
			else
			{
				CInventory@ inv = caller.getInventory();

				for (int i = 0; i < v.ammo_types.length(); ++i)
				{
					const string ammo = v.ammo_types[i].ammo_name;

					for (int i = 0; i < inv.getItemsCount(); i++)
					{
						CBlob@ invItem = inv.getItem(i);
						if (invItem.getName() == ammo)
						{
							ammos.push_back(invItem);
						}
					}
				}
			}

			for (int i = 0; i < ammos.length; i++)
			{
				if (!this.server_PutInInventory(ammos[i]))
				{
					caller.server_PutInInventory(ammos[i]);
				}
			}

			RecountAmmo(this, v);
		}
	}
	// SWAP AMMO
	else if (cmd == this.getCommandID("swap_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		swapAmmo(this, v, v.current_ammo_index + 1);

		if(isServer)
			RecountAmmo(this, v);
	}
	else if (!isServer && cmd == this.getCommandID("sync_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		v.current_ammo_index = params.read_u8();
	}
	else if (!isServer && cmd == this.getCommandID("sync_last_fired"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		u8 last;
		if (!params.saferead_u8(last)) return;

		v.last_fired_index = last;
	}
	/// PUT IN MAG
	else if (isServer && cmd == this.getCommandID("putin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ blob = getBlobByNetworkID(params.read_u16());
		if (caller !is null && blob !is null)
		{
			// put what was in mag into inv
			CBlob@ magBlob = getMagBlob(this);
			if (magBlob !is null)
			{
				magBlob.server_DetachFromAll();
			}
			blob.server_DetachFromAll();
			this.server_AttachTo(blob, "MAG");
		}
	}
	/// FIRE
	else if (cmd == this.getCommandID("fire"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Fire(this, v, caller, charge);
		if (isServer)
			RecountAmmo(this, v);
	}
	/// FLIP OVER
	else if (cmd == this.getCommandID("flip_over"))
	{
		if (isFlipped(this))
		{
			this.getShape().SetStatic(false);
			this.getShape().doTickScripts = true;
			f32 angle = this.getAngleDegrees();
			this.AddTorque(angle < 180 ? -1000 : 1000);
			this.AddForce(Vec2f(0, -1000));
		}
	}
	/// GET IN MAG
	else if (isServer && cmd == this.getCommandID("getin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
			this.server_AttachTo(caller, "MAG");
	}
	/// GET OUT
	else if (isServer && cmd == this.getCommandID("vehicle getout"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());

		if (caller !is null)
		{
			this.server_DetachFrom(caller);
		}
	}
	/// RELOAD as in server_LoadAmmo   - client-side
	else if (!isServer && cmd == this.getCommandID("reload"))
	{
		u8 loadedAmmo = params.read_u8();

		if (loadedAmmo > 0 && this.getAttachments() !is null)
		{
			SetOccupied(this.getAttachments().getAttachmentPointByName("MAG"), 1);
		}

		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		v.getCurrentAmmo().loaded_ammo = loadedAmmo;
	}
	else if (isClient() && cmd == this.getCommandID("recount ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		u8 current_recounted = params.read_u8();
		v.ammo_types[current_recounted].ammo_stocked = params.read_u16();
		v.ammo_types[current_recounted].loaded_ammo = params.read_u8();
	}
	else if (cmd == this.getCommandID("jam_engine"))
	{
		if (isClient())
		{
			u32 time;
			if (!params.saferead_u32(time)) return;
			this.set_bool("engine_stuck", true);
			this.set_u32("engine_stuck_time", time);
			this.getSprite().PlaySound("EngineStart_tank", 1.5f, 0.725f + XORRandom(11)*0.01f);
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		this.Tag("explosion always teamkill");
		f32 explosion_radius = 0.0f;
		f32 explosion_map_damage = 0.0f;
		f32 explosion_damage = 0.0f;
		u8 scrap_amount = 0;
		switch (this.getName().getHash())
		{
			case _m60:
			{
				scrap_amount = 8+XORRandom(8);
				explosion_radius = 64.0f;
				explosion_map_damage = 0.2f;
				explosion_damage = 3.0f;
				break;
			} // normal tank
			case _t10:
			{
				scrap_amount = 13+XORRandom(8);
				explosion_radius = 72.0f;
				explosion_map_damage = 0.25f;
				explosion_damage = 4.0f;
				break;
			} // T10
			case _maus:
			{
				scrap_amount = 17+XORRandom(9);
				explosion_radius = 92.0f;
				explosion_map_damage = 0.3f;
				explosion_damage = 6.0f;
				break;
			} // mouse
			case _pszh4:
			{
				scrap_amount = 3+XORRandom(6);
				explosion_radius = 32.0f;
				explosion_map_damage = 0.1f;
				explosion_damage = 1.5f;
				break;
			} // smol APC
			case _btr82a:
			{
				scrap_amount = 7+XORRandom(6);
				explosion_radius = 48.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 2.25f;
				break;
			} // big APC
			case _bradley:
			{
				scrap_amount = 6+XORRandom(8);
				explosion_radius = 64.0f;
				explosion_map_damage = 0.175f;
				explosion_damage = 3.0f;
				break;
			} // bradley m2
			case _transporttruck:
			{
				scrap_amount = 4+XORRandom(4);
				explosion_radius = 32.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 1.5f;
				break;
			} // vanilla truck?
			case _armory:
			{
				scrap_amount = 5+XORRandom(6);
				explosion_radius = 48.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 1.5f;
				break;
			} // shop truck
			case _importantarmory:
			{
				scrap_amount = 5+XORRandom(6);
				explosion_radius = 48.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 1.5f;
				break;
			} // break the truck truck
			case _outpost:
			{
				break;
			} // outpost
			case _bf109:
			{
				scrap_amount = 5+XORRandom(8);
				// it already has explosion script in its file
				break;
			} // plane
			case _bomberplane:
			{
				scrap_amount = 10+XORRandom(6);
				// it already has explosion script in its file
				break;
			} // bomberplane
			case _jourcop:
			{
				break;
			} // journalist
			case _uh1:
			{
				scrap_amount = 10+XORRandom(9);
				// same as bf109
				break;
			} // heli
			case _techtruck:
			{
				scrap_amount = 4+XORRandom(4);
				explosion_radius = 32.0f;
				explosion_map_damage = 0.1f;
				explosion_damage = 1.5f;
				break;
			} // MG truck
			case _motorcycle:
			{
				scrap_amount = 1+XORRandom(2);
				// no explosion, too small
				break;
			} // bike
			case _civcar:
			{
				scrap_amount = 2+XORRandom(3);
				explosion_radius = 24.0f;
				explosion_map_damage = 0.1f;
				explosion_damage = 0.5f;
				break;
			} // car
			case _pszh4turret:
			case _btrturret:
			case _bradleyturret:
			case _m60turret:
			case _t10turret:
			case _mausturret:
			case _bunker:
			case _heavybunker:
				break;
		}

		if (explosion_damage > 0.0f) // explode if damage set 
		{
			DoExplosion(this, explosion_damage, explosion_map_damage, explosion_radius);
		}
		for (u8 i = 0; i < scrap_amount; i++) // drop scrap via cool velocity
		{
			CBlob@ b = server_CreateBlob("mat_scrap", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.server_SetQuantity(1);
				b.setVelocity(Vec2f(XORRandom(9)-4.0f, XORRandom(5)-6.0f));
			}
		}
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!getNet().isClient()) return;

	ParticleAnimated(CFileMatcher(filename).getFirst(), this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

void DoExplosion(CBlob@ this, f32 damage, f32 map_damage, f32 radius)
{
	if (this.hasTag("exploded")) return;

	f32 random = XORRandom(radius);
	f32 angle = this.getAngleDegrees();
	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (radius + random));
	this.set_f32("map_damage_ratio", map_damage);
	
	Explode(this, radius + random, damage);
	
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	
	for (int i = 0; i < (v_fastrender ? 8 : 35); i++)
	{
		MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(-angle, XORRandom(220) * 0.01f, 90), particles[XORRandom(particles.length)]);
	}
	
	this.Tag("exploded");
	if (!v_fastrender) this.getSprite().Gib();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("broken") || this.hasTag("falling")) return 0;
	if (customData == Hitters::fire)
	{
		return damage*2;
	}

	if (customData == Hitters::mine)
	{
		return damage*0.25f;
	}
 	
	if (isClient() && customData == Hitters::builder && hitterBlob.getName() == "slave")
	{
		this.getSprite().PlaySound("dig_stone.ogg", 1.0f, (0.975f - (this.getMass()*0.000075f))-(XORRandom(11)*0.01f));
	}
	
	Vec2f thisPos = this.getPosition();
	Vec2f hitterBlobPos = hitterBlob.getPosition();

	s8 armorRating = this.get_s8(armorRatingString);
	s8 penRating = hitterBlob.get_s8(penRatingString);
	bool hardShelled = this.get_bool(hardShelledString);

	if (hitterBlob.hasTag("grenade")) return (this.getName() == "maus" || armorRating > 4 ? damage*0.5f : damage * (1.25+XORRandom(10)*0.01f));

	if (armorRating >= 3 && customData == Hitters::sword) return 0;

	if (hitterBlob.getName() == "mat_smallbomb")
	{
		return damage * ((this.hasTag("apc") ? 3.0f : 3.75f)-(armorRating*0.75f));
	}

	if (customData == Hitters::sword) penRating -= 3; // knives don't pierce armor

	if (this.hasTag("turret")) this.set_u32("show_hp", getGameTime() + turretShowHPSeconds * 30);

	const bool is_explosive = customData == Hitters::explosion || customData == Hitters::keg;

	bool isHitUnderside = false;
	bool isHitBackside = false;

	float damageNegation = 0.0f;
	//print ("blob: "+this.getName()+" - damage: "+damage);
	s8 finalRating = getFinalRating(this, armorRating, penRating, hardShelled, this, hitterBlobPos, isHitUnderside, isHitBackside);
	//print("finalRating: "+finalRating);
	// add more damage if hit from below or hit backside of the tank (only hull)
	if (isHitUnderside || isHitBackside)
	{
		damage *= 1.5f;
	}

	// reduce damage if it hits turret (for maus)
	if (this.hasTag("reduce_upper_dmg") && hitterBlob.getPosition().y < thisPos.y && hitterBlob.getPosition().y > thisPos.y-24.0f)
	{
		damage *= 0.5f;
	}

	if (this.hasTag("gun") && is_explosive)
	{
		damage *= 0.25f;
	}

	switch (finalRating)
	{
		// negative armor, trickles up
		case -2:
		{
			if (is_explosive && damage != 0) damage += 1.5f; // suffer bonus base damage (you just got your entire vehicle burned)
			damage *= 1.5f;
		}
		case -1:
		{
			damage *= 1.25f;
		}
		break;

		// positive armor, trickles down
		case 5:
		case 4:
		{
			damage *= 0.5f;
		}
		case 3:
		{
			damage *= 0.75f;
		}
		case 2:
		{
			damage *= 1.0f;
		}
		case 1:
		{
			damageNegation += 0.2f; // reduction to final damage, for negating small bullets
			damage = Maths::Max(damage - damageNegation, 0.0f); // nullification happens here
		}
		break;
	}

	//printf("finalrating " + finalRating);
	//print ("finalDamage: "+damage);

	if (this.hasTag("turret"))
	{
		// broken logic for turrets
		if (this.getHealth()-damage/2 <= 0.0f)
		{
			this.Tag("broken");
			this.server_SetHealth(0.01f);

			return 0;
		}
	}
	else
	{
		// lucky perk
		if (this.getHealth()-damage/2 <= 0.0f && this.getHealth() != 0.01f)
		{
			AttachmentPoint@ drv = this.getAttachments().getAttachmentPointByName("DRIVER");
			if (drv !is null)
			{
				CBlob@ driver = drv.getOccupied();
				if (driver !is null)
				{
					if (isServer())
					{
						if (driver.hasBlob("aceofspades", 1))
						{
							driver.TakeBlob("aceofspades", 1);

							this.server_SetHealth(0.01f);

							driver.getSprite().PlaySound("FatesFriend.ogg", 1.6);

							if (driver.isMyPlayer()) // are we on server?
							{
								SetScreenFlash(42,   255,   150,   150,   0.28);
							}

							this.server_SetHealth(0.01f);

							return 0;
						}
					}
				}
			}
		}
	}

	// if damage is not insignificant, prevent repairs for a time
	if (hitterBlob.getTeamNum() == this.getTeamNum() ? damage > 0.5f : damage > 0.15f)
	{
		this.set_u32("no_heal", getGameTime()+(15+(this.exists("extra_no_heal") ? this.get_u16("extra_no_heal") : 0))*30);

		if (isClient())
		{
			CSprite@ thisSprite = this.getSprite();
			if (thisSprite != null && customData == Hitters::ballista && armorRating > 1) // ballista hits are usually anti-tank. Don't ask me.
			{
				if (this.hasTag("turret")) thisSprite.PlaySound("BigDamage", 2.5f, 0.85f + XORRandom(40)*0.01f); 
				thisSprite.PlaySound("shell_Hit", 3.5f, 0.85f + XORRandom(40)*0.01f);
			}
		}
	}

	return damage;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob.getTeamNum() == this.getTeamNum() && canSeeButtons(this, forBlob))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return false;
		}
		return v.inventoryAccess;
	}
	return false;
}

// VehicleCommon.as
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid)
	{
		return;
	}

	// damage
	if (!this.hasTag("ignore fall"))
	{
		const f32 base = 5.0f;
		const f32 ramp = 1.2f;

		bool pass_bullet = this.hasTag("pass_bullet") && blob !is null && blob.hasTag("bullet");

		if (getNet().isServer() && vellen > base && !pass_bullet) // server only
		{
			if (vellen > base * ramp)
			{
				f32 damage = 0.0f;

				if (vellen < base * Maths::Pow(ramp, 1))
				{
					damage = 0.5f;
				}
				else if (vellen < base * Maths::Pow(ramp, 2))
				{
					damage = 1.0f;
				}
				else if (vellen < base * Maths::Pow(ramp, 3))
				{
					damage = 2.0f;
				}
				else if (vellen < base * Maths::Pow(ramp, 3))
				{
					damage = 3.0f;
				}
				else //very dead
				{
					damage = 8.0f;
				}

				this.server_Hit(this, point1, normal, damage, Hitters::fall);
			}
		}
	}
}