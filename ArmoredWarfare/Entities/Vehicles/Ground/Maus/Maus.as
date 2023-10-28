#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"
#include "TracksHandler.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("tank");
	this.Tag("deal_bunker_dmg");
	this.Tag("reduce_upper_dmg");
	this.Tag("engine_can_get_stuck");
	this.Tag("heavy");

	this.set_u8("type", this.getName() == "maus" ? 0 : this.getName() == "pinkmaus" ? 1 : 2);

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    3600.0f, // move speed         125 is a good fast speed
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

	Vehicle_SetupGroundSound(this, v, "TracksSound",  // movement sound
	    0.3f,   // movement sound volume modifier   0.0f = no manipulation
	    0.2f); // movement sound pitch modifier     0.0f = no manipulation

	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(35.0f,  6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(28.0f,  6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(20.0f,  6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(12.0f,  6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(4.0f,   6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-4.0f,  6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-12.0f, 6.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-18.0f, 5.5f)); if (w !is null) w.SetRelativeZ(-111.89f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-24.0f, 4.0f)); if (w !is null) {w.SetRelativeZ(-111.89f); w.ScaleBy(Vec2f(0.925f,0.925f));}}

	this.getShape().SetOffset(Vec2f(0, 1));

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	bool facing_left = this.getTeamNum() == teamright;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(-100.0f);
	CSpriteLayer@ tracks = sprite.addSpriteLayer("tracks", "MausTracks.png", 96, 16);
	if (tracks !is null)
	{
		int[] frames = { 0, 1, 2 };

		int[] frames2 = { 2, 1, 0 };

		Animation@ animdefault = tracks.addAnimation("default", 1, true);
		animdefault.AddFrames(frames);
		Animation@ animslow = tracks.addAnimation("slow", 3, true);
		animslow.AddFrames(frames);
		Animation@ animrev = tracks.addAnimation("reverse", 2, true);
		animrev.AddFrames(frames2);
		Animation@ animstopped = tracks.addAnimation("stopped", 1, true);
		animstopped.AddFrame(15);

		tracks.SetRelativeZ(1.0f);
		tracks.SetOffset(Vec2f(9.0f, 5.0f));
	}

	if (getNet().isServer())
	{
		{
			CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 1

			if (soundmanager !is null)
			{
				soundmanager.set_bool("manager_Type", false);
				soundmanager.set_string("engine_high", "HeavyEngineRun_high.ogg");
				soundmanager.set_string("engine_mid", "HeavyEngineRun_mid.ogg");
				soundmanager.set_string("engine_low", "HeavyEngineRun_low.ogg");
				soundmanager.set_f32("custom_pitch", 0.875f);
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
				soundmanager.set_string("engine_high", "HeavyEngineRun_high.ogg");
				soundmanager.set_string("engine_mid", "HeavyEngineRun_mid.ogg");
				soundmanager.set_string("engine_low", "HeavyEngineRun_low.ogg");
				soundmanager.set_f32("custom_pitch", 0.875f);
				soundmanager.Init();
				soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));
				
				this.set_u16("followid2", soundmanager.getNetworkID());
			}
		}
	}
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
	
	if (this.getTickSinceCreated() == 3)
	{
		// turret
		if (getNet().isServer())
		{
			CBlob@ turret = server_CreateBlobNoInit(this.get_u8("type") == 0 ? "mausturret" : this.get_u8("type") == 1 ? "pinkmausturret" : "desertmausturret");	

			if (turret !is null)
			{
				turret.Init();
				turret.server_setTeamNum(this.getTeamNum());
				this.server_AttachTo( turret, "TURRET" );
				this.set_u16("turretid", turret.getNetworkID());
				turret.set_u16("tankid", this.getNetworkID());
				
				turret.SetFacingLeft(this.isFacingLeft());
				//turret.SetMass(this.getMass());
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

	Vehicle_LevelOutInAir(this);

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

	ManageTracks(this);
}

// Blow up
void onDie(CBlob@ this)
{
	if (this.hasTag("dead")) return;
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
		return damage * 1.2f;
	}
	if (customData >= HittersAW::bullet) return 0;
	return damage;
}