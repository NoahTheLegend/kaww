#include "Hitters.as";
#include "ZombieCommon.as";

const float target_radius = 3000;
const float maxDistance = 3000.0f;
const float distToFuse = 125.0f;


const u8 LOOT_CASH = 5;

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;

	bool up = false;

	bool left = false;
	bool right = false;

	CMap@ map = this.getMap();
	Vec2f vel = this.getVelocity();
	Vec2f pos = this.getPosition();
	CShape@ shape = this.getShape();

	const f32 vellen = shape.vellen;
	const bool onground = this.isOnGround() || this.isOnLadder();

	// AI
	if (isServer())
	{
		CBlob@ target;
		this.get("target", @target);
		bool found = false;

		if (target !is null)
		{
			found = true;
			if (getGameTime() % 233 == 2) // check if there are no target in range
			{
				@target = getClosestTarget(this.getPosition(), target_radius);
				this.set("target", @target);
				found = (target !is null);
			}
		}
		else if (getGameTime() % 133 == 2)
		{
			@target = getClosestTarget(this.getPosition(), target_radius);
			this.set("target", @target);
			found = (target !is null);
		}

		// Attack!
		if (found)
		{
			Vec2f path = target.getPosition();
			Vec2f pos = this.getPosition();

			// Move towards
			if (pos.x > path.x)
			{
				left = true;
				right = false;
			}
			else
			{
				left = false;
				right = true;
			}

			bool facingleft = this.isFacingLeft();
			bool stand = this.isOnGround() || this.isOnLadder();
			Vec2f walkDirection;

			this.SetFacingLeft(pos.x > path.x);

			CMap@ map = this.getMap();
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

			//jumping
			if (onground)
			{
				this.set_u16("jumpCount", 0);
			}
			else
			{
				this.set_u16("jumpCount", this.get_u16("jumpCount") + 1);
			}

			if ((path - pos).Length() < distToFuse && isVisible(this, target) && this.get_u16("fuseCount") == 0)
			{
				this.set_u16("fuseCount", 70);

				this.getSprite().PlayRandomSound("/BoomerFuseStart", 1.25f, 1.0f);
			}

			if (up && vel.y > -2.9f)
			{
				float jumpStart = 0.7f;
				float jumpMid = 0.5f;
				float jumpEnd = 0.2f;

				Vec2f force = Vec2f(target.getPosition().x > this.getPosition().x ? 1.0f : -1.0f, 0);
				f32 side = 0.0f;

				if (this.isFacingLeft() && left)
				{
					side = -1.0f;
				}
				else if (!this.isFacingLeft() && right)
				{
					side = 1.0f;
				}

				// jump
				if (this.get_u16("jumpCount") <= 0)
				{
					force.y -= 1.5f;
				}
				else if (this.get_u16("jumpCount") < 3)
				{
					force.y -= jumpStart;
				}
				else if (this.get_u16("jumpCount") < 6)
				{
					force.y -= jumpMid;
				}
				else if (this.get_u16("jumpCount") < 8)
				{
					force.y -= jumpEnd;
				}

				force *= 160.0f;

				this.AddForce(force);

				// sound
				if (this.get_u16("jumpCount") == 1)
				{
					TileType tile = this.getMap().getTile(this.getPosition() + Vec2f(0.0f, this.getRadius() + 4.0f)).type;

					if (this.getMap().isTileGroundStuff(tile))
					{
						this.getSprite().PlayRandomSound("/EarthJump");
					}
					else
					{
						this.getSprite().PlayRandomSound("/StoneJump");
					}
				}
			}

			float walkSpeed = 0.80f;

			if (this.get_u16("fuseCount") > 0)
			{
				walkSpeed *= 3.25f;

				if (XORRandom(100) < 35)
				{
					ParticleAnimated("BloodSplatBigger.png", this.getPosition() + Vec2f(XORRandom(20)-10, XORRandom(20)-10), Vec2f(0, 0), float(XORRandom(360)), 0.25f + XORRandom(100)*0.01f, 3 + XORRandom(4), XORRandom(100) * -0.00005f, true);
				}
			}
			else
			{
				if (XORRandom(100) < 10)
				{
					ParticleAnimated("BloodSplatBigger.png", this.getPosition() + Vec2f(XORRandom(20)-10, XORRandom(20)-10), Vec2f(0, 0), float(XORRandom(360)), 0.25f + XORRandom(100)*0.01f, 3 + XORRandom(4), XORRandom(100) * -0.00005f, true);
				}
			}

			bool left_or_right = (left || right);

			if (right)
			{
				if (vel.x < -0.1f)
				{
					walkDirection.x += walkSpeed + 0.3f;
				}
				else if (facingleft)
				{
					walkDirection.x += walkSpeed - 0.2f;
				}
				else
				{
					walkDirection.x += walkSpeed;
				}
			}

			if (left)
			{
				if (vel.x > 0.1f)
				{
					walkDirection.x -= walkSpeed + 0.3f;
				}
				else if (!facingleft)
				{
					walkDirection.x -= walkSpeed - 0.2f;
				}
				else
				{
					walkDirection.x -= walkSpeed;
				}
			}

			f32 force = 1.0f;

			f32 lim = 0.0f;

			if (left_or_right)
			{
				lim = 2.0f;
				if (!onground)
				{
					lim = 2.5f;
				}

				lim *= 0.5f * Maths::Abs(walkDirection.x);
			}

			Vec2f stop_force;

			bool greater = vel.x > 0;
			f32 absx = greater ? vel.x : -vel.x;
			if ((absx < lim) || left && greater || right && !greater)
			{
				force *= 15.0f;
				if (Maths::Abs(force) > 0.01f)
				{
					this.AddForce(walkDirection * force);
				}
			}

			bool stopped = false;
			if (absx > lim)
			{
				stopped = true;
				stop_force.x -= (absx - lim) * (greater ? 1 : -1);

				stop_force.x *= 100.0f * (onground ? 0.8f : 0.3f);

				if (absx > 3.0f)
				{
					f32 extra = (absx - 3.0f);
					f32 scale = (1.0f / ((1 + extra) * 2));
					stop_force.x *= scale;
				}

				this.AddForce(stop_force);
			}

			if (XORRandom(250) == 0) 
			{
				if (this.get_u16("fuseCount") == 0)
				{
					this.set("target", null);
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

	//GUI::DrawIcon("LightCircle.png", Vec2f(getDriver().getScreenCenterPos().x - 256 + (XORRandom(20)-10), getDriver().getScreenCenterPos().y - 256 + (XORRandom(20)-10)), 0.5f);
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

bool isVisible(CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
}