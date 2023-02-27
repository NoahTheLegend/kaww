#include "Hitters.as";
#include "ZombieCommon.as";

const float target_radius = 2000;
const float maxDistance = target_radius;
const float walkSpeed = 1.00f;

const u8 LOOT_CASH = 10;

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;
	/*
	if (this.hasTag("possessed")) {
		this.server_SetHealth(Maths::Clamp(this.getHealth(), -1, this.getInitialHealth()/1.5));
	}
	*/
	bool up = false;
	bool left = false;
	bool right = false;

	float walkSpeedModded = walkSpeed;

	CMap@ map = this.getMap();
	Vec2f vel = this.getVelocity();
	Vec2f pos = this.getPosition();
	CShape@ shape = this.getShape();

	const f32 vellen = shape.vellen;
	const bool onground = this.isOnGround() || this.isOnLadder();

	if (isServer())
	{
		CBlob@ target;
		this.get("target", @target);
		bool found = false;

		if (target !is null)
		{
			found = true;
			if ((getGameTime()+this.getNetworkID()) % 150 == 2) // check if there are no target in range
			{
				@target = getClosestTarget(this.getPosition(), target_radius);
				this.set("target", @target);
				found = (target !is null);
			}
		}
		else if ((getGameTime()+this.getNetworkID()) % 50 == 2)
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

			if ((path - pos).Length() > 15.0f)
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
				if (this.isOnGround()) up = true;
			}

			if (this.isOnWall() && !this.isOnGround())
			{
				ShapeVars@ vars = this.getShape().getVars();
				vars.onladder = true;
			}

			//jumping
			if (onground) {
				this.set_u16("jumpCount", 0);
			} else {
				this.set_u16("jumpCount", this.get_u16("jumpCount") + 1);
			}

			if (XORRandom(200) == 0) {
				if (this.hasTag("nohead")) this.getSprite().PlayRandomSound("/Lurker_headless", 1.1f, 0.7f + XORRandom(35) * 0.01f);
				else this.getSprite().PlayRandomSound("/Lurker_moan", 1.1f, 0.7f + XORRandom(35) * 0.01f);
			}

			if (this.get_u32("playanim") > getGameTime()) walkSpeedModded *= 0.5f;

			if (this.hasTag("possessed"))
			{
				walkSpeedModded *= 2.3f;
			}

			if (this.hasTag("nolegs"))
			{
				walkSpeedModded *= 0.6f;
				
				if (up && vel.y > -2.9f) DoJump(this, 0.3f, 0.0f, 0.0f, left, right, 0.0f);
			}
			else {
				if (up && vel.y > -2.9f) DoJump(this, 0.7f, 0.2f, 0.1f, left, right, 0.0f);
			}

			DoWalk(this, vel, left, right, walkSpeedModded + (this.get_u8("myKey") / 600.0f));

			if ((path - pos).Length() < 30.0f && (this.get_u32("nextatk") <= getGameTime()))
			{
				this.set_u32("nextatk", getGameTime()+18);

				this.getSprite().PlayRandomSound("/Lurker_bite", 1.0f, 0.8f + XORRandom(45) * 0.01f);
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

		if (this.get_u32("nextatk") > getGameTime())
		{
			left = false;
			right = false;
		}
		if (this.get_u32("nextatk") - 5 == getGameTime())
		{
			DoAttack(this, 0.65f, (this.isFacingLeft() ? 180.0f : 0.0f), 80.0f, Hitters::bite);

			if (XORRandom(4) == 0) this.set("target", null);
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	f32 x = b.getVelocity().x;
	f32 y = b.getVelocity().y;
	const bool onground = b.isOnGround() || b.isOnLadder();

	string lurkerstatestring = "";
	if 		(b.hasTag("nohead")) 		{ lurkerstatestring = "nohead"; }
	else if (b.hasTag("nolegs")) 		{ lurkerstatestring = "nolegs"; }
	else if (b.hasTag("possessed")) 	{ lurkerstatestring = "possessed"; }
	

	if (b.get_u32("playanim") > getGameTime() + 1) {
		this.SetAnimation("loselegs");
	} else if (b.get_u32("nextatk") > getGameTime() + 1) {
		this.SetAnimation("bite"+lurkerstatestring);
	} else if (!onground) {
		this.SetAnimation("jump"+lurkerstatestring);
		if (y > 0) {
			this.SetFrameIndex(2);
		} else {
			this.SetFrameIndex(1);
		}
	} else {
		if (Maths::Abs(x) > 0.08f) this.SetAnimation("run"+lurkerstatestring);
		else this.SetAnimation("default"+lurkerstatestring);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ b)
{
	// Don't collide with corpses or familiar beings
	if (b.hasTag("dead"))
		return false;
	if (b.hasTag("player"))
		return true;
	if (b.hasTag("zombie") && getGameTime()%4==0)
		return true;
	return false;
}

void onDie(CBlob@ this)
{
	if (!this.hasTag("despawned"))
	{
		if (XORRandom(100) > 92)
		{
			CBlob @b = server_CreateBlob("heal", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.setVelocity(Vec2f(0.0f, -1.5f));
			}
		}
		else
		{
			CBlob @b = server_CreateBlob("cash", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.setVelocity(Vec2f(0.0f, -1.5f));
				b.set_u8("cash_amount", LOOT_CASH);
			}
		}
	}
}