#include "Hitters.as";
#include "Explosion.as";

void onInit(CSprite@ this)
{
	this.SetAnimation("default");
}

void onInit(CBlob@ this)
{
	this.getShape().getConsts().net_threshold_multiplier = 0.1f; //exp
	
	this.getShape().SetRotationsAllowed(false);

	this.Tag("flesh");
	this.Tag("zombie");

	if (this.getName() == "lurker")
	{
		this.Tag("headshotable");
	}	
	if (XORRandom(3) == 0) this.Tag("possessed");

	this.set_u16("jumpCount", 0);
	this.set_u32("nextatk", getGameTime());
	this.set_u32("playanim", 0);
	this.set_u8("myKey", XORRandom(255)+1); // controls all behaviors

	this.server_setTeamNum(2);

	this.getShape().SetOffset(Vec2f(0, 2));
}

// Face moving direction
void faceDirection(CBlob@ this, CBlob@ target, f32 x)
{
	if (Maths::Abs(x) > 0.2f)
		this.SetFacingLeft(x < 0);
	else
		this.SetFacingLeft(this.getPosition().x > target.getPosition().x);
}

// Show all death effects
void deathEffects(CBlob@ this)
{/*
	if (isClient())
	{
		CParticle@ p = ParticleAnimated("MonsterDie.png", this.getPosition(), Vec2f(0,0), 0.0f, 1.0f, 5, 0.0f, false);
		if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }
	}
	int i;
	for (i = 0; i < 10; i++)
	{
		const Vec2f pos = this.getPosition() + getRandomVelocity(0, 22.0f+XORRandom(30), 360);
		CParticle@ p = ParticleAnimated("MonsterDiePart.png", pos, Vec2f(0,0),  0.0f, 1.0f, 8+XORRandom(4), -0.04f, false);
		if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = true; }
	}*/
}

// CLOSEST TARGET
CBlob@ @getClosestTarget(Vec2f pos, float radius)
{
	CBlob@[] possible_targets;
	getBlobsByTag("player", @possible_targets);
	
	for(int i = 0; i < possible_targets.size(); i++)
	{
		CBlob@ check = possible_targets[i];
		Vec2f dist = check.getPosition() - pos;
		if(dist.getLength() > radius)
		{
			possible_targets.removeAt(i);
		}
	}
	
	CBlob@ target;
	@target = null;
	float smallest_dist = 999.0f; //maxDistance
	for(int i = 0; i < possible_targets.size(); i++)
	{
		CBlob@ check = possible_targets[i];
		Vec2f dist = check.getPosition() - pos;
		if(dist.getLength() < smallest_dist)
		{
			@target = @check;
			smallest_dist = dist.getLength();
		}
	}
	return @target;
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
	if (!getNet().isServer())
	{
		return;
	}

	if (aimangle < 0.0f)
	{
		aimangle += 360.0f;
	}

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateBy(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 attack_distance = 16.0f;

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null && !dontHitMore) // blob
			{
				if (b.hasTag("ignore sword")) continue;

				//big things block attacks
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

				if (!canHit(this, b))
				{
					// no TK
					if (large)
						dontHitMore = true;

					continue;
				}

				if (!dontHitMore)
				{
					Vec2f velocity = b.getPosition() - pos;
					this.server_Hit(b, hi.hitpos, velocity, damage, type, true);  // server_Hit() is server-side only

					// end hitting if we hit something solid, don't if its flesh
					if (large)
					{
						dontHitMore = true;
					}
				}
			}
		}
	}
}

bool canHit(CBlob@ this, CBlob@ b)
{
	if (b.hasTag("invincible"))
		return false;

	// Don't hit temp blobs and items carried by teammates.
	if (b.isAttached())
	{

		CBlob@ carrier = b.getCarriedBlob();

		if (carrier !is null)
			if (carrier.hasTag("player")
			        && (this.getTeamNum() == carrier.getTeamNum() || b.hasTag("temp blob")))
				return false;

	}

	if (b.hasTag("dead"))
		return true;

	return b.getTeamNum() != this.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CPlayer@ damageowner = hitterBlob.getDamageOwnerPlayer();
	// hitmarker sfx
	if (damageowner !is null)
	{
		CBlob@ damageownerblob = damageowner.getBlob();
		if (damageownerblob !is null)
		{
			if (damageownerblob.getSprite() !is null && !this.hasTag("dead") && this !is hitterBlob)
			{
				if (customData == Hitters::bullet)
				{
					if (this.hasTag("headshotable")) {
						if (this.hasTag("nolegs") || (!this.hasTag("nohead") && hitterBlob.getPosition().y < this.getPosition().y - 3.2f && !hitterBlob.hasTag("flesh")))
						{
							if (!this.hasTag("nolegs") && this.getInitialHealth()/2 < this.getHealth()) {
								if (XORRandom(2) == 0) {
									this.Tag("nohead");

									CParticle@ p = ParticleAnimated(this.hasTag("possessed") ? "Lurker_head_possessed.png" : "Lurker_head.png", this.getPosition() - Vec2f(0.0f, 6.0f), Vec2f(velocity.x/30,-3), XORRandom(50)-25, 1.0f, 4, 0.4f, false);
									if (p !is null) { p.diesoncollide = false; p.fastcollision = true; p.lighting = false; }
								}
							}
						}

						if (!this.hasTag("nohead") && !this.hasTag("nolegs") && !this.hasTag("possessed") && hitterBlob.getPosition().y > this.getPosition().y + 2.0f) {
							if (XORRandom(2) == 0) {
								this.set_u32("playanim", getGameTime() + 12);
								this.Tag("nolegs");
								CParticle@ p = ParticleAnimated("Lurker_leg.png", this.getPosition() + Vec2f(2.0f, 4.0f), Vec2f(velocity.x/30,-2), XORRandom(50)-25, 1.0f, 5, 0.4f, false);
								if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }
								CParticle@ p2 = ParticleAnimated("Lurker_leg.png", this.getPosition() + Vec2f(2.0f, 4.0f), Vec2f(velocity.x/30,-2), XORRandom(50)-25, 1.0f, 5, 0.4f, false);
								if (p2 !is null) { p2.diesoncollide = false; p2.fastcollision = false; p2.lighting = false; }
							}
						}

						if (this.getHealth() == this.getInitialHealth()) {
							if (XORRandom(6) == 0) this.getSprite().PlayRandomSound("/Lurker_moan", 1.2f, 0.8f + XORRandom(35) * 0.01f);
							this.server_SetHealth(this.getHealth()/2);
						}
					}
				}
			}
		}
	}

	if (damage > 0.05f)
	{
		makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                0, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}

	if (customData == Hitters::spikes)
	{
		damage *= 0.1f;
	}

	if (customData == Hitters::arrow)
	{
		this.AddForce(velocity*2.5);
	}

	return damage;
}
/*
void onDie(CBlob@ this)
{
	if (!this.hasTag("despawned"))
	{
		if (XORRandom(100) > 92)
		{
			// Drop heart
			CBlob @blob = server_CreateBlob("heal", this.getTeamNum(), this.getPosition());
			if (blob !is null)
			{
				blob.setVelocity(Vec2f(0.0f, -2.0f));
			}
		}
		else
		{
			// Drop cash
			CBlob @blob = server_CreateBlob("cash", this.getTeamNum(), this.getPosition());
			if (blob !is null)
			{
				blob.setVelocity(Vec2f(0.0f, -2.0f));
				blob.set_u8("cash_amount", LOOT_CASH);
			}
		}
	}

	if (this.getName() == "boomer")
	{
		Boom(this);
	}
	else if (this.getName() == "lurker")
	{
		ParticleAnimated("Lurker_headshot", this.getPosition() - Vec2f(0.0f, this.getRadius()/2), Vec2f(0, 0), 0, this.isFacingLeft() ? -1 : 1, 5, 0, false);
	}
}*/

void Boom(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	server_CreateBlob("riddenzone", this.getTeamNum(), this.getPosition());

	this.set_f32("map_damage_radius", 42.0f);
	this.set_f32("map_damage_ratio", 0.10f);
	
	WarfareExplode(this, 84.0f, 3.0f);
	
	for (int i = 0; i < 8; i++) 
	{
		Vec2f dir = getRandomVelocity(0, 1, 120);
		dir.x *= 2;
		dir.Normalize();
		LinearExplosion(this, dir, 29.0f, 38, 2, 0.50f, Hitters::explosion);
	}
	
	if (isClient())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
		
		this.Tag("exploded");
		this.getSprite().Gib();
	}

	for (u16 i = 0; i < 15; i++)
    {
    	ParticleAnimated("BloodSplatBigger.png", this.getPosition(), getRandomVelocity(0, (XORRandom(8)+4), 360), float(XORRandom(360)), 1.5f + XORRandom(200) * 0.01f, 4, 0.25f + XORRandom(100) * 0.00005f, true);
	}

	this.getSprite().PlaySound("/FleshExplosion", 0.7f, 1.0f);

	this.server_Die();
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "Explosion.png")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

void DoWalk(CBlob@ this, Vec2f vel, bool left, bool right, float walkSpeedModded)
{
	Vec2f walkDirection;
	bool facingleft = this.isFacingLeft();
	const bool onground = this.isOnGround() || this.isOnLadder();

	if (right)
	{
		if (vel.x < -0.1f)
		{
			walkDirection.x += walkSpeedModded + 0.3f;
		}
		else if (facingleft)
		{
			walkDirection.x += walkSpeedModded - 0.2f;
		}
		else
		{
			walkDirection.x += walkSpeedModded;
		}
	}

	if (left)
	{
		if (vel.x > 0.1f)
		{
			walkDirection.x -= walkSpeedModded + 0.3f;
		}
		else if (!facingleft)
		{
			walkDirection.x -= walkSpeedModded - 0.2f;
		}
		else
		{
			walkDirection.x -= walkSpeedModded;
		}
	}

	f32 force = 1.0f;

	f32 lim = 0.0f;

	if ((left || right))
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
}


void DoJump(CBlob@ this, float jumpStart, float jumpMid, float jumpEnd, bool left, bool right, float sideways)
{
	float side = 0.0f;
	if (this.isFacingLeft() && left)
	{
		side = -sideways;
	}
	else if (!this.isFacingLeft() && right)
	{
		side = sideways;
	}

	Vec2f force = Vec2f(side, 0);

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
}

bool isVisible(CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
}