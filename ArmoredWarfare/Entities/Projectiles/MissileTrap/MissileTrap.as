
#include "Hitters.as";
#include "MakeDustParticle.as";

const f32 distance = 256.0f; // 32 tiles

void onInit(CBlob@ this)
{
	this.getSprite().SetFrameIndex(XORRandom(4));
	
	this.Tag("ignore fall");
	this.Tag("aerial");

	this.getShape().getConsts().collideWhenAttached = false;
	this.getShape().SetGravityScale(0);
	this.getShape().getConsts().bullet = true;

	this.addCommandID("switch target");
	this.getSprite().SetRelativeZ(2.5f);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated()>15)
	{
		this.setVelocity(Vec2f(this.getVelocity().x*0.975f, this.getVelocity().y));
	}
	if (this.getTickSinceCreated() > (15 + (Maths::Sqrt(this.getNetworkID())%15)))
	{
		this.setVelocity(Vec2f(this.getVelocity().x, 1.0f));
	}

	if (isClient())
	{
		if (this.getSprite() !is null) this.getSprite().setRenderStyle(RenderStyle::outline_front);
		if (!v_fastrender)
		{
			for(int i = 0; i < 2; i ++)
			{
				Vec2f pos = Vec2f(0,XORRandom(16)-8);
				if (pos.Length() < this.getRadius()) continue;

				float randomPVel = XORRandom(10) / 25.0f;
				Vec2f particleVel = Vec2f( randomPVel ,0).RotateByDegrees(XORRandom(360));
				particleVel += this.getVelocity();

    			CParticle@ p = ParticlePixelUnlimited(this.getPosition()+pos.RotateBy((getGameTime()*3+this.getNetworkID())%360), particleVel, SColor(255,255,255,155), true);
   				if(p !is null)
    			{
    			    p.collides = false;
    			    p.gravity = Vec2f_zero;
    			    p.bounce = 1;
    			    p.lighting = false;
    			    p.timeout = 30;
					p.Z = 1.0f;
					p.damping = 0.95;
    			}
			}
		}
	}
	
	if (!isServer()) return;
	if (getGameTime() % 5 != 0) return;
	if (XORRandom(15) != 0) return;

	if (this.isOnGround()) this.server_Die();
	CBlob@[] missiles;
	getBlobsByTag("missile", @missiles);

	for (u16 i = 0; i < missiles.length; i++)
	{
		CBlob@ missile = missiles[i];
		if (missile is null || this.getDistanceTo(missile) > distance) continue;

		missile.set_u16("target_NetID", this.getNetworkID());

		CBitStream params;
		params.write_u16(missile.getNetworkID());
		this.SendCommand(this.getCommandID("switch target"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("switch target"))
	{
		if (!isClient()) return;
		u16 missile_id;
		if (!params.saferead_u16(missile_id)) return;

		CBlob@ missile = getBlobByNetworkID(missile_id);
		if (missile is null) return;

		missile.set_u16("target_NetID", this.getNetworkID());
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null && solid)
	{
		this.server_Die();
		return;
	}

	if (blob.hasTag("missile"))
	{
		if (isServer())
		{
			this.server_Hit(blob, this.getPosition(), Vec2f_zero, 5.0f, Hitters::explosion, true);
		 	this.server_Die();
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return false;
}