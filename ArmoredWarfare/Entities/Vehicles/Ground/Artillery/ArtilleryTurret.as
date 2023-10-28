#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "PerksCommon.as";

string[] smoke = 
{
	"Explosion.png",
	"LargeSmoke"
};

const u16 cooldown_time = 600; // 20 sec cd
const f32 damage_modifier = 1.65f;

const s16 init_gunoffset_angle = -2; // up by so many degrees
const u8 barrel_compression = 6; // max barrel movement
const u16 recoil = 180;

// 0 == up, 90 == sideways
f32 high_angle = 15.0f; // upper depression limit
f32 low_angle = 70.0f; // lower depression limit

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("blocks bullet");
	this.Tag("fireshe");
	this.Tag("pass_60sec");
	this.Tag("artillery");

	this.set_f32("damage_modifier", damage_modifier);

	Vehicle_Setup(this,
	    0.0f, // move speed
	    0.3f,  // turn speed
	    Vec2f(0.0f, 0.56f), // jump out velocity
	    true);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_AddAmmo(this, v,
	    cooldown_time, // fire delay (ticks)
	    1, // fire bullets amount
	    1, // fire cost
	    "mat_smallbomb", // bullet ammo config name
	    "Small Bombs", // name for ammo selection
	    "ballista_bolt", // bullet config name
	    //"sound_100mm", // fire sound
		"sound_128mm",
	    "EmptyFire", // empty fire sound
	    Vehicle_Fire_Style::custom,
	    Vec2f(-6.0f, -4.0f), // fire position offset
	    1); // charge time

	Vehicle_SetWeaponAngle(this, low_angle, v);

	this.getShape().SetOffset(Vec2f(3, -10));

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.collideWhenAttached = true;	 // we have our own map collision

	this.set_f32("old_angle", 180);

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_smallbomb");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 32, 64);

	sprite.SetZ(50);

	if (arm !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = arm.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(2);
			anim.SetFrameIndex(0);
		}
		
		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(49.5f);
			arm.SetOffset(Vec2f(-80.0f, -10.0f));
		}
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.set_f32("gunelevation", (this.getTeamNum() == teamright ? 270 : 90) - init_gunoffset_angle);
}

f32 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null && !gunner.isKeyPressed(key_action2) && !this.hasTag("broken"))
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

		if ((!facing_left && aim_vec.x < 0) ||
		        (facing_left && aim_vec.x > 0))
		{
			if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

			aim_vec.RotateBy((facing_left ? 1 : -1) * this.getAngleDegrees());

			angle = (-(aim_vec).getAngle() + 270.0f);
			angle = Maths::Max(high_angle , Maths::Min(angle , low_angle));

			not_found = false;
		}
	}

	if (not_found)
	{
		angle = Maths::Abs(Vehicle_getWeaponAngle(this, v));
		this.Tag("nogunner");
		return (facing_left ? -angle : angle);
	}

	this.Untag("nogunner");

	if (facing_left) { angle *= -1; }

	return angle;
}

void onTick(CBlob@ this)
{
	s16 currentAngle = this.get_f32("gunelevation");

	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	CSprite@ sprite = this.getSprite();
	if (this.getTickSinceCreated() == 1 || this.hasTag("pink"))
	{
		if (sprite !is null)
		{
			CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
			if (arm !is null)
			{
				arm.SetFrameIndex(this.hasTag("pink") ? 1 : 0);
				arm.SetAnimation("default");
			}
			if (!this.hasTag("pink"))
				sprite.SetFrameIndex(2);
			else 
			{
				sprite.SetFrameIndex(1);
				sprite.SetAnimation("default");
				this.Untag("pink");
			}
		}
	}

	if (getGameTime() % 5 == 0)
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW");
		if (point !is null && point.getOccupied() !is null)
		{
			CBlob@ tur = point.getOccupied();
			tur.SetFacingLeft(this.isFacingLeft());
			if (isServer()) tur.server_setTeamNum(this.getTeamNum());
		}
	}

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		bool broken = this.hasTag("broken");
		if (!broken) Vehicle_StandardControls(this, v);

		if (v.cooldown_time > 0)
		{
			v.cooldown_time--;
		}

		f32 angle = getAngle(this, v.charge, v);

		s16 targetAngle;
		bool isOperator = false;
		
		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null && !broken)
		{
			Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();
			
			CPlayer@ p = gunner.getOccupied().getPlayer();
			if (p !is null)
			{
				if (hasPerk(p, Perks::operator))
				{
					isOperator = true;
					high_angle = 12.5f;
					low_angle = 75.0f;
				}
				else
				{
					high_angle = 15.0f; // upper depression limit
					low_angle = 70.0f; // lower depression limit
				}
			}

			bool facing_left = this.isFacingLeft();
		}

		if (angle < 0)
		{
			targetAngle = 360 + angle; // facing left
		}
		else
		{
			targetAngle = angle;
		}

		if (!this.hasTag("nogunner"))
		{
			//if (getGameTime()%2==0)
			{
				int factor = 1;
				if (isOperator) factor = 2;

				int difference = Maths::Abs(currentAngle - targetAngle);

				if (difference > 1)
				{	
					if (difference < 180) {
						if (currentAngle < targetAngle) currentAngle += factor;
						else currentAngle -= factor;
					} else {
						if (currentAngle < targetAngle) currentAngle += factor;
						else currentAngle += factor;
					}
					this.set_f32("gunelevation", ((currentAngle % 360.0f) + 360.0f) % 360.0f);
					Vehicle_SetWeaponAngle(this, this.get_f32("gunelevation"), v);
				}
				else if (difference <= factor)
				{
					factor = 1;
				}
			}
		}

		if (this.isFacingLeft()) this.set_f32("gunelevation", Maths::Min(360.0f-high_angle, Maths::Max(this.get_f32("gunelevation") , 360.0f-low_angle)));
		else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));
	}

	if (this.isFacingLeft()) this.set_f32("gunelevation", Maths::Min(360.0f-high_angle, Maths::Max(this.get_f32("gunelevation") , 360.0f-low_angle)));
	else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));

	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
	if (arm !is null)
	{
		arm.ResetTransform();
		arm.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 18.0f));
		arm.SetOffset(Vec2f(-8.0f + (this.isFacingLeft() ? -1.0f : 0.0f), -28.0f + (this.isFacingLeft() ? -0.5f : 0.5f)));
		arm.SetOffset(arm.getOffset() - Vec2f(-barrel_compression + Maths::Min(v.getCurrentAmmo().fire_delay - v.cooldown_time, barrel_compression), 0).RotateBy(this.isFacingLeft() ? 90+this.get_f32("gunelevation") : 90-this.get_f32("gunelevation")));
		arm.SetRelativeZ(-20.0f);
	}
}


void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 48.0f);
	this.set_f32("map_damage_ratio", 0.25f);
	
	Explode(this, 156.0f, 2.0f);
	if (isClient())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
		
		for (int i = 0; i < (v_fastrender ? 12 : 32); i++)
		{
			ParticleAnimated(smoke[XORRandom(smoke.length)], (this.getPosition() + Vec2f((this.isFacingLeft() ? -1 : 1)*60.0f, 0.0f)) + Vec2f(XORRandom(36) - 18, XORRandom(36) - 18), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.16f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 9 + XORRandom(5), XORRandom(70) * -0.00005f, true);
			
			if (i%3!=0 || this.hasTag("apc")) continue;
			makeGibParticle(
			"EmptyShell",               		// file name
			this.getPosition(),                 // position
			(Vec2f(0.0f,-0.5f) + getRandomVelocity(180, 5, 360)), // velocity
			0,                                  // column
			0,                                  // row
			Vec2f(16, 16),                      // frame size
			0.5f,                               // scale?
			0,                                  // ?
			"ShellCasing",                      // sound
			this.get_u8("team_color"));         // team number
		}
	}

	this.Tag("exploded");
	if (!v_fastrender) this.getSprite().Gib();
}

// Blow up
void onDie(CBlob@ this)
{
	DoExplosion(this);
	Explode(this, 64.0f, 1.0f);

	this.getSprite().PlaySound("/turret_die");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire blob"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		
		// check for valid ammo
		if (blob.getName() != v.getCurrentAmmo().bullet_name)
		{
			return;
		}
		
		Vehicle_onFire(this, v, blob, charge);
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	v.firing = v.firing || isActionPressed;

	bool hasammo = v.getCurrentAmmo().loaded_ammo > 0;

	u8 charge = v.charge;
	if ((charge > 0 || isActionPressed) && hasammo)
	{
		if (charge < v.getCurrentAmmo().max_charge_time && isActionPressed)
		{
			charge++;
			v.charge = charge;

			chargeValue = charge;
			return false;
		}
		chargeValue = charge;
		return true;
	}

	return false;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{
	this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound, 1.75f, 0.8f);
	if (bullet !is null)
	{
		bullet.Tag("shell");
		u8 charge_prop = _charge;

		f32 angle = this.get_f32("gunelevation") + this.getAngleDegrees();
		Vec2f vel = Vec2f(0.0f, -45.0f+XORRandom(16)*0.1f).RotateBy(angle);
		bullet.setVelocity(vel);
		Vec2f bullet_pos = this.getPosition()+Vec2f(this.isFacingLeft()?-12.0f:12.0f, -5) + Vec2f((this.isFacingLeft() ? -1 : 1)*16.0f, -7.0f).RotateBy((this.isFacingLeft()?angle+90:angle-90));
		Vec2f pos = this.getPosition()+Vec2f(this.isFacingLeft()?-12.0f:12.0f, -5) + Vec2f((this.isFacingLeft() ? -1 : 1)*50.0f, -7.0f).RotateBy((this.isFacingLeft()?angle+90:angle-90));
		bullet.setPosition(bullet_pos);
		bullet.Tag("rpg");
		bullet.Tag("artillery");

		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null)
		{
			CBlob@ b = gunner.getOccupied();
			if (b.getPlayer() !is null)
			{
				bullet.set_u16("ownerplayer_id", b.getPlayer().getNetworkID());
				bullet.set_u16("ownerblob_id", b.getNetworkID());
				b.Tag("camera_offset");
				bullet.server_SetPlayer(b.getPlayer());
			}
		}

		bullet.AddScript("ShrapnelOnDie.as");
		bullet.set_u8("shrapnel_count", 10+XORRandom(7));
		bullet.set_f32("shrapnel_vel", 9.0f+XORRandom(5)*0.1f);
		bullet.set_f32("shrapnel_vel_random", 1.5f+XORRandom(16)*0.1f);
		bullet.set_Vec2f("shrapnel_offset", Vec2f(0,-1));
		bullet.set_f32("shrapnel_angle_deviation", 10.0f);
		bullet.set_f32("shrapnel_angle_max", 45.0f+XORRandom(21));

		CBlob@ hull = getBlobByNetworkID(this.get_u16("tankid"));

		bool not_found = true;

		if (hull !is null)
		{
			hull.AddForce(Vec2f(hull.isFacingLeft() ? (recoil*5.0f) : (recoil*-5.0f), 0.0f));
		}

		if (isClient())
		{
			bool facing = this.isFacingLeft();
			for (int i = 0; i < 16; i++)
			{
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(10+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2 + XORRandom(2), -0.0031f, true);
				//ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 6 + XORRandom(3), -0.0031f, true);
			}

			for (int i = 0; i < 6; i++)
			{
				float angle = Maths::ATan2(vel.y, vel.x) + 20;
				ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle2 = Maths::ATan2(vel.y, vel.x) - 20;
				ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle3 = Maths::ATan2(vel.y, vel.x) + 10;
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle4 = Maths::ATan2(vel.y, vel.x) - 10;
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);

				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 10 + XORRandom(3), -0.0031f, true);
				ParticleAnimated("Explosion", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.0065f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 2, -0.0031f, true);
			}
		}

		makeGibParticle(
		"EmptyShell",               		// file name
		this.getPosition(),                 // position
		(Vec2f(0.0f,-0.5f) + getRandomVelocity(90, 2, 360)), // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		0.5f,                               // scale?
		0,                                  // ?
		"ShellCasing",                      // sound
		this.get_u8("team_color"));         // team number
	}	

	v.last_charge = _charge;
	v.charge = 0;
	v.cooldown_time = v.getCurrentAmmo().fire_delay;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle") || blob.hasTag("boat"))
	{
		return true;
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

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player"))
	{
		attached.Tag("covered");
		attached.Tag("artillery");
	}
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	attachedPoint.offsetZ = 1.0f;
	this.getShape().SetStatic(true);
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("player"))
	{
		detached.Untag("covered");
		detached.Untag("artillery");
		detached.Untag("increase_max_zoom");
	}
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	this.getShape().SetStatic(false);
	Vehicle_onDetach(this, v, detached, attachedPoint);
}