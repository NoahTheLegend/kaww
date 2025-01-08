#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"
#include "MakeDirtParticles.as"
#include "TracksHandler.as"
#include "TeamColorCollections.as";
#include "ProgressBar.as";

const int smoke_cooldown = 90*30;
const u8 smoke_amount = 40;

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("tank");
	this.Tag("deal_bunker_dmg");
	this.Tag("engine_can_get_stuck");
	this.Tag("blocks bullet");
	this.Tag("heavy");
	this.Tag("reduce_upper_dmg_only_front");
	this.Tag("override_timer_render");

	this.set_u32("smoke_endtime", smoke_cooldown);
	this.set_f32("smoke_time", smoke_cooldown); // load immediately
	this.addCommandID("release smoke");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    7500.0f, // move speed
	    1.0f,  // turn speed
	    Vec2f(0.0f, -1.56f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_SetupGroundSound(this, v, "TracksSound",  // movement sound
	    0.3f,   // movement sound volume modifier   0.0f = no manipulation
	    0.2f); // movement sound pitch modifier     0.0f = no manipulation

	{ CSpriteLayer@ w = Vehicle_addPokeyWheel(this, v, 0, Vec2f(37.0f, 3.0f)); if (w !is null) w.SetRelativeZ(-20.0f); w.ScaleBy(Vec2f(0.9f, 0.9f)); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(30.0f, 4.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(23.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(16.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(9.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(2.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-5.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-12.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-19.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-26.0f, 4.5f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-33.0f, 2.0f)); if (w !is null) w.SetRelativeZ(-20.0f); w.ScaleBy(Vec2f(0.9f, 0.9f)); }

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

	CSpriteLayer@ tracks = sprite.addSpriteLayer("tracks", sprite.getConsts().filename, 96, 32);
	if (tracks !is null)
	{
		int[] frames = { 36, 37, 38 };

		int[] frames2 = { 38, 37, 36 };

		Animation@ animdefault = tracks.addAnimation("default", 1, true);
		animdefault.AddFrames(frames);
		Animation@ animslow = tracks.addAnimation("slow", 3, true);
		animslow.AddFrames(frames);
		Animation@ animrev = tracks.addAnimation("reverse", 2, true);
		animrev.AddFrames(frames2);
		Animation@ animstopped = tracks.addAnimation("stopped", 1, true);
		animstopped.AddFrame(36);

		tracks.SetRelativeZ(-5.0f);
		tracks.SetOffset(Vec2f(2.0f, 8.0f));
	}

	// attach turret & machine gun
	if (getNet().isServer())
	{
		CBlob@ turret = server_CreateBlob("m1abramsturret");	

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

		AttachmentPoint@[] aps;
		this.getAttachmentPoints(@aps);

		for (int a = 0; a < aps.length; a++)
		{
			AttachmentPoint@ ap = aps[a];
			if (ap !is null)
			{
				CBlob@ hooman = ap.getOccupied();
				if (hooman !is null && hooman.isMyPlayer())
				{
					if (ap.name == "DRIVER")
					{
						if (!this.hasTag("no_more_smoke") && ap.isKeyPressed(key_action1) && this.get_f32("smoke_time") >= this.get_u32("smoke_endtime"))
						{
							ReleaseSmoke(this);

							if (!this.hasTag("no_more_smoke")) this.getSprite().PlaySound("smoke_release.ogg", 1.0f, 1.0f + XORRandom(15) * 0.01f);
							this.Tag("no_more_smoke");
						}
					}
				}
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("release smoke"))
	{
		if (this.get_f32("smoke_time") < this.get_u32("smoke_endtime")) return;
		this.set_f32("smoke_time", 0);

		Bar@ bars;
		if (!this.get("Bar", @bars))
		{
			Bar setbars;
    		setbars.gap = 20.0f;
    		this.set("Bar", setbars);
		}
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "smoke"))
			{
				SColor team_front = getNeonColor(this.getTeamNum(), 0);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "smoke", Vec2f(80.0f, 16.0f), false, Vec2f(0, 56), Vec2f(2, 2), back, team_front,
					"smoke_time", this.get_u32("smoke_endtime"), 0.33f, 5, 5, false, "");

    			bars.AddBar(this.getNetworkID(), setbar, true);
			}
		}
		
		for (u8 i = 0; i < smoke_amount; i++)
		{
			Vec2f vel = Vec2f(15.0f+i, 0).RotateBy(XORRandom(180)+180);
			vel.y *= 0.66f;
			CParticle@ p = ParticleAnimated("LargeSmokeWhite.png",
				this.getPosition(),
					vel,
						XORRandom(360),
							5.5f+XORRandom(26)*0.1f, 45 + XORRandom(16), 0.0025f+XORRandom(75)*0.0001f, false);
			if (p !is null)
			{
				p.collides = true;
				p.Z = 550.0f;
				p.fastcollision = true;
				p.deadeffect = -1;
				p.damping = 0.8f+XORRandom(51)*0.001f;
				p.bounce = 0.1f;
				p.lighting_delay = 30;
			}
		}
	}
}

void ReleaseSmoke(CBlob@ this)
{
	CBitStream params;
	this.SendCommand(this.getCommandID("release smoke"), params);
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}