#include "GunCommon.as";
#include "HittersAW.as";
#include "UtilityChecks.as";
#include "CustomBlocks.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached()) return 0;
	return damage;
}

const u16 max_times_used = 8; // max ammo
const f32 light_radius = 16.0f;

const u16 times_cut_per_time_used = 3; // how many cuts to decrease ammo by 1
const f32 drill_damage = 0.1f;
const u16 drill_frequency_tiles = 8;
const u16 drill_frequency_blobs = 8; // how often to drill
const u32 drill_spinup = 20; // sound spinup
const f32 spinup_throttle = 0.75f; // drop active_time to drill_spinup * spinup_throttle when loop sound changes
const f32 max_volume = 0.66f;
const f32 max_pitch = 0.95f;
const u8 particle_frequency = 3;
const u8 reload_count = 8; // stone required to reload
const string blobname = "specammo";

void onInit(CBlob@ this)
{	
	GunSettings settings = GunSettings();

	//General
	settings.CLIP = 0; //Amount of ammunition in the gun at creation
	settings.TOTAL = max_times_used; //Max amount of ammo that can be in a clip
	settings.FIRE_INTERVAL = 10; //Time in between shots
	settings.RELOAD_TIME = 30; //Time it takes to reload (in ticks)
	settings.AMMO_BLOB = ""; //Ammunition the gun takes

	//Bullet
	settings.B_PER_SHOT = 1; //Shots per bullet | CHANGE B_SPREAD, otherwise both bullets will come out together
	settings.B_SPREAD = 5; //the higher the value, the more 'uncontrollable' bullets get
	settings.B_GRAV = Vec2f(0, 0.001); //Bullet gravity drop
	settings.B_SPEED = 60; //Bullet speed, STRONGLY AFFECTED/EFFECTS B_GRAV
	settings.B_TTL = 10; //TTL = 'Time To Live' which determines the time the bullet lasts before despawning
	settings.B_DAMAGE = 0.5f; //1 is 1 heart
	settings.B_TYPE = HittersAW::bullet; //Type of bullet the gun shoots | hitter

	//Recoil
	settings.G_RECOIL = -7; //0 is default, adds recoil aiming up
	//settings.G_RANDOMX = true; //Should we randomly move x
	//settings.G_RANDOMY = false; //Should we randomly move y, it ignores g_recoil
	settings.G_RECOILT = 4; //How long should recoil last, 10 is default, 30 = 1 second (like ticks)
	settings.G_BACK_T = 1; //Should we recoil the arm back time? (aim goes up, then back down with this, if > 0, how long should it last)

	//Sound
	settings.FIRE_VOLUME = 1.0f; //Sound volume
    settings.FIRE_SOUND = "PlasmaCutterFire.ogg"; //Sound when shooting
	settings.RELOAD_SOUND = ""; // no reload
	settings.FIRE_PITCH = 1.1f;
	settings.FIRE_PITCH_RANDOM = 0.1f;
	settings.HIT_PARTICLE = "PlasmaExplosion.png";

	//Offset
	settings.MUZZLE_OFFSET = Vec2f(-12, -1.5f); //Where the muzzle flash appears
	this.set_Vec2f("muzzle_offset", settings.MUZZLE_OFFSET);

	this.set_string("CustomFlash", "PlasmaFlash.png");
	this.set_string("CustomBullet", "PlasmaProjectile.png");
	this.set_string("CustomCase", "");

	this.set("gun_settings", @settings);
	this.Tag("custom_reload");
	this.Tag("no_bullet_particle");
	this.Tag("weapon");

	this.Tag("laser"); // laser tag
	this.set_bool("laser_enabled", false);
	this.set_u32("reload", 0);
	
	this.set_string("laser_texture", "Laser_Blue.png");
	this.set_f32("laser_distance", 32.0f);
	this.set_f32("falloff_start", 0.0f);
	this.set_f32("laser_alpha_mod", 0.75f);
	this.set_Vec2f("laser_offset", Vec2f(3, -1.5f));

	this.set_u16("times_cut", 0);
	this.set_u16("times_shot", 0);

	this.set_u32("drill_active_time", 0);

	this.addCommandID("sync");
	RequestSync(this);

	this.SetLight(false);
	this.SetLightRadius(light_radius);
	this.SetLightColor(SColor(255, 118, 228, 228));

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}

	this.getShape().getConsts().net_threshold_multiplier = 0.1f;
	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	this.set_string("laser_sound", loop_sounds[0]);
	sprite.SetEmitSound(loop_sounds[0]);
	sprite.SetEmitSoundVolume(0.0f);
	sprite.SetEmitSoundSpeed(0.0f);
	sprite.SetEmitSoundPaused(true);
}

void onTick(CBlob@ this)
{
	GunSettings@ settings;
	if (!this.get("gun_settings", @settings))
	{
		return;
	}

	// reloading
	int clip = this.get_u8("clip");
	bool ammo_exceed = clip == 0;
	bool reloading = getGameTime() <= this.get_u32("reload");
	bool just_shot = this.hasTag("just_shot");

	this.set_bool("force_nofire", reloading);

	bool was_light = this.get_bool("laser_enabled");
	bool do_light = !ammo_exceed && !reloading;

	this.SetLight(do_light);
	#ifndef STAGING
	if ((was_light && do_light) || (!was_light && !do_light)) getMap().UpdateLightingAtPosition(this.getInterpolatedPosition(), light_radius);
	#endif

	string anim = ammo_exceed ? "default" : reloading ? "reload" : "default_charged";
	this.set_bool("laser_enabled", do_light);

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point is null) return;
	CBlob@ holder = point.getOccupied();

	if (ammo_exceed)
	{
		if (holder !is null)
		{
			bool hasAmmo = holder.hasBlob(blobname, reload_count);
			if (hasAmmo)
			{
				if (isServer())
					Reload(this, holder);
			}
		}
	}
	else if (just_shot)
	{
		anim = "fire";
	}

	bool a2 = false;
	int tile_hit = -1;
	Vec2f tilepos_hit = Vec2f_zero;

	u16[] hit_blob_ids;

	bool found_tile = false;
	bool found_blob = false;
	
	u32 seed = getGameTime() + this.getNetworkID();
	bool was_hit = false;

	f32 angle_deg = this.getAngleDegrees();
	Vec2f muzzle_offset = Vec2f(0, settings.MUZZLE_OFFSET.y).RotateBy(angle_deg);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap is null) return;

	if (holder !is null && ap.isKeyPressed(key_action2) && do_light)
	{
		a2 = true;
		this.add_u32("drill_active_time", 1);
		if (this.get_u32("drill_active_time") > drill_spinup) this.set_u32("drill_active_time", drill_spinup);

		Vec2f pos = this.getPosition();
		Vec2f aim = holder.getAimPos();
		Vec2f dir = aim - pos - muzzle_offset;
		dir.Normalize();

		f32 distance = this.get_f32("laser_distance");
		Vec2f end = pos + dir * distance;

		f32 angle = dir.getAngle();
		Vec2f offset = this.get_Vec2f("laser_offset").RotateBy(this.isFacingLeft() ? -angle + 180 : -angle);

		HitInfo@[] hitInfos;
		if (getMap().getHitInfosFromRay(pos + offset, -angle, distance, holder, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;
				if (b !is null)
				{
					if (isEnemy(this, b))
					{
						found_blob = true;

						if (seed % drill_frequency_blobs == 0)
						{
							if (isServer()) this.server_Hit(b, b.getPosition(), dir, drill_damage, HittersAW::bullet, true);
							was_hit = true;
						}
					}
				}
				else
				{
					Vec2f tilePos = hi.hitpos;
					CMap@ map = getMap();
					if (map !is null)
					{
						TileType tile = map.getTile(tilePos).type;
						if (isSolid(map, tile))
						{
							found_tile = true;
							tile_hit = tile;
							tilepos_hit = tilePos;

							if (seed % drill_frequency_tiles == 0)
							{
								if (isServer()) map.server_DestroyTile(tilePos, drill_damage);
								was_hit = true;
							}
						}
					}
				}
			}

			if (isServer())
			{
				u16 times_cut = this.get_u16("times_cut");
				if (was_hit) times_cut++;

				if (times_cut >= times_cut_per_time_used)
				{
					times_cut = 0;
					this.set_u8("clip", this.get_u8("clip") - 1);

					if (this.get_u8("clip") == 0)
					{
						Reload(this, holder);
					}
					else Sync(this);
				}
				this.set_u16("times_cut", times_cut);
			}
		}
	}

	if (!isClient()) return;
	
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	if (sprite.isAnimationEnded() && sprite.animation.name != anim)
	{
		if (anim == "reload") sprite.PlaySound("PlasmaCutterReload", 1.0f, 1.0f + XORRandom(11)*0.01f);
		else if (sprite.animation.name == "reload" && anim == "default_charged") sprite.PlaySound("PlasmaCutterReady", 1.0f, 1.0f + XORRandom(11)*0.01f);

		sprite.animation.frame = 0;
		sprite.SetAnimation(anim);
	}

	u32 drill_active_time = this.get_u32("drill_active_time");
	if (drill_active_time > 0)
	{
		if (!a2)
			drill_active_time--;
		else
		{
			// particles
			if (found_tile)
			{
				u32 seed = getGameTime() + this.getNetworkID();
				if (seed % particle_frequency == 0)
				{
					makeHitParticle(this, tilepos_hit + Vec2f(XORRandom(5) - 2, XORRandom(5) - 2));
				}

				makeRayParticles(this, tilepos_hit);
			}
		}
			
		if (was_hit)
		{
			string hitsound = getHitSound(tile_hit);
			if (hitsound != "")
				if (hitsound != "" && tilepos_hit != Vec2f_zero)
				{
					sprite.PlaySound(hitsound, 0.75f, 0.9f + XORRandom(11)*0.01f);
				}
		}

		string matching_sound = getMatchingLoopSound(tile_hit);
		if (matching_sound != this.get_string("laser_sound"))
		{
			drill_active_time = Maths::Min(drill_active_time, drill_spinup * spinup_throttle);

			sprite.SetEmitSound(matching_sound);
			sprite.RewindEmitSound();
			this.set_string("laser_sound", getMatchingLoopSound(tile_hit));
		}

		if (drill_active_time == 0)
		{
			sprite.SetEmitSoundPaused(true);
			sprite.SetEmitSoundVolume(0.0f);
			sprite.SetEmitSoundSpeed(0.0f);
		}
		else
		{
			f32 spin = f32(drill_active_time) / f32(drill_spinup);

			sprite.SetEmitSoundPaused(false);
			sprite.SetEmitSoundVolume(Maths::Min(spin, max_volume));
			sprite.SetEmitSoundSpeed(Maths::Min(spin + 0.5f, max_pitch));
		}
	}

	this.set_u32("drill_active_time", drill_active_time);
}

void Reload(CBlob@ this, CBlob@ holder)
{
	GunSettings@ settings;
	if (!this.get("gun_settings", @settings))
	{
		return;
	}

	this.set_u16("times_shot", 0);
	this.set_u8("clip", max_times_used);
	this.set_u32("reload", getGameTime() + settings.RELOAD_TIME);

	holder.TakeBlob(blobname, reload_count);
	Sync(this);
}

void makeHitParticle(CBlob@ this, Vec2f endpos)
{
	CParticle@ p = ParticleAnimated("PlasmaExplosion.png", endpos, Vec2f(0, 0), XORRandom(360), 0.5f, 3, 0.0f, false);
	if (p is null) return;

	p.gravity = Vec2f_zero;
	p.fastcollision = true;
	p.collides = false;
	p.lighting = false;
	p.Z = 999.0f;
	p.deadeffect = -1;
	p.timeout = 10+XORRandom(5);
}

void makeRayParticles(CBlob@ this, Vec2f endpos, Vec2f offset = Vec2f_zero)
{
	// create an incoming stream of particles from endpos to thispos with a velocity equal to dist/5
	Vec2f pos = this.getPosition() + offset;
	Vec2f diff = endpos - pos;
	f32 distance = diff.Length();
	diff.Normalize();
	Vec2f step = diff * 8.0f; // step size

	for (f32 d = 8.0f; d < distance; d += step.Length())
	{
		Vec2f partpos = pos + diff * d;
		f32 scale = 1.0f - (d / distance);
		Vec2f rnd_offset = Vec2f((XORRandom(4) - 2) * scale, (XORRandom(4) - 2) * scale);
		partpos += rnd_offset;

		u8 lifetime = 5;
		u8 rnd = XORRandom(21);

		Vec2f next_step = pos + diff * (d + step.Length());
		Vec2f velocity = (partpos -  next_step) / lifetime; // calculate velocity between current step and next step

		CParticle@ p = ParticlePixelUnlimited(partpos + rnd_offset, velocity, SColor(255, 98 + rnd, 208 + rnd, 208 + rnd), true);
		if (p !is null)
		{
			p.Z = 1000.0f;
			p.bounce = 0;
			p.collides = false;
			p.fastcollision = true;
			p.gravity = Vec2f_zero;
			p.lighting = true;
			p.timeout = lifetime;
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ blob)
{
	if (blob is null) return false;
	if (blob.hasTag("invincible")) return false;

	if (blob.getTeamNum() != this.getTeamNum()
		&& (blob.hasTag("flesh") || blob.hasTag("structure") || blob.getShape().isStatic()))
	{
		return true;
	}

	return false;
}

void RequestSync(CBlob@ this)
{
	if (!isClient() || getLocalPlayer() is null) return;

	CBitStream params;
	params.write_bool(true);
	params.write_u16(getLocalPlayer().getNetworkID());
	params.write_bool(this.get_bool("laser_enabled"));
	params.write_u16(0);
	params.write_u16(max_times_used);
	params.write_u8(this.get_u8("clip"));
	params.write_u32(this.get_u32("reload"));
	this.SendCommand(this.getCommandID("sync"), params);
}

void Sync(CBlob@ this, u16 pid = 0)
{
	if (!isServer()) return;

	CBitStream params;
	params.write_bool(false);
	params.write_u16(0);
	params.write_bool(this.get_bool("laser_enabled"));
	params.write_u16(this.get_u16("times_cut"));
	params.write_u16(this.get_u16("times_shot"));
	params.write_u8(this.get_u8("clip"));
	params.write_u32(this.get_u32("reload"));

	if (pid != 0)
	{
		CPlayer@ p = getPlayerByNetworkId(pid);
		if (p !is null)
			this.server_SendCommandToPlayer(this.getCommandID("sync"), params, p);
	}

	if (pid == 0)
		this.SendCommand(this.getCommandID("sync"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync"))
	{
		bool request_sync = params.read_bool();
		u16 pid = params.read_u16();
		bool laser_enabled = params.read_bool();
		u16 times_cut = params.read_u16();
		u16 max_times_used = params.read_u16();
		u8 clip = params.read_u8();
		u32 reload = params.read_u32();

		if (request_sync && isServer())
		{
			Sync(this, pid);
		}
		if (!request_sync && isClient())
		{
			this.set_bool("laser_enabled", laser_enabled);
			this.set_u16("times_cut", times_cut);
			this.set_u16("times_shot", max_times_used);
			this.set_u8("clip", clip);
			this.set_u32("reload", reload);
		}
	}
}

const string[] loop_sounds = {
	"PlasmaCutterLoop.ogg",
	"PlasmaCutterLoopDense.ogg",
	"PlasmaCutterLoopAsteroid.ogg",
	"PlasmaCutterLoopIce.ogg"
};

string getMatchingLoopSound(u16 tile)
{
	if (isScrapTile(tile) || isMetalTile(tile)) return loop_sounds[1];
	else if (isTileIce(tile)) return loop_sounds[3];
	else return loop_sounds[0];
}

const string[] hit_sounds = {
	"PlasmaCutterHitMetal.ogg",
	"PlasmaCutterHitRock.ogg",
	"PlasmaCutterHitIce.ogg"
};

string getHitSound(u16 tile, CBlob@ blob = null)
{
	if (blob !is null)
	{
		//todo
	}
	else
	{
		if (isScrapTile(tile) || isMetalTile(tile)) return hit_sounds[0];
		else if (isTileIce(tile)) return hit_sounds[2];
	}

	return "";
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	this.SetLight(false);

	sprite.SetEmitSoundPaused(true);
	sprite.SetEmitSoundVolume(0.0f);
	sprite.SetEmitSoundSpeed(0.0f);

	this.set_u32("drill_active_time", 0);
}