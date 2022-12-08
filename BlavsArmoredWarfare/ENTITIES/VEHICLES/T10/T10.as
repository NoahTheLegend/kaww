#include "VehicleCommon.as"
#include "Explosion.as";
#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("tank");
	this.Tag("deal_bunker_dmg");
	this.Tag("has machinegun");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 2.0f;

	Vehicle_Setup(this,
	    4750.0f, // move speed         125 is a good fast speed
	    0.7f,  // turn speed
	    Vec2f(0.0f, 0.56f), // jump out velocity
	    false);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_AddAmmo(this, v,
        325, // fire delay (ticks)
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

	{ CSpriteLayer@ w = Vehicle_addPokeyWheel(this, v, 0, Vec2f(27.0f, 3.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(20.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(12.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(4.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-4.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-12.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-20.0f, 6.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addWoodenWheel(this, v, 0, Vec2f(-29.0f, 3.0f)); if (w !is null) w.SetRelativeZ(10.0f); }

	this.getShape().SetOffset(Vec2f(0, 2));

	bool facing_left = this.getTeamNum() == 1 ? true : false;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 80, 80);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 1, 2 };
		front.animation.AddFrames(frames);
		front.SetRelativeZ(0.8f);
		front.SetOffset(Vec2f(0.0f, 0.0f));
	}

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

	// turret
	if (getNet().isServer())
	{
		CBlob@ turret = server_CreateBlob("t10turret");	

		if (turret !is null)
		{
			turret.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo( turret, "TURRET" );
			this.set_u16("turretid", turret.getNetworkID());

			turret.SetFacingLeft(facing_left);
		}

		CBlob@ bow = null;//server_CreateBlob("heavygun");	

		if (bow !is null)
		{
			bow.server_setTeamNum(this.getTeamNum());
			turret.server_AttachTo( bow, "BOW" );
			this.set_u16("bowid", bow.getNetworkID());

			bow.SetFacingLeft(facing_left);
		}
		

	{
		CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 1

		if (soundmanager !is null)
		{
			soundmanager.set_bool("manager_Type", false);
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
		
		CSpriteLayer@ tracks = this.getSprite().getSpriteLayer("tracks");
		if (tracks !is null)
		{
			if (Maths::Abs(this.getVelocity().x) > 0.3f)
			{
				if ((this.getVelocity().x) > 0)
				{
					if (!this.isFacingLeft())
					{
						if ((this.getVelocity().x) > 1.5f)
						{
							if (!tracks.isAnimation("default"))
							{
								tracks.SetAnimation("default");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
						else
						{
							if (!tracks.isAnimation("slow"))
							{
								tracks.SetAnimation("slow");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
					}
					else if (!tracks.isAnimation("reverse"))
					{
						tracks.SetAnimation("reverse");
						tracks.animation.timer = 1;
						tracks.SetFrameIndex(0);
					}
					
				}
				else{
					if (this.isFacingLeft())
					{
						if ((this.getVelocity().x) > -1.5f)
						{
							if (!tracks.isAnimation("slow"))
							{
								tracks.SetAnimation("slow");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
						else
						{
							if (!tracks.isAnimation("default"))
							{
								tracks.SetAnimation("default");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
					}
					else if (!tracks.isAnimation("reverse"))
					{
						tracks.SetAnimation("reverse");
						tracks.animation.timer = 1;
						tracks.SetFrameIndex(0);
					}
				}
			}
			else
			{
				tracks.SetAnimation("slow");
				tracks.animation.timer = 0;
			}
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

		if (this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(vel * 0.98);
		}
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