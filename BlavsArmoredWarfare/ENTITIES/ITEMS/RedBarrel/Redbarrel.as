#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.server_setTeamNum(255);

	this.Tag("builder always hit");

	this.getShape().SetRotationsAllowed(false);

	this.getSprite().SetZ(-20.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 35.0f);
	this.set_f32("map_damage_ratio", 0.01f);
	
	Explode(this, 50.0f, 1.75f);

	Explode(this, 24.0f, 1.5f);
	
	for (int i = 0; i < 4; i++) //12
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		LinearExplosion(this, dir, 60.0f, 85, 2, 0.5f, Hitters::water);
		
	}
	
	for (int i = 0; i < 30; i++)
	{
		MakeParticle(this, Vec2f( XORRandom(100) - 50, XORRandom(100) - 50), getRandomVelocity(-angle, XORRandom(155) * 0.01f, 90));
	}
	
	this.Tag("exploded");
	this.getSprite().Gib();
}

void onDie(CBlob@ this)
{
	DoExplosion(this);

	for (int i = 0; i < 15; i++)
	{
		CParticle@ p = ParticleAnimated("BulletHitParticle1.png", this.getPosition() + getRandomVelocity(0, XORRandom(40) * 1.0f, 360), Vec2f(0,0), XORRandom(360), 1.0f + XORRandom(50)*0.01f, 4+XORRandom(4), 0.0f, true);
	}

	// glow
	this.SetLight(true);
	this.SetLightRadius(400.0f);
	this.SetLightColor(SColor(255, 255, 240, 210));
}



f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "grenade")
	{
		return damage * 5;
	}
	
	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid)
	{
		return;
	}

	const f32 vellen = this.getOldVelocity().Length();
	const u8 hitter = this.get_u8("custom_hitter");
	if (vellen > 1.7f)
	{
		Sound::Play("/BombBounce.ogg", this.getPosition(), Maths::Min(vellen / 9.0f, 1.0f), 1.2f);
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "Explosion.png")
{
	if (!isClient()) return;
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}
