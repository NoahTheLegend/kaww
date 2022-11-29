#include "WarfareGlobal.as"
#include "AllHashCodes.as"
#include "ThrowCommon.as";
#include "KnockedCommon.as";
#include "RunnerCommon.as";
#include "BombCommon.as";
#include "Hitters.as";
#include "Recoil.as";
#include "InfantryCommon.as";
#include "MedicisCommon.as";

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
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	bool semiauto;
	u8 burst_size; // bullets fired per click
	u8 burst_rate; // ticks per bullet fired in a burst
	s8 reload_time; // time to reload
	u32 mag_size; // max bullets in mag
	u8 delayafterfire; // time between shots 4
	u8 randdelay; // + randomness
	f32 bullet_velocity; // speed that bullets fly 1.6
	f32 bullet_lifetime; // in seconds, time for bullet to die
	s8 bullet_pen; // penRating for bullet
	// SOUND
	string reload_sfx;
	string shoot_sfx;

	getBasicStats( thisBlobHash, classname, reload_sfx, shoot_sfx, damage_body, damage_head );
	getRecoilStats( thisBlobHash, recoil_x, recoil_y, recoil_length, recoil_force, recoil_cursor, sideways_recoil, sideways_recoil_damp, ads_cushion_amount, length_of_recoil_arc );
	getWeaponStats( thisBlobHash, 
	inaccuracy_cap, inaccuracy_pershot, 
	semiauto, burst_size, burst_rate, 
	reload_time, mag_size, delayafterfire, randdelay, 
	bullet_velocity, bullet_lifetime, bullet_pen );

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
	infantry.semiauto 				= semiauto;
	infantry.burst_size 			= burst_size;
	infantry.burst_rate 			= burst_rate;
	infantry.reload_time 			= reload_time;
	infantry.mag_size 				= mag_size;
	infantry.delayafterfire 		= delayafterfire;
	infantry.randdelay 				= randdelay;
	infantry.bullet_velocity 		= bullet_velocity;
	infantry.bullet_lifetime 		= bullet_lifetime;
	infantry.bullet_pen 			= bullet_pen;
	this.set("infantryInfo", @infantry);

	this.set_u32("mag_bullets_max", mag_size);
	this.set_u32("mag_bullets", mag_size);

	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.Tag("player");
	this.Tag("flesh");
	this.addCommandID("sync_reload_to_server");
	this.Tag("3x2");

	if (thisBlobHash == _mp5) this.Tag(medicTagString);

	this.set_u8("hitmarker", 0);
	this.set_s8("reloadtime", 0); // for server

	// one of these two has to go
	this.set_s8("charge_time", 0);
	this.set_s32("my_chargetime", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);

	this.set_u8("recoil_count", 0);
	this.set_s8("recoil_direction", 0);
	this.set_u8("inaccuracy", 0);

	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -80.0f));

	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot bullet");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	if (this.getName() == "revolver")
	{
		this.set_u8("stab time", 16);
		this.set_u8("stab timing", 13);
		this.set_f32("stab damage", 1.5f);
	}
	else if (this.getName() == "ranger")
	{
		this.set_u8("stab time", 33);
		this.set_u8("stab timing", 14);
		this.set_f32("stab damage", 1.5f);
	}
	else if (this.getName() == "shotgun")
	{
		this.Tag("simple reload"); // set "simple" reload tags for only-sound reload code
	}
	else if (this.getName() == "sniper")
	{
		this.Tag("simple reload");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached())
	{
		if (customData == Hitters::explosion)
			return damage*0.05f;
		else if (customData == Hitters::arrow)
			return damage*0.5f;
		else return 0;
	}
	if ((customData == Hitters::explosion || hitterBlob.getName() == "ballista_bolt") && hitterBlob.getName() != "grenade")
	{
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
					if (hi.hasTag("bunker") || hi.hasTag("tank")) 
					{
						at_bunker = true;
						break;
					}
				}
			}
			if (at_bunker) return 0;

			u16 dist_blocks = Maths::Floor((pos-hitterBlob.get_Vec2f("from_pos")).Length()/8);
			// printf(""+dist_blocks);
			return damage * Maths::Min(0.125f, 0.125f - (0.0015 * (dist_blocks/25)));
		}
	}

	return damage;
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
	if (this.hasTag("dead") || this.isAttached()) return;
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
	HitInfo@[] hitMapInfos;
	if (this.getName() == "shotgun" && map.getHitInfosFromRay(blobPos, -exact_aimangle, radius + attack_distance, this, @hitMapInfos))
	{
		bool dontHitMore = false;
		for (uint i = 0; i < hitMapInfos.length; i++)
		{
			HitInfo@ hi = hitMapInfos[i];
			CBlob@ b = hi.blob;
			if (!dontHitMore)
			{
				Vec2f tpos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
				//bool canhit = canhit && map.getSectorAtPosition(tpos, "no build") is null;
				if (!map.isTileCastle(map.getTile(tpos).type))
					map.server_DestroyTile(hi.hitpos, 0.1f, this);
			}
		}
	}
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;

			if (b !is null) // blob
			{
				if (b.hasTag("ignore sword")) continue;
				if (b.getTeamNum() == this.getTeamNum()) continue;
				if (b.getName() == "wooden_platform" || b.hasTag("door")) damage *= 1.5;

				//big things block attacks
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

				if (!dontHitMore)
				{
					this.server_Hit(b, hi.hitpos, Vec2f(0,0), damage, type, true); 
					
					// end hitting if we hit something solid, don't if its flesh
				}
			}
		}
	}
}

void ManageGun( CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars, InfantryInfo@ infantry )
{
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer() && !ismyplayer)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			responsible = p.isBot();
		}
	}

	CControls@ controls = this.getControls();
	CSprite@ sprite = this.getSprite();
	s8 charge_time = this.get_s32("my_chargetime");//archer.charge_time;
	this.set_s8("charge_time", charge_time);
	bool isStabbing = archer.isStabbing;
	bool isReloading = this.get_bool("isReloading"); //archer.isReloading;
	u8 charge_state = archer.charge_state;
	bool just_action1;
	bool is_action1;

	just_action1 = (this.get_bool("just_a1") && this.hasTag("can_shoot_if_attached")) || (!this.isAttached() && this.isKeyJustPressed(key_action1));
	is_action1 = (this.get_bool("is_a1") && this.hasTag("can_shoot_if_attached")) || (!this.isAttached() && this.isKeyPressed(key_action1));
	bool was_action1 = this.wasKeyPressed(key_action1);
	bool hidegun = false;

	if (this.hasTag("dead"))
	{
		just_action1 = false;
		is_action1 = false;
	}

	if (this.getCarriedBlob() !is null)
	{
		if (this.getCarriedBlob().hasTag("hidesgunonhold"))
		{
			hidegun = true;
		}
	}

	if (!this.hasTag(medicTagString))
	{
		u8 time = 21;
		u8 timing = 13;
		f32 damage = 0.85f;
		if (this.exists("stab time")) time = this.get_u8("stab time");
		if (this.exists("stab timing")) timing = this.get_u8("stab timing");
		if (this.exists("stab damage")) damage = this.get_f32("stab damage");
		if (this.isKeyPressed(key_action3) && !hidegun && !isReloading && this.get_u32("end_stabbing") < getGameTime())
		{
			this.set_u32("end_stabbing", getGameTime()+time);
			this.Tag("attacking");
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

	bool scoped = this.hasTag("scopedin");

	const u8 inaccuracyCap = infantry.inaccuracy_cap;
	InAirLogic(this, inaccuracyCap);

	if (this.getName() == "mp5")
	{
		if (this.get_s8("charge_time") == 46)
		{
			CBitStream params;
			this.SendCommand(this.getCommandID("sync_reload_to_server"), params);
		}
	}

	if (this.isKeyPressed(key_action2))
	{
		this.Untag("scopedin");

		if (!isReloading && !menuopen || this.hasTag("attacking"))
		{
			moveVars.walkFactor *= 0.75f;
			this.Tag("scopedin");
		}
	}
	else
	{
		this.Untag("scopedin");
	}

	if (hidegun) return;
	
	if (isKnocked(this))
	{
		charge_time = 0;

		archer.isReloading = false;
	}
	else
	{
		const s8 reloadTime = infantry.reload_time;
		const u32 magSize = infantry.mag_size;
		// reload
		if (charge_time == 0 && controls !is null && !archer.isReloading && controls.isKeyJustPressed(KEY_KEY_R) && this.get_u32("no_reload") < getGameTime() && this.get_u32("mag_bullets") < this.get_u32("mag_bullets_max"))
		{
			//print("RELOAD!!");
			bool reloadistrue = false;
			CInventory@ inv = this.getInventory();
			if (inv !is null && inv.getItem("mat_7mmround") !is null)
			{
				// actually reloading
				reloadistrue = true;
				charge_time = reloadTime;
				//archer.isReloading = true;
				isReloading = true;
				this.set_bool("isReloading", true);
	
				CBitStream params; // sync to server
				if (isClient())
				{
					params.write_s8(charge_time);
					this.SendCommand(this.getCommandID("sync_reload_to_server"), params);
				}
			}
			else if (ismyplayer)
			{
				sprite.PlaySound("NoAmmo.ogg", 0.85);
			}

			if (this.hasTag("simple reload") && reloadistrue) // simple reload is used when you have nothing else 
			{ // besides reload sound, look for onBlobNameReload() in this file and InfantryCommon.as otherwise
				charge_time = reloadTime;
				//archer.isReloading = true;
				this.set_bool("isReloading", true);

				//printf(""+infantry.reload_sfx);

				sprite.PlaySound(infantry.reload_sfx, 55.0);
			}
		}
		if (isServer() && this.hasTag("sync_reload"))
		{
			s8 reload = charge_time > 0 ? charge_time : this.get_s8("reloadtime");
			if (reload > 0)
			{
				charge_time = reload;
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

			CPlayer@ player = this.getPlayer();
			if (player !is null)
			{
				//print("p: " + player.getCharacterName() + "  cahrge: " + charge_time);
			}

			if (charge_time == 0 && isStabbing == false)
			{
				if (menuopen) return;
				if (isReloading) return;

				charge_state = ArcherParams::readying;

				if (this.get_u32("mag_bullets") <= 0)
				{
					charge_state = ArcherParams::no_ammo;

					if (ismyplayer && !was_action1)
					{
						sprite.PlaySound("EmptyGun.ogg", 0.4);
					}
				}
				else
				{
					ClientFire(this, charge_time, infantry);

					charge_time = infantry.delayafterfire + XORRandom(infantry.randdelay);
					charge_state = ArcherParams::fired;

					float recoilForce = infantry.recoil_force;
					this.AddForce(Vec2f(this.getAimPos() - this.getPosition()) * (scoped ? -recoilForce/1.6 : -recoilForce));
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
						// reload
						CInventory@ inv = this.getInventory();
						if (inv !is null)
						{
							//printf(""+need_ammo);
							//printf(""+current);
							for (u8 i = 0; i < 20; i++)
							{
								u32 current = this.get_u32("mag_bullets");
								u32 miss = magSize-current;
								CBlob@ mag;
								for (u8 i = 0; i < inv.getItemsCount(); i++)
								{
									CBlob@ b = inv.getItem(i);
									if (b is null || b.getName() != "mat_7mmround" || b.hasTag("dead")) continue;
									@mag = @b;
									break;
								}
								if (mag !is null)
								{
									u16 quantity = mag.getQuantity();
									if (quantity <= miss)
									{
										//printf("a");
										//printf(""+miss);
										//printf(""+quantity);
										this.add_u32("mag_bullets", quantity);
										mag.Tag("dead");
										if (isServer()) mag.server_Die();
										continue;
									}
									else
									{
										//printf("e");
										this.set_u32("mag_bullets", magSize);
										if (isServer()) mag.server_SetQuantity(quantity - miss);
										break;
									}
								}
								else break;
							}
						}
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
					// reload
					CInventory@ inv = this.getInventory();
					if (inv !is null)
					{
						//printf(""+need_ammo);
						//printf(""+current);
						for (u8 i = 0; i < 20; i++)
						{
							u32 current = this.get_u32("mag_bullets");
							u32 miss = magSize-current;
							CBlob@ mag;
							for (u8 i = 0; i < inv.getItemsCount(); i++)
							{
								CBlob@ b = inv.getItem(i);
								if (b is null || b.getName() != "mat_7mmround" || b.hasTag("dead")) continue;
								@mag = @b;
								break;
							}
							if (mag !is null)
							{
								u16 quantity = mag.getQuantity();
								if (quantity <= miss)
								{
									//printf("a");
									//printf(""+miss);
									//printf(""+quantity);
									this.add_u32("mag_bullets", quantity);
									mag.Tag("dead");
									if (isServer()) mag.server_Die();
									continue;
								}
								else
								{
									//printf("e");
									this.set_u32("mag_bullets", magSize);
									if (isServer()) mag.server_SetQuantity(quantity - miss);
									break;
								}
							}
							else break;
						}
					}
				}

				archer.isStabbing = false;
				archer.isReloading = false;

				this.set_bool("isReloading", false);
			}

			if (this.getPlayer() !is null)
			{
				bool sprint = this.getHealth() == this.getInitialHealth() && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
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

				float walkStat = 1.0f;
				float airwalkStat = 1.0f;
				float jumpStat = 1.0f;
				getMovementStats(this.getName().getHash(), sprint, walkStat, airwalkStat, jumpStat);
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

	if (this.get_u8("hitmarker") > 0)
	{
		this.set_u8("hitmarker", this.get_u8("hitmarker")-1);

		if (this.get_u8("hitmarker") == 20)
		{
			this.set_u8("hitmarker", 0);
		}
	}

	if (this.get_u8("recoil_count") > 0)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				Recoil(this, local, this.get_u8("recoil_count")/3, this.get_s8("recoil_direction"));
			}
		}

		this.set_u8("recoil_count", Maths::Floor(this.get_u8("recoil_count") / infantry.length_of_recoil_arc));
	}

	if (this.get_u8("inaccuracy") > 0)
	{
		s8 testnum = (this.get_u8("inaccuracy") - 5);
		if (testnum < 0)
		{
			this.set_u8("inaccuracy", 0);
		}
		else
		{
			this.set_u8("inaccuracy", this.get_u8("inaccuracy") - 5);
		}
		
		if (this.get_u8("inaccuracy") > inaccuracyCap) {this.set_u8("inaccuracy", inaccuracyCap);}
	}
	
	if (responsible)
	{
		// set cursor
		if (ismyplayer && !getHUD().hasButtons())
		{
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
			else
			{
				frame = Maths::Floor(this.get_u8("inaccuracy") / 5);

				if (frame > 9)
				{
					frame = 9;
				}
				if (frame < 1)
				{
					frame = 1;
				}
				getHUD().SetCursorFrame(frame);
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

void onTick(CBlob@ this)
{
	InfantryInfo@ infantry;
	if (!this.get( "infantryInfo", @infantry )) return;

	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer)) return;
	
	if (isKnocked(this) || this.isInInventory())
	{
		archer.charge_state = 0;
		//archer.charge_time = 0;
		this.set_s32("my_chargetime", 0);
		getHUD().SetCursorFrame(0);
		return;
	}

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars)) return;	

	ManageGun(this, archer, moveVars, infantry);

	if (!this.isOnGround()) // ladders sometimes dont work
	{
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), blobs);
		for (u16 i = 0; i < blobs.length; i++)
		{
			if (blobs[i] !is null && blobs[i].getName() == "ladder")
			{
				if (this.isOverlapping(blobs[i])) 
				{
					this.getShape().getVars().onladder = true;
					break;
				}
			}
		}
	}
	if (this.isKeyPressed(key_action1)) this.set_u32("no_reload", getGameTime()+10);

	this.set_bool("is_a1", false);
	this.set_bool("just_a1", false);
}

bool canSend( CBlob@ this )
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ClientFire( CBlob@ this, const s8 charge_time, InfantryInfo@ infantry )
{
	Vec2f thisAimPos = this.getAimPos();

	float angle = Maths::ATan2(thisAimPos.y - this.getPosition().y, thisAimPos.x - this.getPosition().x) * 180 / 3.14159;
	angle += -0.099f + (XORRandom(2) * 0.01f);
	if (this.isFacingLeft())
	{ 
		ParticleAnimated("Muzzleflash", this.getPosition() + Vec2f(0.0f, 1.0f), this.getVelocity()/2, angle, 0.06f + XORRandom(3) * 0.01f, 3 + XORRandom(2), -0.15f, false);
	}
	else
	{
		ParticleAnimated("Muzzleflashflip", this.getPosition() + Vec2f(0.0f, 1.0f), this.getVelocity()/2, angle + 180, 0.06f + XORRandom(3) * 0.01f, 3 + XORRandom(2), -0.15f, false);
	}

	Vec2f targetVector = thisAimPos - this.getPosition();
	f32 targetDistance = targetVector.Length();
	f32 targetFactor = targetDistance / 367.0f;
	
	float bulletSpread = getBulletSpread(infantry.class_hash) + float(this.get_u8("inaccuracy"));
	ShootBullet(this, this.getPosition() - Vec2f(0,1), thisAimPos, infantry.bullet_velocity, bulletSpread*targetFactor, infantry.burst_size );

	ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -8.0f : 8.0f, -0.0f), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
	
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

				this.set_u8("inaccuracy", this.get_u8("inaccuracy") + infantry.inaccuracy_pershot * (this.hasTag("sprinting")?2.0f:1.0f));
			
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

void ShootBullet( CBlob@ this, Vec2f arrowPos, Vec2f aimpos, float arrowspeed, float bulletSpread, u8 burstSize )
{
	if (canSend(this))
	{
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

		float damageBody = infantry.damage_body;
		float damageHead = infantry.damage_head;
		s8 bulletPen = infantry.bullet_pen;

		bool shotOnce = false;
		Vec2f arrowVel;
		//if (!params.saferead_Vec2f(arrowVel)) return;
		while (params.saferead_Vec2f(arrowVel))
		{
			if (isServer())
			{
				CBlob@ proj = CreateBulletProj(this, arrowPos, arrowVel, damageBody, damageHead, bulletPen);
				if (this.getName() == "sniper") proj.Tag("strong");
				proj.server_SetTimeToDie(infantry.bullet_lifetime);
			}
			shotOnce = true;
		}

		if (!shotOnce) return;
		
		if (this.get_u32("mag_bullets") > 0 && this.get_u32("next_bullet_take") <= getGameTime()) this.set_u32("mag_bullets", this.get_u32("mag_bullets") - 1);
		this.set_u32("next_bullet_take", getGameTime()+1);

		const u32 magSize = infantry.mag_size;
		if (this.get_u32("mag_bullets") > magSize) this.set_u32("mag_bullets", magSize);
		if (isClient()) this.getSprite().PlaySound(infantry.shoot_sfx, 0.9f, 0.95f + XORRandom(35) * 0.01f);
	}
	else if (cmd == this.getCommandID("sync_reload_to_server"))
	{
		if (isClient())
		{
			if (this.getName() == "revolver") onRevolverReload(this);
			else if (this.getName() == "ranger") onRangerReload(this);
			else if (this.getName() == "sniper") onSniperReload(this);
			else if (this.getName() == "mp5") onMp5Reload(this);
		}
		if (isServer())
		{
			s8 reload = params.read_s8();
			this.set_s8("reloadtime", reload);
			//printf("Synced to server: "+this.get_s8("reloadtime"));
			this.Tag("sync_reload");
			this.Sync("isReloading", true);
		}
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