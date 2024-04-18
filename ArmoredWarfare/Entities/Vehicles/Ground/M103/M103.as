#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"
#include "MakeDirtParticles.as"
#include "TracksHandler.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("tank");
	this.Tag("deal_bunker_dmg");
	this.Tag("engine_can_get_stuck");
	this.Tag("heavy");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    4750.0f, // move speed
	    1.0f,  // turn speed
	    Vec2f(0.0f, -1.56f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_SetupGroundSound(this, v, "TracksSound",  // movement sound
	    0.3f,   // movement sound volume modifier   0.0f = no manipulation
	    0.2f); // movement sound pitch modifier     0.0f = no manipulation

	{ CSpriteLayer@ w = Vehicle_addPokeyWheel(this, v, 0, Vec2f(26.0f,   0.75f)); if (w !is null) w.SetRelativeZ(20.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(20.0f,  4.25f)); if (w !is null) w.SetRelativeZ(10.0f); w.ScaleBy(Vec2f(1.05f,1.05f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(12.0f,  4.25f)); if (w !is null) w.SetRelativeZ(10.0f); w.ScaleBy(Vec2f(1.05f,1.05f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(4.0f,   4.25f)); if (w !is null) w.SetRelativeZ(10.0f); w.ScaleBy(Vec2f(1.05f,1.05f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-4.0f,  4.25f)); if (w !is null) w.SetRelativeZ(10.0f); w.ScaleBy(Vec2f(1.05f,1.05f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-12.0f, 4.25f)); if (w !is null) w.SetRelativeZ(10.0f); w.ScaleBy(Vec2f(1.05f,1.05f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-20.0f, 4.25f)); if (w !is null) w.SetRelativeZ(10.0f); w.ScaleBy(Vec2f(1.05f,1.05f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-28.0f, 0.25f)); if (w !is null) w.SetRelativeZ(20.0f); w.ScaleBy(Vec2f(1.075f,1.075f));}

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

	CSpriteLayer@ tracks = sprite.addSpriteLayer("tracks", sprite.getConsts().filename, 80, 80);
	if (tracks !is null)
	{
		int[] frames = { 15, 16, 17 };

		int[] frames2 = { 17, 16, 15 };

		Animation@ animdefault = tracks.addAnimation("default", 1, true);
		animdefault.AddFrames(frames);
		Animation@ animslow = tracks.addAnimation("slow", 3, true);
		animslow.AddFrames(frames);
		Animation@ animrev = tracks.addAnimation("reverse", 2, true);
		animrev.AddFrames(frames2);
		Animation@ animstopped = tracks.addAnimation("stopped", 1, true);
		animstopped.AddFrame(15);

		tracks.SetRelativeZ(50.8f);
		tracks.SetOffset(Vec2f(0.0f, 0.0f));
	}

	// attach turret & machine gun
	if (getNet().isServer())
	{
		CBlob@ turret = server_CreateBlob("m103turret");	

		if (turret !is null)
		{
			turret.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo( turret, "TURRET" );
			this.set_u16("turretid", turret.getNetworkID());
			turret.set_u16("tankid", this.getNetworkID());

			turret.SetFacingLeft(facing_left);
			//turret.SetMass(this.getMass());
		}

		{
			CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 1

			if (soundmanager !is null)
			{
				soundmanager.set_bool("manager_Type", false);
				soundmanager.set_string("engine_high", "HeavyEngineRun_high.ogg");
				soundmanager.set_string("engine_mid", "HeavyEngineRun_mid.ogg");
				soundmanager.set_string("engine_low", "HeavyEngineRun_low.ogg");
				soundmanager.set_f32("custom_pitch", 1.0f);
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
				soundmanager.set_f32("custom_pitch", 1.0f);
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
	
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		if (getGameTime()%30==0)
		{
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("TURRET");
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

		ManageTracks(this);
	}

	Vehicle_LevelOutInAir(this);

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
	Explode(this, 72.0f, 1.0f);

	this.getSprite().PlaySound("/vehicle_die");

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