#include "WarfareGlobal.as";
#include "AllHashCodes.as";
#include "ThrowCommon.as";
#include "KnockedCommon.as";
#include "RunnerCommon.as";
#include "BombCommon.as";
#include "Hitters.as";
#include "HittersAW.as";
#include "InfantryCommon.as";
#include "MedicisCommon.as";
#include "TeamColour.as";
#include "CustomBlocks.as";
#include "RunnerHead.as";
#include "PlayerRankInfo.as";
#include "HoverMessage.as";
#include "ProgressBar.as";
#include "TeamColorCollections.as";
#include "StandardFire.as";
#include "GlobalInfantryHooks.as";

// firebringer's stats
const f32 firebringer_max_scale = 750.0f;
const u8 firebringer_aftershot = 30;

const u16 dash_cooldown = 45;
const f32 dash_force = 4.25f;
const u16 jet_fuel = 35; // flytime in ticks
const u8 jet_fuel_restore = 2; // per tick
const u8 jet_refuel_delay = 30;
const u8 jet_fuel_min = jet_fuel/10;
const f32 jet_force = 32.0f;

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null && !player.exists("PerkStats"))
	{
		addPerk(player, 0);
	}
	InitPerk(this, player);
}

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	const string thisBlobName = this.getName();
	const int thisBlobHash = thisBlobName.getHash();

	string classname; // case sensitive
	int class_hash = thisBlobHash; // hash of the name
	// DAMAGE
	f32 damage_body; // damage dealt to body
	f32 damage_head; // damage dealt on headshot
	// SHAKE
	f32 recoil_x; // x shake (20)
	f32 recoil_y; // y shake (45)
	f32 recoil_length; // how long to recoil (?)
	// RECOIL
	f32 recoil_force; // amount to push player
	u8 recoil_cursor; // amount to raise mouse pos
	u8 sideways_recoil; // sideways recoil amount
	u8 sideways_recoil_damp; // higher number means less sideways recoil
	f32 ads_cushion_amount; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	f32 length_of_recoil_arc; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	u8 inaccuracy_cap; // max amount of inaccuracy
	u8 inaccuracy_pershot; // aim inaccuracy  (+3 per shot)
	u8 inaccuracy_midair;
	u8 inaccuracy_hit;
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// movement (extra)
	f32 reload_walkspeed_factor;
	f32 reload_jumpheight_factor;
	f32 stab_walkspeed_factor;
	f32 stab_jumpheight_factor;
	// GUN
	bool semiauto;
	u8 burst_size; // bullets fired per click
	u8 burst_rate; // ticks per bullet fired in a burst
	s16 reload_time; // time to reload
	u8 noreloadtimer; // time after each shot where you can't reload
	u32 mag_size; // max bullets in mag
	u8 delayafterfire; // time between shots 4
	u8 randdelay; // + randomness
	f32 bullet_velocity; // speed that bullets fly 1.6
	u32 bullet_lifetime; // in ticks, time for bullet to die
	s16 bullet_pen; // penRating for bullet
	bool emptyshellonfire; // should an empty shell be released when shooting
	// SOUND
	string reload_sfx;
	string shoot_sfx;

	getBasicStats( thisBlobHash, classname, reload_sfx, shoot_sfx, damage_body, damage_head );
	getRecoilStats( thisBlobHash, recoil_x, recoil_y, recoil_length, recoil_force, recoil_cursor, sideways_recoil, sideways_recoil_damp, ads_cushion_amount, length_of_recoil_arc );
	getWeaponStats( thisBlobHash, 
	inaccuracy_cap, inaccuracy_pershot, inaccuracy_midair, inaccuracy_hit,
	semiauto, burst_size, burst_rate, 
	reload_time, noreloadtimer, mag_size, delayafterfire, randdelay, 
	bullet_velocity, bullet_lifetime, bullet_pen, emptyshellonfire);
	getExtraMovementStats( thisBlobHash, reload_walkspeed_factor,
	reload_jumpheight_factor, stab_walkspeed_factor, stab_jumpheight_factor);

	InfantryInfo infantry;
	infantry.classname 				= classname;
	infantry.class_hash 			= class_hash;
	infantry.reload_sfx 			= reload_sfx;
	infantry.shoot_sfx 				= shoot_sfx;
	infantry.damage_body 			= damage_body;
	infantry.damage_head 			= damage_head;

	infantry.recoil_x 				= recoil_x;
	infantry.recoil_y 				= recoil_y;
	infantry.recoil_length 			= recoil_length;
	infantry.recoil_force 			= recoil_force;
	infantry.recoil_cursor 			= recoil_cursor;
	infantry.sideways_recoil 		= sideways_recoil;
	infantry.sideways_recoil_damp 	= sideways_recoil_damp;
	infantry.ads_cushion_amount 	= ads_cushion_amount;
	infantry.length_of_recoil_arc 	= length_of_recoil_arc;

	infantry.reload_walkspeed_factor = reload_walkspeed_factor;
	infantry.reload_jumpheight_factor= reload_jumpheight_factor;
	infantry.stab_walkspeed_factor   = stab_walkspeed_factor;
	infantry.stab_jumpheight_factor  = stab_jumpheight_factor;

	infantry.inaccuracy_cap 		= inaccuracy_cap;
	infantry.inaccuracy_pershot 	= inaccuracy_pershot;
	infantry.inaccuracy_midair      = inaccuracy_midair;
	infantry.inaccuracy_hit         = inaccuracy_hit;
	infantry.semiauto 				= semiauto;
	infantry.burst_size 			= burst_size;
	infantry.burst_rate 			= burst_rate;
	infantry.reload_time 			= reload_time;
	infantry.noreloadtimer          = noreloadtimer;
	infantry.mag_size = mag_size;
	infantry.delayafterfire 		= delayafterfire;
	infantry.randdelay 				= randdelay;
	infantry.bullet_velocity 		= bullet_velocity;
	infantry.bullet_lifetime 		= bullet_lifetime;
	infantry.bullet_pen 			= bullet_pen;
	infantry.emptyshellonfire 		= emptyshellonfire;

	this.set("infantryInfo", @infantry);

	this.set_u32("mag_bullets_max", mag_size);
	this.set_u32("mag_bullets", mag_size);

	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.Tag("player");
	this.Tag("flesh");
	this.addCommandID("sync_reload_to_server");
	this.addCommandID("aos_effects");
	this.addCommandID("levelup_effects");
	this.addCommandID("bootout");
	this.addCommandID("reload");
	this.addCommandID("addxp_universal");
	this.addCommandID("attach_parachute");
	this.addCommandID("shield_effects");
	this.addCommandID("throw fire");
	this.addCommandID("basic_sync");
	this.addCommandID("sync_mag");
	this.addCommandID("sync_regen");
	this.addCommandID("jet_effects");
	this.addCommandID("jet_effects_kagsucks");

	this.Tag("3x2");
	this.set_u32("set_nomenus", 0);

	if (thisBlobHash == _mp5)
	{
		this.Tag("no_knife");
		this.Tag(medicTagString);
	}

	this.set_s16("reloadtime", 0); // for server

	// one of these two has to go
	this.set_s16("charge_time", 0);
	this.set_s32("my_chargetime", 0);
	this.set_s32("my_reloadtime", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);

	this.set_s32("custom_hitter", HittersAW::bullet);

	this.set_u32("lmg_aftershot", 0);
	this.set_u32("firebringer_aftershot", 0);

	this.set_s16("recoil_direction", 0);
	this.set_u8("inaccuracy", 0);
	this.set_u32("bull_boost", 0);
	this.set_u32("turret_delay", 0);
	this.set_u32("regen", 0);

	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -80.0f));
	this.set_f32("scale", 0);

	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot rpg");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	Animation@ anim = this.getSprite().getAnimation("reload");
	if (anim !is null)
	{
		this.set_u8("initial_reloadanim_time", anim.time);
	}

	this.set_u32("can_spot", 0);

	this.set_f32("stab damage", 1.25f);
	this.set_u8("ammo_pershot", 1);
	this.set_string("ammo_prop", "ammo");
	this.set_s16("bullet_type", 0);

	this.set_bool("is_rpg", false);
	this.set_bool("is_firebringer", false);
	this.set_bool("is_lmg", false);
	
	this.set_bool("timed_particle", false);
	this.set_Vec2f("gun_offset", Vec2f(0,0));
	this.set_u8("mg_hidelevel", 5);

	this.Tag("infantry");

	// todo: move this to infantrycommon.as
	switch (thisBlobHash)
	{
		case _revolver:
		{
			this.set_u8("stab time", 24);
			this.set_u8("stab timing", 16);
			this.Tag("no bulletgib on shot");
			this.set_f32("stab damage", 1.33f);
			this.set_u8("scoreboard_icon", 0);
			this.set_u8("class_icon", 1);
			break;
		}
		case _shielder:
		{
			this.Tag("no_knife");
			this.set_u8("stab time", 30);
			this.set_u8("stab timing", 0);
			this.set_f32("stab damage", 0.0f);
			this.set_u8("scoreboard_icon", 8);
			this.set_u8("class_icon", 7);

			this.Tag("is_shielder");
			break;
		}
		case _ranger:
		{
			this.set_u8("stab time", 36);
			this.set_u8("stab timing", 22);
			this.set_f32("stab damage", 1.1f);
			this.set_u8("scoreboard_icon", 1);
			this.set_u8("class_icon", 2);
			break;
		}
		case _lmg:
		{
			this.set_bool("is_lmg", true);
			this.set_s32("custom_hitter", HittersAW::machinegunbullet);
			this.set_u8("stab time", 24);
			this.set_u8("stab timing", 8);
			this.set_bool("timed_particle", true);
			this.set_Vec2f("gun_offset", Vec2f(0,2));
			this.set_u8("scoreboard_icon", 10);
			this.set_u8("class_icon", 9);
			break;
		}
		case _mp5:
		{
			this.set_bool("timed_particle", true);
			this.set_u8("scoreboard_icon", 5);
			this.set_u8("class_icon", 6);

			this.Tag("is_mp5");
			break;
		}
		case _shotgun:
		{
			this.set_u8("stab time", 28);
			this.set_u8("stab timing", 19);
			this.set_s16("bullet_type", -1);
			this.Tag("simple reload"); // set "simple" reload tags for only-sound reload code
			this.set_f32("stab damage", 1.25f);
			this.set_u8("ammo_pershot", 4);
			this.set_u8("scoreboard_icon", 3);
			this.set_u8("class_icon", 3);
			break;
		}
		case _sniper:
		{
			this.set_u8("stab time", 24);
			this.set_s16("bullet_type", 1);
			this.set_u8("ammo_pershot", 2);
			this.set_u8("scoreboard_icon", 4);
			this.set_u8("class_icon", 4);
			break;
		}
		case _firebringer:
		{
			this.set_bool("is_firebringer", true);
			
			sprite.SetEmitSound("FlamethrowerFire.ogg");
			sprite.SetEmitSoundSpeed(1.1f);
			sprite.SetEmitSoundVolume(0.66f);
			sprite.SetEmitSoundPaused(true);
			
			this.set_u8("stab time", 28);
			this.set_u8("stab timing", 19);
			this.set_u32("mag_bullets", 0);
			this.set_string("ammo_prop", "specammo");
			this.set_f32("stab damage", 1.25f);
			this.set_u8("scoreboard_icon", 9);
			this.set_u8("class_icon", 8);
			break;
		}
		case _rpg:
		{
			this.set_u8("stab time", 24);
			this.set_bool("is_rpg", true);
			this.set_u32("mag_bullets", 0);
			this.set_string("ammo_prop", "mat_heatwarhead");
			this.set_u8("scoreboard_icon", 3);
			this.set_u8("class_icon", 2);
			break;
		}
	}
	
	this.set_u8("noreload_custom", 15);
	if (this.getName() == "sniper") this.set_u8("noreload_custom", 30);

	gunInit(this);
	barInit(this);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("vehicle"))
	{
		this.setVelocity(detached.getVelocity());
	}
	// Deploy parachute!
	if (detached.hasTag("aerial"))
	{
		if (!getMap().rayCastSolid(this.getPosition(), this.getPosition() + Vec2f(0.0f, 120.0f)) && !this.isOnGround() && !this.isInWater() && !this.isAttached())
		{
			CPlayer@ p = this.getPlayer();
			bool stats_loaded = false;
			PerkStats@ stats;
			if (p !is null && p.get("PerkStats", @stats))
				stats_loaded = true;
				
			if (stats_loaded && stats.parachute && (!this.hasTag("parachute") || (isServer() && !isClient())))
			{
				Sound::Play("/ParachuteOpen", detached.getPosition());
				this.Tag("parachute");

				//AttachParachute(this);
			}
		}
	}
	if (detached !is null && getLocalPlayer() !is null && getLocalPlayer().getBlob() is this && (detached.getName() == "binoculars" || detached.getName() == "launcher_javelin"))
	{
		if (!g_fixedcamera && this.get_bool("disable_fixedcamera"))
		{
			this.set_bool("disable_fixedcamera", false);
			g_fixedcamera = true;
		}
	}
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
	if (this.hasTag("dead") || this.isAttached() || this.getPlayer() is null)
	{
		this.set_u32("end_stabbing", 0);
		this.Untag("attacking");
		return;
	}
	if (!getNet().isServer()) { return; }
	if (aimangle < 0.0f) { aimangle += 360.0f; }

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateBy(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 attack_distance = 18.0f;

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	f32 angle = arcdegrees;
	bool can_dig = false;
	if (this.getName() == "shotgun" || this.getName() == "firebringer")
	{
		can_dig = true;
		angle *= 0.5f;
	}
	HitInfo@[] hitMapInfos;
	if (map.getHitInfosFromArc(blobPos, -exact_aimangle, angle, radius + attack_distance, this, @hitMapInfos))
	{
		bool dontHitMore = false;
		
		for (uint i = 0; i < hitMapInfos.length; i++)
		{
			HitInfo@ hi = hitMapInfos[i];
			CBlob@ b = hi.blob;

			if (b !is null) // blob
			{
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();
				if (b.hasTag("ignore sword")) continue;
				if (b.getTeamNum() == this.getTeamNum()) continue;
				if (b.hasTag("machinegunner") && b.get_u8("mg_hidelevel") <= 1) continue;
				if (b.getName() == "wooden_platform") damage *= 1.25f;
				if (b.hasTag("door")) damage *= 2.5f;

				//big things block attacks
				{
					this.server_Hit(b, hi.hitpos, Vec2f(0,0), damage, type, false); 
					if (b.hasTag("door") && b.getShape().getConsts().collidable) break;
					// end hitting if we hit something solid, don't if its flesh
				}
			}

			if (!dontHitMore && can_dig)
			{
				Vec2f tpos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
				//bool canhit = canhit && map.getSectorAtPosition(tpos, "no build") is null;
				TileType type = map.getTile(tpos).type;
				if (map.isTileBackground(map.getTile(tpos)) || !map.isTileSolid(map.getTile(tpos))) continue;
				if (!(map.isTileCastle(type) || isTileScrap(type))
				&& !isTileScrap(type) && (!isTileCompactedDirt(type) || XORRandom(2) == 0))
					map.server_DestroyTile(hi.hitpos, 0.1f, this);
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		if (this.getName() == "rpg")
		{
			CBlob@ b = server_CreateBlob("mat_heatwarhead", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.server_SetQuantity(this.get_u32("mag_bullets"));
			}
		}
		if (this.getName() == "firebringer")
		{
			CBlob@ b = server_CreateBlob("specammo", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.server_SetQuantity(this.get_u32("mag_bullets"));
			}
		}
	}
}

void ManageGun(CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars, InfantryInfo@ infantry)
{
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	CPlayer@ p = this.getPlayer();
	bool stats_loaded = false;
	PerkStats@ stats;
	if (p !is null && p.get("PerkStats", @stats) && stats !is null)
		stats_loaded = true;
	
	if (isServer())
	{
		if (stats_loaded)
		{
			bool aos = this.hasBlob("aceofspades", 1);
			this.set_bool("has_aos", aos);

			if (stats.id == Perks::lucky
			&& this.get_u32("aceofspades_timer") < getGameTime()
			&& !aos)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					int xslots = inv.getInventorySlots().x;
					int yslots = inv.getInventorySlots().y;
					CBlob@ item = inv.getItem(xslots * yslots - 1);
					//if (item !is null) // theres an item in the last slot
					//{
					//	item.server_RemoveFromInventories();
					//}
					//else //if (!this.hasBlob("aceofspades", 1))  // theres no item in the last slot
					{
						// give ace
						CBlob@ b = server_CreateBlob("aceofspades", -1, this.getPosition());
						if (b !is null)
						{
							this.server_PutInInventory(b);
						}
					}
				}
			}
		}
	}

	CControls@ controls = this.getControls();
	CSprite@ sprite = this.getSprite();
	s32 charge_time = this.get_s32("my_chargetime");
	s32 reload_time = this.get_s32("my_reloadtime");
	this.set_s16("charge_time", charge_time);
	if (this.get_u32("end_stabbing") >= getGameTime())
	{
		archer.isStabbing = true;
	}
	bool isStabbing = archer.isStabbing;
	bool isReloading = this.get_bool("isReloading") || this.get_s32("my_reloadtime") > 0;
	u8 charge_state = archer.charge_state;
	bool just_action1;
	bool is_action1;

	bool is_shotgun = this.getName() == "shotgun";
	bool is_rpg = this.getName() == "is_rpg";

	just_action1 = reload_time <= 0 && (this.get_bool("just_a1") && this.hasTag("can_shoot_if_attached")) || (!this.isAttached() && this.isKeyJustPressed(key_action1));
	is_action1 = reload_time <= 0 && (this.get_bool("is_a1") && this.hasTag("can_shoot_if_attached")) || (!this.isAttached() && this.isKeyPressed(key_action1));
	bool was_action1 = reload_time <= 0 && this.wasKeyPressed(key_action1);
	bool hidegun = false;

	if (this.hasTag("dead") || (stats_loaded && stats.id == Perks::mason && this.get_s32("selected_structure") != -1))
	{
		just_action1 = false;
		is_action1 = false;
	}

	if ((is_action1 || this.get_u32("lmg_aftershot") > getGameTime()
		|| this.get_u32("firebringer_aftershot") > getGameTime()) && !isReloading)
	{
		if (this.get_bool("is_lmg"))
		{
			moveVars.walkFactor *= 0.65f;
			moveVars.jumpFactor *= 0.65f;
		}
		else if (this.get_bool("is_firebringer"))
		{
			moveVars.walkFactor *= 0.8f;
			moveVars.jumpFactor *= 0.7f;
		}
	}

	if (this.getCarriedBlob() !is null)
	{
		if (this.getCarriedBlob().getName() == "medkit")
		{
			just_action1 = false;
			is_action1 = false;
			was_action1 = false;
		}
		if (this.getCarriedBlob().hasTag("hidesgunonhold"))
		{
			hidegun = true;
		}
	}

	bool lock_stab = false;
	if (this.get_u32("turret_delay") < getGameTime() && this.isKeyPressed(key_action3) && this.isKeyPressed(key_down) && !hidegun && !isReloading && this.isOnGround() && this.getVelocity().Length() <= 1.0f)
	{
		if (this.hasBlob("mat_scrap", 1) && this.getPlayer() !is null && stats.id == Perks::fieldengineer)
		{
			if (getGameTime()%12 == 0 && this.getSprite() !is null)
			{
				this.getSprite().PlaySound("SentryBuild.ogg", 0.33f, 1.05f+0.001f*XORRandom(115));
			}
			lock_stab = true;
			if (this.get_f32("turret_load") < 90)
			{
				this.add_f32("turret_load", 1);
			}
			else
			{
				this.set_f32("turret_load", 0);
				this.set_u32("turret_delay", getGameTime()+150);

				if (isServer())
				{
					this.TakeBlob("mat_scrap", 1);
					CBlob@ turret_exists = getBlobByNetworkID(this.getPlayer().get_u16("turret_netid"));
					if (turret_exists !is null && turret_exists.getName() == "sentrygun")
					{
						this.server_Hit(turret_exists, turret_exists.getPosition(), Vec2f(0,0), 150.0f, HittersAW::bullet, true); 
						//turret_exists.server_Die();
					}
					CBlob@ turret = server_CreateBlob("sentrygun", this.getTeamNum(), this.getPosition());
					if (turret !is null)
					{
						this.getPlayer().set_u16("turret_netid", turret.getNetworkID());
						turret.SetDamageOwnerPlayer(this.getPlayer());
					}
				}
			}
		}
	}
	else if (this.get_f32("turret_load") > 0) this.set_f32("turret_load", 0);

	if (this.get_f32("turret_load") > 0)
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "sentry_build"))
			{
				SColor team_front = getNeonColor(this.getTeamNum(), 0);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "sentry_build", Vec2f(64.0f, 16.0f), false, Vec2f(0, 40), Vec2f(2, 2), back, team_front,
					"turret_load", 90/*sentry buildtime*/, 1.0f, 5, 5, false, "");

    			bars.AddBar(this.getNetworkID(), setbar, true);
			}
		}	
	}
	else if (this.isKeyJustReleased(key_action3) || this.isKeyPressed(key_right) || this.isKeyPressed(key_left) || this.isKeyJustReleased(key_down))
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			bars.RemoveBar("sentry_build", false);
		}
	}

	if (!this.hasTag(medicTagString))
	{
		u8 time = 21;
		u8 timing = 13;
		f32 damage = 0.85f;
		bool no_medkit = true;
		CBlob@ carried = this.getCarriedBlob();
		if (carried !is null && carried.getName() == "medkit") no_medkit = false;
		if (this.exists("stab time")) time = this.get_u8("stab time");
		if (this.exists("stab timing")) timing = this.get_u8("stab timing");
		if (this.exists("stab damage")) damage = this.get_f32("stab damage");
		if (this.isKeyPressed(key_action3) && !this.hasTag("no_knife") && !hidegun && !isReloading && this.get_u32("end_stabbing") < getGameTime()+6 && no_medkit)
		{
			if (canStab(this) && !lock_stab)
			{
				this.set_u32("end_stabbing", getGameTime()+time);
				this.Tag("attacking");

				if (this.getSprite() !is null && this.getSprite().getAnimation("stab") !is null)
				{
					Animation@ anim = this.getSprite().getAnimation("stab");
					anim.frame = 0;
				}
			}
		}
		if (this.hasTag("attacking") && getGameTime() == this.get_u32("end_stabbing")-timing)
		{
			f32 attackarc = 60.0f;
			DoAttack(this, damage, (this.isFacingLeft() ? 180.0f : 0.0f), attackarc, Hitters::sword);
			this.Untag("attacking");
		}
		if (this.get_u32("end_stabbing") > getGameTime())
		{
			just_action1 = false;
			is_action1 = false;
			was_action1 = false;
		}
	}
	
	const bool pressed_action2 = this.isKeyPressed(key_action2) && this.isOnGround();
	bool menuopen = getHUD().hasButtons();
	Vec2f pos = this.getPosition();

	const u8 inaccuracyCap = infantry.inaccuracy_cap;
	
	InAirLogic(this, inaccuracyCap);

	if (this.isKeyPressed(key_action2))
	{
		this.Untag("scopedin");

		if (!isReloading && !menuopen || this.hasTag("attacking"))
		{
			moveVars.walkFactor *= 0.8f;
			this.Tag("scopedin");
		}
	}
	else
	{
		this.Untag("scopedin");
	}
	
	bool scoped = this.hasTag("scopedin");

	if (hidegun) return;
	
	if (isKnocked(this))
	{
		this.set_u8("reloadqueue", 0);
		charge_time = 0;

		archer.isReloading = false;
	}
	else
	{
		s16 reloadTime = infantry.reload_time;
		
		if (p !is null && p.getBlob() !is null)
		{
			Animation@ anim = p.getBlob().getSprite().getAnimation("reload");
			if (anim !is null && stats_loaded)
			{
				u8 time = anim.time;
				reloadTime = infantry.reload_time * stats.reload_time;
				anim.time = Maths::Round(this.get_u8("initial_reloadanim_time") * stats.reload_time);
			}
		}
		
		const u32 magSize = infantry.mag_size;
	
		bool done_shooting = this.get_s16("charge_time") <= 0 && this.get_s32("my_chargetime") <= 0;
		bool not_full = this.get_u32("mag_bullets") < this.get_u32("mag_bullets_max");

		if (done_shooting && this.get_u32("no_reload") < getGameTime())
		{
			// reload
			if (controls !is null // bots may break
				&& !isReloading && this.get_u32("end_stabbing") < getGameTime()
				&& ((((isClient() && controls.isKeyJustPressed(KEY_KEY_R)) || (this.get_u8("reloadqueue") > 0)) && not_full)
				|| (this.hasTag("forcereload"))))
			{
				bool forcereload = false;
				s32 delay = getGameTime()+this.get_u8("noreload_custom");

				this.set_u32("no_reload", delay);
				this.set_s32("my_reloadtime", infantry.reload_time);
				this.set_u32("reset_reloadtime", infantry.reload_time+getGameTime());
				this.set_s32("my_chargetime", charge_time);
				
				if (this.hasTag("forcereload"))
				{
					this.set_u32("mag_bullets", this.get_u32("mag_bullets_max"));
					this.Untag("forcereload");
					forcereload = true;
				}
				bool reloadistrue = false;
				CInventory@ inv = this.getInventory();
				if ((inv !is null && inv.getItem(this.get_string("ammo_prop")) !is null) || forcereload)
				{
					// actually reloading
					reloadistrue = true;
					charge_time = reloadTime;

					isReloading = true;
					this.set_bool("isReloading", true);

					CBitStream params; // sync to server
					if (ismyplayer && !this.isBot()) // isClient()
					{
						params.write_s16(charge_time);
						this.SendCommand(this.getCommandID("sync_reload_to_server"), params);
					}
				}
				//else if (ismyplayer)
				//{
				//	sprite.PlaySound("NoAmmo.ogg", 0.85);
				//}
			}
		}
		
		if (isServer() && this.hasTag("sync_reload"))
		{
			s16 reload = charge_time > 0 ? charge_time : this.get_s16("reloadtime");
			if (reload > 0)
			{
				reload_time = reload;
				//archer.isReloading = true;
				this.set_bool("isReloading", true);

				CBitStream params;
				params.write_bool(this.get_bool("isReloading"));
				params.write_s32(this.get_s32("my_chargetime"));
				this.SendCommand(this.getCommandID("basic_sync"), params);

				//this.Sync("isReloading", true);
				isReloading = true;
				this.Untag("sync_reload");
			}
		}

		const bool oldEnough = this.getTickSinceCreated() > 5;
		const bool is_m1 = infantry.semiauto ? just_action1 : is_action1;
		// shoot
		if (charge_time == 0 && oldEnough && is_m1)
		{
			moveVars.walkFactor *= 0.75f;
			moveVars.jumpFactor *= 0.7f;
			moveVars.canVault = false;

			if (!isStabbing)
			{
				if (menuopen) return;
				if (isReloading) return;
				if (this.get_s32("my_chargetime") > 0 || this.get_s32("my_reloadtime") > 0) return;

				charge_state = ArcherParams::readying;

				if (this.get_u32("mag_bullets") <= 0)
				{
					charge_state = ArcherParams::no_ammo;
					
					if (ismyplayer && (!was_action1 || charge_time == 0))
					{
						this.Tag("armangle_lock");
						charge_time += infantry.delayafterfire;
						sprite.PlaySound("EmptyGun.ogg", 0.4);
					}
				}
				else
				{
					this.Untag("armangle_lock");

					bool do_effects = !this.get_bool("is_firebringer");
					if (do_effects) ClientFire(this, stats, charge_time, infantry, this.getPosition()+this.get_Vec2f("gun_offset"));
					else if (this.isMyPlayer())
					{
						this.add_f32("scale", 3.0f*Maths::Sqrt(this.get_f32("scale")+firebringer_max_scale));
						this.set_f32("scale", Maths::Min(firebringer_max_scale-XORRandom(firebringer_max_scale/5), this.get_f32("scale")));

						CBitStream params;
						params.write_f32(this.get_f32("scale"));
						this.SendCommand(this.getCommandID("throw fire"), params);
					}

					charge_time = infantry.delayafterfire + XORRandom(infantry.randdelay);
					charge_state = ArcherParams::fired;

					if (this.get_u8("inaccuracy")/infantry.inaccuracy_cap > 0.33f || is_shotgun || is_rpg)
					{
						float recoilForce = infantry.recoil_force;
						f32 normalized = (this.getAimPos() - this.getPosition()).Angle();
						Vec2f force = Vec2f(1, 0).RotateBy(normalized) * (scoped ? -recoilForce/1.6 : -recoilForce);
						force *= 200;
						if (is_rpg) force = Vec2f(force.x, force.y*1.5f); // funny
						this.AddForce(Vec2f(force.x, -force.y));
					}
				}
			}
			else
			{
				charge_time--;

				if (charge_time <= 0)
				{
					charge_time = 0;
					if (isReloading)
					{
						TakeAmmo(this, magSize);
					}

					archer.isStabbing = false;
					archer.isReloading = false;

					this.set_bool("isReloading", false);
				}
			}
		}
		else
		{
			charge_time--;

			if (charge_time <= 0)
			{
				charge_time = 0;
				if (isReloading)
				{
					TakeAmmo(this, magSize);
				}

				archer.isStabbing = false;
				archer.isReloading = false;

				this.set_bool("isReloading", false);
			}

			if (p !is null)
			{
				float walkStat = 1.0f;
				float airwalkStat = 2.33f;
				float jumpStat = 1.0f;

				bool sprint = (stats_loaded ? stats.sprint : true) && this.getHealth() == this.getInitialHealth() && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
				
				// operators move slower than normal
				if (stats_loaded)
				{
					if (stats.id == Perks::bull) sprint = stats.sprint && this.getHealth() >= this.getInitialHealth()*0.5f && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
					getMovementStats(this.getName().getHash(), sprint, walkStat, airwalkStat, jumpStat);

					walkStat 	*= stats.walk_factor;
					airwalkStat *= stats.walk_factor_air;
					jumpStat 	*= stats.jump_factor;

					if (stats.id == Perks::bull && this.get_u32("bull_boost") != 0 && this.get_u32("bull_boost") > getGameTime())
					{
						walkStat 	*= stats.walk_extra_factor;
						airwalkStat *= stats.walk_extra_factor_air;
						jumpStat 	*= stats.jump_extra_factor;
					}
				}


				if (sprint)
				{
					CBlob@ carried = this.getCarriedBlob();
					if (!this.hasTag("sprinting") && (carried is null || !carried.hasTag("very heavy weight")))
					{
						if (isClient())
						{
							ParticleAnimated("DustSmall.png", this.getPosition()-Vec2f(0, -3.75f), Vec2f(this.isFacingLeft() ? 1.0f : -1.0f, -0.1f), 0.0f, 0.75f, 2, XORRandom(70) * -0.00005f, true);
						}
					}
					this.Tag("sprinting");
				}
				else
				{
					this.Untag("sprinting");
				}

				moveVars.walkFactor *= walkStat;
				moveVars.walkSpeedInAir = airwalkStat;
				moveVars.jumpFactor *= jumpStat;
			}
		}
	}

	// inhibit movement
	if (charge_time > 0)
	{
		if (isReloading)
		{
			moveVars.walkFactor *= infantry.reload_walkspeed_factor; // 0.55f default
			moveVars.jumpFactor *= infantry.reload_jumpheight_factor; // 1.0 default
		}
	}
	else if (isStabbing)
	{
		moveVars.walkFactor *= infantry.stab_walkspeed_factor; // 0.2f default
		moveVars.jumpFactor *= infantry.stab_jumpheight_factor; // 0.8 default
	}

	if (this.get_u8("inaccuracy") > 0 && this.get_u32("accuracy_delay") < getGameTime())
	{
		this.set_u8("inaccuracy", this.get_u8("inaccuracy") >= 5 ? this.get_u8("inaccuracy") - 5 : 0);
	}
	
	if (responsible)
	{
		// set cursor
		if (ismyplayer && !getHUD().hasButtons())
		{
			InfantryInfo@ infantry;
			int frame = 0;

			if (this.get_u8("inaccuracy") == 0)
			{
				if (this.isKeyPressed(key_action2))
				{
					getHUD().SetCursorFrame(0);
				}
				else
				{
					getHUD().SetCursorFrame(1);
				}	
			}
			else if (this.get("infantryInfo", @infantry))
			{
				f32 max_frame = 9;
				f32 frame;
				f32 inaccuracy = this.get_u8("inaccuracy");
				f32 inaccuracy_cap = infantry.inaccuracy_cap;

				frame = Maths::Ceil((inaccuracy/inaccuracy_cap)*9);
				//printf(""+frame);

				getHUD().SetCursorFrame(Maths::Clamp(Maths::Floor(frame), 1, max_frame));
			}
		}

		// activate/throw
		//if (this.isKeyJustPressed(key_action3))
		//{
		//	client_SendThrowOrActivateCommand(this);
		//}
	}

	this.set_s32("my_chargetime", charge_time);
	//this.Sync("my_chargetime", true);
	//printf((isClient()?"CLIENT ":"SERVER ")+charge_time);
	archer.charge_state = charge_state;
}

void TakeAmmo(CBlob@ this, u32 magSize)
{
	this.set_s32("my_reloadtime", 0);
	
	CInventory@ inv = this.getInventory();
	if (inv !is null)
	{
		//printf(""+need_ammo);
		//printf(""+current);
		for (u8 i = 0; i < 20; i++)
		{
			u8 multiplier = this.get_u8("ammo_pershot");
			u32 current = this.get_u32("mag_bullets");
			u32 miss = (magSize-current)*multiplier;
			CBlob@ mag;
			for (u8 i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ b = inv.getItem(i);
				if (b is null || b.getName() != this.get_string("ammo_prop") || b.hasTag("dead")) continue;
				@mag = @b;
				break;
			}
			if (mag !is null)
			{
				u16 quantity = mag.getQuantity();
				if (quantity <= miss)
				{
					mag.Tag("dead");
					if (isServer())
					{
						this.add_u32("mag_bullets", Maths::Max(0, Maths::Ceil(f32(quantity)/f32(multiplier))));//
						this.Sync("mag_bullets", true); // for some fucking reason this differs from regular command syncing
						CBitStream params; // and for even more retarded (shitcode) reason this is needed for proper RPG sync ¯\_(ツ)_/¯
						params.write_u32(this.get_u32("mag_bullets"));
						this.SendCommand(this.getCommandID("sync_mag"), params);

						mag.server_Die();
					}
					continue;
				}
				else
				{
					if (isServer())
					{
						this.set_u32("mag_bullets", magSize);//
						this.Sync("mag_bullets", true);
						CBitStream params;
						params.write_u32(this.get_u32("mag_bullets"));
						this.SendCommand(this.getCommandID("sync_mag"), params);
//
						mag.server_SetQuantity(quantity - miss);
					}
					break;
				}
			}
			else break;
		}
	}
}

void HandleOther(CBlob@ this)
{
	u32 gt = getGameTime()+this.getNetworkID();
	if (gt%30==0)
	{
		if (isServer())
		{
			if (!this.hasTag("camera_offset") && !(isClient() && isServer()) && this.getPlayer() is null) this.server_Die(); // bots sometimes get stuck AI
			if (this.hasTag("invincible") && !this.isAttached()) this.Untag("invincible");
		}
		if (isClient())
		{
			if (((this.getTeamNum() == getRules().get_u8("teamleft") && getRules().get_s16("teamLeftTickets") == 0)
			|| (this.getTeamNum() == getRules().get_u8("teamright") && getRules().get_s16("teamRightTickets") == 0)))
			{
				this.SetLightRadius(16.0f);
				this.SetLightColor(SColor(255, 255, 255, 255));
				this.SetLight(true);
			}
		}
	}
	if (this.get_u32("reset_reloadtime") < getGameTime())
	{
		this.set_s32("my_reloadtime", 0);
	}
}

bool ModifyTDM(CBlob@ this, RunnerMoveVars@ moveVars)
{
	bool isTDM = (getMap().tilemapwidth <= 300);
	if (!isTDM) return false;
	
	if (this.isMyPlayer())
	{
		this.set_f32("dash_cooldown_current", Maths::Max(0, this.get_f32("next_dash")-getGameTime()));
		f32 cooldown = this.get_f32("dash_cooldown_current");

		if (this.isAttached()) return false;

		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (cooldown <= dash_cooldown/10 && hasBar(bars, "dash"))
			{
				bars.RemoveBar("dash", false);
			}

			CControls@ controls = this.getControls();
			if (controls is null) return false;
			CSprite@ sprite = this.getSprite();
			if (sprite is null) return false;

			if (controls.isKeyPressed(KEY_LSHIFT) && this.get_f32("jet_current") > jet_fuel_min)
			{

				if (!hasBar(bars, "jet"))
				{
					SColor color = SColor(255, 255, 2255, 55);
					ProgressBar setbar;
					setbar.Set(this.getNetworkID(), "jet", Vec2f(48.0f, 12.0f), false, Vec2f(0, 40), Vec2f(2, 2), back, color,
						"jet_current", jet_fuel+1, 1.0f, 5, 5, false, "");

    				bars.AddBar(this.getNetworkID(), setbar, true);

					this.set_f32("jet_current", jet_fuel);
				}

				this.set_f32("jet_current", Maths::Max(jet_fuel_min, this.get_f32("jet_current") - 1));
				this.set_u32("jet_refuel_delay", getGameTime()+jet_refuel_delay);

				Jet(this);

				sprite.SetEmitSound("FlamethrowerFire.ogg");
				sprite.SetEmitSoundVolume(0.3f);
				sprite.SetEmitSoundSpeed(0.85f+0.15f*(jet_fuel/this.get_f32("jet_current")));
				sprite.SetEmitSoundPaused(false);
			}
			else
			{
				sprite.SetEmitSoundPaused(true);
			}
			
			if (this.get_u32("jet_refuel_delay") < getGameTime()) //&& (this.isOnGround() || this.isOnLadder() || this.isInWater()))
			{
				this.set_f32("jet_current", Maths::Min(jet_fuel, this.get_f32("jet_current") + jet_fuel_restore));
				if (this.get_f32("jet_current") == jet_fuel)
				{
					bars.RemoveBar("jet", false);
					sprite.RewindEmitSound();
				}
			}

			if (controls.isKeyJustPressed(KEY_LCONTROL) && cooldown < 5)
			{
				bars.RemoveBar("dash", true);
				this.set_f32("dash_cooldown_current", dash_cooldown);
				this.set_f32("next_dash", getGameTime()+dash_cooldown);
				
				SColor color = SColor(255, 255, 255, 255);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "dash", Vec2f(48.0f, 12.0f), false, Vec2f(0, 40), Vec2f(2, 2), back, color,
					"dash_cooldown_current", dash_cooldown+2, 1.0f, 5, 5, false, "");

    			bars.AddBar(this.getNetworkID(), setbar, true);
				Dash(this, moveVars);
			}
		}
	}

	return true;
}

void Dash(CBlob@ this, RunnerMoveVars moveVars)
{
	f32 dir_x = 1;
	this.isKeyPressed(key_left) ? dir_x = -1 : this.isKeyPressed(key_right) ? dir_x = 1 : this.isFacingLeft() ? dir_x = -1 : dir_x = 1;

	f32 force = this.getMass() * dash_force * moveVars.walkFactor * dir_x;
	this.setVelocity(Vec2f(0, this.getVelocity().y));
	this.AddForce(Vec2f(force, 0));

	if (this.getSprite() !is null)
	{
		this.getSprite().PlayRandomSound("Dash", 0.5f+XORRandom(150)*0.001f, 1.0f+XORRandom(250)*0.001f);
	}
}

void Jet(CBlob@ this)
{
	f32 dir_x = 1;
	this.isKeyPressed(key_left) ? dir_x = -1 : this.isKeyPressed(key_right) ? dir_x = 1 : this.isFacingLeft() ? dir_x = -1 : dir_x = 1;
	Vec2f force = Vec2f(dir_x / 10, -1.0f) * jet_force;
	this.AddForce(force);

	CBitStream params;
	this.SendCommand(this.getCommandID("jet_effects"), params);
}

void onTick(CBlob@ this)
{
	visualTimerTick(this);
	HandleOther(this);

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	InfantryInfo@ infantry;
	if (!this.get( "infantryInfo", @infantry )) return;

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer)) return;
	
	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars)) return;

	bool isTDM = ModifyTDM(this, moveVars);

	bool stats_loaded = false;
	PerkStats@ stats;
	if (this.getPlayer() !is null && this.getPlayer().get("PerkStats", @stats))
		stats_loaded = true;

	ManageFirebringerLogic(this);
	ManageParachute(this, stats);

	if (this.isBot() && this.getTickSinceCreated() == 1 && isClient()) 
	{
		LoadHead(this.getSprite(), XORRandom(99)); // TODO: make a way to sync between players and save when blob dies!
	}

	if (this.getName() != "sniper") // climbing trees by default
	{
		if (stats_loaded)
		{
			if (!stats.ghillie && this.hasScript("ClimbTree.as")) this.RemoveScript("ClimbTree.as");
			else if (stats.ghillie && !this.hasScript("ClimbTree.as")) this.AddScript("ClimbTree.as");
		}
	}
	
	if (isKnocked(this) || this.isInInventory())
	{
		archer.charge_state = 0;
		this.set_s32("my_chargetime", 0);
		//getHUD().SetCursorFrame(0);
		return;
	}

	ManageGun(this, archer, moveVars, infantry);
	if (getHUD() !is null && getHUD().hasMenus())
	{
		this.set_u32("set_nomenus", getGameTime()+1);
	}
	if (this.get_u32("set_nomenus") > getGameTime()) this.Tag("had_menus");
	else this.Untag("had_menus");
	
	if (this.get_u8("reloadqueue") > 0) this.sub_u8("reloadqueue", 1);
	CControls@ controls = this.getControls();
	if (controls !is null && isClient())
	{
		// queue reloading timer
		if (controls.isKeyJustPressed(KEY_KEY_R))
		{
			this.set_u8("reloadqueue", 8);
			//this.Sync("reloadqueue", true);
		}
	}
	
	this.set_bool("is_a1", false);
	this.set_bool("just_a1", false);
}

void ManageFirebringerLogic(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	if (this.get_bool("is_firebringer"))
	{
		if (isClient())
		{
			if (this.get_u32("endtime") < getGameTime())
			{
				sprite.SetEmitSoundPaused(true);
			}
			else if (this.get_u32("endtime") >= getGameTime())
			{
				sprite.SetEmitSoundPaused(false);
				
				u32 diff = this.get_u32("endtime") - getGameTime();
				sprite.SetEmitSoundSpeed(1.1f+XORRandom(21)*0.01f - (0.5f-0.5f*(float(diff)/float(firebringer_aftershot))));
				sprite.SetEmitSoundVolume(0.5f - (0.4f-0.4f*(float(diff)/float(firebringer_aftershot))));
			}
		}
		if (this.get_u32("endtime") - firebringer_aftershot/5 < getGameTime())
			this.set_f32("scale", Maths::Max(0, this.get_f32("scale") - 10.0f*Maths::Sqrt(this.get_f32("scale"))));
	}
}

bool canSend( CBlob@ this )
{
	if (this.hasTag("had_menus") || this.getTickSinceCreated() <= 5) return false;
	return (this.isMyPlayer() || this.getPlayer() is null);
}

void ClientFire(CBlob@ this, PerkStats@ stats, const s16 charge_time, InfantryInfo@ infantry, Vec2f pos)
{
	if (this.hasTag("had_menus") || this.getTickSinceCreated() <= 5) return;
	Vec2f thisAimPos = this.getAimPos() - Vec2f(0,4);

	float angle = Maths::ATan2(thisAimPos.y - pos.y, thisAimPos.x - pos.x) * 180 / 3.14159;
	angle += -0.099f + (XORRandom(2) * 0.01f);

	Vec2f targetVector = thisAimPos - pos;
	f32 targetDistance = targetVector.Length();
	f32 targetFactor = targetDistance / 367.0f;
	
	float perk_mod = 1.0f;
	CPlayer@ p = this.getPlayer();
	bool is_local = p !is null && p.isMyPlayer();

	if (p !is null && is_local && stats !is null)
	{
		perk_mod = stats.accuracy; // improved accuracy
	}

	this.set_u32("accuracy_delay", getGameTime()+3);
	Vec2f thispos = this.getPosition();

	float bulletSpread = getBulletSpread(infantry.class_hash) + (float(this.get_u8("inaccuracy")))/perk_mod;
	if (this.get_bool("is_rpg"))
	{
		targetVector = this.getAimPos() - thispos;
		targetDistance = targetVector.Length();
		targetFactor = targetDistance / 367.0f;
		f32 mod = this.isKeyPressed(key_action2) && this.isOnGround() ? 0.1f : 0.3f;

		ShootRPG(this, thispos - Vec2f(-24,0).RotateBy(angle), this.getAimPos() + Vec2f(-(1 + this.get_u8("inaccuracy")) + XORRandom((180 + this.get_u8("inaccuracy")) - 50)*mod * targetFactor, -(3 + this.get_u8("inaccuracy")) + XORRandom(180 + this.get_u8("inaccuracy")) - 50)*mod * targetFactor, 8.0f * infantry.bullet_velocity);
	
		ParticleAnimated("SmallExplosion3", pos + Vec2f(this.isFacingLeft() ? -8.0f : 8.0f, -2.0f).RotateBy(this.isFacingLeft()?angle+180:angle), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.75f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);

		if (this.isMyPlayer())
		{
			ShakeScreen((Vec2f(infantry.recoil_x - XORRandom(infantry.recoil_x*4) + 1, -infantry.recoil_y + XORRandom(infantry.recoil_y) + 6)), infantry.recoil_length*2, this.getInterpolatedPosition());
			ShakeScreen(48, 28, thispos);
		}
	}
	else
	{
		ShootBullet(this, thispos - Vec2f(0,1), thisAimPos, infantry.bullet_velocity,
			bulletSpread*targetFactor, infantry.burst_size, this.get_s16("bullet_type"));
	}

	//if (this.get_u32("mag_size") > 0)
	this.set_u32("no_reload", getGameTime()+this.get_u8("noreload_custom"));
	//printf(""+this.get_u32("no_reload"));

	// this causes backwards shit
	ParticleAnimated("SmallExplosion3", pos+ Vec2f(this.isFacingLeft() ? -12.0f : 12.0f, -2.0f).RotateBy(this.isFacingLeft()?angle+180:angle), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
	
	CPlayer@ local = getLocalPlayer();
	if (local !is null)
	{
		CBlob@ local_blob = local.getBlob();
		if (local !is null)
		{
			if (is_local)
			{
				f32 mod = 0.5; // make some smart stuff here?
				if (this.isKeyPressed(key_action2) && this.isOnGround()) mod *= 0.25;

				float recoilX = infantry.recoil_x;
				float recoilY = infantry.recoil_y;
				ShakeScreen((Vec2f(recoilX - XORRandom(recoilX*2) + 1, -recoilY + XORRandom(recoilY) + 1) * mod), infantry.recoil_length*mod, this.getInterpolatedPosition());
				ShakeScreen(28, 10, pos);

				this.set_u8("inaccuracy", Maths::Min(infantry.inaccuracy_cap, this.get_u8("inaccuracy") + infantry.inaccuracy_pershot * (this.hasTag("sprinting")?2.0f:1.0f)));

				if (infantry.emptyshellonfire)
				makeGibParticle(
					"EmptyShellSmall",	                    // file name
					thispos,                 // position
					Vec2f(this.isFacingLeft() ? 2.0f : -2.0f, 0.0f), // velocity
					0,                                  // column
					0,                                  // row
					Vec2f(16, 16),                      // frame size
					0.2f,                               // scale?
					0,                                  // ?
					"ShellCasing",                      // sound
					this.get_u8("team_color"));         // team number
			}
		}
	}
}

void ShootRPG(CBlob @this, Vec2f arrowPos, Vec2f aimPos, f32 arrowspeed)
{
	if (canSend(this))
	{
		Vec2f arrowVel = (aimPos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);

		this.SendCommand(this.getCommandID("shoot rpg"), params);
	}

	if (this.isMyPlayer()) ShakeScreen(28, 8, this.getPosition());
}

void ShootBullet( CBlob@ this, Vec2f arrowPos, Vec2f aimPos, float arrowspeed, float bulletSpread, u8 burstSize, s16 type)
{
	if (canSend(this) || (isServer() && this.isBot()))
	{
		if (this.get_u32("no_more_proj") <= getGameTime())
		{
			shootGun(this.getNetworkID(), -(aimPos-arrowPos).Angle(), arrowPos+this.get_Vec2f("gun_offset"), aimPos, bulletSpread, burstSize, type);
			this.set_u32("no_more_proj", getGameTime()+1);
			InfantryInfo@ infantry;
			if (!this.get("infantryInfo", @infantry)) return;
			if (this.get_s32("my_chargetime") == 0)
			{
				this.set_s32("my_chargetime", infantry.delayafterfire);
			}
		}
	}

	if (this.isMyPlayer()) ShakeScreen(28, 8, this.getPosition());
}

const f32 _fire_length_raw = 64.0f;
const f32 _fire_angle = 7.0f;
const f32 inaccuracy_mod = 0.115f; // increases fire angle but decreases fire length per 1 inaccuracy
const f32 inaccuracy_length_decrease_mod = 2.5f;
const f32 inaccuracy_angle_increase_mod = 0.85f;
const u32 firehit_delay = 1;

bool solidHit(CBlob@ this, CBlob@ blob)
{
	return ((!blob.isAttached() || blob.hasTag("collidewithbullets") || blob.hasTag("machinegunner"))
			&& !blob.hasTag("machinegun") && (blob.hasTag("wooden")
			|| blob.hasTag("door") || blob.hasTag("flesh") || blob.hasTag("vehicle")));
}

bool canDamage(CBlob@ this, CBlob@ blob)
{
	return blob.get_u32("firehit_delay") < getGameTime()
			&& blob.getTeamNum() != this.getTeamNum() && (blob.hasTag("apc")
			|| blob.hasTag("weak vehicle") || blob.hasTag("truck")
			|| blob.hasTag("wooden") || blob.hasTag("door") || blob.hasTag("flesh"));
}

void ThrowFire(CBlob@ this, Vec2f pos, f32 angle)
{
	if (this.get_u32("mag_bullets") == 0) return;
	if (isServer())
	{
		if (this.get_s16("firebringer_takeammo") != 2)
		{
			this.add_s16("firebringer_takeammo", 1);
			this.add_u32("mag_bullets", -1);
		}
		else
		{
			this.set_s16("firebringer_takeammo", 0);
		}
		
		CBitStream params;
		params.write_u32(this.get_u32("mag_bullets"));
		this.SendCommand(this.getCommandID("sync_mag"), params);
	}

	this.set_u32("firebringer_aftershot", getGameTime()+10);
	
	bool client = isClient();
	if (client && !this.isOnScreen()) return;

	if (client)
	{
		this.set_u32("endtime", getGameTime()+firebringer_aftershot);
	}

	InfantryInfo@ infantry;
	if (!this.get( "infantryInfo", @infantry )) return;
	
	u8 inaccuracy = this.get_u8("inaccuracy");
	f32 deviation = inaccuracy_mod * inaccuracy * inaccuracy_angle_increase_mod;
	f32 fire_damage = infantry.damage_body;

	f32 fire_length_raw = _fire_length_raw - deviation * inaccuracy_length_decrease_mod;
	f32 fire_angle = _fire_angle + deviation;
	this.set_u8("inaccuracy", Maths::Min(infantry.inaccuracy_cap, this.get_u8("inaccuracy") + infantry.inaccuracy_pershot));
	
	if (getMap() is null) return;
	Vec2f vel = Vec2f_zero;
	
	f32 fire_length = fire_length_raw * (this.get_f32("scale")/firebringer_max_scale);
	f32 rot = float(XORRandom(fire_angle))-fire_angle*0.5f;

	if (client)
	{
		ParticleAnimated("FireDust"+(XORRandom(3)+1)+".png", pos+Vec2f(0, -20).RotateBy(angle), vel, angle, 0.75f+XORRandom(51)*0.01f, 2+XORRandom(3), 0, true);

		for (u8 i = 0; i < 3; i++)
		{
			ParticleAnimated("SmallFire", pos+Vec2f(0, -16).RotateBy(angle), Vec2f(0, -1).RotateBy(rot), 0, 1.0f, 3, 0, false);
		}
	}

	const f32 shorten = 8*2.5f;
	int mapsize = getMap().tilemapwidth * getMap().tilemapheight;
	f32 current_angle = fire_angle*0.5f;
	
	const f32 max_endpoint = 512.0f;

	for (u8 i = 1; i <= current_angle; i++)
	{
		f32 initpoint = fire_length/8;
		f32 endpoint = Maths::Min(max_endpoint, initpoint);
		HitInfo@[] infos;
		getMap().getHitInfosFromRay(pos, angle-90-fire_angle+i*4, fire_length*2.75f, this, @infos);

		bool doContinue = false;
		for (u16 j = 0; j < infos.length; j++)
		{
			if (doContinue) continue;
			HitInfo@ info = infos[j];
			if (info is null) continue;

			if (info.blob is null && info.tileOffset < mapsize && info.distance < Maths::Min(max_endpoint, endpoint*8*2.75f))
			{
				//if (XORRandom(10) == 0) getMap().server_setFireWorldspace(info.hitpos, true); // disabled ignition for balance
				endpoint = Maths::Min(max_endpoint, info.distance/shorten);
			}
			if (info.blob !is null && !info.blob.isInWater())
			{
				if (info.blob.hasTag("structure") || info.blob.hasTag("trap")
					|| info.blob.isLadder() || info.blob.isOverlapping(this)) continue;

				if (solidHit(this, info.blob))
				{
					if (info.blob.isAttached()) fire_damage *= 0.5f;

					if (!info.blob.hasTag("flesh"))
					{
						endpoint = Maths::Min(max_endpoint, info.distance/shorten);
						doContinue = true;
					}
					if (isServer() && canDamage(this, info.blob))
					{
						this.server_Hit(info.blob, info.blob.getPosition(), Vec2f(0, 0.35f), fire_damage, Hitters::fire, true);
						info.blob.set_u32("firehit_delay", getGameTime()+firehit_delay);
					}
				}
			}
		}
		if (client)
		{
			for (u8 j = 0; j < endpoint; j++)
			{
				CParticle@ p = ParticleAnimated("SmallFire"+(1+XORRandom(2)), pos-Vec2f(0,1)+Vec2f(0, -16 + -j*(20*(endpoint/initpoint))).RotateBy(angle-fire_angle+i*4), Vec2f(0,-2).RotateBy(angle-fire_angle/2+i+XORRandom(100)-50), 0, 2.0f, 3, 0, false);
				if (p !is null)
				{
					p.growth = -0.075f;
					p.deadeffect = -1;
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("throw fire"))
	{
		if (isServer() || !this.isMyPlayer())
		{
			f32 scale = params.read_f32();
			this.set_f32("scale", scale);
		}
		ThrowFire(this, this.getPosition()+Vec2f(0,1), 90 + -(this.getAimPos()-this.getPosition()).Angle());
	}
	else if (cmd == this.getCommandID("sync_mag"))
	{
		if (!isClient()) return;

		u32 mag;
		if (!params.saferead_u32(mag)) return;
		
		this.set_u32("mag_bullets", mag);
	}
	else if (cmd == this.getCommandID("basic_sync"))
	{
		if (isClient())
		{
			bool isReloading;
			s32 my_chargetime;
			if (!params.saferead_bool(isReloading)) return;
			if (!params.saferead_s32(my_chargetime)) return;

			this.set_bool("isReloading", isReloading);
			this.set_s32("my_chargetime", my_chargetime);
		}
	}
	else if (cmd == this.getCommandID("sync_regen")) // Eatable.as, syncs serverside prop to color hp bar in yellow
	{
		if (!isClient()) return;
		u32 regen = params.read_u32();
		this.set_u32("regen", regen);
	}
	else if (cmd == this.getCommandID("shoot rpg"))
	{
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;
		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer)) return;

		InfantryInfo@ infantry;
		if (!this.get( "infantryInfo", @infantry )) return;

		if (getGameTime() <= this.get_u32("next_create")) return;
		this.set_u32("next_create", getGameTime()+15);

		if (getNet().isServer())
		{
			CBlob@ proj = CreateRPGProj(this, arrowPos, arrowVel);
			proj.server_SetTimeToDie(3);
		}

		if (this.get_u32("mag_bullets") > 0) this.set_u32("mag_bullets", this.get_u32("mag_bullets") - 1);
		if (this.get_u32("mag_bullets") > this.get_u32("mag_bullets_max")) this.set_u32("mag_bullets", this.get_u32("mag_bullets_max"));
		
		this.getSprite().PlaySound("RPG_shoot.ogg", 1.25f, 0.95f + XORRandom(15) * 0.01f);
	}
	else if (cmd == this.getCommandID("reload"))
	{
		this.Tag("forcereload");
	}
	else if (cmd == this.getCommandID("sync_reload_to_server"))
	{
		if (isClient())
		{
			int blobHash = this.getName().getHash();
			switch (blobHash)
			{
				case _revolver:
				{
					onRevolverReload(this);
					break;
				}
				case _shielder:
				{
					onShielderReload(this);
					break;
				}
				case _ranger:
				{
					onRangerReload(this);
					break;
				}
				case _lmg:
				{
					onLMGReload(this);
					break;
				}
				case _shotgun:
				{
					onShotgunReload(this);
					break;
				}
				case _sniper:
				{
					onSniperReload(this);
					break;
				}
				case _mp5:
				{
					onMp5Reload(this);
					break;
				}
				case _firebringer:
				{
					onFirebringerReload(this);
					break;
				}
				case _rpg:
				{
					onRPGReload(this);
					break;
				}
			}
		}
		if (isServer())
		{
			s16 reload = params.read_s16();
			this.set_s16("reloadtime", reload);
			this.set_s32("my_chargetime", reload);
			//printf("Synced to server: "+this.get_s16("reloadtime"));
			this.Tag("sync_reload");

			CBitStream params;
			params.write_bool(this.get_bool("isReloading"));
			params.write_s32(this.get_s32("my_chargetime"));
			this.SendCommand(this.getCommandID("basic_sync"), params);
			//this.Sync("isReloading", true);
		}
	}
	//else if (cmd == this.getCommandID("attach_parachute"))
	//{
	//	if (isServer())
	//	{
	//		AttachParachute(this);
	//	}
	//}
	else if (cmd == this.getCommandID("addxp_universal"))
	{
		u8 exp_reward;
		if (!params.saferead_u8(exp_reward)) return;
		if (this.getPlayer() !is null)
		{
			add_message(ExpMessage(exp_reward));
			CheckRankUps(getRules(), // do reward coins and sfx
				getRules().get_u32(this.getPlayer().getUsername() + "_exp"), // player new exp
				this);	
		}
	}
	if (!isServer() && cmd == this.getCommandID("jet_effects_kagsucks"))
	{	
		MakeParticle(this, Vec2f(0, 0.5f + XORRandom(50)*0.01f), "SmallExplosion" + (1 + XORRandom(2)));
		MakeParticle(this, Vec2f(0, 0.5f + XORRandom(50)*0.01f), XORRandom(100) < 65 ? "SmallGreySteam" : "MediumGreySteam");
	}
	else if (!isClient() && cmd == this.getCommandID("jet_effects"))
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("jet_effects_kagsucks"), params);
	}
	else if (cmd == this.getCommandID("aos_effects"))
	{
		if (this.isMyPlayer()) // are we on server?
		{
			this.getSprite().PlaySound("FatesFriend.ogg", 1.2);
			SetScreenFlash(42,   255,   150,   150,   0.28);
		}
		else
		{
			this.getSprite().PlaySound("FatesFriend.ogg", 2.0);
		}
	}
	else if (cmd == this.getCommandID("shield_effects"))
	{
		if (isClient())
		{
			bool isBullet = params.read_bool();
			if (this.getSprite() is null) return;
			this.getSprite().PlaySound(isBullet ? "ShieldHit.ogg" : "ShieldBash.ogg", 1.0f, 0.9f+XORRandom(21)*0.01f);
		}
	}
	else if (cmd == this.getCommandID("levelup_effects"))
	{
		u8 level;
		if (!params.saferead_u8(level)) return;
		string rank;
		if (!params.saferead_string(rank)) return;

		CRules@ rules = getRules();
		CPlayer@ player = this.getPlayer();
		if (player is null) return;
		// flash screen
        if (player.isMyPlayer())
        {
            SetScreenFlash(30,   255,   255,   255,   2.3);
        }
        
        // play sound
        if (isClient()) this.getSprite().PlaySound("LevelUp", 1.6f, 1.0f);
        if (isServer())
        {
            // coins
            server_DropCoins(this.getPosition(), 50);
        }

        //if (isServer()) //client
        {
            // chat message
            if (player.isMyPlayer()) {
                client_AddToChat("You've been promoted to " + rank + "!", SColor(255, 50, 150, 20));
            }
            else {
                client_AddToChat(player.getCharacterName() + " has been promoted to " + rank + "!", SColor(255, 50, 140, 20));
            }
            
            if (this !is null)
            {
                // create floating rank
                CParticle@ p;
				//printf(""+level);
				@p = ParticleAnimated("Ranks.png", this.getPosition() + Vec2f(0,-14), Vec2f(0,-0.9), 0.0f, 1.0f, 0, level, Vec2f(32, 32), 0, 0, true);
               
				if(p !is null)
                {
                    p.collides = false;
                    p.Z = 1000;
                    p.timeout = 2; // this shit doesnt work
                }

                // create particle
                ParticleAnimated("LevelUpParticle", this.getPosition(), this.getVelocity() - Vec2f(0,1.2), 0.0f, 1.0f, 3, 0.2f, true);
            }
        }
        
        // adjust to the current level
        rules.set_string(player.getUsername() + "_last_lvlup", rank);
	}
	else if (cmd == this.getCommandID("bootout"))
	{
		if (isClient()) this.getSprite().PlaySound("bridge_open", 1.0f, 1.25f);
		if (isServer()) this.server_DetachFromAll();
	}
}

bool canHit(CBlob@ this, CBlob@ b)
{
	if (b.hasTag("invincible"))
		return false;

	// Don't hit temp blobs and items carried by teammates.
	if (b.isAttached())
	{
		CBlob@ carrier = b.getCarriedBlob();

		if (carrier !is null)
			if (carrier.hasTag("player")
			        && (this.getTeamNum() == carrier.getTeamNum() || b.hasTag("temp blob")))
				return false;
	}

	if (b.hasTag("dead"))
		return true;

	return b.getTeamNum() != this.getTeamNum();
}

void onRender(CSprite@ this)
{
	visualTimerRender(this);
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(0, 8);
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 0.66f, 2 + XORRandom(3), -0.1f, false);
}