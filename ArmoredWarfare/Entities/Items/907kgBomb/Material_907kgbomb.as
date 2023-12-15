#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";

const u8 boom_max = 6;

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.set_u8("boom_start", 0);
	this.set_bool("booming", false);
	this.Tag("heavy weight");
		
	this.set_f32("map_damage_ratio", 0.01f);
	this.getCurrentScript().tickFrequency = 10;
	
	this.Tag("explosive");
	this.Tag("always bullet collide");
	this.Tag("trap");
	this.Tag("bomber ammo");
	this.Tag("no_armory_pickup");
	this.Tag("weapon");
	
	this.maxQuantity = 1;
}

void DoExplosion(CBlob@ this, Vec2f velocity)
{
	ShakeScreen(512, 64, this.getPosition());
	f32 modifier = this.get_u8("boom_start") / 3.0f;
	
	this.set_f32("map_damage_radius", 6.0f * this.get_u8("boom_start"));
	
	for (int i = 0; i < 4; i++)
	{
		Explode(this, 64.0f * modifier, 5.0f);
		//guarantly hit blobs
		if (getNet().isServer())
		{
			CBlob@[] bs;
			getMap().getBlobsInRadius(this.getPosition(), 80.0f*modifier, bs);
			for (u32 i = 0; i < bs.length; i++)
			{
				CBlob@ b = bs[i];
				if (b is null) continue;
				if (b.hasTag("vehicle"))
				{
					this.server_Hit(b, b.getPosition(), Vec2f(0,-100), 5.0f / (modifier+1), Hitters::keg);
				}
				if (b.hasTag("flesh"))
				{
					this.server_Hit(b, b.getPosition(), Vec2f(0,0.01f), 15.0f, Hitters::keg);
				}
			}
		}
	}
}

void onTick(CBlob@ this)
{
	if (isServer() && this.isAttached())
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (ap !is null && ap.getOccupied() !is null)
		{
			CBlob@ oc = ap.getOccupied();
			AttachmentPoint@[] aps;
			oc.getAttachmentPoints(aps);
			for (u8 i = 0; i < aps.size(); i++)
			{
				AttachmentPoint@ api = aps[i];
				if (api is null) continue;
				if (api.getOccupied() is null) continue;

				if (api.getOccupied().hasTag("aerial") || api.getOccupied().hasTag("machinegun"))
				{
					this.server_DetachFromAll();
					break;
				}
			}
		}
	}
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
	if (this.exists("damage") && this.get_f32("damage") > this.getInitialHealth()) 
	{
		if (!this.get_bool("booming")) ExplosionEffects(this);
		this.set_bool("booming", true);
	}
	if (hitterBlob !is null && hitterBlob.getTeamNum() == this.getTeamNum())
	{
		damage *= 0.1f;
	}
	this.add_f32("damage", damage);
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

	if (vellen > 6.0f)
	{
		if (!this.get_bool("booming")) ExplosionEffects(this);
		this.set_bool("booming", true);

		// DoExplosion(this, this.getOldVelocity());
	}
}