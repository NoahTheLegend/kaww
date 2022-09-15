// small artillery

#include "Hitters.as"
#include "ComputerCommon.as"

Random _missile_r(12231);

const f32 damage = 0.5f;
const f32 searchRadius = 128.0f;
const f32 radius = 24.0f;
const float thrust = 0.5f;

const string firstTickString = "first_tick";
const string clientFirstTickString = "first_tick_client";

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(15);
	this.set_s8(navigationPhaseString, 0);

	this.set_bool(firstTickString, true);
	this.set_bool(clientFirstTickString, true);

	this.getSprite().SetFrame(0);
	this.getShape().SetGravityScale(0.6f);
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
	Vec2f futurePos = thisPos + thisVel;

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
			return;
		}
	}

	u16 targetBlobID = this.get_u16(curTargetNetIDString);
	CBlob@ targetBlob = getBlobByNetworkID(targetBlobID);
	if ( targetBlobID == 0 || targetBlob == null || this.getTickSinceCreated() < 5)
	{
		return;
	}

	
	//homing logic
	Vec2f targetPos = targetBlob.getPosition();
	Vec2f gravity = Vec2f(0, sv_gravity*0.6f); 
	Vec2f bVel = targetBlob.getVelocity() - (thisVel + gravity); //compensates for missile speed
	Vec2f targetVec = targetPos - thisPos;
	f32 targetDist = targetVec.getLength(); //distance to target

	Vec2f futureTargetPos = targetPos + bVel; // main targetpos finder

	float turnAngle = 0.0f;

	switch (this.get_s8(navigationPhaseString))
	{
		case 0:
		{
			Vec2f raisingPos = targetPos + Vec2f(0, -2000.0f);
			turnAngle = (raisingPos-thisPos).getAngleDegrees();
			if (targetPos.y - 100.0f > thisPos.y)
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
					return;
				}
			}

			//this block of code re-does the calculation to be more exact
			targetVec = futureTargetPos - thisPos;
			targetDist = targetVec.getLength();
			float thisFinalSpeed = Maths::Sqrt(2.0f*thrust * targetDist) + travelDist;
			float thisAverageSpeed = (thisFinalSpeed + travelDist) / 2;
			float travelTicks = targetDist / thisFinalSpeed; // theoretical ticks required to get to the target (again, TODO)
			futureTargetPos = targetPos + (bVel*travelTicks); // matches future target pos with travel time
			targetVec = futureTargetPos - thisPos;

			turnAngle = targetVec.getAngleDegrees();
		}
		break;
		
	}
	
	float angle = -turnAngle + 360.0f;
	float thisAngle = this.getAngleDegrees();
		
	float angleDiff = angle - thisAngle;
	angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;

	this.setAngleDegrees(thisAngle + Maths::Clamp(angleDiff, -10.0f, 10.0f));
	
	//Vec2f thrustVec = futureTargetPos - thisPos;
	Vec2f thrustVec = Vec2f(1.0f, 0).RotateByDegrees(this.getAngleDegrees());
	Vec2f thrustNorm = thrustVec;
	//thrustNorm.Normalize();
	f32 thrustAngle = thrustNorm.getAngleDegrees();

	bool hasThrust = Maths::Abs(angleDiff) < 45.0f;

	Vec2f newVel = thisVel + (hasThrust ? (thrustNorm * thrust) : Vec2f_zero);

	f32 maxSpeed = 10.0f;
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
	makeTargetSquare(futureTargetPos, targetSquareAngle, Vec2f(2.5f, 2.5f), 2.0f, 1.0f, redConsoleColor); //target acquired square
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	makeMissileEffect(thisPos); //boom effect
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
	
	Sound::Play("BasicShotSound.ogg", thisPos, 0.3f , 1.3f + (0.1f * _missile_r.NextFloat()));
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