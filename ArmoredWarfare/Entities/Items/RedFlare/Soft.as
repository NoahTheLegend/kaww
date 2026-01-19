#define CLIENT_ONLY

#include "Hitters.as"
#include "UtilityChecks.as";

void onInit(CBlob@ this)
{
	this.Tag("soft");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.05f) //sound for all damage
	{
		if (hitterBlob !is this)
		{
			playSoundInProximity(this, "dig_soft.ogg", Maths::Min(1.25f, Maths::Max(0.5f, damage)));
		}

		makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}
    return damage;
}


void onGib(CSprite@ this)
{
	playSoundInProximity(this.getBlob(), "dig_soft.ogg", 1.0f, 0.75f+XORRandom(51) * 0.001f);
}