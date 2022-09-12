#include "Hitters.as";
#include "ZombieCommon.as";

const float target_radius = 2000;
const float maxDistance = target_radius;
const float distToFuse = 125.0f;
const float walkSpeed = 0.80f;

const u8 LOOT_CASH = 5;

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;

	bool up = false;
	bool left = false;
	bool right = false;

	float walkSpeedModded = walkSpeed;

	CMap@ map = this.getMap();
	Vec2f vel = this.getVelocity();
	Vec2f pos = this.getPosition();
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.net_threshold_multiplier = 0.5f;

	const bool onground = this.isOnGround() || this.isOnLadder();

	//brain
	if (isServer())
	{
		CBlob@ target;
		this.get("target", @target);
		bool found = false;

		if (target !is null)
		{
			found = true;
			if (getGameTime() % 220 == 2) // check if there are no target in range
			{
				@target = getClosestTarget(this.getPosition(), target_radius);
				this.set("target", @target);
				found = (target !is null);
			}
		}
		else if (getGameTime() % 120 == 2)
		{
			@target = getClosestTarget(this.getPosition(), target_radius);
			this.set("target", @target);
			found = (target !is null);
		}

		if (found) // target found
		{
			Vec2f path = target.getPosition();
			Vec2f pos = this.getPosition();

			if (this.getDistanceTo(target) > 15.0f) // move towards
			{
				left = (pos.x > path.x);
				right = (pos.x < path.x);
			}
			
			this.SetFacingLeft(pos.x > path.x);
			bool facingleft = this.isFacingLeft();

			//trigger jump
			const f32 radius = this.getRadius() * 2.0f;
			if ((map.isTileSolid(Vec2f(pos.x - radius, pos.y + 0.45f * radius)) && facingleft)
				|| (map.isTileSolid(Vec2f(pos.x + radius, pos.y + 0.45f * radius))) && !facingleft
				|| (this.isOnWall() && XORRandom(4) == 0))
			{
				if (this.get_u16("fuseCount") > 12 || this.get_u16("fuseCount") == 0) // dont jump at end of fuse
				{
					up = true;
				}
			}

			if (up && vel.y > -2.9f)
			{
				DoJump(this, 0.7f, 0.2f, 0.1f, left, right, 0.7f);
			}

			this.set_u16("jumpCount", onground ? 0 : this.get_u16("jumpCount") + 1);

			if ((path - pos).Length() < distToFuse && isVisible(this, target) && this.get_u16("fuseCount") == 0)
			{
				this.set_u16("fuseCount", 70);
				this.Sync("fuseCount", true);

				this.getSprite().PlayRandomSound("/BoomerFuseStart", 1.25f, 1.0f);
			}

			if (this.get_u16("fuseCount") > 0)
			{
				walkSpeedModded *= 3.0f;
			}

			DoWalk(this, vel, left, right, walkSpeedModded);

			// lose target randomly
			if (XORRandom(250) == 0) 
			{
				if (this.get_u16("fuseCount") == 0)
				{
					this.set("target", null);
				}
			}


			// particles
			if (isClient())
			{
				if (XORRandom(100) < 40)
				{
					ParticleAnimated("BloodSplatBigger.png", this.getPosition() + Vec2f(XORRandom(20)-10, XORRandom(20)-10), Vec2f(0, 0), float(XORRandom(360)), 0.25f + XORRandom(100)*0.01f, 3 + XORRandom(4), XORRandom(100) * -0.00005f, true);
				}
			}
		}
		else // NO ENEMY FOUND
		{
			// Chance to despawn
			if (XORRandom(13) == 0 && (getGameTime() % 50) == 0)
			{
				//this.Tag("despawned");
				//this.server_Die();
			}
		}

		if (this.get_u16("fuseCount") == 1)
		{
			Boom(this);
		}

		if (this.get_u16("fuseCount") > 0)
		{
			this.set_u16("fuseCount", this.get_u16("fuseCount") - 1);
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	f32 x = blob.getVelocity().x;

	if (blob.get_u16("fuseCount") > 0)
	{
		this.SetAnimation("fuse");
	}
	else
	{
		if (Maths::Abs(x) > 0.08f)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("default");
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// Don't collide with corpses or familiar beings
	if (blob.hasTag("dead"))
		return false;
	if (blob.hasTag("player"))
		return true;
	return false;
}

void onDie(CBlob@ this)
{
	if (!this.hasTag("despawned"))
	{
		Boom(this);

		// loot
		if (XORRandom(100) > 91)
		{
			if (isServer())
			{
				CBlob @blob = server_CreateBlob("heal", this.getTeamNum(), this.getPosition());
				if (blob !is null)
				{
					blob.setVelocity(Vec2f(0.0f, -2.5f));
				}
			}
		}
		else
		{
			CBlob @blob = server_CreateBlob("cash", this.getTeamNum(), this.getPosition());
			if (blob !is null)
			{
				blob.setVelocity(Vec2f(0.0f, -2.5f));
				blob.set_u8("cash_amount", LOOT_CASH);
			}
		}
	}
}