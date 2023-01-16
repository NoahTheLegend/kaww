#include "WarfareGlobal.as"
#include "ThrowCommon.as";
#include "KnockedCommon.as";
#include "RunnerCommon.as";
#include "BombCommon.as";
#include "Hitters.as";
#include "InfantryCommon.as";
#include "AntiTankCommon.as";
#include "TeamColour.as";

void onInit(CBlob@ this)
{
	this.set_u32("mag_bullets_max", 1); // mag size

	this.set_u32("mag_bullets", 0);

	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.Tag("player");
	this.Tag("flesh");
	this.addCommandID("sync_reload_to_server");

	

	this.set_s32("my_chargetime", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);

	this.set_s8("recoil_direction", 0);
	this.set_u8("inaccuracy", 0);

	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -80.0f));

	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot bullet");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
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
	if (damage > 0.15f && this.getHealth() - damage/2 <= 0 && this.getHealth() > 0.01f)
	{
		if (this.hasBlob("aceofspades", 1))
		{
			this.TakeBlob("aceofspades", 1);

			this.server_SetHealth(0.01f);

			if (this.isMyPlayer()) // are we on server?
			{
				this.getSprite().PlaySound("FatesFriend.ogg", 1.2);
				SetScreenFlash(42,   255,   150,   150,   0.28);
			}
			else
			{
				this.getSprite().PlaySound("FatesFriend.ogg", 2.0);
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
		else if ((hitterBlob.getName() == "grenade" || customData == Hitters::explosion) && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Operator")
		{
			damage *= 1.75f; // take double damage
		}
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
			return damage * Maths::Min(0.2f, 0.2f - (0.0025 * (dist_blocks/25)));
		}
	}

	return damage;
}

void ManageParachute( CBlob@ this )
{
	if (this.isOnGround() || this.isInWater() || this.isAttached())
	{	
		if (this.hasTag("parachute"))
		{
			this.Untag("parachute");

			for (uint i = 0; i < 50; i ++)
			{
				Vec2f vel = getRandomVelocity(90.0f, 3.5f + (XORRandom(10) / 10.0f), 25.0f) + Vec2f(0, 2);
				ParticlePixel(this.getPosition() - Vec2f(0, 30) + getRandomVelocity(90.0f, 10 + (XORRandom(20) / 10.0f), 25.0f), vel, getTeamColor(this.getTeamNum()), true, 119);
			}
		}
	}
	
	if (this.hasTag("parachute"))
	{
		this.set_u32("no_climb", getGameTime()+2);
		this.AddForce(Vec2f(Maths::Sin(getGameTime() / 9.5f) * 13, (Maths::Sin(getGameTime() / 4.2f) * 8)));
		this.setVelocity(Vec2f(this.getVelocity().x, this.getVelocity().y * (this.isKeyPressed(key_down) ? 0.83f : this.isKeyPressed(key_up) ? 0.55f : 0.73)));
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	// Deploy parachute!
	if (detached.hasTag("aerial"))
	{
		if (!getMap().rayCastSolid(this.getPosition(), this.getPosition() + Vec2f(0.0f, 150.0f)) && !this.isOnGround() && !this.isInWater() && !this.isAttached())
		{
			if (!this.hasTag("parachute"))
			{
				Sound::Play("/ParachuteOpen", detached.getPosition());
				this.Tag("parachute");
			}
		}
	}
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
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

void ManageGun(CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars)
{
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer() && this.getHealth() > 0.01f)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			if (!ismyplayer)
			{
				responsible = p.isBot();
			}
			
			if (getGameTime() % 90 == 0
			&& getRules().get_string(p.getUsername() + "_perk") == "Lucky")
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					int xslots = inv.getInventorySlots().x;
					int yslots = inv.getInventorySlots().y;
					CBlob@ item = inv.getItem(xslots * yslots - 1);
					
					if (item !is null) // theres an item in the last slot
					{
						if (!this.hasBlob("aceofspades", 1)) // but we have the ace already
						{
							item.server_RemoveFromInventories();
						}
					}
					else if (!this.hasBlob("aceofspades", 1))  // theres no item in the last slot
					{
						// give ace
						CBlob@ b = server_CreateBlob("aceofspades", -1, this.getPosition());
						if (b !is null)
						{
							if (this.getInventory().canPutItem(b)) // if there is room to put the item, put it
							{
								this.server_PutInInventory(b);
							}
							else // no room, must be a weird inventory
							{
								// dump the first slot cause fuck it
								CBlob@ _item = inv.getItem(0);
								if (_item !is null)
								{
									_item.server_RemoveFromInventories();
								}
							}
						}
					}
				}
			}
		}
	}

	CControls@ controls = this.getControls();
	CSprite@ sprite = this.getSprite();
	s8 charge_time = this.get_s32("my_chargetime");//archer.charge_time;
	bool isStabbing = archer.isStabbing;
	bool isReloading = this.get_bool("isReloading"); //archer.isReloading;
	u8 charge_state = archer.charge_state;
	bool just_action1;
	bool is_action1;

	just_action1 = (this.get_bool("just_a1") && this.hasTag("can_shoot_if_attached")) || (!this.isAttached() && this.isKeyJustPressed(key_action1)); // binoculars thing
	is_action1 = (this.get_bool("is_a1") && this.hasTag("can_shoot_if_attached")) || (!this.isAttached() && this.isKeyPressed(key_action1));
	bool was_action1 = this.wasKeyPressed(key_action1);
	bool hidegun = false;
	if (this.getCarriedBlob() !is null)
	{
		if (this.getCarriedBlob().hasTag("hidesgunonhold"))
		{
			hidegun = true;
		}
	}
	bool no_medkit = true;
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null && carried.getName() == "medkit") no_medkit = false;
		
	if (this.isKeyPressed(key_action3) && !hidegun && !isReloading && this.get_u32("end_stabbing") < getGameTime() && no_medkit)
	{
		this.set_u32("end_stabbing", getGameTime()+21);
		this.Tag("attacking");
	}
	if (this.hasTag("attacking") && getGameTime() == this.get_u32("end_stabbing")-13)
	{
		f32 attackarc = 70.0f;
		DoAttack(this, 1.5f, (this.isFacingLeft() ? 180.0f : 0.0f), attackarc, Hitters::sword);
		this.Untag("attacking");
	}
	if (this.get_u32("end_stabbing") > getGameTime())
	{
		just_action1 = false;
		is_action1 = false;
		was_action1 = false;
	}
	const bool pressed_action2 = this.isKeyPressed(key_action2);
	bool menuopen = getHUD().hasButtons();
	Vec2f pos = this.getPosition();

	bool scoped = this.hasTag("scopedin");

	InAirLogic(this, inaccuracycap);

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
		this.set_u8("reloadqueue", 0);
		
		charge_time = 0;

		archer.isReloading = false;
	}
	else
	{
		// reload
		if (controls !is null &&
			!isReloading &&
			(controls.isKeyJustPressed(KEY_KEY_R) || (this.get_u8("reloadqueue") > 0 && isClient())) &&
			this.get_u32("mag_bullets") < this.get_u32("mag_bullets_max"))
		{
			this.set_u8("reloadqueue", 0);
			this.Sync("reloadqueue", true);

			bool reloadistrue = false;
			CInventory@ inv = this.getInventory();
			if (inv !is null && inv.getItem("mat_heatwarhead") !is null)
			{
				// actually reloading
				reloadistrue = true;
				charge_time = reloadtime;
				//archer.isReloading = true;
				isReloading = true;
				this.set_bool("isReloading", true);
	
				CBitStream params; // sync to server
				if (ismyplayer) // isClient()
				{
					this.Tag("reloading");
					this.set_bool("reloading", true);
					params.write_s8(charge_time);
					this.SendCommand(this.getCommandID("sync_reload_to_server"), params);
				}
			}
			else if (ismyplayer)
			{
				sprite.PlaySound("NoAmmo.ogg", 0.85);
			}

			if (reloadistrue)
			{
				charge_time = reloadtime;
				//archer.isReloading = true;
				this.set_bool("isReloading", true);
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
		// shoot
		if (charge_time == 0 && this.getTickSinceCreated() > 5 && semiauto ? just_action1 : is_action1)
		{
			moveVars.walkFactor *= 0.5f;
			moveVars.jumpFactor *= 0.7f;
			moveVars.canVault = false;

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
					ClientFire(this, charge_time);

					charge_time = delayafterfire + XORRandom(randdelay);
					charge_state = ArcherParams::fired;

					this.AddForce(Vec2f(this.getAimPos() - this.getPosition()) * (scoped ? -recoilforce/1.6 : -recoilforce));
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
								u32 max = this.get_u32("mag_bullets_max");
								u32 miss = max-current;
								CBlob@ mag;
								for (u8 i = 0; i < inv.getItemsCount(); i++)
								{
									CBlob@ b = inv.getItem(i);
									if (b is null || b.getName() != "mat_heatwarhead" || b.hasTag("dead")) continue;
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
										this.set_u32("mag_bullets", max);
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
								u32 max = this.get_u32("mag_bullets_max");
								u32 miss = max-current;
								CBlob@ mag;
								for (u8 i = 0; i < inv.getItemsCount(); i++)
								{
									CBlob@ b = inv.getItem(i);
									if (b is null || b.getName() != "mat_heatwarhead" || b.hasTag("dead")) continue;
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
										this.set_u32("mag_bullets", max);
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
					bool sprint = this.getHealth() == this.getInitialHealth() && this.isOnGround() && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
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
						moveVars.walkFactor *= 0.95f;
						moveVars.walkSpeedInAir = 2.9f;
						moveVars.jumpFactor *= 1.0f;
					}
					else
					{
						this.Untag("sprinting");
						moveVars.walkFactor *= 0.8f;
						moveVars.walkSpeedInAir = 2.5f;
						moveVars.jumpFactor *= 1.0f;
					}
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
		
		if (this.get_u8("inaccuracy") > inaccuracycap) {this.set_u8("inaccuracy", inaccuracycap);}
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
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	if (this.getTickSinceCreated() <= 1) this.set_u32("mag_bullets", 0);

	ManageParachute(this);
	
	if (isKnocked(this) || this.isInInventory())
	{
		archer.charge_state = 0;
		//archer.charge_time = 0;
		this.set_s32("my_chargetime", 0);
		getHUD().SetCursorFrame(0);
		return;
	}

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	ManageGun(this, archer, moveVars);

	/*
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
	*/

	if (this.get_u8("reloadqueue") > 0) this.sub_u8("reloadqueue", 1);
	CControls@ controls = this.getControls();
	if (controls !is null)
	{	
		// queue reloading timer
		if (controls.isKeyJustPressed(KEY_KEY_R))
		{
			this.set_u8("reloadqueue", 8);
			this.Sync("reloadqueue", true);
		}
	}

	this.set_bool("is_a1", false);
	this.set_bool("just_a1", false);
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ClientFire(CBlob@ this, const s8 charge_time)
{
	float angle = Maths::ATan2(this.getAimPos().y - this.getPosition().y, this.getAimPos().x - this.getPosition().x) * 180 / 3.14159;
	angle += -0.099f + (XORRandom(2) * 0.01f);
	if (this.isFacingLeft())
	{
		ParticleAnimated("Muzzleflash", this.getPosition() + Vec2f(0.0f, 1.0f), this.getVelocity()/2, angle, 0.06f + XORRandom(3) * 0.01f, 3 + XORRandom(2), -0.15f, false);
	}
	else
	{
		ParticleAnimated("Muzzleflashflip", this.getPosition() + Vec2f(0.0f, 1.0f), this.getVelocity()/2, angle + 180, 0.06f + XORRandom(3) * 0.01f, 3 + XORRandom(2), -0.15f, false);
	}

	if (canSend(this))
	{
		Vec2f targetVector = this.getAimPos() - this.getPosition();
		f32 targetDistance = targetVector.Length();
		f32 targetFactor = targetDistance / 367.0f;
		f32 mod = this.isKeyPressed(key_action2) ? 0.2f : 0.3f;

		ShootBullet(this, this.getPosition() - Vec2f(-24,0).RotateBy(angle), this.getAimPos() + Vec2f(-(2 + this.get_u8("inaccuracy")) + XORRandom((180 + this.get_u8("inaccuracy")) - 110)*mod * targetFactor, -(2 + this.get_u8("inaccuracy")) + XORRandom(180 + this.get_u8("inaccuracy")) - 110)*mod * targetFactor, 8.0f * bulletvelocity);
	
		ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -8.0f : 8.0f, -0.0f), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.75f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);

		if (this.isMyPlayer()) ShakeScreen((Vec2f(recoilx - XORRandom(recoilx*4) + 1, -recoily + XORRandom(recoily) + 6)), recoillength*2, this.getInterpolatedPosition());
		if (this.isMyPlayer()) ShakeScreen(48, 28, this.getPosition());
	}
}

void ShootBullet(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed)
{
	if (canSend(this))
	{
		Vec2f arrowVel = (aimpos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);

		this.SendCommand(this.getCommandID("shoot bullet"), params);
	}

	if (this.isMyPlayer()) ShakeScreen(28, 8, this.getPosition());
}

CBlob@ CreateProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	CBlob@ proj = server_CreateBlobNoInit("ballista_bolt");
	if (proj !is null)
	{
		proj.SetDamageOwnerPlayer(this.getPlayer());
		proj.Init();

		proj.set_f32(projDamageString, damage_body);
		proj.set_f32(projExplosionRadiusString, 32.0f);
		proj.set_f32(projExplosionDamageString, 15.0f);
		proj.set_f32("linear_length", 12.0f);

		proj.set_f32("bullet_damage_body", damage_body);
		proj.set_f32("bullet_damage_head", damage_head);
		proj.IgnoreCollisionWhileOverlapped(this);
		proj.server_setTeamNum(this.getTeamNum());
		proj.setPosition(arrowPos);
		proj.setVelocity(arrowVel);
		proj.set_s8(penRatingString, 2);

		proj.Tag("rpg");
	}
	return proj;
}

void onDie(CBlob@ this)
{
	if (isServer() && this.get_u32("mag_bullets") > 0)
	{
		CBlob@ b = server_CreateBlob("mat_heatwarhead", -1, this.getPosition());
		if (b !is null) b.server_SetQuantity(1);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot bullet"))
	{
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;
		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer)) return;

		if (getNet().isServer())
		{
			CBlob@ proj = CreateProj(this, arrowPos, arrowVel);
			proj.server_SetTimeToDie(3);
		}

		if (this.get_u32("mag_bullets") > 0) this.set_u32("mag_bullets", this.get_u32("mag_bullets") - 1);
		if (this.get_u32("mag_bullets") > this.get_u32("mag_bullets_max")) this.set_u32("mag_bullets", this.get_u32("mag_bullets_max"));
		
		this.getSprite().PlaySound(shootsfx, 1.25f, 0.95f + XORRandom(15) * 0.01f);
	}
	else if (cmd == this.getCommandID("sync_reload_to_server"))
	{
		if (isClient())
		{
			this.getSprite().PlaySound(reloadsfx, 0.8);
		}
		if (isServer())
		{
			this.Tag("reloading");
			this.set_bool("reloading", true);
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