#define CLIENT_ONLY

void onInit(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
	
    sprite.PlaySound("/RpgExplosion", 1.1, 0.9f + XORRandom(20) * 0.01f);
    MakeParticles(this);
}

void MakeParticles(CBlob@ this)
{
    Vec2f pos = this.getPosition();

	for (int i = 0; i < 16; i++)
	{
		ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(16) - 8, XORRandom(12) - 6), getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + Vec2f(0.0f, -0.8f), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 3 + XORRandom(4), XORRandom(45) * -0.00005f, true);
	}
	for (int i = 0; i < 6; i++)
	{
		ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(20) * 0.005f, 360), float(XORRandom(360)), 0.75f + XORRandom(40) * 0.01f, 5 + XORRandom(6), XORRandom(30) * -0.0001f, true);
	}

	for (int i = 0; i < (20 + XORRandom(20)); i++)
	{
		makeGibParticle("GenericGibs", pos - Vec2f(0, 2), getRandomVelocity((pos + Vec2f(XORRandom(32) - 16, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	            2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}
}