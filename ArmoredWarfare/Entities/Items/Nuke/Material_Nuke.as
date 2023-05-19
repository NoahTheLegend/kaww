#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";

const u8 boom_max = 16;

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.set_u8("boom_start", 0);
	this.set_bool("booming", false);
	this.Tag("heavy weight");
		
	this.set_f32("map_damage_ratio", 0.5f);
	this.getCurrentScript().tickFrequency = 5;
	
	this.Tag("explosive");
	this.Tag("always bullet collide");
	
	this.maxQuantity = 1;
}

void DoExplosion(CBlob@ this, Vec2f velocity)
{
	ShakeScreen(512, 64, this.getPosition());
	f32 modifier = this.get_u8("boom_start") / 3.0f;
	
	this.set_f32("map_damage_radius", 14.0f * this.get_u8("boom_start"));
	
	for (int i = 0; i < 4; i++)
	{
		Explode(this, 86.0f * modifier, 32.0f);
		//guarantly hit blobs
		if (getNet().isServer())
		{
			CBlob@[] bs;
			getMap().getBlobsInRadius(this.getPosition(), 128.0f*modifier, bs);
			for (u32 i = 0; i < bs.length; i++)
			{
				CBlob@ b = bs[i];
				if (b is null) continue;
				if (b.hasTag("flesh") || b.hasTag("vehicle"))
				{
					this.server_Hit(b, b.getPosition(), this.getOldVelocity(), 5.0f / (modifier+1), Hitters::keg);
				}
			}
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.get_bool("booming") && this.get_u8("boom_start") < boom_max)
	{
		DoExplosion(this, Vec2f(0, 0));
		this.set_u8("boom_start", this.get_u8("boom_start") + 1);
		
		if (this.get_u8("boom_start") == boom_max) this.server_Die();
		
		// print("" + this.get_u8("boom_start"));
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() != this.getTeamNum() || hitterBlob is null)
	{
		if (!this.get_bool("booming")) ExplosionEffects(this);
		this.set_bool("booming", true);
	}
	return damage;
}

void ExplosionEffects( CBlob@ this )
{
	Vec2f pos = this.getPosition();

	CParticle@ p = ParticleAnimated("explosion-huge1.png",
		pos - Vec2f(0,40),
		Vec2f(0.0,0.0f),
		1.0f, 1.0f,
		4,
		0.0f, true );
	if (p != null)
	{
		p.Z = 100;
	}

	SetScreenFlash(200, 255, 255, 100);
	Sound::Play("explosion-big1.ogg");

    this.getSprite().SetEmitSoundPaused( true );
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && !blob.hasTag("flesh") ? !blob.isCollidable() : !solid) return;

	f32 vellen = this.getOldVelocity().Length();

	if (vellen > 5.0f)
	{
		if (!this.get_bool("booming")) ExplosionEffects(this);
		this.set_bool("booming", true);

		// DoExplosion(this, this.getOldVelocity());
	}
}