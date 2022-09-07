#include "Hitters.as";
#include "ZombieCommon.as";

const float target_radius = 3000;
const float maxDistance = 3000.0f;

const u8 LOOT_CASH = 1;

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
			if (getGameTime() % 150 == 2) // check if there are no target in range
			{
				@target = getClosestTarget(this.getPosition(), target_radius);
				this.set("target", @target);
				found = (target !is null);
			}
		}
		else if (getGameTime() % 50 == 2)
		{
			@target = getClosestTarget(this.getPosition(), target_radius);
			this.set("target", @target);
			found = (target !is null);
		}

		// FOUND AN ENEMY! Attack!
		if (found)
		{
			Vec2f path = target.getPosition();
			Vec2f pos = this.getPosition();

			if ((path - pos).Length() > 13.0f)
			{
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
			}

			bool facingleft = this.isFacingLeft();
			bool stand = this.isOnGround() || this.isOnLadder();
			Vec2f walkDirection;

			this.SetFacingLeft(pos.x > path.x);

			CMap@ map = this.getMap();
			const f32 radius = this.getRadius() * 2.0f;
			if ((map.isTileSolid(Vec2f(pos.x - radius, pos.y + 0.45f * radius)) && facingleft)
				|| (map.isTileSolid(Vec2f(pos.x + radius, pos.y + 0.45f * radius))) && !facingleft
				|| (this.isOnWall() && XORRandom(2) == 0))
			{
				up = true;
			}

			//jumping
			if (onground)
			{
				this.set_u16("jumpCount", 0);

				if (XORRandom(200) == 0)
				{
					this.getSprite().PlayRandomSound("/Lurker_moan", 1.0f, 0.8f + XORRandom(35) * 0.01f);
				}
			}
			else
			{
				this.set_u16("jumpCount", this.get_u16("jumpCount") + 1);
			}

			if (up && vel.y > -2.9f)
			{
				float jumpStart = 0.7f;
				float jumpMid = 0.2f;
				float jumpEnd = 0.1f;

				Vec2f force = Vec2f(0, 0);
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
						//this.getSprite().PlayRandomSound("/EarthJump");
					}
					else
					{
						//this.getSprite().PlayRandomSound("/StoneJump");
					}
				}
			}

			const float walkSpeed = 1.25f;

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

			if ((path - pos).Length() < 30.0f && (this.get_u16("atkCount") == 0))
			{
				this.set_u16("atkCount", 18);

				this.getSprite().PlayRandomSound("/Lurker_bite", 1.0f, 0.8f + XORRandom(55) * 0.01f);
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

		if (this.get_u16("atkCount") > 0)
		{
			left = false;
			right = false;
			this.set_u16("atkCount", this.get_u16("atkCount") - 1);
		}
		if (this.get_u16("atkCount") == 6)
		{
			DoAttack(this, 0.5f, (this.isFacingLeft() ? 180.0f : 0.0f), 80.0f, Hitters::bite);

			if (XORRandom(3) == 0) this.set("target", null);
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	f32 x = blob.getVelocity().x;

	if (blob.get_u16("atkCount") > 0)
	{
		this.SetAnimation("bite");
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

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null) { return; }

	Vec2f vel = this.getVelocity();
}