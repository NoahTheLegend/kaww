#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("shootseat");
	this.Tag("weak vehicle");
	this.Tag("has machinegun");
	this.Tag("friendly_bullet_pass");
	this.Tag("truck");

	this.set_f32("max_angle_diff", 0.5f);

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	              7750.0f, // move speed
	              0.87f,  // turn speed
	              Vec2f(0.0f, 0.56f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_SetupGroundSound(this, v, "TechnicalTruckEngine",  // movement sound
	                         0.65f, // movement sound volume modifier   0.0f = no manipulation
	                         0.3f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(22.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(20.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(2.5f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(1.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-32.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-33.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	


	this.getShape().SetOffset(Vec2f(-4, 2));
	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);

	// Add machine gun on top
	if (getNet().isServer())
	{
		for (u8 i = 0; i < 3; i++)
		{
			CBlob@ bow = server_CreateBlob("heavygun");	

			if (bow !is null)
			{
				bow.server_setTeamNum(this.getTeamNum());
				this.server_AttachTo(bow, "BOW"+i);
				this.set_u16("bowid"+0,bow.getNetworkID());
			}
		}
	}

	this.SetFacingLeft(this.getTeamNum() == 1 ? true : false);
}

void onTick(CBlob@ this)
{
	if (getGameTime()%30==0)
	{
		for (u8 i = 0; i < 3; i++)
		{
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW"+i);
			if (point !is null)
			{
				CBlob@ tur = point.getOccupied();
				if (isServer() && tur !is null) tur.server_setTeamNum(this.getTeamNum());
			}
		}
	}
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		for (u8 i = 0; i < 5; i++)
		{
			AttachmentPoint@ pass = this.getAttachments().getAttachmentPointByName("PASSENGER"+i);
			if (pass !is null && pass.getOccupied() !is null)
			{
				CBlob@ b = pass.getOccupied();
				if (b !is null)
				{
					if (b.getAimPos().x < b.getPosition().x) b.SetFacingLeft(true);
					else b.SetFacingLeft(false);
					//if (!pass.getOccupied().hasTag("show_gun"))
					{
						if (pass.isKeyPressed(key_action1)) b.set_bool("is_a1", true);
						if (pass.isKeyJustPressed(key_action1)) b.set_bool("just_a1", true);
						b.Tag("show_gun");
						b.Tag("can_shoot_if_attached");
						//if (b.isKeyPressed(key_action1)) printf("e");
					}
				}
			}
		}

		CSprite@ sprite = this.getSprite();
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
						////front.setVisible(!local.isAttachedTo(this));
						//front.setVisible(false);
					}
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

	Vehicle_LevelOutInAir(this); // 2x
	Vehicle_LevelOutInAir(this);
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 64.0f, 1.0f);

	if (!isServer()) return;
	for (u8 i = 0; i < 3; i++)
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("BOW"+i);
		if (ap !is null && ap.getOccupied() !is null)
			ap.getOccupied().server_Die();
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
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
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
	if (hitterBlob.hasTag("bullet"))
	{
		return damage *= 0.5f;
	}
	return damage;
}