#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"
#include "MakeDirtParticles.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("deal_bunker_dmg");
	this.Tag("engine_can_get_stuck");
	this.Tag("truck");
	this.Tag("respawn_if_crew_present");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    5000.0f, // move speed
	    1.0f,  // turn speed
	    Vec2f(0.0f, -2.5f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_SetupGroundSound(this, v, "ArmoryEngine",  // movement sound
	                         0.35f, // movement sound volume modifier   0.0f = no manipulation
	                         0.5f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(27.5f, 6.5f)); if (w !is null) w.SetRelativeZ(10.0f); }//w.ScaleBy(Vec2f(1.1f, 1.1f));}
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(26.0f, 6.5f)); if (w !is null) w.SetRelativeZ(-10.0f);}//w.ScaleBy(Vec2f(1.1f, 1.1f));}

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(14.5f, 6.5f)); if (w !is null) w.SetRelativeZ(10.0f); }//w.ScaleBy(Vec2f(1.1f, 1.1f));}
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(13.0f, 6.5f)); if (w !is null) w.SetRelativeZ(-10.0f);}//w.ScaleBy(Vec2f(1.1f, 1.1f));}

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-16.5f,6.5f)); if (w !is null) w.SetRelativeZ(10.0f); }//w.ScaleBy(Vec2f(1.1f, 1.1f));}
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-18.0f,6.5f)); if (w !is null) w.SetRelativeZ(-10.0f);}//w.ScaleBy(Vec2f(1.1f, 1.1f));}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	bool facing_left = this.getTeamNum() == teamright;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);

	// attach turret & machine gun
	if (getNet().isServer())
	{
		CBlob@ turret = server_CreateBlob("gradturret");	

		if (turret !is null)
		{
			turret.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo(turret, "TURRET");
			this.set_u16("turretid", turret.getNetworkID());
			turret.set_u16("tankid", this.getNetworkID());

			turret.SetFacingLeft(facing_left);
			//turret.SetMass(this.getMass());
		}
	}	
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("TURRET");
	if (this.getTickSinceCreated() > 30)
	{
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
		if (getGameTime()%30==0)
		{
			if (point !is null)
			{
				CBlob@ tur = point.getOccupied();
				if (isServer() && tur !is null) tur.server_setTeamNum(this.getTeamNum());
			}
		}

		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		Vehicle_StandardControls(this, v);
	}

	Vehicle_LevelOutInAir(this);
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 96.0f, 8.0f);
	this.getSprite().PlaySound("/vehicle_die");

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
