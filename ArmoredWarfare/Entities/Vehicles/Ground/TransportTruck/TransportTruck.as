#include "VehicleCommon.as"
#include "ClassSelectMenu.as";
#include "StandardRespawnCommand.as";
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"


const string spawn_prop = "spawn_prop";

// techtruck logic

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");

	this.set_s16(spawn_prop, 30);

	InitClasses(this);

	Vehicle_Setup(this,
	              37.0f, // move speed  //103
	              0.5f,  // turn speed
	              Vec2f(0.0f, 0.57f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_SetupGroundSound(this, v, "TransportTruckEngine",  // movement sound
	                         0.35f, // movement sound volume modifier   0.0f = no manipulation
	                         0.5f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(15.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(28.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-26.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }


	this.getShape().SetOffset(Vec2f(-4, 0)); //0,8

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

	if (getNet().isServer())
	{
		if (this.getTeamNum() != 2)
		{
			u8 teamleft = getRules().get_u8("teamleft");
			u8 teamright = getRules().get_u8("teamright");
			CBlob@ loot = server_CreateBlob("armory",this.getTeamNum(),this.getPosition() - Vec2f((this.getTeamNum() == teamleft ? 64.0f : -64.0f),0.0f));
		}
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.SetFacingLeft(this.getTeamNum() == teamright);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (isOverlapping(this, caller) && !caller.isAttached())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CButton@ button = caller.CreateGenericButton("$change_class$", Vec2f(0, -2), this, SpawnCmd::buildMenu, getTranslatedString("Change class"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == SpawnCmd::buildMenu || cmd == SpawnCmd::changeClass)
	{
		onRespawnCommand(this, cmd, params);
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
						//front.setVisible(!local.isAttachedTo(this));
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
		else if (Maths::Abs(vel.x) > 2.0f)
		{
			if (getGameTime() % 4 == 0)
			{
				if (isClient())
				{
					Vec2f pos = this.getPosition();
					CMap@ map = getMap();
					
					ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(18) - 9 + (this.isFacingLeft() ? 30 : -30), XORRandom(18) - 3), getRandomVelocity(0.0f, 0.5f + XORRandom(60) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.1f), float(XORRandom(360)), 0.7f + XORRandom(70) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
				}
			}
		}
	}

	if (this.get_s16(spawn_prop) > 0 && getGameTime() % 5 == 0)
	{
		this.set_s16(spawn_prop, this.get_s16(spawn_prop) - 1);
	}


	if (this.get_s16(spawn_prop) == 0 && this.getTeamNum() != 2)
	{
		CBlob@[] blobsInRadius;
		getBlobsByName("m60", @blobsInRadius);
		getBlobsByName("techtruck", @blobsInRadius);

		if (blobsInRadius.length <= 3)
		{
			this.set_s16(spawn_prop, 250);

			if (!isServer())
				return;
			server_CreateBlob(XORRandom(100) <= 70 ? "m60" : "techtruck",this.getTeamNum(),this.getPosition() + Vec2f(64 - XORRandom(32), 0.0f));
			
		}
		else
		{
			this.set_s16(spawn_prop, 200);
		}
	}
	
	Vehicle_LevelOutInAir(this);
}

// Lose
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

    u16 i;
    for(i = 0; i < getPlayerCount(); i++) // For every player
    {
        if (getPlayer(i).getTeamNum() == this.getTeamNum()) // On my team
        {
        	if (getPlayer(i).getBlob() !is null)
        	{
        		Explode(getPlayer(i).getBlob(), 32.0f, 1.0f);
            
        		getPlayer(i).getBlob().server_Die();
        	}
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