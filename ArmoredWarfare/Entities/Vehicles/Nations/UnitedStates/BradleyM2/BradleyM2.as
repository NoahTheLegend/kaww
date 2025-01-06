#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"
#include "MakeDirtParticles.as"
#include "TracksHandler.as"
#include "ProgressBar.as";
#include "TeamColorCollections.as";

const int trap_cooldown = 20*30;
const u8 traps_amount = 4;

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("tank");
	this.Tag("deal_bunker_dmg");
	this.Tag("ignore fall");

	this.set_u32("traps_endtime", trap_cooldown);
	this.set_f32("traps_time", trap_cooldown); // load immediately
	this.addCommandID("release traps");

	this.set_u32("next_shoot", 0);
	this.Tag("override_timer_render");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	this.inventoryButtonPos = Vec2f(-8.0f, -12.0f);

	Vehicle_Setup(this,
	    5500.0f, // move speed
	    1.0f,  // turn speed
	    Vec2f(0.0f, -1.56f), // jump out velocity
	    true);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_SetupGroundSound(this, v, "TracksSound",  // movement sound
	    0.2f,   // movement sound volume modifier   0.0f = no manipulation
	    0.25f); // movement sound pitch modifier     0.0f = no manipulation

	{ CSpriteLayer@ w = Vehicle_addPokeyWheel(this, v, 0, Vec2f(30.0f, 6.0f)); if (w !is null) w.SetRelativeZ(-20.0f);   w.ScaleBy(Vec2f(0.75f, 0.75f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(26.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f);  w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(20.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f);  w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(14.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f);  w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(8.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f);   w.ScaleBy(Vec2f(0.78f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(2.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f);   w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-4.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f);  w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-10.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-16.0f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); w.ScaleBy(Vec2f(0.85f, 0.85f));}
	{ CSpriteLayer@ w = Vehicle_addRollerWheel(this, v, 0, Vec2f(-22.0f, 6.0f)); if (w !is null) w.SetRelativeZ(-10.0f); w.ScaleBy(Vec2f(0.75f, 0.75f));}

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
	//	front.SetOffset(Vec2f(0.0f, 3.0f));
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

		tracks.SetRelativeZ(-5.0f);
		tracks.SetOffset(Vec2f(5.0f, -3.0f));
	}

	// attach turret & machine gun
	if (getNet().isServer())
	{
		//add javlauncher
		if (getNet().isServer())
		{
			CBlob@ launcher = server_CreateBlob("launcher_javelin");	

			if (launcher !is null)
			{
				launcher.server_setTeamNum(this.getTeamNum());
				this.server_AttachTo(launcher, "JAVLAUNCHER");
				this.set_u16("launcherid", launcher.getNetworkID());
			}
		}

		CBlob@ turret = server_CreateBlob("bradleyturret");	

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
				soundmanager.set_f32("custom_pitch", 1);
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
				soundmanager.set_f32("custom_pitch", 1);
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
			if (tur is null) this.server_Die();
			else
			{
				AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("JAVLAUNCHER");
				CBlob@ launcher = ap.getOccupied();
				if (launcher !is null)
				{
					launcher.SetFacingLeft(tur.isFacingLeft());
				}
			}
		}
	}

	this.add_f32("traps_time", 1);

	if (this.get_f32("traps_time") > this.get_u32("traps_endtime")+15)
	{
		this.Untag("no_more_traps");
	}
	
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
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
						// javelin traps
						if (!this.hasTag("no_more_traps") && ap.isKeyPressed(key_action1) && this.get_f32("traps_time") > this.get_u32("traps_endtime"))
						{
							if (hooman.isMyPlayer())
							{
								ReleaseTraps(this);
							}

							if (!this.hasTag("no_more_traps")) this.getSprite().PlaySound("Missile_Launch.ogg", 1.0f, 0.5f + XORRandom(15) * 0.01f);
							this.Tag("no_more_traps");
						}
					}
				}
			}
		}

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

		if (getNet().isClient())
		{
			CPlayer@ p = getLocalPlayer();
			if (p !is null)
			{
				CBlob@ local = p.getBlob();
				if (local !is null)
				{
					CSpriteLayer@ front = this.getSprite().getSpriteLayer("front layer");
					if (front !is null)
					{
						//front.setVisible(!local.isAttachedTo(this));
					}
				}
			}
		}

		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("JAVLAUNCHER");
		if (this.get_u32("next_shoot") < getGameTime() && ap !is null)
		{
			CBlob@ launcher = ap.getOccupied();
			if (launcher !is null && launcher.hasTag("dead"))
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null && inv.getItem("mat_heatwarhead") !is null)
				{
					if (isServer()) inv.server_RemoveItems("mat_heatwarhead", 1);
					launcher.Untag("dead");
					this.set_u32("next_shoot", getGameTime()+75);
				}
			}
		}

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
		}
	}
}

void ReleaseTraps(CBlob@ this)
{
	CBitStream params;
	this.SendCommand(this.getCommandID("release traps"), params);
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 72.0f, 1.0f);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("JAVLAUNCHER");
	if (ap !is null)
	{
		CBlob@ launcher = ap.getOccupied();
		if (launcher !is null) launcher.server_Die();
	}

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
	if (cmd == this.getCommandID("release traps"))
	{
		if (this.get_f32("traps_time") <= this.get_u32("traps_endtime")) return;
		this.set_f32("traps_time", 0);

		Bar@ bars;
		if (!this.get("Bar", @bars))
		{
			Bar setbars;
    		setbars.gap = 20.0f;
    		this.set("Bar", setbars);
		}
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "traps"))
			{
				SColor team_front = getNeonColor(this.getTeamNum(), 0);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "traps", Vec2f(80.0f, 16.0f), false, Vec2f(0, 56), Vec2f(2, 2), back, team_front,
					"traps_time", this.get_u32("traps_endtime"), 0.33f, 5, 5, false, "");

    			bars.AddBar(this.getNetworkID(), setbar, true);
			}
		}
		
		if (getNet().isServer())
		{
			for (u8 i = 0; i < traps_amount; i++)
			{
				CBlob@ proj = server_CreateBlob("missiletrap", this.getTeamNum(), this.getPosition()+Vec2f(XORRandom(8)-4, 0));
				if (proj is null) return;

				proj.set_u16("heli_id", this.getNetworkID());
	
				Vec2f vel = Vec2f(-XORRandom(11)*0.1f-2.0f, 0).RotateBy(45 + 90/(traps_amount-1)*i);
				proj.setVelocity(vel);
				proj.getShape().SetGravityScale(0.025f);
				proj.server_SetTimeToDie(10.0f);
			}
		} 
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}


void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	AttachmentPoint@ pilot = blob.getAttachments().getAttachmentPointByName("DRIVER");
	if (pilot !is null && pilot.getOccupied() !is null)
	{
		CBlob@ driver_blob = pilot.getOccupied();
		if (driver_blob.isMyPlayer())
		{
			visualTimerRender(this);
		}
	}
}