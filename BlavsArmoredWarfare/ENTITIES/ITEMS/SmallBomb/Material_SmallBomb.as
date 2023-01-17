#include "Hitters.as";
#include "Explosion.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);


	this.set_bool("map_damage_raycast", true);
	this.set_Vec2f("explosion_offset", Vec2f(0, 16));

	this.set_u8("stack size", 1);
	this.set_f32("bomb angle", 90);

	// this.Tag("map_damage_dirt");

	this.Tag("explosive");
	this.Tag("medium weight");
	this.Tag("always bullet collide");
	this.Tag("no_armory_pickup");

	this.maxQuantity = 4;
	if (isServer()) this.server_SetQuantity(this.maxQuantity);
}

void onDie(CBlob@ this)
{
	if (this.hasTag("DoExplode"))
	{
		DoExplosion(this);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onTick(CBlob@ this)
{
	switch (this.getQuantity())
	{
		case 1:
		{
			this.getSprite().SetFrameIndex(0);
			break;
		}
		case 2:
		{
			this.getSprite().SetFrameIndex(1);
			break;
		}
		case 3:
		{
			this.getSprite().SetFrameIndex(2);
			break;
		}
		case 4:
		{
			this.getSprite().SetFrameIndex(3);
			break;
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage >= this.getHealth() && !this.hasTag("dead"))
	{
		this.Tag("DoExplode");
		//this.set_f32("bomb angle", 90);
		this.server_Die();
	}

	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (!solid) return;

	f32 vellen = this.getOldVelocity().Length();
	if (vellen >= 8.0f) 
	{	
		this.Tag("DoExplode");
		this.server_Die();
	}
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();

	f32 random = XORRandom(16);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = this.getAngleDegrees() - this.get_f32("bomb angle");

	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (24.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.3f);

	WarfareExplode(this, 32.0f + random, (3.0f+(XORRandom(31)*0.1f)) * modifier);

	if(isClient())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();

		for (int i = 0; i < 35; i++)
		{
			MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(-angle, XORRandom(220) * 0.01f, 90), particles[XORRandom(particles.length)]);
		}

		this.getSprite().Gib();
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}
