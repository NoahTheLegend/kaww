#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";

// Civilian Car logic

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("weak vehicle");
	this.Tag("pass_60sec");
	this.Tag("truck");

	Vehicle_Setup(this,
	              6000.0f, // move speed
	              0.08f,  // turn speed
	              Vec2f(0.0f, 0.51f), // jump out velocity
	              false  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_SetupGroundSound(this, v, "TechnicalTruckEngine",  // movement sound
	                         0.4f, // movement sound volume modifier   0.0f = no manipulation
	                         0.3f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(20.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-19.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }


	this.getShape().SetOffset(Vec2f(0, 0)); //0,8

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-25.0f);
}

void onTick(CBlob@ this)
{
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		CSprite@ sprite = this.getSprite();

		Vec2f vel = this.getVelocity();
		if (!this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(vel * 0.995);
		}
		else if (Maths::Abs(vel.x) > 1.5f)
		{
			if (getGameTime() % 4 == 0)
			{
				const Vec2f pos = this.getPosition() + Vec2f((this.isFacingLeft() ? 1 : -1)*(28+XORRandom(15)), -2.0f + XORRandom(18));
				CParticle@ p = ParticleAnimated("BrownParticle.png", pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), 0.25f, false);
				if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }
			}
		}
	}
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 64.0f, 1.0f);
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
	if (this.getVelocity().Length() < 1.0f || blob.hasTag("structure") || blob.hasTag("bunker")) return false;
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
void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
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
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
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
