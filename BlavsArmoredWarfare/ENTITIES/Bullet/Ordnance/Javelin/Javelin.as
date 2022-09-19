// small artillery

#include "Hitters.as"
#include "ComputerCommon.as"
#include "Explosion.as"
#include "OrdnanceCommon.as"

Random _missile_r(12231);

const f32 damage = 8.0f;
const f32 searchRadius = 132.0f;
const f32 radius = 24.0f;

void onInit(CBlob@ this)
{
	MissileInfo missile;
	missile.main_engine_force 			= JavelinParams::main_engine_force;
//	missile.secondary_engine_force 		= JavelinParams::secondary_engine_force;
//	missile.rcs_force 					= JavelinParams::rcs_force;
	missile.turn_speed 					= JavelinParams::turn_speed;
	missile.max_speed 					= JavelinParams::max_speed;
//	missile.lose_target_ticks 			= JavelinParams::lose_target_ticks;
	this.set("missileInfo", @missile);

	this.set_f32(robotechHeightString, 64.0f); // pixels
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	const u32 gameTime = getGameTime();

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	int teamNum = this.getTeamNum();

	f32 travelDist = thisVel.getLength();

	const bool is_client = isClient();
	const bool is_server = isServer();

	const bool firstTick = this.get_bool(firstTickString) || (is_client && this.get_bool(clientFirstTickString));
	if (firstTick)
	{
		if (is_client)
		{
			doMuzzleFlash(thisPos, thisVel);
			this.set_bool(clientFirstTickString, false);
		}
		this.setAngleDegrees(-thisVel.getAngleDegrees());
		this.set_bool(firstTickString, false);
	}

	HitInfo@[] hitInfos;
	bool hasHit = map.getHitInfosFromRay(thisPos, -thisVel.getAngleDegrees(), travelDist, this, @hitInfos);
	if (hasHit) //hitray scan
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b == null) // check
			{ continue; }
			
			if (!doesCollideWithBlob(this, b))
			{ continue; }

			thisPos = hi.hitpos;

			this.setPosition(thisPos);
			this.server_Die();
			this.server_Hit(hi.blob, thisPos, Vec2f(0,0), damage, Hitters::ballista, true); 
			return;
		}
	}

	MissileInfo@ missile;
	if (!this.get( "missileInfo", @missile )) 
	{ return; }

	u16 targetBlobID = this.get_u16(targetNetIDString);
	CBlob@ targetBlob = getBlobByNetworkID(targetBlobID);
	if ( targetBlobID == 0 || targetBlob == null || this.getTickSinceCreated() < 5)
	{
		return;
	}

	// smoke effect
	if (XORRandom(2) == 0) 
	{
		if (is_client)
		{
			ParticleAnimated("LargeSmoke", this.getPosition(), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, 90), float(XORRandom(360)), 0.5f + XORRandom(25) * 0.01f, 1 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		}
	}
	
	//homing logic
	Vec2f targetPos = targetBlob.getPosition();
	Vec2f targetVel = targetBlob.getVelocity();

	Vec2f bVel = thisVel - targetVel; //compensates for missile speed
	float bSpeed = bVel.getLength();
	Vec2f bVelNorm = bVel;
	bVelNorm.Normalize();

	Vec2f targetVec = targetPos - thisPos;
	f32 targetDist = targetVec.getLength(); //distance to target

	Vec2f gravity = Vec2f(0, sv_gravity*0.6f); 
	Vec2f lastBVel = this.get_Vec2f(lastRelativeVelString);
	Vec2f bAccel = (lastBVel - bVel) + gravity;
	Vec2f bAccelNorm = bAccel;
	bAccelNorm.Normalize();
	this.set_Vec2f(lastRelativeVelString, bVel);

	const float mainEngineForce = missile.main_engine_force;
	const float maxSpeed = missile.max_speed;
	const float turnSpeed = missile.turn_speed;
	float turnAngle = 0.0f;

	switch (this.get_s8(navigationPhaseString))
	{
		case 0:
		{
			Vec2f risingPos = targetPos + Vec2f(0, -2000.0f);
			turnAngle = (risingPos-thisPos).getAngleDegrees();
			
			if (thisPos.y < this.get_f32(robotechHeightString))
			{
				this.set_s8(navigationPhaseString, 1);
			}
		}
		break;

		case 1:
		{
			if (is_server) //server only detonation
			{
				if (targetDist < radius*0.8f) //if closer than 80% of explosion radius, detonate.
				{
					this.server_Die();
					this.server_Hit(targetBlob, targetPos, Vec2f(0,0), damage, Hitters::ballista, true); 
					return;
				}
			}

			float bVelAngle = ((bVelNorm*2.0f) + bAccelNorm).getAngleDegrees();
			float targetVecAngle = targetVec.getAngleDegrees();

			float directionDiff = targetVecAngle - bVelAngle;
			directionDiff += directionDiff > 180 ? -360 : directionDiff < -180 ? 360 : 0;
			bool movingAway = Maths::Abs(directionDiff) > 90.0f;

			turnAngle = movingAway ? bVelAngle + 180.0f : targetVecAngle + directionDiff;
		}
		break;
		
	}
	
	float angle = -turnAngle + 360.0f;
	float thisAngle = this.getAngleDegrees();
		
	float angleDiff = angle - thisAngle;
	angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;

	// turning
	this.setAngleDegrees(thisAngle + Maths::Clamp(angleDiff, -turnSpeed, turnSpeed));
	
	// thrust
	Vec2f thrustNorm = Vec2f(1.0f, 0).RotateByDegrees(this.getAngleDegrees());
	Vec2f thrustVec = thrustNorm * mainEngineForce;

	bool hasThrust = Maths::Abs(angleDiff) < 45.0f;
	Vec2f newVel = thisVel + (hasThrust ? thrustVec : Vec2f_zero);

	if (maxSpeed != 0 && newVel.getLength() > maxSpeed) //max speed logic - 0 means no cap
	{
		newVel.Normalize();
		newVel *= maxSpeed;
	}

	this.setVelocity(newVel);

	if (!is_client)
	{ return; }
	const f32 gameTimeVariation = gameTime + this.getNetworkID();
	const f32 targetSquareAngle = (gameTimeVariation * 10.1f) % 360;
	
	if (hasThrust) doThrustParticles(thisPos, -thrustNorm*2.0f); //exhaust particles
	
	//client UI and sounds
	makeTargetSquare(targetPos-thisVel, targetSquareAngle, Vec2f(2.5f, 2.5f), 2.0f, 1.0f, redConsoleColor); //target acquired square
}

void doThrustParticles(Vec2f pPos = Vec2f_zero, Vec2f pVel = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (pPos == Vec2f_zero || pVel == Vec2f_zero)
	{ return; }

	if (_missile_r.NextFloat() > 0.8f) //percentage chance of spawned particles
	{ return; }

	f32 pAngle = 360.0f * _missile_r.NextFloat();
	pVel.RotateByDegrees( 20.0f * (1.0f - (2.0f * _missile_r.NextFloat())) );

   	CParticle@ p = ParticleAnimated("PingParticle.png", pPos, pVel, pAngle, 0.4f, 1, 0, true);
   	if(p !is null)
   	{
		p.fastcollision = true;
		p.gravity = Vec2f_zero;
		p.bounce = 0;
		p.Z = 8;
		p.timeout = 10;
	}
}

void doMuzzleFlash(Vec2f thisPos = Vec2f_zero, Vec2f flashVec = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (thisPos == Vec2f_zero || flashVec == Vec2f_zero)
	{ return; }
	
	Vec2f flashNorm = flashVec;
	flashNorm.Normalize();

	const int particleNum = 4; //particle amount

	for(int i = 0; i < particleNum; i++)
   	{
		Vec2f pPos = thisPos;
		Vec2f pVel = flashNorm;
		pVel *= 0.2f + _missile_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _missile_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

		f32 pAngle = 360.0f * _missile_r.NextFloat();

		CParticle@ p = ParticleAnimated("GenericBlast6.png", pPos, pVel, pAngle, 0.5f, 1, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 10;
		}
	}
	
	Sound::Play("RPGFire.ogg", thisPos, 0.6f , 0.8f + (0.1f * _missile_r.NextFloat()));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	int thisTeamNum = this.getTeamNum();
	int blobTeamNum = blob.getTeamNum();

	return
	(
		(
			thisTeamNum != blobTeamNum ||
			blob.hasTag("dead")
		)
		&&
		(
			blob.hasTag("flesh")
		)
	);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f collisionPos )
{
	if ((this == null || blob == null) && solid)
	{
		this.server_Die();
		return;
	}

	if (!doesCollideWithBlob(this, blob))
	{ return; }

	this.server_Die();
	this.server_Hit(blob, collisionPos, Vec2f(0,0), damage, Hitters::ballista, true); 
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	DoExplosion(this, this.getVelocity());

	makeMissileEffect(thisPos); //boom effect
}

void makeMissileEffect(Vec2f thisPos = Vec2f_zero)
{
	if(!isClient() || thisPos == Vec2f_zero)
	{return;}

	u16 particleNum = XORRandom(5)+5;

	Sound::Play("Bomb.ogg", thisPos, 0.8f, 0.8f + (0.4f * _missile_r.NextFloat()) );

	for (int i = 0; i < particleNum; i++)
    {
        Vec2f pOffset(_missile_r.NextFloat() * radius, 0);
        pOffset.RotateBy(_missile_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("BulletHitParticle1.png", 
									thisPos + pOffset, 
									Vec2f_zero, 
									_missile_r.NextFloat() * 360.0f, 
									0.5f + (_missile_r.NextFloat() * 0.5f), 
									XORRandom(3)+1, 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.collides = false;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

bool DoExplosion(CBlob@ this, Vec2f velocity)
{
	f32 mod = 1.5;

	Explode(this, 26.0f*mod, 12.0f*(mod/2));
	LinearExplosion(this, velocity, 22.0f*mod/2+XORRandom(9), 10.0f*mod, 9, 5.0f*mod, Hitters::fall);
	
	this.getSprite().PlaySound("/ShellExplosion");

	if (isClient())
	{
		Vec2f pos = this.getPosition();

		for (int i = 0; i < 6; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(15) * 0.005f, 360), float(XORRandom(360)), 0.75f + XORRandom(40) * 0.01f, 5 + XORRandom(6), XORRandom(30) * -0.0001f, true);
		}

		for (int i = 0; i < (15 + XORRandom(15)); i++)
		{
			makeGibParticle("GenericGibs", pos, getRandomVelocity((pos + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
		}
	}

	return true;
}