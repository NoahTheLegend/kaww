// small artillery

#include "WarfareGlobal.as"
#include "Hitters.as"
#include "ComputerCommon.as"
#include "Explosion.as"
#include "OrdnanceCommon.as"

Random _missile_r(12231);

const f32 damage = 12.5f;
const f32 searchRadius = 132.0f;
const f32 radius = 40.0f;

void onInit(CBlob@ this)
{
	this.Tag("jav");
	MissileInfo missile;
	missile.main_engine_force 			= GutseekerParams::main_engine_force;
//	missile.secondary_engine_force 		= GutseekerParams::secondary_engine_force;
//	missile.rcs_force 					= GutseekerParams::rcs_force;
	missile.turn_speed 					= GutseekerParams::turn_speed;
	missile.max_speed 					= GutseekerParams::max_speed;
//	missile.lose_target_ticks 			= GutseekerParams::lose_target_ticks;
	missile.gravity_scale 				= GutseekerParams::gravity_scale;
	this.set("missileInfo", @missile);

	this.set_Vec2f("disperse_pos", Vec2f_zero);

	this.getShape().SetGravityScale(missile.gravity_scale);
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
			return;
		}
	}

	MissileInfo@ missile;
	if (!this.get( "missileInfo", @missile )) 
	{ return; }

	// smoke effect
	if (XORRandom(2) == 0) 
	{
		if (is_client)
		{
			ParticleAnimated("LargeSmoke", this.getPosition(), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, 90), float(XORRandom(360)), 0.5f + XORRandom(25) * 0.01f, 1 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		}
	}
	
	//homing logic
	if ( this.getTickSinceCreated() < 5) return;
	
	Vec2f targetPos = this.get_Vec2f("disperse_pos");
	Vec2f targetVel = Vec2f_zero;

	u16 targetBlobID = this.get_u16(targetNetIDString);
	CBlob@ targetBlob = getBlobByNetworkID(targetBlobID);
	if (targetBlobID != 0 && targetBlob != null)
	{
		targetPos = targetBlob.getPosition();
		targetVel = targetBlob.getVelocity();
	}

	Vec2f bVel = thisVel - targetVel; //compensates for missile speed
	float bSpeed = bVel.getLength();
	Vec2f bVelNorm = bVel;
	bVelNorm.Normalize();

	Vec2f targetVec = targetPos - thisPos;
	f32 targetDist = targetVec.getLength(); //distance to target

	float mainEngineForce = missile.main_engine_force;
	float maxSpeed = missile.max_speed;
	float turnSpeed = missile.turn_speed;

	switch (this.get_s8(navigationPhaseString))
	{
		case 0:
		{
			if (is_server) //server only detonation
			{
				if (targetDist < 32.0f)
				{
					this.server_Die();
					return;
				}
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

			if (targetBlob == null) return; // die like a fly
		}
		break;
	}

	// acceleration math
	float gravityScale = missile.gravity_scale;
	Vec2f gravity = Vec2f(0, (sv_gravity*gravityScale) / getTicksASecond()); 

	Vec2f lastBVel = this.get_Vec2f(lastRelativeVelString);
	Vec2f bAccel = (lastBVel - bVel) + gravity;
	Vec2f bAccelNorm = bAccel;
	bAccelNorm.Normalize();
	this.set_Vec2f(lastRelativeVelString, bVel);

	// find optimal flight angle
	float influence = gravity.y / mainEngineForce;
	float bVelAngle = (bVelNorm + (bAccelNorm*influence)).getAngleDegrees();
	float targetVecAngle = targetVec.getAngleDegrees();

	float directionDiff = targetVecAngle - bVelAngle;
	directionDiff += directionDiff > 180 ? -360 : directionDiff < -180 ? 360 : 0;
	bool movingAway = Maths::Abs(directionDiff) > 90.0f;

	float turnAngle = movingAway ? bVelAngle + 180.0f : targetVecAngle + directionDiff;
	
	// turning 
	float angle = -turnAngle + 360.0f;
	float thisAngle = this.getAngleDegrees();
		
	float angleDiff = angle - thisAngle;
	angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;
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
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	DoExplosion(this, this.getVelocity());

	makeMissileEffect(thisPos); //boom effect

	if (!isServer()) return;

	MissileInfo@ missile;
	if (!this.get( "missileInfo", @missile )) return;

	int targetAmount = missile.target_netid_list.length;
	if (targetAmount > 0)
	{
		for (uint i = 0; i < targetAmount; i++)
		{
			u16 netID = missile.target_netid_list[i];
			CBlob@ targetBlob = getBlobByNetworkID(netID);
			if (targetBlob == null) continue;

			Vec2f launchVec = Vec2f(1.0f + _missile_r.NextFloat(), 0);
			launchVec.RotateByDegrees(360.0f * _missile_r.NextFloat());
			
			CBlob@ blob = server_CreateBlob("missile_gutseeker", this.getTeamNum(), thisPos);
			if (blob != null)
			{
				blob.setVelocity((this.getVelocity() + Vec2f(0, -0.5f - 0.25f*XORRandom(40))) + launchVec * 2.0f);
				blob.IgnoreCollisionWhileOverlapped(this, 20);

				blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
				blob.set_u16(targetNetIDString, netID);
				blob.set_s8(navigationPhaseString, 1);
			}
		}
	}
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
	this.set_f32("map_damage_radius", 34.0f);
	this.set_f32("map_damage_ratio", 0.2f);

	f32 mod = 1.5;

	WarfareExplode(this, radius*mod, damage*(mod/2));
	//LinearExplosion(this, velocity, 2.0f, 2.0f, 2, 1.0f, Hitters::fall);
	
	this.getSprite().PlaySound("/ClusterExplode");

	if (isClient())
	{
		Vec2f pos = this.getPosition();

		for (int i = 0; i < 6; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(35) * 0.005f, 360), float(XORRandom(360)), 1.0f + XORRandom(40) * 0.01f, 7 + XORRandom(6), XORRandom(40) * -0.0001f, true);
		}

		for (int i = 0; i < (15 + XORRandom(15)); i++)
		{
			makeGibParticle("GenericGibs", pos, getRandomVelocity((pos + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
		}
	}

	return true;
}