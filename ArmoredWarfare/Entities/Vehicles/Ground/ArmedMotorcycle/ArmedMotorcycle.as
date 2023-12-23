#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";

const u8 shootDelay = 3;
const f32 projDamage = 0.35f;

f32 high_angle = 30.0f; // upper depression limit
f32 low_angle = 115.0f; // lower depression limit

void onInit(CBlob@ this)
{
	this.Tag("motorcycle");
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("shootseat");
	this.Tag("weak vehicle");
	this.Tag("engine_can_get_stuck");
	this.Tag("pass_60sec");
	this.Tag("friendly_bullet_pass");
	this.Tag("autoflip");

	this.set_f32("max_angle_diff", 1.25f);

	//print("" + this.getName().getHash());

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	        	  6500.0f, // move speed
	              0.47f,  // turn speed
	              Vec2f(0.0f, 0.56f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	// machinegun stuff
	this.set_u8("TTL", 40);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 15);
	this.set_s32("custom_hitter", HittersAW::machinegunbullet);
	this.addCommandID("shoot");

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("ammo");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();

			ammo.server_SetQuantity(ammo.getQuantity()*2);
		}
	}

	Vehicle_AddAmmo(this, v,
	                    2, // fire delay (ticks), +1 tick on server due to onCommand delay
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "ammo", // bullet ammo config name
	                    "Ammo", // name for ammo selection
	                    "arrow", // bullet config name
	                    "M60fire", // fire sound  
	                    "EmptyFire", // empty fire sound
	                    Vehicle_Fire_Style::custom,
	                    Vec2f(-6.0f, 2.0f), // fire position offset
	                    0 // charge time
	                   );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(11.0f, 6.0f)); if (w !is null) {w.ScaleBy(Vec2f(0.85f, 0.85f)); w.SetRelativeZ(-10.0f);} }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(7.0f, 6.0f)); if (w !is null) {w.ScaleBy(Vec2f(0.85f, 0.85f)); w.SetRelativeZ(-10.0f);} }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-14.5f, 6.0f)); if (w !is null) {w.ScaleBy(Vec2f(0.85f, 0.85f)); w.SetRelativeZ(-10.0f);} }

	this.getShape().SetOffset(Vec2f(0, 2));
	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);

	CSpriteLayer@ front = sprite.addSpriteLayer("front", sprite.getConsts().filename, 80, 80);
	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(3);
			front.SetAnimation(anim);
			front.SetRelativeZ(51.0f);
			front.SetOffset(Vec2f(0.0f, 14.0f));
		}
	}

	CSpriteLayer@ mg = sprite.addSpriteLayer("mg", "SmallMachineGun.png", 16, 16);
	if (mg !is null)
	{
		this.set_f32("gun_elevation", this.isFacingLeft()?-90:90);
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.SetFacingLeft(this.getTeamNum() == teamright);

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
		}
	}

	if (getNet().isServer())
	{
		{
			CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 1

			if (soundmanager !is null)
			{
				soundmanager.set_bool("manager_Type", false);
				soundmanager.set_string("engine_high", "LightEngineRun_high.ogg");
				soundmanager.set_string("engine_mid", "LightEngineRun_mid.ogg");
				soundmanager.set_string("engine_low", "LightEngineRun_low.ogg");
				soundmanager.set_f32("custom_pitch", 0.9f);
				soundmanager.Init();
				soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));

				this.set_u16("followid", soundmanager.getNetworkID());
			}
		}
		{
			CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 2

			if (soundmanager !is null)
			{
				soundmanager.set_bool("manager_Type", true);
				soundmanager.set_string("engine_high", "LightEngineRun_high.ogg");
				soundmanager.set_string("engine_mid", "LightEngineRun_mid.ogg");
				soundmanager.set_string("engine_low", "LightEngineRun_low.ogg");
				soundmanager.set_f32("custom_pitch", 0.9f);
				soundmanager.Init();
				soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));
				
				this.set_u16("followid2", soundmanager.getNetworkID());
			}
		}
	}
}

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		// allow passenger shoot from it
		AttachmentPoint@ pass = this.getAttachments().getAttachmentPointByName("PASSENGER");
		if (pass !is null && pass.getOccupied() !is null)
		{
			CBlob@ b = pass.getOccupied();
			if (b !is null)
			{
				if (pass.isKeyPressed(key_action1)) b.set_bool("is_a1", true);
				if (pass.isKeyJustPressed(key_action1)) b.set_bool("just_a1", true);
				b.Tag("show_gun");
				b.Tag("can_shoot_if_attached");

				if (b.getAimPos().x < b.getPosition().x) b.SetFacingLeft(true);
				else b.SetFacingLeft(false);
			}
		}

		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null)
		{
			gunner.offsetZ = 50.0f;
			bool flip = this.isFacingLeft();
			const f32 flip_factor = flip ? -1 : 1;

			CBlob@ hooman = gunner.getOccupied();
			if (hooman !is null)
			{
				Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();
				CBlob@ realPlayer = getLocalPlayerBlob();
				const bool pressed_m1 = gunner.isKeyPressed(key_action1);
				f32 angle = this.get_f32("gunelevation")-90 + this.getAngleDegrees();

				if (pressed_m1)
				{
					if (getGameTime() > this.get_u32("fireDelayGun") && hooman.isMyPlayer())
					{
						if (this.hasBlob("ammo", 1))
						{
							f32 spread = XORRandom(3)-1.5f;
							Vec2f shootpos = Vec2f(4*flip_factor,0);
							shootVehicleGun(hooman.getNetworkID(), this.getNetworkID(),
								angle+spread, (this.getPosition()+this.getVelocity()*1.1f)+shootpos.RotateBy(this.getAngleDegrees()),
									gunner.getAimPos(), 0.0f, 1, 0, 0.4f, 0.6f, 2,
										this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));	

							CBitStream params;
							params.write_s32(this.get_f32("gunelevation")-90);
							params.write_Vec2f(this.getPosition()+(shootpos-Vec2f(12*flip_factor,0)).RotateBy(this.getAngleDegrees()));

							this.SendCommand(this.getCommandID("shoot"), params);
							this.set_u32("fireDelayGun", getGameTime() + (shootDelay));
						}
					}
				}

				this.set_f32("gunelevation", flip_factor * Maths::Max(high_angle, Maths::Min(flip_factor * getAngle(this, 0, v), low_angle)));
			}
			else this.set_f32("gunelevation", flip_factor * 90);
		}

		AttachmentPoint@ driver = this.getAttachments().getAttachmentPointByName("DRIVER");
		if (driver !is null)
		{
			if (this.isOnWall() && (driver.isKeyPressed(key_left) || driver.isKeyPressed(key_right)))
			{
				this.AddForce(Vec2f(0, -400.0f));
			}

			if (driver.isKeyPressed(key_down) && !this.isOnGround())
			{
				this.AddTorque(this.isFacingLeft() ? 300.0f : -300.0f);
			}
			else
			{
				f32 deg = this.getAngleDegrees();
				if ((!this.isFacingLeft() && deg > 270)
				|| (this.isFacingLeft() && deg < 90))
				{
					this.AddTorque(this.isFacingLeft() ? -400.0f : 400.0f);
				}
				else if ((!this.isFacingLeft() && deg < 90)
				|| (this.isFacingLeft() && deg > 270))
				{
					this.AddTorque(this.isFacingLeft() ? 400.0f : -400.0f);
				}
			}
		}

		Vec2f vel = this.getVelocity();
		if (!this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(Vec2f(vel.x * 0.995, vel.y));
		}
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ mg = sprite.getSpriteLayer("mg");
	if (mg !is null)
	{
		mg.ResetTransform();
		mg.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 2.0f));
		mg.SetOffset(Vec2f(-6 + (this.isFacingLeft() ? -1.0f : 0.0f), -3.0f + (this.isFacingLeft() ? -0.5f : 0.5f)));
		mg.SetRelativeZ(200.0f);
	}

	Vehicle_LevelOutInAirCushion(this);

	// feed info and attach sound managers
	if (this.exists("followid"))
	{
		CBlob@ soundmanager = getBlobByNetworkID(this.get_u16("followid"));

		if (soundmanager !is null)
		{	
			soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));
			soundmanager.set_bool("isThisOnGround", this.isOnGround() && this.wasOnGround());
			soundmanager.setVelocity(this.getVelocity());
			soundmanager.set_f32("engine_RPM_M", this.get_f32("engine_RPM"));
			soundmanager.set_bool("engine_stuck", this.get_bool("engine_stuck"));
		}
	}
	if (this.exists("followid2"))
	{
		CBlob@ soundmanager = getBlobByNetworkID(this.get_u16("followid2"));

		if (soundmanager !is null)
		{	
			soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 10 : -10, -6));
			soundmanager.set_bool("isThisOnGround", this.isOnGround() && this.wasOnGround());
			soundmanager.setVelocity(this.getVelocity());
			soundmanager.set_f32("engine_RPM_M", this.get_f32("engine_RPM"));
			soundmanager.set_bool("engine_stuck", this.get_bool("engine_stuck"));
		}
	}
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 64.0f, 1.0f);

	if (this.exists("bowid"))
	{
		CBlob@ bow = getBlobByNetworkID(this.get_u16("bowid"));
		if (bow !is null)
		{
			bow.server_Die();
		}
	}
	if (this.exists("followid"))
	{
		CBlob@ soundmanager = getBlobByNetworkID(this.get_u16("followid"));

		if (soundmanager !is null)
		{	
			soundmanager.server_Die();
		}
	}
	if (this.exists("followid2"))
	{
		CBlob@ soundmanager = getBlobByNetworkID(this.get_u16("followid2"));

		if (soundmanager !is null)
		{	
			soundmanager.server_Die();
		}
	}
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
	if (blob.hasTag("boat"))
	{
		return true;
	}
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle") || blob.hasTag("bunker") || blob.hasTag("flesh"))
	{
		return false;
	}

	if (blob.hasTag("flesh") && !blob.isAttached())
	{
		return true;
	}
	else
	{;
		return Vehicle_doesCollideWithBlob_ground(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	attached.Tag("collidewithbullets");
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
	detached.Untag("collidewithbullets");
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	detached.Untag("show_gun");
	detached.Untag("can_shoot_if_attached");
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

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet);
	if (is_bullet)
			return damage *= 0.5f;

	return damage;
}


f32 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null && !gunner.isKeyPressed(key_action2) && !this.hasTag("broken"))
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos()+Vec2f(0,6);

		if ((!facing_left && aim_vec.x < 0) ||
		        (facing_left && aim_vec.x > 0))
		{
			this.getSprite().SetEmitSoundPaused(false);
			this.getSprite().SetEmitSoundVolume(1.25f);

			if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

			aim_vec.RotateBy((facing_left ? 1 : -1) * this.getAngleDegrees());

			angle = (-(aim_vec).getAngle() + 270.0f);
			angle = Maths::Max(high_angle , Maths::Min(angle , low_angle));

			not_found = false;
		}
		else
		{
			this.getSprite().SetEmitSoundPaused(true);
		}
	}

	if (not_found)
	{
		angle = Maths::Abs(Vehicle_getWeaponAngle(this, v));
		this.Tag("nogunner");
		return (facing_left ? -90 : 90);
	}

	this.Untag("nogunner");
	if (facing_left) { angle *= -1; }

	return angle;
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

		if (this.hasBlob("ammo", 1))
		{
			if (isServer()) this.TakeBlob("ammo", 1);
			ParticleAnimated("SmallExplosion3", (arrowPos + Vec2f(20, 0).RotateBy(this.get_f32("gunelevation")-90)), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
			this.getSprite().PlaySound("M60fire.ogg", 0.75f, 1.0f + XORRandom(15) * 0.01f);
		}
	}
}
