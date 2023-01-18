#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(100) < 30 ? true : false);

	this.getSprite().SetZ(5);

	this.Tag("destructable");
	this.Tag("weakprop");
	this.Tag("builder always hit");
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if (customData == Hitters::sword)
	{
		damage *= 0.5f;
	}

	for (uint i = 0; i < 10 + XORRandom(10); i++)
	{
		Vec2f velr = Vec2f((XORRandom(19) - 9.0f)/6, (XORRandom(10) - 9.0f)/3);
		velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

		ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 255), true);
	}

	this.getSprite().PlaySound("GlassBreak", 2.2f, 0.7f + XORRandom(40) * 0.01f);

	return damage;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f collisionPos )
{
	if (blob !is null && blob.hasTag("flesh"))
	{
		this.server_Hit(this, this.getPosition(), Vec2f(0,0), 0.175f, Hitters::builder);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("flesh") || blob.hasTag("collideswithglass"))
	{
		return true;
	}

    return false;
}