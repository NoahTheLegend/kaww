#include "WarfareGlobal.as"
#include "AllHashCodes.as"
#include "SeatsCommon.as"
#include "VehicleCommon.as"
#include "VehicleAttachmentCommon.as"
#include "GenericButtonCommon.as"
#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";
#include "ProgressBar.as";

// general script for all vehicles, includes movement features, attachments,
// visuals, core damage modifiers and damage logic (for bunkers as well)
//
// more nitpicked damage modifiers (mostly for precise balancing) and
// unique vehicles' logic that is not reused are located in corresponding blob files 

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

const u8 BASE_NOHEAL_TIME_AFTERHIT = 2; // seconds
const u8 MAX_NOHEAL_TIME_AFTERHIT = 25;

const string wheelsTurnAmountString = "wheelsTurnAmount";
const string engineRPMString = "engine_RPM";
const string engineRPMTargetString = "engine_RPMtarget";
const string engineThrottleString = "engine_throttle";

const u8 turretShowHPSeconds = 8;

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.addCommandID("jam_engine");
	this.addCommandID("init_flipping");
	this.addCommandID("sync_flipping");
	this.addCommandID("flip_vehicle");
	this.addCommandID("aos_effects");
	this.addCommandID("sync_mag");
	this.addCommandID("reload_mag");
	this.Tag("lag_ondie");

	//vehicle common
	this.addCommandID("fire");
	this.addCommandID("fire blob");
	this.addCommandID("flip_over");
	this.addCommandID("getin_mag");
	this.addCommandID("load_ammo");
	this.addCommandID("ammo_menu");
	this.addCommandID("swap_ammo");
	this.addCommandID("sync_ammo");
	this.addCommandID("sync_last_fired");
	this.addCommandID("putin_mag");
	this.addCommandID("vehicle getout");
	this.addCommandID("reload");
	this.addCommandID("recount ammo");

	// armory
	this.addCommandID("separate");
	this.addCommandID("pick_10");
	this.addCommandID("pick_5");
	this.addCommandID("pick_2");
	this.addCommandID("pick_1");
	this.addCommandID("warn_opposite_team");

	this.addCommandID("set detaching");
	this.addCommandID("set attaching");
	this.addCommandID("sync overheat");

	string blobName = this.getName();
	int blobHash = blobName.getHash();

	this.set_string("engine_start", "EngineStart_tank");

	// misc
	switch(blobHash)
	{
		case _maus:
		case _pinkmaus:
		case _desertmaus:
		case _t10:
		case _kingtiger:
		case _is7:
		case _m103:
		{
			this.set_string("engine_start", "HeavyEngineStart_tank");
			break;
		}
		case _motorcycle:
		case _armedmotorcycle:
		{
			this.set_string("engine_start", "LightEngineStart_tank");
			break;
		}
	}

	// armor
	s8 armorRating = 0;
	bool hardShelled = false;

	switch(blobHash)
	{
		case _is7turret:
		{
			armorRating = 7;
			hardShelled = true;
			break;
		}
		case _barge:
		case _mausturret:
		case _pinkmausturret:
		case _desertmausturret:
		case _is7:
		{
			armorRating = 5;
			hardShelled = true;
			break;
		}
		case _maus:
		case _pinkmaus:
		case _desertmaus:
		case _t10turret:
		case _m1abramsturret:
		armorRating = 5; break;
		
		case _t10:
		case _kingtiger:
		case _importantarmory:
		case _importantarmoryt2:
		case _m60turret:
		case _e50turret:
		case _m103turret:
		case _m103:
		case _m1abrams:
		case _kingtigerturret:
		armorRating = 4; break;
			
		case _m60:
		case _e50:
		case _leopard1:
		case _leopard1turret:
		case _bc25t:
		case _bc25turret:
		case _artillery:
		case _artilleryturret:
		case _bradley:
		case _bradleyturret:
		case _m2browning:
		case _mg42:
		case _firethrower:
		case _ah1:
		case _mi24:
		case _nh90:
		case _grad:
		armorRating = 3; break;

		case _transporttruck:
		case _armory:
		case _btr82a:
		case _btrturret:
		case _bmp:
		case _bmpturret:
		case _pszh4:
		case _pszh4turret:
		case _uh1:
		case _gradturret:
		armorRating = 2; break;

		case _techtruck:
		case _gun:
		case _techbigtruck:
		armorRating = 1; break;

		case _bf109:
		case _bomberplane:
		case _civcar:
		case _armedmotorcycle:
		armorRating = 0; break;

		case _motorcycle:
		case _jourcop:
		armorRating = -1; break;

		default:
		{
			//print ("blobName: "+ blobName + " hash: "+blobHash);
			//print ("-");
		}
	}

	// weapon & projectile

	s8 weaponRating = 0; // penetration rating
	f32 linear_length = 4.0f; // explosion depth
	f32 scale_impact_damage = 1.0f; // direct damage modifier
	f32 scale_infantry_damage = 1.0f; // damage to infantry
	f32 impact_radius = -1.0f;

	switch (blobHash) // weapon rating and length of linear (map) and explosion damage in radius
	{
		case _artilleryturret:
		{
			weaponRating = 6;
			linear_length = 16.0f;
			scale_infantry_damage = 0.5f;
			scale_impact_damage = 2.0f;
			break;
		}
		case _mausturret:
		case _pinkmausturret:
		case _desertmausturret:
		case _is7turret:
		{
			weaponRating = 5;
			linear_length = 20.0f;
			scale_infantry_damage = 0.3f;
			scale_impact_damage = 1.5f;
			break;
		}
		case _kingtigerturret:
		{
			weaponRating = 5;
			linear_length = 18.0f;
			scale_infantry_damage = 0.2f;
			scale_impact_damage = 1.4f;
			break;
		}
		case _t10turret:
		{
			weaponRating = 4;
			linear_length = 14.0f;
			scale_infantry_damage = 0.15f;
			scale_impact_damage = 1.4f;
			break;
		}
		case _m1abramsturret:
		{
			weaponRating = 4;
			linear_length = 16.0f;
			scale_infantry_damage = 0.175f;
			scale_impact_damage = 1.3f;
			break;
		}
		case _m103turret:
		{
			weaponRating = 3;
			linear_length = 12.0f;
			scale_infantry_damage = 0.1f;
			scale_impact_damage = 1.3f;
			break;
		}
		case _m60turret:
		case _e50turret:
		case _leopard1turret:
		{
			weaponRating = 3;
			linear_length = 10.0f;
			scale_infantry_damage = 0.2f;
			scale_impact_damage = 1.2f;
			break;
		}
		case _bc25turret:
		{
			weaponRating = 2;
			linear_length = 2.0f;
			scale_infantry_damage = 0.75f;
		}
		case _uh1:
		case _ah1:
		case _mi24:
		case _nh90:
		{
			weaponRating = 1;
			break;
		}
		case _gradturret:
		{
			weaponRating = -2;
			linear_length = 0.0f;
			scale_infantry_damage = 4.0f;
			break;
		}
		case _m2browning:
		case _mg42:
		{
			weaponRating = -1;
			break;
		}
		case _bradleyturret:
		case _btrturret:
		case _bmpturret:
		{
			weaponRating = -2;
			linear_length = 4.0f;
			scale_impact_damage = 0.3f;
			scale_infantry_damage = 0.15f;
			impact_radius = 8.0f;
			break;
		}
		case _pszh4turret:
		{
			weaponRating = -2;
			linear_length = 4.0f;
			scale_impact_damage = 0.25f;
			scale_infantry_damage = 0.15f;
			impact_radius = 8.0f;
			break;
		}
	}

	this.set_f32("linear_length", linear_length);
	this.set_f32("scale_impact_damage", scale_impact_damage);
	this.set_f32("scale_infantry_damage", scale_infantry_damage);
	this.set_f32("impact_radius", impact_radius);

	// vulnerabilities
	float backsideOffset = -1.0f;

	switch (blobHash) // backside
	{
		case _maus:
		case _pinkmaus:
		case _desertmaus:
		backsideOffset = 32.0f; break;

		case _t10:
		case _bc25t:
		case _e50:
		case _grad:
		backsideOffset = 24.0f; break;
		
		case _m60:
		case _leopard1:
		case _btr82a:
		case _bradley:
		case _bmp:
		case _artillery:
		case _barge:
		case _m103:
		case _kingtiger:
		backsideOffset = 20.0f; break;

		case _pszh4:
		case _is7:
		case _m1abrams:
		backsideOffset = 16.0f; break;

		case _uh1:
		case _ah1:
		case _mi24:
		case _nh90:
		backsideOffset = 32.0f; break;

		case _bf109:
		backsideOffset = 16.0f; break;

		case _bomberplane:
		backsideOffset = 16.0f; break;

		case _techbigtruck:
		backsideOffset = -20.0f; break;
	}

	// engine power
	f32 intake = 0.0f;
	switch(blobHash)
	{
		// min is -75
		case _is7:
		intake = -75.0f; break;

		case _maus:
		case _pinkmaus:
		case _desertmaus:
		intake = -50.0f; break;

		case _m103:
		case _kingtiger:
		intake = -40.0f; break;

		case _t10:
		intake = -25.0f; break;

		case _bc25t:
		intake = -50.0f; break;
		
		case _m1abrams:
		intake = 10.0f; break;

		case _e50:
		case _bmp:
		intake = 20.0f; break;

		case _m60:
		intake = 50.0f; break;

		case _btr82a:
		intake = 75.0f; break;

		case _pszh4:
		case _bradley:
		intake = 100.0f; break;

		case _techtruck:
		case _techbigtruck:
		intake = 150.0f; break;

		case _armory:
		case _importantarmory:
		case _importantarmoryt2:
		case _civcar:
		case _armedmotorcycle:
		intake = 100.0f; break;

		case _motorcycle:
		case _artillery:
		intake = 200.0f; break;
	}

	this.set_f32("add_gas_intake", intake);
	
	this.set_s8(armorRatingString, armorRating);
	this.set_bool(hardShelledString, hardShelled);
	this.set_s8(weaponRatingString, weaponRating);
	this.set_f32(backsideOffsetString, backsideOffset);

	this.set_f32(engineRPMString, 0.0f);
	this.set_f32(engineThrottleString, 0.0f);

	this.set_f32(wheelsTurnAmountString, 0.0f);

	this.set_u32("show_hp", 0);
	this.set_string("invname", this.getInventoryName());

	this.set_u32("flipping_endtime", 0);
	this.set_f32("flipping_time", 0);
	this.set_f32("shake_diff", 0);

	if (isClient() && getLocalPlayer() !is null)
	{
		CBitStream params;
		params.write_u16(getLocalPlayer().getNetworkID());
		this.SendCommand(this.getCommandID("sync_mag"),params);
	}
}

void ManageFlipping(CBlob@ this)
{
	u32 endtime = this.get_u32("flipping_endtime");
	if (endtime != 0) this.add_f32("flipping_time", 1);

	if (this.get_f32("flipping_time") >= endtime)
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (hasBar(bars, "flipping"))
				bars.RemoveBar("flipping", false);
		}
	}
	
	if (!isServer()) return;
	if (getGameTime() % 30 == 0 && endtime != 0)
	{
		if (this.get_f32("flipping_time") >= endtime)
		{
			CBitStream params;
			params.write_bool(false);
			params.write_u32(0);
			this.SendCommand(this.getCommandID("sync_flipping"), params);

			this.set_f32("flipping_time", 0);
		}

		CBitStream params;
		params.write_bool(true);
		params.write_f32(this.get_f32("flipping_time"));
		this.SendCommand(this.getCommandID("sync_flipping"), params);
	}
}

void ManageDisguise(CBlob@ this)
{
	if ((getGameTime()+this.getNetworkID()) % 45 == 0 && !this.hasTag("gun"))
	{
		const u8 map_luminance = getMap().getColorLight(this.getPosition()).getLuminance();
		if (map_luminance < 85)
		{
			if (!this.hasTag("turret"))
			{
				this.setInventoryName("Hidden");
			}
			
			this.set_u32("disguise", getGameTime() + 90);
		}
		else
		{
			this.set_u32("disguise", getGameTime());
			this.setInventoryName(this.get_string("invname"));
		}
	}
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	if (map is null) return;
	
	visualTimerTick(this);
	ManageFlipping(this);
	ManageDisguise(this);

	u32 gt = getGameTime();

	if (!(isClient() && isServer()) && !this.hasTag("aerial") && !sv_test && getGameTime() < 60*30 && !this.hasTag("pass_60sec"))
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
			this.getSprite().PlaySound(this.get_string("engine_start"), 2.5f, 1.0f + XORRandom(11)*0.01f);
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
				sprite.SetEmitSoundVolume(Maths::Min(velx * 0.61f * volMod, 1.0f));
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
		if (this.get_f32("engine_RPM") > 2000) {gas_intake += 150+custom_add;}
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

		f32 max_diff = 1.5f;
		if (this.exists("max_angle_diff")) max_diff = this.get_f32("max_angle_diff");

		f32 last_diff = this.get_f32("shake_diff");
		f32 diff = (this.getPosition().x - this.getOldPosition().x);
		this.set_f32("shake_diff", Maths::Lerp(last_diff, diff, 0.1f));

		f32 delta = diff-this.get_f32("shake_diff"); 

		sprite.ResetTransform();
		sprite.RotateBy(delta*-max_speed*max_diff, Vec2f(this.isFacingLeft() ? 6 : -6, 0));
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

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!isFlipped(this)) return;
	if (caller.getDistanceTo(this) > this.getRadius()) return;
	if (this.hasTag("turret") || this.hasTag("machinegun") || this.hasTag("autoflip")) return;
	
	CBitStream params;
	CButton@ button = caller.CreateGenericButton(12, Vec2f(0, -12), this, this.getCommandID("init_flipping"), "Flip this vehicle.", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	/// LOAD AMMO
	if (isServer)
	{
		if (cmd == this.getCommandID("load_ammo"))
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
		else if (cmd == this.getCommandID("init_flipping"))
		{
			f32 endtime = this.get_u32("flipping_endtime");
			if (endtime == 0)
				this.set_u32("flipping_endtime", 30*Maths::Round(this.getMass()/750));

			CBitStream params1;
			params1.write_bool(false);
			params1.write_u32(this.get_u32("flipping_endtime"));
			this.SendCommand(this.getCommandID("sync_flipping"), params1);
		}
	}
	if (cmd == this.getCommandID("sync_mag"))
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		if (id != 0 && isServer)
		{
			CPlayer@ p = getPlayerByNetworkId(id);
			if (p is null) return;

			syncMagToPlayer(this, p, v);
		}
		if (id == 0 && isClient())
		{
			u32 cooldown_time;
			if (!params.saferead_u32(cooldown_time)) return;
			u32 fire_time;
			if (!params.saferead_u32(fire_time)) return;
			u32 fired_amount;
			if (!params.saferead_u32(fired_amount)) return;

			v.cooldown_time = cooldown_time;
			v.fire_time = fire_time;
			v.fired_amount = fired_amount;
		}
	}
	else if (cmd == this.getCommandID("reload_mag"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		
		if (v.cooldown_time > 0 || v.fired_amount <= 1) return;

		bool init;
		if (!params.saferead_bool(init)) return;
		
		if (init && isServer)
		{
			CBitStream params1;
			params1.write_bool(false);
			this.SendCommand(this.getCommandID("reload_mag"), params1);
			reloadMag(this);
		}
		if (!init && isClient())
		{
			reloadMag(this);
		}
	}
	else if (cmd == this.getCommandID("sync_flipping"))
	{
		if (!isFlipped(this))
		{
			this.set_u32("flipping_endtime", 0);
			this.set_f32("flipping_time", 0);
			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				bars.RemoveBar("flipping", false);
			}
			return;
		}

		bool current = false;
		u32 endtime;
		f32 time;
		if (!params.saferead_bool(current)) return;
		if (!current)
		{
			if (!params.saferead_u32(endtime)) return;
			this.set_u32("flipping_endtime", endtime);
		}
		else
		{
			if (!params.saferead_f32(time)) return;
			this.set_f32("flipping_time", time);
		}

		Bar@ bars;
		if (!this.get("Bar", @bars))
		{
			Bar setbars;
        	setbars.gap = 20.0f;
        	this.set("Bar", setbars);
		}
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "flipping"))
			{
				SColor team_front = SColor(255, 133, 133, 160);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "flipping", Vec2f(128.0f, 24.0f), true, Vec2f(0, 64), Vec2f(2, 2), back, team_front,
					"flipping_time", this.get_u32("flipping_endtime"), 0.25f, 5, 5, false, "flip_vehicle");

    			bars.AddBar(this.getNetworkID(), setbar, true);
			}
		}
	}
	else if (cmd == this.getCommandID("aos_effects"))
	{
		this.getSprite().PlaySound("FatesFriend.ogg", 2.0);
	}
	else if (cmd == this.getCommandID("flip_vehicle"))
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			bars.RemoveBar("flipping", false);
		}

		this.set_u32("flipping_endtime", 0);
		this.set_f32("flipping_time", 0);
		this.setAngleDegrees(this.getAngleDegrees()+180);

		AttachmentPoint@ tur = this.getAttachments().getAttachmentPointByName("TURRET");
		if (tur !is null && tur.getOccupied() !is null)
		{
			CBlob@ tur_blob = tur.getOccupied();

			AttachmentPoint@ tur_gunner = tur_blob.getAttachments().getAttachmentPointByName("GUNNER");
			if (tur_gunner !is null && tur_gunner.getOccupied() is null)
			{
				tur_blob.SetFacingLeft(!tur_blob.isFacingLeft());
			}
		}
		this.SetFacingLeft(!this.isFacingLeft());
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
		u32 fired_amount;
		if (!params.saferead_u32(fired_amount)) return;

		v.fired_amount = fired_amount;
		this.set_u32("fired_amount", fired_amount);
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
			for (int i = 0; i < (v_fastrender ? 3 : 8); i++)
			{
				MakeParticle(this, Vec2f( (this.isFacingLeft()?1:-1)*(XORRandom(24)+8), XORRandom(16) - 8), getRandomVelocity(-this.getVelocity().Angle(), XORRandom(150) * 0.01f, 90), smokes[XORRandom(smokes.length)]);
			}
			
			u32 time;
			if (!params.saferead_u32(time)) return;
			this.set_bool("engine_stuck", true);
			this.set_u32("engine_stuck_time", time);
			this.getSprite().PlaySound(this.get_string("engine_start"), 1.5f, 0.725f + XORRandom(11)*0.01f);
		}
	}
}

void syncMagToPlayer(CBlob@ this, CPlayer@ p, VehicleInfo@ v)
{
	CBitStream params;
	params.write_u16(0);
	params.write_u32(v.cooldown_time);
	params.write_u32(v.fire_time);
	params.write_u32(v.fired_amount);
	this.server_SendCommandToPlayer(this.getCommandID("sync_mag"), params, p);
}

void reloadMag(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	
	v.getCurrentAmmo().fire_delay = this.get_u16("cooldown_time");
	v.cooldown_time = v.getCurrentAmmo().fire_delay;
	v.fired_amount = 1;
	v.fire_time = 0;
	v.charge = 0;
	v.firing = false;

	this.set_u32("fired_amount", v.fired_amount);
	SetFireDelay(this, v.getCurrentAmmo().fire_delay, v);
}

void onDie(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	if (this.hasTag("upgrade")) return;
	
	if (isServer())
	{
		this.Tag("explosion always teamkill");
		f32 explosion_radius = 0.0f;
		f32 explosion_map_damage = 0.0f;
		f32 explosion_damage = 0.0f;
		u8 scrap_amount = 0;
		switch (this.getName().getHash())
		{
			case _bc25t:
			case _m60:
			case _e50:
			case _leopard1:
			{
				scrap_amount = 12+XORRandom(8);
				explosion_radius = 64.0f;
				explosion_map_damage = 0.2f;
				explosion_damage = 3.0f;
				break;
			}
			case _t10:
			case _kingtiger:
			case _m103:
			{
				scrap_amount = 16+XORRandom(8);
				explosion_radius = 72.0f;
				explosion_map_damage = 0.25f;
				explosion_damage = 4.0f;
				break;
			}
			case _maus:
			case _pinkmaus:
			case _desertmaus:
			case _m1abrams:
			case _is7:
			{
				scrap_amount = 35+XORRandom(11);
				explosion_radius = 100.0f;
				explosion_map_damage = 0.3f;
				explosion_damage = 7.5f;
				break;
			}
			case _ah1:
			case _mi24:
			case _nh90:
			case _grad:
			{
				scrap_amount = 22+XORRandom(9);
				explosion_radius = 92.0f;
				explosion_map_damage = 0.3f;
				explosion_damage = 6.0f;
				break;
			}
			case _pszh4:
			{
				scrap_amount = 4+XORRandom(5);
				explosion_radius = 32.0f;
				explosion_map_damage = 0.1f;
				explosion_damage = 1.5f;
				break;
			}
			case _btr82a:
			{
				scrap_amount = 9+XORRandom(6);
				explosion_radius = 48.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 2.25f;
				break;
			}
			case _bradley:
			case _bmp:
			{
				scrap_amount = 10+XORRandom(8);
				explosion_radius = 64.0f;
				explosion_map_damage = 0.175f;
				explosion_damage = 3.0f;
				break;
			}
			case _transporttruck:
			{
				scrap_amount = 4+XORRandom(4);
				explosion_radius = 32.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 1.5f;
				break;
			}
			case _armory:
			{
				scrap_amount = 5+XORRandom(6);
				explosion_radius = 48.0f;
				explosion_map_damage = 0.15f;
				explosion_damage = 1.5f;
				break;
			}
			case _importantarmory:
			{
				break;
			}
			case _outpost:
			{
				break;
			}
			case _bf109:
			{
				scrap_amount = 5+XORRandom(8);
				// it already has explosion script in its file
				break;
			}
			case _bomberplane:
			{
				scrap_amount = 10+XORRandom(6);
				// it already has explosion script in its file
				break;
			}
			case _jourcop:
			{
				break;
			}
			case _uh1:
			case _artillery:
			{
				scrap_amount = 10+XORRandom(9);
				break;
			}
			case _techtruck:
			case _techbigtruck:
			{
				scrap_amount = 4+XORRandom(4);
				explosion_radius = 32.0f;
				explosion_map_damage = 0.1f;
				explosion_damage = 1.5f;
				break;
			}
			case _motorcycle:
			case _barge:
			{
				scrap_amount = 1+XORRandom(2);
				// no explosion, too small
				break;
			}
			case _civcar:
			case _armedmotorcycle:
			{
				scrap_amount = 2+XORRandom(2);
				explosion_radius = 24.0f;
				explosion_map_damage = 0.1f;
				explosion_damage = 0.5f;
				break;
			}
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

	ParticleAnimated(CFileMatcher(filename).getFirst(), this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 3 + XORRandom(3), XORRandom(100) * -0.00005f, true);
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
	if (this.hasTag("broken") || this.hasTag("falling") || (this.exists("ignore_damage") && this.get_u32("ignore_damage") > getGameTime())) return 0;
	
	if (customData == Hitters::fire)
	{
		return damage*2;
	}

	if (customData == Hitters::mine)
	{
		return damage*0.25f;
	}
 	
	if (isClient() && customData == Hitters::builder && hitterBlob.getName() == "mechanic")
	{
		this.getSprite().PlaySound("dig_stone.ogg", 1.0f, (0.975f - (this.getMass()*0.000075f))-(XORRandom(11)*0.01f));
	}
	
	Vec2f thisPos = this.getPosition();
	Vec2f hitterBlobPos = hitterBlob.getPosition();

	s8 armorRating = this.get_s8(armorRatingString);
	s8 penRating = hitterBlob.get_s8(penRatingString);
	bool hardShelled = this.get_bool(hardShelledString);

	if (customData == Hitters::sword) penRating -= 3; // knives don't pierce armor

	if (hitterBlob.getName() == "c4")
	{
		damage *= 1.33f;
	}

	if (armorRating >= 3 && customData == Hitters::sword) return 0;

	if (hitterBlob.getName() == "mat_smallbomb")
	{
		damage *= ((this.hasTag("apc") ? 3.0f : 4.25f)-(armorRating*0.75f));
	}

	if (this.hasTag("turret")) this.set_u32("show_hp", getGameTime() + turretShowHPSeconds * 30);

	const bool is_explosive = customData == Hitters::explosion || customData == Hitters::keg;

	bool isHitUnderside = false;
	bool isHitBackside = false;

	float damageNegation = 0.0f;
	//print ("blob: "+this.getName()+" - damage: "+damage);
	s8 finalRating = getFinalRating(this, armorRating, penRating, hardShelled, this, hitterBlobPos, isHitUnderside, isHitBackside);
	
	bool is_aircraft = customData == HittersAW::aircraftbullet;
	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet-1);
	bool is_apbullet = customData == HittersAW::apbullet;

	if (this.hasTag("aerial") && hitterBlob.hasTag("shell"))
	{
		damage *= 2.0f;
	}
	if (hitterBlob.hasTag("grenade"))
	{
		if (!hitterBlob.hasTag("atgrenade"))
			damage *= Maths::Max(0.1f, (0.5f-0.2f*finalRating));

		if (this.hasTag("truck") && !this.hasTag("importantarmory"))
			damage *= 1.5f;
		else
			damage *= 1.0f+(XORRandom(26)*0.01f);
		
		if (this.hasTag("aerial")) damage *= 4.0f;
		if (hitterBlob.get_u16("follow_id") == this.getNetworkID()) damage *= 1.5f;

		u16 blocks_between = Maths::Round((hitterBlobPos - thisPos).Length()/16.0f);
		if (blocks_between > this.getRadius()/8)
			damage /= Maths::Max(0.1f, 1.0f-(this.getRadius()/8-blocks_between));
	}

	if (this.hasTag("tank") && hitterBlob.getName() == "missile_javelin")
	{
		if (damage > 10.0f) damage = 10.0f + 10.0f * 0.33f; // limit damage to thick armor (hack?)
	}
	
	if (is_bullet && !is_apbullet)
	{
		if (this.hasTag("tank") && !is_aircraft) damage *= (armorRating > 3 ? 0 : 0.25f);
		return damage;
	}
	if (is_apbullet)
	{
		if (this.hasTag("tank") && !is_aircraft) damage *= 2.0f;
	}
	//print("finalRating: "+finalRating);
	// add more damage if hit from below or hit backside of the tank (only hull)
	if (isHitUnderside || isHitBackside)
	{
		damage *= 1.5f;
	}

	// reduce damage if it hits turret (for maus)
	if ((this.hasTag("reduce_upper_dmg") || (this.hasTag("reduce_upper_dmg_only_front") && !isHitBackside))
		&& hitterBlob.getPosition().y < thisPos.y && hitterBlob.getPosition().y > thisPos.y-24.0f)
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
			break;
		}
		case -1:
		{
			damage *= 1.25f;
			break;
		}
		break;

		// positive armor, trickles down
		case 5:
		case 4:
		{
			damage *= 0.5f;
			break;
		}
		case 3:
		{
			damage *= 0.65f;
			break;
		}
		case 2:
		{
			damage *= 0.8f;
			break;
		}
		case 1:
		{
			damage *= 0.9f;
			break;
		}
		case 0:
		{
			damage *= 1.0f;
			break;
		}
	}

	// if damage is not insignificant, prevent repairs for a time
	if (damage > 0.25f)
	{
		f32 extra = this.exists("extra_no_heal") ? this.get_u16("extra_no_heal") : 0;
		int time = ((BASE_NOHEAL_TIME_AFTERHIT+extra) * damage) * 30;
		int no_heal_time_old = this.get_u32("no_heal");
		if (no_heal_time_old > getGameTime())
			time += no_heal_time_old-getGameTime();
		if (time > MAX_NOHEAL_TIME_AFTERHIT*30)
			time = MAX_NOHEAL_TIME_AFTERHIT*30;

		this.set_u32("no_heal", getGameTime()+time);

		if (isClient())
		{
			CSprite@ thisSprite = this.getSprite();
			if (thisSprite != null && customData == Hitters::ballista && armorRating > 1)
			{
				if (this.hasTag("turret")) thisSprite.PlaySound("BigDamage", 2.5f, 0.85f + XORRandom(40)*0.01f); 
				thisSprite.PlaySound("shell_Hit", 3.5f, 0.85f + XORRandom(40)*0.01f);
			}
		}
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
		if (this.getHealth()-damage/2 <= 0.0f && this.getHealth() > 5.0f)
		{
			AttachmentPoint@ drv = this.getAttachments().getAttachmentPointByName("DRIVER");
			if (drv !is null)
			{
				CBlob@ driver = drv.getOccupied();
				if (driver !is null)
				{
					if (isServer() && !this.hasTag("aerial"))
					{
						if (driver.get_bool("has_aos"))
						{
							driver.TakeBlob("aceofspades", 1);

							CBitStream params;
							this.SendCommand(this.getCommandID("aos_effects"), params);

							if (driver.isMyPlayer()) // are we on server?
							{
								SetScreenFlash(42,   255,   150,   150,   0.28);
							}

							this.server_SetHealth(0.01f);
							this.set_u32("ignore_damage", getGameTime()+30);

							return 0;
						}
					}
				}
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

	f32 vellen = this.getShape().vellen;

	// damage
	if (!this.hasTag("ignore fall"))
	{
		const f32 base = 8.0f;
		const f32 ramp = 1.2f;

		if (getNet().isServer() && vellen > base) // server only
		{
			if (vellen > base * ramp)
			{
				f32 damage = 0.0f;

				if (vellen < base * Maths::Pow(ramp, 1))
				{
					damage = 0.33f;
				}
				else if (vellen < base * Maths::Pow(ramp, 2))
				{
					damage = 0.85f;
				}
				else if (vellen < base * Maths::Pow(ramp, 3))
				{
					damage = 1.5f;
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

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (!blob.hasTag("override_timer_render")) visualTimerRender(this);
}