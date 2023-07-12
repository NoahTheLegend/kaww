#include "VehicleCommon.as"
#include "WarfareGlobal.as"
#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";
#include "ProgressBar.as";
#include "TeamColorCollections.as";
#include "GunStandard.as"

const Vec2f upVelo = Vec2f(0.00f, -0.05f);
const Vec2f downVelo = Vec2f(0.00f, 0.01f);
const Vec2f leftVelo = Vec2f(-0.03f, 0.00f);
const Vec2f rightVelo = Vec2f(0.03f, 0.00f);

const Vec2f minClampVelocity = Vec2f(-0.50f, -0.80f);
const Vec2f maxClampVelocity = Vec2f( 0.475f, 0.00f);

const f32 projDamage = 0.275f;

const f32 thrust = 1020.00f;

const u8 cooldown_time = 15;//210;
const u8 recoil = 0;

const s16 init_gunoffset_angle = -3; // up by so many degrees

const Vec2f gun_clampAngle = Vec2f(-180, 180);
const Vec2f miniGun_offset = Vec2f(-43,7);
const u8 shootDelay = 2;

const int trap_cooldown = 20*30;
const u8 traps_amount = 5;

void onInit(CBlob@ this)
{
	this.set_bool("map_damage_raycast", true);
	this.set_u32("duration", 0);
	this.set_u8("mode", 1);
	
	this.set_u8("TTL", 60);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 20);
	this.set_s32("custom_hitter", HittersAW::aircraftbullet);

	this.getShape().SetOffset(Vec2f(0,0));

	this.Tag("vehicle");
	this.Tag("aerial");
	this.Tag("helicopter");
	
	this.set_bool("lastTurn", false);
	this.addCommandID("shoot bullet");
	this.addCommandID("release traps");

	this.set_u32("traps_endtime", trap_cooldown);
	this.set_f32("traps_time", trap_cooldown); // load immediately

	if (this !is null)
	{
		CShape@ shape = this.getShape();
		if (shape !is null)
		{
			shape.SetRotationsAllowed(false);
		}
	}

	if (isServer())
	{
		CBlob@ ac = server_CreateBlobNoInit("ammocarry"); // manager 1
		if (ac !is null)
		{
			ac.Init();
			ac.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo(ac, "AMMOCARRY");
			this.set_u16("ammocarryid", ac.getNetworkID());
		}
	}

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.offsetZ = 10.0f;
			ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
		}
	}

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_up | CBlob::map_collide_right);
	this.inventoryButtonPos = Vec2f(-8.0f, -4);

	this.addCommandID("shoot");
	
	// shits in console if not added
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
}

void onInit(CSprite@ this)
{	
	this.SetRelativeZ(-20.0f);
	//Add blade
	CSpriteLayer@ blade = this.addSpriteLayer("blade", "UH_Blade.png", 92, 8);
	if (blade !is null)
	{
		Animation@ anim = blade.addAnimation("default", 1, true);
		int[] frames = {1, 2, 3, 2};
		anim.AddFrames(frames);
		
		blade.SetOffset(Vec2f(-5.5, -27));
		blade.SetRelativeZ(20.0f);
		blade.SetVisible(true);
	}
	//Add tail rotor
	CSpriteLayer@ tailrotor = this.addSpriteLayer("tailrotor", "UH_TailRotor.png", 16, 16);
	if (tailrotor !is null)
	{
		Animation@ anim = tailrotor.addAnimation("default", 1, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		
		tailrotor.SetOffset(Vec2f(58.0, -5));
		tailrotor.SetRelativeZ(20.0f);
		tailrotor.SetVisible(true);
	}
	CSpriteLayer@ mini = this.addSpriteLayer("minigun", "UHT_Gun.png", 16, 16);
	if (mini !is null)
	{
		mini.SetOffset(miniGun_offset);
		mini.SetRelativeZ(-50.0f);
		mini.SetVisible(true);
	}

	this.SetEmitSound("Eurokopter_Loop.ogg");
	this.SetEmitSoundSpeed(0.01f);
	this.SetEmitSoundPaused(false);
}

void updateLayer(CSprite@ sprite, string name, int index, bool visible, bool remove)
{
	if (sprite !is null)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(name);
		if (layer !is null)
		{
			if (remove == true)
			{
				sprite.RemoveSpriteLayer(name);
				return;
			}
			else
			{
				layer.SetFrameIndex(index);
				layer.SetVisible(visible);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onTick(CBlob@ this)
{
	barTick(this);

	if (this !is null)
	{
		Vehicle_ensureFallingCollision(this);

		this.add_f32("traps_time", 1);

		if (getGameTime() >= this.get_u32("next_shoot"))
		{
			this.Untag("no_more_shooting");
			this.Untag("no_more_proj");
		}
		if (this.get_f32("traps_time") > this.get_u32("traps_endtime")+15)
		{
			this.Untag("no_more_traps");
		}
		if (this.getVelocity().x > 6.25f || this.getVelocity().x < -6.25f) this.setVelocity(Vec2f(this.getOldVelocity().x, this.getVelocity().y));

		if (this.getPosition().y < 70.0f && this.getVelocity().y < 0.5f)
		{
			//this.setVelocity(Vec2f(this.getVelocity().x, this.getVelocity().y*0.16f));
			this.AddForce(Vec2f(0, 220.0f));
		}

		CSprite@ sprite = this.getSprite();
		CShape@ shape = this.getShape();
		Vec2f currentVel = this.getVelocity();
		f32 angle = shape.getAngleDegrees();

		const bool flip = this.isFacingLeft();

		Vec2f newForce = Vec2f(0, 0);

		AttachmentPoint@[] aps;
		this.getAttachmentPoints(@aps);
		
		CSpriteLayer@ blade = sprite.getSpriteLayer("blade");
		CSpriteLayer@ tailrotor = sprite.getSpriteLayer("tailrotor");
		for(int a = 0; a < aps.length; a++)
		{
			AttachmentPoint@ ap = aps[a];
			if (ap !is null)
			{
				CBlob@ hooman = ap.getOccupied();
				if (hooman !is null)
				{
					if (ap.name == "DRIVER")
					{
						const bool pressed_w  = ap.isKeyPressed(key_up);
						const bool pressed_s  = ap.isKeyPressed(key_down);
						const bool pressed_a  = ap.isKeyPressed(key_left);
						const bool pressed_d  = ap.isKeyPressed(key_right);
						const bool pressed_c  = ap.isKeyPressed(key_pickup);
						const bool pressed_m1 = ap.isKeyPressed(key_action1);
						const bool pressed_m2 = ap.isKeyPressed(key_action2);

						if (hooman.isMyPlayer() && hooman.getControls() !is null)
						{
							if (hooman.getControls().isKeyJustPressed(KEY_LCONTROL))
							{
								this.add_u8("mode", 1);
								if (this.get_u8("mode") > 2) this.set_u8("mode", 0);
							}
						}

						// shoot
						
						if (!this.isOnGround() && !this.hasTag("no_more_shooting") && ap.isKeyPressed(key_action3) && this.get_u32("next_shoot") < getGameTime())
						{
							CInventory@ inv = this.getInventory();
							if (inv !is null && inv.getItem(0) !is null && inv.getItem(0).getName() == "mat_bolts")
							{
								if (hooman.isMyPlayer())
								{
									f32 rot = 1.0f;
									if (this.isFacingLeft()) rot = -1.0f;
									ShootBullet(this, this.getPosition()+Vec2f(54.0f*rot, 0).RotateBy(angle), this.getPosition()+Vec2f(64.0f*rot, 0).RotateBy(angle), 30.0f);
								}
								this.getSprite().PlaySound("Missile_Launch.ogg", 1.25f, 0.95f + XORRandom(15) * 0.01f);
								this.set_u32("next_shoot", getGameTime()+cooldown_time);
							}
						}

						// javelin traps

						if (!this.isOnGround() && !this.hasTag("no_more_traps") && ap.isKeyPressed(key_action1) && this.get_f32("traps_time") > this.get_u32("traps_endtime"))
						{
							if (hooman.isMyPlayer())
							{
								f32 rot = 1.0f;
								if (this.isFacingLeft()) rot = -1.0f;
								ReleaseTraps(this);
							}

							if (!this.hasTag("no_more_shooting")) this.getSprite().PlaySound("Missile_Launch.ogg", 1.0f, 0.5f + XORRandom(15) * 0.01f);
							this.Tag("no_more_traps");
						}
						
						const f32 mass = this.getMass();

						if (!this.hasTag("falling")
						&& hooman.getPlayer() !is null
						&& getRules().get_string(hooman.getPlayer().getUsername()+"_perk") == "Operator")
						{
							if (pressed_a) newForce += Vec2f(leftVelo.x*0.25f, leftVelo.y*0.25f);
							if (pressed_d) newForce += Vec2f(rightVelo.x*0.25f, rightVelo.y*0.25f);

							if (pressed_w) newForce += Vec2f(upVelo.x*0.75f, upVelo.y*0.75f);
							if (pressed_s) newForce += Vec2f(downVelo.x*0.5f, downVelo.y*0.5f);
						}
						if (!this.hasTag("falling"))
						{
							if (pressed_a) newForce += leftVelo;
							if (pressed_d) newForce += rightVelo;

							if (pressed_w) newForce += upVelo;
							if (pressed_s) newForce += downVelo;
						}
						else
						{
							newForce -= Vec2f(upVelo.x*0.45f, upVelo.y*0.45f);
						}

						Vec2f mousePos = ap.getAimPos();
						CBlob@ pilot = ap.getBlob();
						
						if (!this.hasTag("falling"))
						{
							if (pilot !is null && pressed_m2 && (this.getVelocity().x < 5.00f || this.getVelocity().x > -5.00f))
							{
								if (mousePos.x < pilot.getPosition().x) this.SetFacingLeft(true);
								else if (mousePos.x > pilot.getPosition().x) this.SetFacingLeft(false);
							}
							else if (this.getVelocity().x < -0.50f)
								this.SetFacingLeft(true);
							else if (this.getVelocity().x > 0.50f)
								this.SetFacingLeft(false);
						}

						bool flip = this.isFacingLeft();
						CSpriteLayer@ minigun = sprite.getSpriteLayer("minigun");
						if (minigun !is null)
						{
							if (this.get_bool("lastTurn") != flip)
							{
								this.set_bool("lastTurn", flip);
								minigun.ResetTransform();
							}
						}
					}
					else if (ap.name == "GUNNER")
					{
						bool flip = this.isFacingLeft();
						CBlob@ realPlayer = getLocalPlayerBlob();
						const bool pressed_m1 = ap.isKeyPressed(key_action1);
						Vec2f GunAimPos = ap.getAimPos();
						const f32 flip_factor = flip ? -1: 1;

						CSpriteLayer@ minigun = sprite.getSpriteLayer("minigun");
						if (minigun !is null)
						{
							if (this.get_bool("lastTurn") != flip)
							{
								this.set_bool("lastTurn", flip);
								minigun.ResetTransform();
							}

							CBlob@ ammocarry = getBlobByNetworkID(this.get_u16("ammocarryid"));
							if (ammocarry is null)
							{
								sprite.RemoveSpriteLayer("minigun");
								return;
							}

							Vec2f aimvector = GunAimPos - this.getPosition()+Vec2f(this.isFacingLeft() ? 42 : -42, -10).RotateBy(this.getAngleDegrees());

							const f32 angle = constrainAngle(-aimvector.Angle() + (flip ? 180 : 0)) * flip_factor;
							const f32 clampedAngle = (Maths::Clamp(angle, gun_clampAngle.x, gun_clampAngle.y) * flip_factor);

							this.set_f32("gunAngle", clampedAngle);

							minigun.ResetTransform();
							minigun.RotateBy(clampedAngle-this.getAngleDegrees(), Vec2f(5 * flip_factor, 1));

							if (pressed_m1)
							{
								CBlob@ ammocarry = getBlobByNetworkID(this.get_u16("ammocarryid"));
								if (ammocarry !is null && ammocarry.hasBlob("ammo", 1))
								{
									this.getSprite().PlaySound("AssaultFire.ogg", 1.33f, 1.15f + XORRandom(35) * 0.01f);
								}
								if (getGameTime() > this.get_u32("fireDelayGun") && hooman.isMyPlayer())
								{
									CBlob@ ammocarry = getBlobByNetworkID(this.get_u16("ammocarryid"));
									if (ammocarry !is null && ammocarry.hasBlob("ammo", 1))
									{
										f32 bulletSpread = 20.0f;

										f32 true_angle = this.isFacingLeft()?-angle+180:angle;
										true_angle += XORRandom(bulletSpread+1)/10-bulletSpread/10/2;

										shootVehicleGun(hooman.getNetworkID(), this.getNetworkID(),
											true_angle, this.getPosition()+Vec2f(this.isFacingLeft()?-39:39, 7).RotateBy(this.getAngleDegrees()),
											ap.getAimPos(), bulletSpread, 1, 0, 0.4f, 0.6f, 2,
												this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));	

										CBitStream params;
										params.write_s32(this.get_f32("gunAngle"));
										params.write_Vec2f(this.getPosition()+Vec2f(this.isFacingLeft()?-39:39, 9));

										this.SendCommand(this.getCommandID("shoot"), params);
										this.set_u32("fireDelayGun", getGameTime() + (shootDelay));
									}
								}
							}
						}
					}
				}
			}
		}
		Vec2f targetForce;
		Vec2f currentForce = this.get_Vec2f("current_force");
		CBlob@ pilot = this.getAttachmentPoint(0).getOccupied();
		if (pilot !is null) targetForce = this.get_Vec2f("target_force") + newForce;
		else targetForce = Vec2f(0, 0);

		f32 targetForce_y = Maths::Clamp(targetForce.y, minClampVelocity.y, maxClampVelocity.y);

		Vec2f clampedTargetForce = Vec2f(Maths::Clamp(targetForce.x, Maths::Max(minClampVelocity.x, -Maths::Abs(targetForce_y)), Maths::Min(maxClampVelocity.x, Maths::Abs(targetForce_y))), targetForce_y);

		Vec2f resultForce;
		if(!this.get_bool("glide"))
		{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), Lerp(currentForce.y, clampedTargetForce.y, lerp_speed_y));
			this.set_Vec2f("current_force", resultForce);
		}
		else
		{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), -0.5890000005);
			this.set_Vec2f("current_force", resultForce);
		}

		if (this.hasTag("falling") && !this.hasTag("set_force"))
		{
			this.Tag("set_force");
			this.set_Vec2f("result_force", resultForce);
		}

		this.AddForce(resultForce * thrust);
		this.setAngleDegrees(resultForce.x * 75.00f);
		if (this.hasTag("falling"))
		{
			this.setAngleDegrees(this.get_Vec2f("result_force").x * 75.00f);
		}
		
		int anim_time_formula = Maths::Floor(1.00f + (1.00f - Maths::Abs(resultForce.getLength())) * 3) % 4;
		if (this.hasTag("falling")) anim_time_formula = Maths::Floor(1.00f + (1.00f - Maths::Abs(this.get_Vec2f("result_force").getLength())) * 3) % 4;
		blade.ResetTransform();
		blade.SetOffset(Vec2f(-5.5, -27));
		blade.animation.time = anim_time_formula;
		if (blade.animation.time == 0)
		{
			blade.SetOffset(Vec2f(-6.5, -27));
			blade.SetFrameIndex(0);
			blade.RotateBy(180, Vec2f(0.0f,2.0f));
		}
		
		if (sprite !is null && this.hasTag("falling"))
		{
			if (getGameTime() % 8 == 0)
			{
				sprite.SetFacingLeft(!sprite.isFacingLeft());
			}
		}

		tailrotor.animation.time = anim_time_formula;
		if (tailrotor.animation.time == 0)
		{
			tailrotor.SetFrameIndex(1);
		}

		f32 volume = (Maths::Log(4.5)*(resultForce.getLength()+0.2)+2)/4;
		sprite.SetEmitSoundVolume(Maths::Min(volume*1.5, 1.5f));
		sprite.SetEmitSoundSpeed(Maths::Min(0.0075f + Maths::Abs(resultForce.getLength() * 4.00f), 1.33f) * volume + (this.getVelocity().Length() > 1.0f ? Maths::Max(resultForce.y + 0.25f, 0) : 0));
		if (this.hasTag("falling")) sprite.SetEmitSoundSpeed(Maths::Min(0.000075f + Maths::Abs(this.get_Vec2f("result_force").getLength() * 1.00f), 0.85f) * 1.55);

		this.set_Vec2f("target_force", clampedTargetForce);
	
		if (this.hasTag("falling"))
		{
			if (getGameTime()%8==0)
				this.getSprite().PlaySound("FallingAlarm.ogg", 1.0f, 1.3f);

			this.setAngleDegrees(this.getAngleDegrees() + (Maths::Sin(getGameTime() / 5.0f) * 8.5f));
		}
	}
}

void ShootBullet(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed)
{
	Vec2f arrowVel = (aimpos - arrowPos);
	arrowVel.Normalize();
	arrowVel *= arrowspeed;
	CBitStream params;
	params.write_Vec2f(arrowPos);
	params.write_Vec2f(arrowVel);
	this.SendCommand(this.getCommandID("shoot bullet"), params);
}

void ReleaseTraps(CBlob@ this)
{
	CBitStream params;
	this.SendCommand(this.getCommandID("release traps"), params);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer() && solid && this.hasTag("falling"))
		this.server_Die();
}

void ShootGun(CBlob@ this, f32 angle, Vec2f gunPos)
{	
	/*
	if (isServer())
	{
		f32 sign = (this.isFacingLeft() ? -1 : 1);
		angle += (float(XORRandom(100) - 50) / 50.0f);
		angle += this.getAngleDegrees();

		Vec2f arrowVel = Vec2f(25.0f, 0.0f).RotateBy(angle);

		CBlob@ proj = CreateBullet(this, gunPos-Vec2f(sign * 24, 8), arrowVel * sign);
		if (proj !is null)
		{
			proj.server_SetTimeToDie(5.0);
			proj.Tag("aircraft_bullet");

			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
			if (ap !is null && ap.getOccupied() !is null && ap.getOccupied().getPlayer() !is null)
			{
				proj.SetDamageOwnerPlayer(ap.getOccupied().getPlayer());
			}
		}
	}
	*/
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot"))
	{
		this.set_u32("next_shoot", getGameTime()+shootDelay);
		s32 arrowAngle;
		if (!params.saferead_s32(arrowAngle)) return;
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;

		//Vec2f vel = Vec2f(500.0f / 16.5f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(arrowAngle);

		//arrowPos = arrowPos+(Vec2f(24 * (this.isFacingLeft()?1:-1), -8));
		//Vec2f arrowVel = Vec2f(27.5f, 0).RotateBy((this.isFacingLeft()?180:0)+arrowAngle);

		CBlob@ ammocarry = getBlobByNetworkID(this.get_u16("ammocarryid"));
		if (ammocarry !is null && ammocarry.hasBlob("ammo", 1))
		{
			ammocarry.TakeBlob("ammo", 1);
			if (getNet().isServer())
			{
				//CBlob@ proj = CreateBullet(this, arrowPos, arrowVel);
				//if (proj !is null)
				//{
				//	proj.server_SetTimeToDie(5.0);
				//	proj.Tag("aircraft_bullet");
				//}
			}
			ParticleAnimated("SmallExplosion3", (arrowPos + Vec2f(8,0).RotateBy(this.isFacingLeft()?arrowAngle+180:arrowAngle)), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		}
	}
	else if (cmd == this.getCommandID("shoot bullet"))
	{
		this.set_u32("next_shoot", getGameTime()+15);
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;

		if (getGameTime() <= this.get_u32("next_create")) return;
		this.set_u32("next_create", getGameTime()+15);
		
		if (getNet().isServer())
		{
			CBlob@ proj = CreateProj(this, arrowPos, arrowVel);
			if (proj is null) return;
			
			proj.set_f32(projExplosionRadiusString, 16.0f);
			proj.set_f32(projExplosionDamageString, 16.0f);

			proj.set_f32("map_damage_radius", 16.0f);
			proj.set_f32("map_damage_ratio", 0.01f);

			proj.set_s8(penRatingString, 1);

			proj.server_SetTimeToDie(8);
			proj.Tag("rpg");
			proj.Tag("no_hitmap");

			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
			if (ap !is null && ap.getOccupied() !is null && ap.getOccupied().getPlayer() !is null)
			{
				proj.SetDamageOwnerPlayer(ap.getOccupied().getPlayer());
			}

			CInventory@ inv = this.getInventory();
			if (inv !is null && inv.getItem(0) !is null && inv.getItem(0).getName() == "mat_bolts")
			{
				inv.getItem(0).server_SetQuantity(inv.getItem(0).getQuantity()-1);
			}
		} 
	}
	else if (cmd == this.getCommandID("release traps"))
	{
		if (this.get_f32("traps_time") <= this.get_u32("traps_endtime")) return;
		this.set_f32("traps_time", 0);

		Bar@ bars;
		if (!this.get("Bar", @bars))
		{
			Bar setbars;
    		setbars.gap = 20.0f;
    		this.set("Bar", setbars);
		}
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "traps"))
			{
				SColor team_front = getNeonColor(this.getTeamNum(), 0);
				ProgressBar setbar;
				setbar.Set(this, "traps", Vec2f(80.0f, 16.0f), false, Vec2f(0, 56), Vec2f(2, 2), back, team_front,
					"traps_time", this.get_u32("traps_endtime"), 0.33f, 5, 5, false, "");

    			bars.AddBar(this, setbar, true);
			}
		}
		
		if (getNet().isServer())
		{
			for (u8 i = 0; i < traps_amount; i++)
			{
				CBlob@ proj = server_CreateBlob("missiletrap", this.getTeamNum(), this.getPosition()+Vec2f(XORRandom(8)-4, XORRandom(8)-4));
				if (proj is null) return;

				proj.set_u16("heli_id", this.getNetworkID());
				Vec2f vel = Vec2f(0, -8).RotateBy(((195+XORRandom(166))/traps_amount) * i - 90);
				vel.y = -0.5f * XORRandom(6);
				vel.x *= 0.25f;
				proj.setVelocity(vel);
				proj.getShape().SetGravityScale(0);
				proj.server_SetTimeToDie(5.0f);
			}
		} 
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return this.getTeamNum() == forBlob.getTeamNum();
}

CBlob@ CreateBullet(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	if (!this.hasTag("no_more_proj"))
	{
		CBlob@ proj = server_CreateBlobNoInit("bulletheavy");
		if (proj !is null)
		{
			proj.SetDamageOwnerPlayer(this.getPlayer());
			proj.Init();

			proj.set_s8(penRatingString, 2);

			proj.set_f32("bullet_damage_body", projDamage);
			proj.set_f32("bullet_damage_head", projDamage+0.125f);
			proj.IgnoreCollisionWhileOverlapped(this);
			proj.server_setTeamNum(this.getTeamNum());
			proj.setVelocity(arrowVel.RotateBy(0.025f*(XORRandom(5)-2.0f)));

			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
			if (ap !is null && ap.getOccupied() !is null && ap.getOccupied().getPlayer() !is null)
			{
				proj.SetDamageOwnerPlayer(ap.getOccupied().getPlayer());
			}
			
			//proj.getShape().setDrag(proj.getShape().getDrag() * 0.3f);
			proj.setPosition(arrowPos + Vec2f((this.isFacingLeft() ? -90.0f : 24.0f), 8.0f).RotateBy(this.getAngleDegrees()));
		}
		this.Tag("no_more_proj");
		return proj;
	}
	else
		return null;
}

CBlob@ CreateProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	if (!this.hasTag("no_more_proj"))
	{
		CBlob@ proj = server_CreateBlobNoInit("ballista_bolt");
		if (proj !is null)
		{
			proj.SetDamageOwnerPlayer(this.getPlayer());
			proj.Init();

			proj.set_f32("bullet_damage_body", 1.0f);
			proj.set_f32("bullet_damage_head", 2.0f);
			proj.IgnoreCollisionWhileOverlapped(this);
			proj.server_setTeamNum(this.getTeamNum());
			proj.setVelocity(arrowVel);
			proj.setPosition(arrowPos+Vec2f(-16, 2.0f));
		}
		this.Tag("no_more_proj");
		return proj;
	}
	else
		return null;
}

const f32 lerp_speed_x = 0.3f;
const f32 lerp_speed_y = 1.75f;

f32 Lerp(f32 a, f32 b, f32 time)
{
	return a + (b - a) * time;
}

f32 constrainAngle(f32 x)
{
	x = (x + 180) % 360;
	if (x < 0) x += 360;
	return x - 180;
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (isServer())
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("AMMOCARRY");
		if (ap !is null && ap.getOccupied() !is null)
		{
			ap.getOccupied().server_setTeamNum(this.getTeamNum());
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached !is null)
	{
		{
			attached.Tag("invincible");
			attached.Tag("invincibilityByVehicle");
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (detached !is null)
	{
		detached.Untag("invincible");
		detached.Untag("invincibilityByVehicle");
	}
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (!blob.isCollidable() || blob.isAttached()){
		return false;
	} // no colliding against people inside vehicles
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(8, 0).RotateBy(this.getAngleDegrees());
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("ignore damage")) return 0;
	if (damage >= this.getHealth())
	{
		this.Tag("ignore damage");
		this.Tag("falling");
		this.Tag("invincible");
		this.set_u32("falling_time", getGameTime());
		if (isServer())
		{
			this.server_SetTimeToDie(30);
			this.server_SetHealth(this.getInitialHealth());
		}
		return 0;
	}
	else if (hitterBlob.getName() == "ballista_bolt")
	{
		return damage * 1.0f;
	}

	if (customData == HittersAW::aircraftbullet) 	 
	{
		damage += 0.1f;
		return damage * 0.4f;
	}
	else if (customData == HittersAW::heavybullet) 
	{
		damage += 0.1f;
		return damage * 0.65f;
	}
	else if (customData == HittersAW::bullet)
	{
		return damage * 0.75f;
	}

	return damage;
}

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();

	this.set_f32("map_damage_radius", 48.0f);
	this.set_f32("map_damage_ratio", 0.4f);
	f32 angle = this.get_f32("bomb angle");

	Explode(this, 100.0f, 100.0f);

	for (int i = 0; i < 4; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 40);
		LinearExplosion(this, dir, 40.0f + XORRandom(64), 48.0f, 6, 0.5f, Hitters::explosion);
	}

	Vec2f pos = this.getPosition() + this.get_Vec2f("explosion_offset").RotateBy(this.getAngleDegrees());
	CMap@ map = getMap();

	if (isClient())
	{
		for (int i = 0; i < (v_fastrender ? 10 : 40); i++)
		{
			MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(angle, XORRandom(400) * 0.01f, 70), particles[XORRandom(particles.length)]);
		}
	}

	this.getSprite().Gib();
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1 + XORRandom(200) * 0.01f, 2 + XORRandom(5), XORRandom(100) * -0.00005f, true);
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	AttachmentPoint@ pilot = blob.getAttachments().getAttachmentPointByName("DRIVER");
	if (pilot !is null && pilot.getOccupied() !is null)
	{
		CBlob@ driver_blob = pilot.getOccupied();
		if (driver_blob.isMyPlayer())
		{
			u8 mode = blob.get_u8("mode");
			if (mode == 0) return; // disabled

			barRender(this);

			f32 screenWidth = getScreenWidth();
			f32 screenHeight = getScreenHeight();

			//Vec2f oldpos2d = getDriver().getScreenPosFromWorldPos(driver_blob.getOldPosition());
			//Vec2f pos2d = oldpos2d;

			Vec2f oldpos = driver_blob.getOldPosition();
			Vec2f pos = driver_blob.getPosition();
			Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , 0);

			Vec2f force = blob.get_Vec2f("target_force")*64+Vec2f(0, 38);	
			Vec2f offset = pos2d;

			if (mode == 1) // leftside square
			{
				offset = Vec2f(50, screenHeight*0.5f); // fixed pos
				Vec2f pane_size = Vec2f(40.0f, 40.0f);
				GUI::DrawPane(offset-pane_size, offset+pane_size, SColor(100, 0, 0, 0));
				GUI::DrawTextCentered("CTRL", offset+Vec2f(-28, screenHeight*0.05f), SColor(100, 0, 0, 0));
			}

			SColor color;
			if (force.y < 0) color = SColor(255, 55, 255, 55); // up
			else color = color = SColor(255, 215, 155, 15);

			if (mode == 2) // outlines
			{
				force = force*1.75f;
				GUI::DrawLine2D(offset+Vec2f(2,1), offset+Vec2f(force.x, force.y > 0 ? force.y : force.y * 2.75f)+Vec2f(2,-1), SColor(255, 255, 255, 255));
				GUI::DrawLine2D(offset+Vec2f(-2,1), offset+Vec2f(force.x, force.y > 0 ? force.y : force.y * 2.75f)+Vec2f(-2,-1), SColor(255, 255, 255, 255));
			}

			GUI::DrawLine2D(offset, offset+Vec2f(force.x, force.y > 0 ? force.y : force.y * 2.75f), color);
			GUI::DrawLine2D(offset+Vec2f(1,0), offset+Vec2f(force.x, force.y > 0 ? force.y : force.y * 2.75f)+Vec2f(1,0), color);
			GUI::DrawLine2D(offset+Vec2f(-1,0), offset+Vec2f(force.x, force.y > 0 ? force.y : force.y * 2.75f)+Vec2f(-1,0), color);
		
			// draw ammo count
			GUI::DrawSunkenPane(pos2d-Vec2f(40.0f, -48.0f), pos2d+Vec2f(18.0f, 70.0f));
			GUI::DrawIcon("Materials.png", 30, Vec2f(16,16), pos2d+Vec2f(-40, 42.0f), 0.75f, 1.0f);
			GUI::SetFont("menu");
			if (blob.getInventory() !is null)
				GUI::DrawTextCentered(""+blob.getInventory().getCount("mat_bolts"), pos2d+Vec2f(-8, 58.0f), SColor(255, 255, 255, 0));
		}
	}

	AttachmentPoint@ COPILOT = blob.getAttachments().getAttachmentPointByName("GUNNER");
	if (COPILOT !is null && COPILOT.getOccupied() !is null)
	{
		CBlob@ driver_blob = COPILOT.getOccupied();
		if (!driver_blob.isMyPlayer()) return;
		CBlob@ ammocarry = getBlobByNetworkID(blob.get_u16("ammocarryid"));
		if (ammocarry is null) return;

		// draw ammo count
		Vec2f oldpos = driver_blob.getOldPosition();
		Vec2f pos = driver_blob.getPosition();
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , 0);

		GUI::DrawSunkenPane(pos2d-Vec2f(40.0f, -48.0f), pos2d+Vec2f(18.0f, 70.0f));
		GUI::DrawIcon("Materials.png", 31, Vec2f(16,16), pos2d+Vec2f(-40, 42.0f), 0.75f, 1.0f);
		GUI::SetFont("menu");
		if (ammocarry.getInventory() !is null)
			GUI::DrawTextCentered(""+ammocarry.getInventory().getCount("ammo"), pos2d+Vec2f(-8, 58.0f), SColor(255, 255, 255, 0));
	}
}