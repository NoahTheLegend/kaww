#include "Hitters.as";
#include "TeamColour.as";

void onTick(CBlob@ this)
{
	if (isServer())
	{
		if ((this.isAttached() || this.isOnGround()) && getGameTime()%15==0)
		{
			this.server_Hit(this, this.getPosition(), this.getOldVelocity(), this.isAttached()?2.0f:0.5f, Hitters::builder);
		}
	}

	if (this.getTickSinceCreated() == 0)
	{
		Sound::Play("/ParachuteOpen", this.getPosition());
		this.Tag("parachute");
	}

	ManageParachute(this);
}

void ManageParachute( CBlob@ this )
{
	if (this.isOnGround() || this.isInWater() || this.isAttached())
	{	
		if (this.hasTag("parachute"))
		{
			this.Untag("parachute");

			for (uint i = 0; i < 50; i ++)
			{
				Vec2f vel = getRandomVelocity(90.0f, 3.5f + (XORRandom(10) / 10.0f), 25.0f) + Vec2f(0, 2);
				ParticlePixel(this.getPosition() - Vec2f(0, 30) + getRandomVelocity(90.0f, 10 + (XORRandom(20) / 10.0f), 25.0f), vel, getTeamColor(this.getTeamNum()), true, 119);
			}
		}
	}
	
	if (this.hasTag("parachute"))
	{
		this.AddForce(Vec2f(Maths::Sin(getGameTime() / 9.5f) * 5, (Maths::Sin(getGameTime() / 4.2f) * 8)));
		this.setVelocity(Vec2f(this.getVelocity().x, this.getVelocity().y * 0.75f));
	}
}