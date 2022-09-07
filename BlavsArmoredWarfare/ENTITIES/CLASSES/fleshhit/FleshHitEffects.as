#include "Hitters.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.1f && (hitterBlob !is this || customData == Hitters::crush))  //sound for anything actually painful
	{
		f32 capped_damage = Maths::Min(damage, 3.0f);

		//set this false if we whouldn't show blood effects for this hit
		bool showblood = true;

		//read customdata for hitter
		switch (customData)
		{
			case Hitters::drown:
			case Hitters::burn:
			case Hitters::fire:
				showblood = false;
				break;

			case Hitters::sword:
				Sound::Play("SwordKill", this.getPosition());
				break;

			case Hitters::stab:
				if (this.getHealth() > 0.0f && damage > 2.0f)
				{
					this.Tag("cutthroat");
				}
				break;

			default:
				if (customData != Hitters::bite)
					Sound::Play("FleshHit.ogg", this.getPosition());
				break;
		}

		worldPoint.y -= this.getRadius() * 0.5f;

		if (showblood)
		{
			if (capped_damage > 1.0f)
			{
				ParticleBloodSplat(worldPoint, true);
			}

			if (capped_damage > 0.25f)
			{
				for (f32 count = 0.0f ; count < capped_damage; count += 0.3f)
				{
					ParticleBloodSplat(worldPoint + getRandomVelocity(0, 0.75f + capped_damage * 1.0f * XORRandom(5), 360.0f), false);
				}
			}

			if (capped_damage > 0.01f)
			{
				f32 angle = (velocity).Angle();

				for (f32 count = 0.0f ; count < capped_damage + 0.6f; count += 0.1f)
				{
					Vec2f vel = getRandomVelocity(angle, 1.0f + 0.3f * capped_damage * 0.1f * XORRandom(20), 60.0f);
					vel += hitterBlob.getVelocity()/7;
					vel.y -= 1.5f * capped_damage;
					ParticleBlood(worldPoint, vel * 0.7f, SColor(255, 126, 0, 0));
					
					Vec2f velr = Vec2f((XORRandom(19) - 9.0f)/3, (XORRandom(10) - 9.0f)/5);
					velr += hitterBlob.getVelocity()/7;
					velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

					ParticlePixel(this.getPosition(), velr, SColor(255, 90, 30, 30), true);
				}

				if (XORRandom(3) != 0)
					makeGibParticle("RunnerGibs.png", worldPoint, velocity/10 + getRandomVelocity(90, 1.0f, 80), XORRandom(6), 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", this.getTeamNum());
			}
		}
	}

	return damage;
}

