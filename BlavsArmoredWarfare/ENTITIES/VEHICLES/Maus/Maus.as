#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("tank");
	this.Tag("deal_bunker_dmg");

	if (XORRandom(5) == 0)
	{
		this.setInventoryName("Panzerkampfwagen VIII Maus 'Minnie Mouse'");
		this.Tag("pink");
	}

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    115.0f, // move speed         125 is a good fast speed
	    0.9f,  // turn speed
	    Vec2f(0.0f, 0.56f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_AddAmmo(this, v,
        360, // fire delay (ticks)
        1, // fire bullets amount
        1, // fire cost
        "mat_arrows", // bullet ammo config name
        "Arrows", // name for ammo selection
        "arrow", // bullet config name
        "BowFire", // fire sound
        "EmptyFire" // empty fire sound
       );

	v.charge = 400;

	Vehicle_SetupGroundSound(this, v, "TankEngine_maus",  // movement sound
	    1.0f,   // movement sound volume modifier   0.0f = no manipulation
	    1.4f); // movement sound pitch modifier     0.0f = no manipulation

	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(31.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(23.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(15.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(7.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-1.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-9.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-17.0f, 7.0f)); if (w !is null) w.SetRelativeZ(-0.89f); }

	this.getShape().SetOffset(Vec2f(0, 1));

	bool facing_left = this.getTeamNum() == 1 ? true : false;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(-100.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", "MausFrontLayer.png", 64, 8);
	if (front !is null)
	{
		if (!this.hasTag("pink"))
		{
			front.SetFrameIndex(0);
			sprite.SetFrameIndex(0);
		}
		else
		{
			front.SetFrameIndex(1);
			sprite.SetFrameIndex(1);
		}
		front.SetRelativeZ(-0.88f);
		front.SetOffset(Vec2f(6.0f, 5.0f));
	}
}

void onTick(CBlob@ this)
{
	this.set_Vec2f("backside_hitpos", this.getPosition()+Vec2f(this.isFacingLeft() ? 24.0f : -24.0f, 0));

	if (this.getTickSinceCreated() == 1)
	{
		// turret
		if (getNet().isServer())
		{
			CBlob@ turret = server_CreateBlobNoInit("mausturret");	

			if (turret !is null)
			{
				if (this.hasTag("pink")) turret.Tag("pink");
				turret.Init();
				turret.server_setTeamNum(this.getTeamNum());
				this.server_AttachTo( turret, "TURRET" );
				this.set_u16("turretid", turret.getNetworkID());

				turret.SetFacingLeft(this.isFacingLeft());
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

		if (this.isOnMap() && Maths::Abs(this.getVelocity().x) > 2.5f)
		{
			if (getGameTime() % 4 == 0)
			{
				if (isClient())
				{
					Vec2f pos = this.getPosition();
					CMap@ map = getMap();
					
					//ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(18) - 9 + (this.isFacingLeft() ? 30 : -30), XORRandom(18) - 3), getRandomVelocity(0.0f, 0.5f + XORRandom(60) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.1f), float(XORRandom(360)), 0.7f + XORRandom(70) * 0.01f, 3 + XORRandom(3), XORRandom(70) * -0.00005f, true);
				}
			}
		}

		if (isClient() && getGameTime() % 20 == 0)
		{
			Vec2f pos = this.getPosition();
			CMap@ map = getMap();
			
			//ParticleAnimated("SmallSmoke1", pos + Vec2f((this.isFacingLeft() ? 1 : -1)*(28+XORRandom(15)),0.0f) + Vec2f(XORRandom(10) - 5, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(50) * 0.01f, 90) + Vec2f(0.0f,-0.15f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 5 + XORRandom(8), XORRandom(70) * -0.00005f, true);
		}
	}

	// Crippled
	if (this.getHealth() <= this.getInitialHealth() * 0.25f)
	{
		if (getGameTime() % 4 == 0 && XORRandom(5) == 0)
		{
			const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius()*0.4f, 360);
			CParticle@ p = ParticleAnimated("BlackParticle.png", pos, Vec2f(0,0), -0.5f, 1.0f, 5.0f, 0.0f, false);
			if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

			Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

			ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);

			if (isClient() && XORRandom(2) == 0)
			{
				Vec2f pos = this.getPosition();
				CMap@ map = getMap();
				
				ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(60) - 30, XORRandom(48) - 24), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, 90), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 7 + XORRandom(8), XORRandom(70) * -0.00005f, true);
			}
		}
	}

	Vehicle_LevelOutInAir(this);
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 64.0f, 1.0f);

	this.getSprite().PlaySound("/vehicle_die");

	for (int i = 0; i < 10; i++)
	{
		ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(120) - 60, XORRandom(20) - 10), getRandomVelocity(0.0f, XORRandom(25) * 0.005f, 360) + Vec2f((XORRandom(5) - 2) * 0.6f, 0.4f), float(XORRandom(360)), 1.0f + XORRandom(40) * 0.01f, 6 + XORRandom(6), XORRandom(30) * -0.001f, true);
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
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}