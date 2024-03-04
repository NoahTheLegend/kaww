#include "Hitters.as";
#include "HittersAW.as";
#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;

    this.Tag("destructable");
	this.Tag("bunker");
	this.Tag("structure");
	this.Tag("sandbags");

	this.Tag("builder always hit");
	this.Tag("builder urgent hit");

	this.setPosition(this.getPosition()+Vec2f(0,8));

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(-100.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", "Sandbags.png", 32, 32);
	if (front !is null)
	{
		front.SetFrameIndex(11);
		//sprite.SetFrameIndex(11);

		front.SetRelativeZ(146.88f);
		front.SetOffset(Vec2f(0.0f, -11.0f));
	}

	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
	if (isServer() && this.getTickSinceCreated() == 60)
	{
		CMap@ map = this.getMap();
		if (map !is null)
		{//dont rotate it depending on side after constructing map
			this.SetFacingLeft(this.getPosition().x > map.tilemapwidth*4);
		}
	}
	
	if (!getMap().hasSupportAtPos(this.getPosition()))
	{
		this.server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("projectile") && blob.getTickSinceCreated() > 1)
	{
		return true;
	}
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	for (uint i = 0; i < (3 + XORRandom(damage*3)); i++)
	{
		Vec2f velr = Vec2f((XORRandom(29) - 15.0f)/9, (XORRandom(10) - 15.0f)/4);
		velr += hitterBlob.getVelocity()/9;
		velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

		ParticlePixel(this.getPosition(), velr, SColor(255, 200, 150, 40), true);
	}

	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet);
	if (is_bullet)
	{
		Sound::Play("/BulletSandbag", this.getPosition(), 1.55f, 0.85f + XORRandom(40) * 0.01f);

		MakeDustParticle((hitterBlob.getPosition() + this.getPosition())/2, "/dust2.png");

		return damage / 3;
	}
	if (hitterBlob.getName() == "ballista_bolt")
	{
		Sound::Play("/BulletSandbag", this.getPosition(), 1.55f, 0.85f + XORRandom(40) * 0.01f);
		if (!v_fastrender) MakeDustParticle((hitterBlob.getPosition() + this.getPosition())/2, "/dust2.png");

		return damage / 10;
	}
	if (hitterBlob.hasTag("atgrenade"))
	{
		if (!v_fastrender) MakeDustParticle((hitterBlob.getPosition() + this.getPosition())/2, "/dust2.png");
		return damage / 10.0f;
	}
	return damage;
}