#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";

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

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(10.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-14.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	


	this.getShape().SetOffset(Vec2f(0, 2));
	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);

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
				soundmanager.set_f32("custom_pitch", 1.15f);
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
				soundmanager.set_f32("custom_pitch", 1.15f);
				soundmanager.Init();
				soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));
				
				this.set_u16("followid2", soundmanager.getNetworkID());
			}
		}
	}
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

				//if (b.isKeyPressed(key_action1)) printf("e");

				if (b.getAimPos().x < b.getPosition().x) b.SetFacingLeft(true);
				else b.SetFacingLeft(false);
			}
		}

		AttachmentPoint@ driver = this.getAttachments().getAttachmentPointByName("DRIVER");
		if (driver !is null)
		{
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
	if (hitterBlob.hasTag("bullet"))
	{
		return damage *= 0.5f;
	}
	return damage;
}