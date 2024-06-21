#include "Hitters.as";
#include "HittersAW.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (!this.hasTag("was_hit"))
		this.Tag("was_hit");

	if (damage > 0.05f) //sound for all damage
	{
		this.getSprite().PlayRandomSound("TreeChop");

		if (damage >= 0.75f)
			makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                0, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}

	if (customData == Hitters::sword)
	{
		damage *= 0.5f;
	}

	return damage;
}
