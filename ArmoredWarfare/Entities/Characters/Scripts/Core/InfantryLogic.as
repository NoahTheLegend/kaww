#include "WarfareGlobal.as";
#include "AllHashCodes.as";
#include "ThrowCommon.as";
#include "KnockedCommon.as";
#include "RunnerCommon.as";
#include "BombCommon.as";
#include "Hitters.as";
#include "InfantryCommon.as";
#include "MedicisCommon.as";
#include "TeamColour.as";
#include "CustomBlocks.as";
#include "RunnerHead.as";
#include "PlayerRankInfo.as";
#include "HoverMessage.as";

void onInit(CBlob@ this)
{
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
	u8 inaccuracy_hit;
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
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
	f32 bullet_lifetime; // in seconds, time for bullet to die
	s8 bullet_pen; // penRating for bullet
	bool emptyshellonfire; // should an empty shell be released when shooting
	// SOUND
	string reload_sfx;
	string shoot_sfx;

	getBasicStats( thisBlobHash, classname, reload_sfx, shoot_sfx, damage_body, damage_head );
	getRecoilStats( thisBlobHash, recoil_x, recoil_y, recoil_length, recoil_force, recoil_cursor, sideways_recoil, sideways_recoil_damp, ads_cushion_amount, length_of_recoil_arc );
	getWeaponStats( thisBlobHash, 
	inaccuracy_cap, inaccuracy_pershot, inaccuracy_hit,
	semiauto, burst_size, burst_rate, 
	reload_time, noreloadtimer, mag_size, delayafterfire, randdelay, 
	bullet_velocity, bullet_lifetime, bullet_pen, emptyshellonfire);

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

	infantry.inaccuracy_cap 		= inaccuracy_cap;
	infantry.inaccuracy_pershot 	= inaccuracy_pershot;
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
	this.Tag("3x2");
	this.set_u32("set_nomenus", 0);

	if (thisBlobHash == _mp5) this.Tag(medicTagString);

	this.set_s8("reloadtime", 0); // for server

	// one of these two has to go
	this.set_s8("charge_time", 0);
	this.set_s32("my_chargetime", 0);
	this.set_s32("my_reloadtime", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);

	this.set_s8("recoil_direction", 0);
	this.set_u8("inaccuracy", 0);
	this.set_u32("bull_boost", 0);
	this.set_u32("turret_delay", 0);

	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -80.0f));

	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot rpg");
	this.addCommandID("shoot bullet");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.set_f32("stab damage", 1.25f);
	
	this.set_u32("can_spot", 0);

	this.set_string("ammo_prop", "ammo");
	this.set_u8("ammo_pershot", 1);

	if (this.getName() == "revolver")
	{
		this.set_u8("stab time", 19);
		this.set_u8("stab timing", 13);
		this.Tag("no bulletgib on shot");
		this.set_f32("stab damage", 1.5f);
		//this.set_u8("ammo_pershot", 2);
	}
	else if (this.getName() == "ranger")
	{
		this.set_u8("stab time", 33);
		this.set_u8("stab timing", 14);
		this.set_f32("stab damage", 1.75f);
	}
	else if (this.getName() == "shotgun")
	{
		this.Tag("simple reload"); // set "simple" reload tags for only-sound reload code
		this.set_f32("stab damage", 1.75f);
		this.set_u8("ammo_pershot", 4);
	}
	else if (this.getName() == "sniper")
	{
		this.set_u8("ammo_pershot", 3);
	}
	else if (this.getName() == "rpg")
	{
		this.set_bool("is_rpg", true);
		this.set_u32("mag_bullets", 0);
		this.set_string("ammo_prop", "mat_heatwarhead");
	}

	this.set_u8("noreload_custom", 15);
	if (this.getName() == "sniper") this.set_u8("noreload_custom", 30);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	{
		InfantryInfo@ infantry;
		if (this.get("infantryInfo", @infantry))
		{
			this.set_u32("accuracy_delay", getGameTime()+ACCURACY_HIT_DELAY);
			f32 cap = this.get_u8("inaccuracy")+infantry.inaccuracy_hit;
			if (cap < 255) this.add_u8("inaccuracy", infantry.inaccuracy_hit);
			else this.set_u8("inaccuracy", infantry.inaccuracy_cap);
		}
	}

	CPlayer@ p = this.getPlayer();
	if (p !is null)
	{
		if (getRules().get_string(p.getUsername() + "_perk") == "Lucky" && this.getHealth() <= 0.01f && !this.hasBlob("aceofspades", 1)) return 0;
	}
	if (isServer()) //update bots' logic
	{
		if (this.hasTag("disguised"))
		{
			this.set_u32("can_spot", getGameTime()+150); // reveal us for some time
		}
		if (this.isBot() && hitterBlob.getDamageOwnerPlayer() !is null && hitterBlob.hasTag("bullet"))
		{
			this.set_string("last_attacker", hitterBlob.getDamageOwnerPlayer().getUsername());
		}
	}
	if (hitterBlob.getName() == "mat_smallbomb")
	{
		damage *= 4;
	}
	if (this.isAttached())
	{
		if (customData == Hitters::explosion)
			return damage*0.04f;
		else if (customData == Hitters::arrow)
			return damage*0.5f;
		else return (customData == Hitters::sword ? this.hasTag("mgunner") ? damage : 0 : 0);
	}
	if (this.getPlayer() !is null)
	{
		if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Camouflage")
		{
			if (customData == Hitters::fire)
			{
				return damage * 2;
			}
		}
		else if (this.getVelocity().y > 0.0f && !this.isOnGround() && !this.isOnLadder()
		&& !this.isInWater() && !this.isAttached()
		&& getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
		{
			damage * 0.5f;
		}
		else if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Bull")
		{
			damage *= 0.75f;
		}
	}
	if (damage > 0.15f && this.getHealth() - damage/2 <= 0 && this.getHealth() > 0.01f)
	{
		if (this.hasBlob("aceofspades", 1))
		{
			this.TakeBlob("aceofspades", 1);
			this.set_u32("aceofspades_timer", getGameTime()+90);

			this.server_SetHealth(0.01f);

			if (this.getPlayer() !is null)
			{
				CBitStream params;
				this.SendCommand(this.getCommandID("aos_effects"), params);
			}

			return damage = 0;
		}
	}
	if (this.getPlayer() !is null)
	{
		if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Death Incarnate")
		{
			damage *= 2.0f; // take double damage
		}
	}
	if (customData != Hitters::explosion && hitterBlob.getName() == "ballista_bolt") return damage * 2;
	if ((customData == Hitters::explosion || hitterBlob.getName() == "ballista_bolt") || hitterBlob.hasTag("grenade"))
	{
		if (hitterBlob.get_u16("follow_id") == this.getNetworkID()) return damage*5.0f;
		if (damage == 0.005f || damage == 0.01f) damage = 1.75f+(XORRandom(25)*0.01f); // someone broke damage
		if (hitterBlob.exists("explosion_damage_scale")) damage *= hitterBlob.get_f32("explosion_damage_scale");

		bool at_bunker = false;
		Vec2f pos = this.getPosition();
		Vec2f hit_pos = hitterBlob.getPosition();

		CBlob@[] bunkers;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @bunkers);

		if (!getMap().rayCastSolidNoBlobs(pos, hit_pos))
		{
			HitInfo@[] infos;
			Vec2f hitvec = hit_pos - pos;

			if (getMap().getHitInfosFromRay(pos, -hitvec.Angle(), hitvec.getLength(), this, @infos))
			{
				for (u16 i = 0; i < infos.length; i++)
				{
					CBlob@ hi = infos[i].blob;
					if (hi is null) continue;
					if (hi.getTeamNum() != this.getTeamNum()) continue;
					if (hi.hasTag("bunker") || hi.hasTag("tank")) 
					{
						at_bunker = true;
						break;
					}
				}
			}
			if (at_bunker) return 0;
			else return damage * (0.2f + (hitterBlob.hasTag("small_bolt") ? 0.3f : 0.0f));

			u16 dist_blocks = Maths::Floor((pos-hitterBlob.get_Vec2f("from_pos")).Length()/8);
			// printf(""+dist_blocks);
			return damage * Maths::Min(0.125f, 0.125f - (0.0015 * (dist_blocks/25)));
		}
	}

	return damage;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (isServer())
	{
		if (attached !is null && attached.hasTag("change team on pickup"))
		{
			attached.server_setTeamNum(this.getTeamNum());
		}
	}
	if (attached !is null && getLocalPlayer() !is null && getLocalPlayer().getBlob() is this && (attached.getName() == "binoculars" || attached.getName() == "launcher_javelin"))
	{
		if (g_fixedcamera)
		{
			this.set_bool("disable_fixedcamera", true);
			g_fixedcamera = false;
		}
	}

	if (attachedPoint !is null && attachedPoint.name == "PICKUP" && attached !is this)
	{
		this.Untag("parachute");
	}
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
			if (!this.hasTag("parachute") || (isServer() && !isClient()))
			{
				Sound::Play("/ParachuteOpen", detached.getPosition());
				this.Tag("parachute");

				AttachParachute(this);
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

	f32 attack_distance = 16.0f;

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	f32 angle = 45;
	bool is_shotgun = false;
	if (this.getName() == "shotgun")
	{
		is_shotgun = true;
		angle = 30;
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
				if (b.exists("mg_invincible") && b.get_u32("mg_invincible") >= getGameTime()) continue;
				if (b.getName() == "wooden_platform" || b.hasTag("door")) damage *= 1.5;

				//big things block attacks
				{
					this.server_Hit(b, hi.hitpos, Vec2f(0,0), damage, type, false); 
					if (b.hasTag("door") && b.getShape().getConsts().collidable) break;
					// end hitting if we hit something solid, don't if its flesh
				}
			}

			if (!dontHitMore && is_shotgun)
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

void AttachParachute(CBlob@ this)
{
	if (isServer() && this.getTickSinceCreated() > 5)
	{
		CAttachment@ aps = this.getAttachments();
		if (aps !is null)
		{			
			AttachmentPoint@ att = aps.getAttachmentPointByName("PARACHUTE");
			CBlob@ para = server_CreateBlob("parachuteblob", this.getTeamNum(), this.getPosition());
			if (para !is null)
			{
				CBlob@ carry = this.getCarriedBlob();
				if (carry !is null)
				{
					carry.server_DetachFromAll();
					this.server_PutInInventory(carry);
				}
				this.server_AttachTo(para, att);
			}
		}
	}
}

void ManageParachute(CBlob@ this)
{
	if (this.isOnGround() || this.isInWater() || this.isAttached() || this.hasTag("dead"))
	{ // disable parachute
		if (this.hasTag("parachute"))
		{
			for (uint i = 0; i < 50; i ++)
			{
				Vec2f vel = getRandomVelocity(90.0f, 3.5f + (XORRandom(10) / 10.0f), 25.0f) + Vec2f(0, 2);
				ParticlePixel(this.getPosition() - Vec2f(0, 30) + getRandomVelocity(90.0f, 10 + (XORRandom(20) / 10.0f), 25.0f), vel, getTeamColor(this.getTeamNum()), true, 119);
			}
		}
		this.Untag("parachute");

		if (isServer())
		{
			CAttachment@ aps = this.getAttachments();
			if (aps !is null)
			{
				AttachmentPoint@ ap = aps.getAttachmentPointByName("PARACHUTE");
				if (ap !is null && ap.getOccupied() !is null)
				{
					CBlob@ para = ap.getOccupied();
					para.server_Die();
				}
			}
		}
	} // make a parachute
	else if (!this.hasTag("parachute"))
	{
		if (this.getPlayer() !is null && this.get_u32("last_parachute") < getGameTime())
		{
			if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
			{
				if (this.isKeyPressed(key_up) && this.getVelocity().y > 5.0f)
				{
					if (isClient())
					{
						Sound::Play("/ParachuteOpen", this.getPosition());
						this.set_u32("last_parachute", getGameTime()+60);
						this.Tag("parachute");
						
						CBitStream params;
						this.SendCommand(this.getCommandID("attach_parachute"), params);
					}
				}
			}
		}
	}
	
	// maintain flying
	if (this.hasTag("parachute"))
	{
		if (this.isMyPlayer() && getGameTime()%30==0)
		{
			CAttachment@ aps = this.getAttachments();
			if (aps !is null)
			{
				AttachmentPoint@ ap = aps.getAttachmentPointByName("PARACHUTE");
				if (ap !is null && ap.getOccupied() is null)
				{
					CBitStream params;
					this.SendCommand(this.getCommandID("attach_parachute"), params);
				}
			}
		}

		f32 mod = 1.0f;
		bool aughhh = false;
		if (this.getPlayer() !is null)
		{
			if (this.hasTag("parachute") && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
			{
				mod = 3.0f;
				aughhh = true;
			}
		}

		this.set_u32("no_climb", getGameTime()+2);
		this.AddForce(Vec2f(Maths::Sin(getGameTime() / 9.5f) * 13, (Maths::Sin(getGameTime() / 4.2f) * 8)));
		Vec2f vel = this.getVelocity();
		if (aughhh)
		{
			if (this.isKeyPressed(key_left))
				this.AddForce(Vec2f(-20.0f, 0));
			else if (this.isKeyPressed(key_right))
				this.AddForce(Vec2f(20.0f, 0));
		}
		this.setVelocity(Vec2f(vel.x, vel.y * (this.isKeyPressed(key_down) ? 0.83f : this.isKeyPressed(key_up) ? 0.55f / mod : 0.73/*default fall speed*/)));
	}
}

void onDie(CBlob@ this)
{
	if (isServer() && this.getName() == "rpg")
	{
		if (this.get_u32("mag_bullets") > 0)
		{
			CBlob@ b = server_CreateBlob("mat_heatwarhead", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.server_SetQuantity(1);
			}
		}
	}
}

void ManageGun( CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars, InfantryInfo@ infantry )
{
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer())
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			if (!ismyplayer) //always false inside isServer()
			{
				responsible = p.isBot();
			}
			
			if (!this.hasBlob("aceofspades", 1)
			&& this.get_u32("aceofspades_timer") < getGameTime()
			&& getRules().get_string(p.getUsername() + "_perk") == "Lucky")
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
						if (b !is null) this.server_PutInInventory(b);
					}
				}
			}
		}
	}

	CControls@ controls = this.getControls();
	CSprite@ sprite = this.getSprite();
	s8 charge_time = this.get_s32("my_chargetime");
	s8 reload_time = this.get_s32("my_reloadtime");
	this.set_s8("charge_time", charge_time);
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

	if (this.hasTag("dead"))
	{
		just_action1 = false;
		is_action1 = false;
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
		if (this.hasBlob("mat_scrap", 1) && this.getPlayer() !is null && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Field Engineer")
		{
			if (getGameTime()%12 == 0 && this.getSprite() !is null)
			{
				this.getSprite().PlaySound("SentryBuild.ogg", 0.33f, 1.05f+0.001f*XORRandom(115));
			}
			lock_stab = true;
			if (this.get_f32("turret_load") < 120)
			{
				this.add_f32("turret_load", 1);
			}
			else
			{
				this.set_f32("turret_load", 0);
				this.set_u32("turret_delay", getGameTime()+150);
				if (isServer())
				{
					this.TakeBlob("mat_scrap", 3);
					CBlob@ turret_exists = getBlobByNetworkID(this.getPlayer().get_u16("turret_netid"));
					if (turret_exists !is null && turret_exists.getName() == "sentrygun")
					{
						this.server_Hit(turret_exists, turret_exists.getPosition(), Vec2f(0,0), 150.0f, Hitters::arrow, true); 
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
		for (int i = 0; i < this.get_f32("turret_load"); i++)
		{
			SColor color = this.getTeamNum() == 0 ? 0xff2cafde : 0xffd5543f;
			Vec2f pbPos = this.getOldPosition() + Vec2f(0,-16.0f) + Vec2f_lengthdir(i < 30 ? 2.75f : i < 60 ? 2.0f : i < 90 ? 1.25f : 0.5f, i*12).RotateBy(90, Vec2f(0,0));
			CParticle@ pb = ParticlePixelUnlimited( pbPos, this.getVelocity(), color , true );
			if(pb !is null)
			{
				pb.timeout = 0.01f;
				pb.gravity = Vec2f_zero;
				pb.damping = 0.9;
				pb.collides = false;
				pb.fastcollision = true;
				pb.bounce = 0;
				pb.lighting = false;
				pb.Z = 500;
			}
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
		if (this.isKeyPressed(key_action3) && !hidegun && !isReloading && this.get_u32("end_stabbing") < getGameTime() && no_medkit)
		{
			if (this.getName() != "mp5" && !lock_stab)
			{
				this.set_u32("end_stabbing", getGameTime()+time);
				this.Tag("attacking");
			}
		}
		if (this.hasTag("attacking") && getGameTime() == this.get_u32("end_stabbing")-timing)
		{
			f32 attackarc = 45.0f;
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
	
	const bool pressed_action2 = this.isKeyPressed(key_action2);
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
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			u8 time = 3;
			if (getRules().get_string(p.getUsername() + "_perk") == "Sharp Shooter")
			{
				reloadTime = infantry.reload_time * 1.5;
				time = 4;
			}
			else if (getRules().get_string(p.getUsername() + "_perk") == "Bull")
			{
				reloadTime = infantry.reload_time * 0.75f;
				time = 2;
			}
			if (p.getBlob() !is null && p.getBlob().getSprite() !is null)
			{
				Animation@ anim = p.getBlob().getSprite().getAnimation("reload");
				if (anim !is null)
				{
					anim.time = time;
				}
			}
		}
		
		const u32 magSize = infantry.mag_size;
	
		bool done_shooting = this.get_s8("charge_time") <= 0 && this.get_s32("my_chargetime") <= 0;
		bool not_full = this.get_u32("mag_bullets") < this.get_u32("mag_bullets_max");

		if (done_shooting && this.get_u32("no_reload") < getGameTime())
		{
			// reload
			if (controls !is null // bots may break
				&& !isReloading && this.get_u32("end_stabbing") < getGameTime()
				&& ((((controls.isKeyJustPressed(KEY_KEY_R) && isClient()) || (this.get_u8("reloadqueue") > 0)) && not_full)
				|| (this.hasTag("forcereload"))))
			{
				bool forcereload = false;
				s32 delay = getGameTime()+this.get_u8("noreload_custom");

				this.set_u32("no_reload", delay);
				this.set_s32("my_reloadtime", infantry.reload_time);
				this.set_u32("reset_reloadtime", infantry.reload_time+getGameTime());
				
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
						params.write_s8(charge_time);
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
			s8 reload = charge_time > 0 ? charge_time : this.get_s8("reloadtime");
			if (reload > 0)
			{
				reload_time = reload;
				//archer.isReloading = true;
				this.set_bool("isReloading", true);
				this.Sync("isReloading", true);
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

					ClientFire(this, charge_time, infantry);
					this.Tag("client_shoot_lock");

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
						TakeAmmo(this, magSize);

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
					TakeAmmo(this, magSize);

				archer.isStabbing = false;
				archer.isReloading = false;

				this.set_bool("isReloading", false);
			}

			if (this.getPlayer() !is null)
			{
				float walkStat = 1.0f;
				float airwalkStat = 1.0f;
				float jumpStat = 1.0f;

				bool sprint = this.getHealth() == this.getInitialHealth() && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
				getMovementStats(this.getName().getHash(), sprint, walkStat, airwalkStat, jumpStat);

				// operators move slower than normal
				if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Operator")
				{	
					sprint = false;
					walkStat *= 0.95f;
				}
				else if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Bull")
				{
					sprint = this.getHealth() >= this.getInitialHealth()/2 && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
					walkStat = 1.1f;
					airwalkStat = 2.15f;
					jumpStat = 1.2f;
					if (this.get_u32("bull_boost") != 0 && this.get_u32("bull_boost") > getGameTime())
					{
						walkStat = 1.3f;
						airwalkStat = 2.6f;
						jumpStat = 1.75f;
					}
				}

				if (sprint)
				{
					if (!this.hasTag("sprinting"))
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
			this.set_u8("inaccuracy", 0);
			moveVars.walkFactor *= 0.55f;
		}
		if (isStabbing)
		{
			moveVars.walkFactor *= 0.2f;
			moveVars.jumpFactor *= 0.8f;
		}
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
	this.Sync("my_chargetime", true);
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
					this.add_u32("mag_bullets", Maths::Max(1, quantity/multiplier));
					mag.Tag("dead");
					if (isServer()) mag.server_Die();
					continue;
				}
				else
				{
					this.set_u32("mag_bullets", magSize);
					if (isServer()) mag.server_SetQuantity(quantity - miss);
					break;
				}
			}
			else break;
		}
	}
}

void onTick(CBlob@ this)
{
	if (isServer()&&getGameTime()%30==0)
	{
		if (!(isClient() && isServer()) && this.getPlayer() is null) this.server_Die(); // bots sometimes get stuck AI
		if (this.hasTag("invincible") && !this.isAttached()) this.Untag("invincible");
	}
	if ((this.getTeamNum() == 0 && getRules().get_s16("blueTickets") == 0)
	|| (this.getTeamNum() == 1 && getRules().get_s16("redTickets") == 0))
	{
		this.SetLightRadius(8.0f);
		this.SetLightColor(SColor(255, 255, 255, 255));
		this.SetLight(true);
	}

	if (this.get_u32("reset_reloadtime") < getGameTime())
	{
		this.set_s32("my_reloadtime", 0);
	}

	InfantryInfo@ infantry;
	if (!this.get( "infantryInfo", @infantry )) return;

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer)) return;

	ManageParachute(this);

	if (this.isBot() && this.getTickSinceCreated() == 1 && isClient()) 
	{
		LoadHead(this.getSprite(), XORRandom(99)); // TODO: make a way to sync between players and save when blob dies!
	}

	if (this.getName() != "sniper")
	{
		bool has_camo = this.getPlayer() !is null && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Camouflage";
		if (!has_camo)
		{
			if (this.hasScript("ClimbTree.as")) this.RemoveScript("ClimbTree.as");
		}
		else if (!this.hasScript("ClimbTree.as")) this.AddScript("ClimbTree.as");
	}
	
	if (isKnocked(this) || this.isInInventory())
	{
		archer.charge_state = 0;
		this.set_s32("my_chargetime", 0);
		getHUD().SetCursorFrame(0);
		return;
	}

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars)) return;	

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

bool canSend( CBlob@ this )
{
	if (this.hasTag("had_menus") || this.getTickSinceCreated() <= 5) return false;
	return (this.isMyPlayer() || this.getPlayer() is null);
}

void ClientFire( CBlob@ this, const s8 charge_time, InfantryInfo@ infantry )
{
	if (this.hasTag("had_menus") || this.getTickSinceCreated() <= 5) return;
	Vec2f thisAimPos = this.getAimPos() - Vec2f(0,4);

	float angle = Maths::ATan2(thisAimPos.y - this.getPosition().y, thisAimPos.x - this.getPosition().x) * 180 / 3.14159;
	angle += -0.099f + (XORRandom(2) * 0.01f);

	bool no_muzzle = false;

	#ifdef STAGING
		no_muzzle = true;
	#endif

	if (v_fastrender && !this.isMyPlayer())
		no_muzzle = true;
	
	if (!no_muzzle)
	{
		if (this.isFacingLeft())
		{ 
			ParticleAnimated("Muzzleflash", this.getPosition() + Vec2f(0.0f, 1.0f), this.getVelocity()/2, angle, 0.075f + XORRandom(2) * 0.01f, 3 + XORRandom(2), -0.15f, false);
		}
		else
		{
			ParticleAnimated("Muzzleflashflip", this.getPosition() + Vec2f(0.0f, 1.0f), this.getVelocity()/2, angle + 180, 0.075f + XORRandom(2) * 0.01f, 3 + XORRandom(2), -0.15f, false);
		}
	}

	Vec2f targetVector = thisAimPos - this.getPosition();
	f32 targetDistance = targetVector.Length();
	f32 targetFactor = targetDistance / 367.0f;
	
	float perk_mod = 1.0f;
	if (this.getPlayer() !is null)
	{
		if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Sharp Shooter")
		{
			perk_mod = 1.5f; // improved accuracy
		}
	}

	this.set_u32("accuracy_delay", getGameTime()+3);

	float bulletSpread = getBulletSpread(infantry.class_hash) + (float(this.get_u8("inaccuracy")))/perk_mod;
	if (this.get_bool("is_rpg"))
	{
		targetVector = this.getAimPos() - this.getPosition();
		targetDistance = targetVector.Length();
		targetFactor = targetDistance / 367.0f;
		f32 mod = this.isKeyPressed(key_action2) ? 0.1f : 0.3f;

		ShootRPG(this, this.getPosition() - Vec2f(-24,0).RotateBy(angle), this.getAimPos() + Vec2f(-(1 + this.get_u8("inaccuracy")) + XORRandom((180 + this.get_u8("inaccuracy")) - 50)*mod * targetFactor, -(3 + this.get_u8("inaccuracy")) + XORRandom(180 + this.get_u8("inaccuracy")) - 50)*mod * targetFactor, 8.0f * infantry.bullet_velocity);
	
		ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -8.0f : 8.0f, -2.0f).RotateBy(this.isFacingLeft()?angle+180:angle), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.75f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);

		if (this.isMyPlayer()) ShakeScreen((Vec2f(infantry.recoil_x - XORRandom(infantry.recoil_x*4) + 1, -infantry.recoil_y + XORRandom(infantry.recoil_y) + 6)), infantry.recoil_length*2, this.getInterpolatedPosition());
		if (this.isMyPlayer()) ShakeScreen(48, 28, this.getPosition());
	}
	else
	{
		ShootBullet(this, this.getPosition() - Vec2f(0,1), thisAimPos, infantry.bullet_velocity, bulletSpread*targetFactor, infantry.burst_size );
	}

	//if (this.get_u32("mag_size") > 0)
	this.set_u32("no_reload", getGameTime()+this.get_u8("noreload_custom"));
	//printf(""+this.get_u32("no_reload"));

	// this causes backwards shit
	ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -12.0f : 12.0f, -2.0f).RotateBy(this.isFacingLeft()?angle+180:angle), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
	
	CPlayer@ p = getLocalPlayer();
	if (p !is null)
	{
		CBlob@ local = p.getBlob();
		if (local !is null)
		{
			CPlayer@ ply = local.getPlayer();

			if (ply !is null && this.isMyPlayer())
			{
				f32 mod = 0.5; // make some smart stuff here?
				if (this.isKeyPressed(key_action2)) mod *= 0.25;

				float recoilX = infantry.recoil_x;
				float recoilY = infantry.recoil_y;
				ShakeScreen((Vec2f(recoilX - XORRandom(recoilX*2) + 1, -recoilY + XORRandom(recoilY) + 1) * mod), infantry.recoil_length*mod, this.getInterpolatedPosition());
				ShakeScreen(28, 10, this.getPosition());

				this.set_u8("inaccuracy", Maths::Min(infantry.inaccuracy_cap, this.get_u8("inaccuracy") + infantry.inaccuracy_pershot * (this.hasTag("sprinting")?2.0f:1.0f)));
				
				if (infantry.emptyshellonfire)
				makeGibParticle(
					"EmptyShellSmall",	                    // file name
					this.getPosition(),                 // position
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

void ShootRPG(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed)
{
	if (canSend(this))
	{
		Vec2f arrowVel = (aimpos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);

		this.SendCommand(this.getCommandID("shoot rpg"), params);
	}

	if (this.isMyPlayer()) ShakeScreen(28, 8, this.getPosition());
}

void ShootBullet( CBlob@ this, Vec2f arrowPos, Vec2f aimpos, float arrowspeed, float bulletSpread, u8 burstSize )
{
	if (canSend(this) || (isServer() && this.isBot()))
	{
		// passes between shots sometimes
		//if (this.get_s8("charge_time") == 0 && this.hasTag("no_more_shoot") && this.getSprite() !is null)
		//{
		//	this.getSprite().PlaySound("EmptyGun.ogg", 0.33f); // gun jam sound if server cancels command
		//}
		CBitStream params;
		params.write_Vec2f(arrowPos); // only once, only one place to fire from

		for (uint i = 0; i < burstSize; i++)
		{
			Vec2f spreadAimpos = aimpos;
			if (bulletSpread > 0.0f) spreadAimpos += Vec2f(bulletSpread * (0.5f - _infantry_r.NextFloat()), bulletSpread * (0.5f - _infantry_r.NextFloat()));
			Vec2f arrowVel = (spreadAimpos - arrowPos);
			arrowVel.Normalize();
			arrowVel *= arrowspeed;
			params.write_Vec2f(arrowVel);
		}
		
		this.SendCommand(this.getCommandID("shoot bullet"), params);

		InfantryInfo@ infantry;
		if (!this.get( "infantryInfo", @infantry )) return;
		if (this.get_s32("my_chargetime") == 0)
		{
			this.set_s32("my_chargetime", infantry.delayafterfire);
			this.Tag("no_more_shoot");
		}
	}

	if (this.isMyPlayer()) ShakeScreen(28, 8, this.getPosition());
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot bullet"))
	{
		if (this is null || this.hasTag("dead")) return;
		InfantryInfo@ infantry;
		if (!this.get( "infantryInfo", @infantry )) return;
		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer)) return;

		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;

		this.Untag("client_shoot_lock");

		if (isServer())
		{
			if (this.hasTag("created"))
			{
				this.Untag("created");
				return;
			}
		}

		if (this.get_u32("next_bullet") > getGameTime()) return;
		this.set_u32("next_bullet", getGameTime()+2);

		float damageBody = infantry.damage_body;
		float damageHead = infantry.damage_head;

		if (this.getPlayer() !is null)
		{
			if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Sharp Shooter")
			{
				damageBody *= 1.33f; // 150%
				damageHead *= 1.33f;
			}
		}

		s8 bulletPen = infantry.bullet_pen;

		bool shotOnce = false;
		Vec2f arrowVel;
		//if (!params.saferead_Vec2f(arrowVel)) return;
		if (this.getName() == "shotgun")
		{
			for (u8 i = 0; i < 16; i++)
			{
				shotOnce = true;
				if (isServer() && params.saferead_Vec2f(arrowVel))
				{
					if (this.hasTag("disguised")) this.set_u32("can_spot", getGameTime()+30);
					CBlob@ proj = CreateBulletProj(this, arrowPos, arrowVel, damageBody, damageHead, bulletPen);
					proj.Tag("shrapnel");
					proj.server_SetTimeToDie(infantry.bullet_lifetime);
				}
				else break;
			}
		}
		else
		{
			if (params.saferead_Vec2f(arrowVel))
			{
				if (isServer())
				{
					if (this.hasTag("disguised")) this.set_u32("can_spot", getGameTime()+30);
					CBlob@ proj = CreateBulletProj(this, arrowPos, arrowVel, damageBody, damageHead, bulletPen);
					if (this.getName() == "sniper") proj.Tag("strong");
					proj.server_SetTimeToDie(infantry.bullet_lifetime);
				}
				shotOnce = true;
			}
		}

		if (!shotOnce) return;
		
		if (isServer())
		{
			if (this.get_u32("mag_bullets") > 0) this.set_u32("mag_bullets", this.get_u32("mag_bullets") - 1);
			this.Sync("mag_bullets", true);
		}

		const u32 magSize = infantry.mag_size;
		if (this.get_u32("mag_bullets") > magSize) this.set_u32("mag_bullets", magSize);
		if (isClient()) this.getSprite().PlaySound(infantry.shoot_sfx, 0.9f, 0.90f + XORRandom(40) * 0.01f);

		this.Untag("no_more_shoot");
	}
	else if (cmd == this.getCommandID("shoot rpg"))
	{
		if (this.hasTag("disguised")) this.set_u32("can_spot", getGameTime()+30);
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
			if (this.getName() == "revolver") onRevolverReload(this);
			else if (this.getName() == "ranger") onRangerReload(this);
			else if (this.getName() == "sniper") onSniperReload(this);
			else if (this.getName() == "mp5") onMp5Reload(this);
			else if (this.getName() == "shotgun") onShotgunReload(this);
			else if (this.getName() == "rpg") onRPGReload(this);
		}
		if (isServer())
		{
			s8 reload = params.read_s8();
			this.set_s8("reloadtime", reload);

			this.set_s32("my_chargetime", reload);
			//printf("Synced to server: "+this.get_s8("reloadtime"));
			this.Tag("sync_reload");
			this.Sync("isReloading", true);
		}
	}
	else if (cmd == this.getCommandID("attach_parachute"))
	{
		if (isServer())
		{
			AttachParachute(this);
		}
	}
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
                client_AddToChat("You've been promoted to " + rank.toLower() + "!", SColor(255, 50, 150, 20));
            }
            else {
                client_AddToChat(player.getCharacterName() + " has been promoted to " + rank.toLower() + "!", SColor(255, 50, 140, 20));
            }
            
            if (this !is null)
            {
                // create floating rank
                CParticle@ p;
				// don't ask why, i just don't know. You can test on ur own.
				//printf(""+level);
				if (level <= 21) @p = ParticleAnimated("Ranks.png", this.getPosition() + Vec2f(8.5f,-14), Vec2f(0,-0.9), 0.0f, 1.0f, 0, level - 1, Vec2f(32, 32), 0, 0, true);
                else @p = ParticleAnimated("Ranks1.png", this.getPosition() + Vec2f(8.5f,-14), Vec2f(0,-0.9), 0.0f, 1.0f, 0, 3 - (getLevels().length - level), Vec2f(32, 32), 0, 0, true);
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