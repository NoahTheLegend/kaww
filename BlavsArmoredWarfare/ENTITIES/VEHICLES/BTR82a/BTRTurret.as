#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"

string[] smoke = 
{
	"Explosion.png",
	"LargeSmoke"
};

const u8 cooldown_time = 110;
const u8 recoil = 250;
const f32 damage_modifier = 0.65f;

const s16 init_gunoffset_angle = -3; // up by so many degrees

// 0 == up, 90 == sideways
const f32 high_angle = 27.0f; // upper depression limit
const f32 low_angle = 98.0f; // lower depression limit

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("apc");
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
	    "mat_14mmround", // bullet ammo config name
	    "14mm Rounds", // name for ammo selection
	    "ballista_bolt", // bullet config name
	    "sound_14mm", // fire sound
	    "EmptyFire", // empty fire sound
	    Vehicle_Fire_Style::custom,
	    Vec2f(-6.0f, -8.0f), // fire position offset
	    1); // charge time

	Vehicle_SetWeaponAngle(this, low_angle, v);
	this.set_string("autograb blob", "mat_bolts");

	this.getShape().SetOffset(Vec2f(0, -12));

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.collideWhenAttached = true;	 // we have our own map collision

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_14mmround");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 24, 80);

	if (arm !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(20);

		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(0.5f);
		}
	}

	sprite.SetZ(-100.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 80, 80);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 1, 2 };
		front.animation.AddFrames(frames);
		front.SetRelativeZ(0.8f);
		front.SetOffset(Vec2f(0.0f, 0.0f));
	}

	this.set_f32("gunelevation", (this.getTeamNum() == 1 ? 270 : 90) - init_gunoffset_angle);

	sprite.SetEmitSound("Hydraulics.ogg");
	sprite.SetEmitSoundPaused(true);
	sprite.SetEmitSoundVolume(1.25f);
}

f32 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null && !this.hasTag("broken"))
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

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
		return (facing_left ? -angle : angle);
	}

	this.Untag("nogunner");

	if (facing_left) { angle *= -1; }

	return angle;
}

void onTick(CBlob@ this)
{
	s16 currentAngle = this.get_f32("gunelevation");

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

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
				if (getRules().get_string(p.getUsername() + "_perk") == "Operator")
				{
					isOperator = true;
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

		this.getSprite().SetEmitSoundPaused(true);

		if (!this.hasTag("nogunner"))
		{
			int factor = 1;
			if (isOperator) factor = 3;

			int difference = Maths::Abs(currentAngle - targetAngle);

			if (difference <= 1) return;
			else if (difference <= factor) factor = 1;

			if (difference < 180) {
				if (currentAngle < targetAngle) currentAngle += factor;
				else currentAngle -= factor;
			} else {
				if (currentAngle < targetAngle) currentAngle += factor;
				else currentAngle += factor;
			}
			this.getSprite().SetEmitSoundPaused(false);
			this.getSprite().SetEmitSoundVolume(1.25f);

			this.set_f32("gunelevation", ((currentAngle % 360) + 360) % 360);
			Vehicle_SetWeaponAngle(this, this.get_f32("gunelevation"), v);
		}

		if (this.isFacingLeft()) this.set_f32("gunelevation", Maths::Min(360-high_angle, Maths::Max(this.get_f32("gunelevation") , 360-low_angle)));
		else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));
	}

	if (this.isFacingLeft()) this.set_f32("gunelevation", Maths::Min(360-high_angle, Maths::Max(this.get_f32("gunelevation") , 360-low_angle)));
	else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
	if (arm !is null)
	{
		arm.ResetTransform();
		arm.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 15.5f));
		arm.SetOffset(Vec2f(-9.0f, -24.0f + (this.isFacingLeft() ? -1.0f : 0.0f)));
		arm.SetRelativeZ(-101.0f);
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

		f32 anglereal = this.getAngleDegrees();
		f32 angle = this.get_f32("gunelevation") + this.getAngleDegrees();
		Vec2f vel = Vec2f(0.0f, -22.5f).RotateBy(angle);
		bullet.setVelocity(vel);
		bullet.setPosition(bullet.getPosition() + vel + Vec2f((this.isFacingLeft() ? -1 : 1)*4.0f, 0.0f));

		this.AddForce(Vec2f(this.isFacingLeft() ? (recoil*5.0f) : (-recoil*5.0f), 0.0f));

		if (isClient())
		{
			Vec2f pos = this.getPosition();
			CMap@ map = getMap();

			float _angle = this.isFacingLeft() ? -anglereal+180 : anglereal; // on turret spawn it works wrong otherwise
			_angle += -0.098f + (XORRandom(4) * 0.01f);
			
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
	v.cooldown_time = v.getCurrentAmmo().fire_delay;
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