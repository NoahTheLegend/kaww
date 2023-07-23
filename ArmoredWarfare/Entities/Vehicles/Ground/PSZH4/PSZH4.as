#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("apc");
	this.Tag("deal_bunker_dmg");
	this.Tag("engine_can_get_stuck");
	this.Tag("ignore fall");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    7500.0f, // move speed 125
	    0.45f,  // turn speed
	    Vec2f(0.0f, 0.56f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_AddAmmo(this, v,
        80, // fire delay (ticks)
        1, // fire bullets amount
        1, // fire cost
        "mat_14mmround", // bullet ammo config name
        "mat_14mmround", // name for ammo selection
        "material14mmround", // bullet config name
        "sound_14mm", // fire sound
        "EmptyFire" // empty fire sound
       );

	v.charge = 400;

	Vehicle_SetupGroundSound(this, v, "TechnicalTruckEngine",  // movement sound
	                         0.3f, // movement sound volume modifier   0.0f = no manipulation
	                         0.5f // movement sound pitch modifier     0.0f = no manipulation
	                        );


	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(16.5f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(14.0f, 6.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-19.5f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-21.0f, 6.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	this.getShape().SetOffset(Vec2f(0, 2));

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	bool facing_left = this.getTeamNum() == teamright;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);
	//CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 80, 80);
	//if (front !is null)
	//{
	//	front.addAnimation("default", 0, false);
	//	int[] frames = { 0, 1, 2 };
	//	front.animation.AddFrames(frames);
	//	front.SetRelativeZ(0.8f);
	//	front.SetOffset(Vec2f(0.0f, 0.0f));
	//}

	// turret
	if (getNet().isServer())
	{
		CBlob@ turret = server_CreateBlob("pszh4turret");	

		if (turret !is null)
		{
			turret.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo( turret, "TURRET" );
			this.set_u16("turretid", turret.getNetworkID());
			turret.set_u16("tankid", this.getNetworkID());

			turret.SetFacingLeft(facing_left);
			//turret.SetMass(this.getMass());
		}
	}	
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	MakeLoadAmmoButton(this, caller, Vec2f(0,0), v);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() > 30)
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("TURRET");
		if (point !is null)
		{
			CBlob@ tur = point.getOccupied();
			if (isServer())
			{
				if (tur is null) this.server_Die();
			}
		}
	}
	
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("TURRET");
		if (point !is null)
		{
			CBlob@ tur = point.getOccupied();
			if (isServer() && tur !is null) tur.server_setTeamNum(this.getTeamNum());
		}
		
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		Vehicle_StandardControls(this, v);

		if (isServer() && this.isInWater())
		{
			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
			if (ap !is null && ap.getOccupied() is null && (getGameTime() + this.getNetworkID())%120 == 0)
			{
				if (isServer()) this.server_Hit(this, this.getPosition(), Vec2f(0,0), this.getInitialHealth()/(20+XORRandom(11)), Hitters::builder);
			}
		}
	}

	Vehicle_LevelOutInAir(this);
	Vehicle_DontRotateInWater(this);
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 64.0f, 1.0f);

	this.getSprite().PlaySound("/vehicle_die");

	if (this.exists("bowid"))
	{
		CBlob@ bow = getBlobByNetworkID(this.get_u16("bowid"));
		if (bow !is null)
		{
			bow.server_Die();
		}
	}
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("TURRET");
	if (point !is null)
	{
		CBlob@ tur = point.getOccupied();
		if (isServer() && tur !is null) tur.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("boat"))
	{
		return true;
	}
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
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
	if (attached.hasTag("player")) attached.Tag("covered");
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
	if (detached.hasTag("player")) detached.Untag("covered");
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 0.75f;
	}
	if (customData == HittersAW::bullet)
		return damage*0.2f;
	if (customData == HittersAW::heavybullet || customData == HittersAW::aircraftbullet)
		return damage * 2.25f;

	return damage;
}