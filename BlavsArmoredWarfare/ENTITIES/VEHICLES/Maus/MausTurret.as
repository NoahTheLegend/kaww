#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"

string[] smoke = 
{
	"Explosion.png",
	"LargeSmoke"
};

const u16 cooldown_time = 320;
const f32 damage_modifier = 1.25f;

const s16 init_gunoffset_angle = -2; // up by so many degrees

// 0 == up, 90 == sideways
const f32 high_angle = 76.5f; // upper depression limit
const f32 low_angle = 99.0f; // lower depression limit

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("blocks bullet");

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
	    "mat_bolts", // bullet ammo config name
	    "Ballista Bolts", // name for ammo selection
	    "ballista_bolt", // bullet config name
	    //"sound_100mm", // fire sound
		"sound_128mm",
	    "EmptyFire", // empty fire sound
	    Vehicle_Fire_Style::custom,
	    Vec2f(-6.0f, -4.0f), // fire position offset
	    1); // charge time

	Vehicle_SetWeaponAngle(this, low_angle, v);
	this.set_string("autograb blob", "mat_bolts");

	this.getShape().SetOffset(Vec2f(5, -12));

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.collideWhenAttached = true;	 // we have our own map collision

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_bolts");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 16, 48);

	if (arm !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = arm.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(10);
			anim.AddFrame(11);
		}
		
		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(110.5f);
			arm.SetOffset(Vec2f(-80.0f, -7.0f));
		}
	}

	this.set_f32("gunelevation", (this.getTeamNum() == 1 ? 270 : 90) - init_gunoffset_angle);
}

f32 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null)
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
	if (this.isFacingLeft() && !this.hasTag("facing left"))
	{
		this.getShape().SetOffset(Vec2f(8.0f, -15.0f));
		this.Tag("facing left");
		this.Untag("facing right");
	}
	else if (!this.isFacingLeft() && !this.hasTag("facing right"))
	{
		this.getShape().SetOffset(Vec2f(-8.0f, -15.0f));
		this.Untag("facing left");
		this.Tag("facing right");
	}

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		Vehicle_StandardControls(this, v);

		if (v.cooldown_time > 0)
		{
			v.cooldown_time--;
		}

		f32 angle = getAngle(this, v.charge, v);
		s16 targetAngle;

		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null)
		{
			Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

			bool facing_left = this.isFacingLeft();

			//if (aim_vec.x > 0)
			//{
			//	this.SetFacingLeft(true);
			//}
			//else {
			//	this.SetFacingLeft(false);
			//}
		}

		if (angle < 0) //
		{
			targetAngle = 360 + angle; // facing left
		}
		else
		{
			targetAngle = angle;
		}

		s16 currentAngle = this.get_f32("gunelevation");

		if (!this.hasTag("nogunner"))
		{
			if (Maths::Abs(currentAngle - targetAngle) <= 1) return;

			if (Maths::Abs(currentAngle - targetAngle) < 180) {
				if (currentAngle < targetAngle) currentAngle++;
				else currentAngle--;
			} else {
				if (currentAngle < targetAngle) currentAngle--;
				else currentAngle++;
			}

			this.set_f32("gunelevation", ((currentAngle % 360) + 360) % 360);
			Vehicle_SetWeaponAngle(this, this.get_f32("gunelevation"), v);
		}

		if (this.isFacingLeft())
		{
			this.set_f32("gunelevation", Maths::Min(360-high_angle, Maths::Max(this.get_f32("gunelevation") , 360-low_angle)));
		}
		else
		{
			this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));
		}
		//this.set_f32("gunelevation", Maths::Min(360-high_angle , this.get_f32("gunelevation")));

		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.ResetTransform();
			arm.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 8.0f));
			arm.SetOffset(Vec2f(-19.0f + (this.isFacingLeft() ? -1.0f : 0.0f), -20.5f + (this.isFacingLeft() ? -0.5f : 0.5f)));
			arm.SetRelativeZ(-20.0f);
		}

		if (getNet().isClient())
		{
			CPlayer@ p = getLocalPlayer();
			if (p !is null)
			{
				CBlob@ local = p.getBlob();
				if (local !is null)
				{
					CSpriteLayer@ front = sprite.getSpriteLayer("front layer");
					if (front !is null)
					{
						//front.setVisible(!local.isAttachedTo(this));
					}
				}
			}
		}
	}
}

// Blow up
void onDie(CBlob@ this)
{
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
	this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);
	if (bullet !is null)
	{
		u8 charge_prop = _charge;

		f32 angle = this.get_f32("gunelevation") + this.getAngleDegrees();
		Vec2f vel = Vec2f(0.0f, -27.5f).RotateBy(angle);
		bullet.setVelocity(vel);
		bullet.setPosition(bullet.getPosition() + (vel*1.5) + Vec2f((this.isFacingLeft() ? -1 : 1)*12.0f, 5.0f));

		if (isClient())
		{
			Vec2f pos = this.getPosition();
			CMap@ map = getMap();
			
			for (int i = 0; i < 12; i++)
			{
				ParticleAnimated(smoke[XORRandom(smoke.length)], (bullet.getPosition() + Vec2f((this.isFacingLeft() ? -1 : 1)*12.0f, 0.0f)) + Vec2f(XORRandom(36) - 18, XORRandom(36) - 18), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.16f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 9 + XORRandom(5), XORRandom(70) * -0.00005f, true);
			}
		}

		makeGibParticle(
		"EmptyShell",               		// file name
		this.getPosition(),                 // position
		(Vec2f(0.0f,-0.5f) + getRandomVelocity(90, 5, 360)), // velocity
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
	v.cooldown_time = cooldown_time;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle"))
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
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	this.getShape().SetStatic(false);
	Vehicle_onDetach(this, v, detached, attachedPoint);
}