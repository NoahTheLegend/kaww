#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 3;
	this.server_SetTimeToDie(5);
	
	this.set_string("custom_explosion_sound", "Molotov_Explode.ogg");
	
	this.Tag("projectile");
	this.Tag("map_damage_dirt");
}

void onTick(CSprite@ this)
{
	ParticleAnimated("SmallFire", this.getBlob().getPosition() + Vec2f(1 - XORRandom(3), -4), Vec2f(0, -1 - XORRandom(2)), 0, 1.0f, 2, 0.25f, false);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer())
	{
		if (solid && blob is null)
		{
			f32 vellen = this.getOldVelocity().Length();
			if (vellen > 3.0f)
			{
				this.server_Die();
			}
		}
		if (blob !is null && blob.isCollidable())
		{
			f32 vellen = this.getOldVelocity().Length();
			if (blob.getName() == "wooden_platform")
			{
				f32 velx = this.getOldVelocity().x;
				f32 vely = this.getOldVelocity().y;
				f32 deg = blob.getAngleDegrees();

				if ((deg < 45.0f || deg > 315.0f) && vely > 0.0f) //up		
				{
					this.server_Die();
				}
				if (deg > 45.0f && deg < 135.0f && velx < 0.0f) //right
				{
					this.server_Die();
				}
				if (deg > 135.0f && deg < 225.0f && vely < 0.0f) //down
				{
					this.server_Die();
				}
				if (deg > 225.0f && deg < 315.0f && velx > 0.0f) //left
				{
					this.server_Die();
				}
			}
			else if (vellen > 2.0f && doesCollideWithBlob(this, blob)) this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().SetEmitSoundPaused(true);
	DoExplosion(this);
}

void DoExplosion(CBlob@ this)
{
	if (!this.hasTag("dead"))
	{
		Explode(this, 8.0f, 2.0f);
		
		if (isServer())
		{
			Vec2f vel = this.getOldVelocity();
			for (int i = 0; i < 6 + XORRandom(2) ; i++)
			{
				CBlob@ blob = server_CreateBlob("flame", -1, this.getPosition() + Vec2f(0, -8));
				Vec2f nv = Vec2f((XORRandom(100) * 0.01f * vel.x * 1.30f), -(XORRandom(100) * 0.01f * 3.00f));
				
				blob.setVelocity(nv);
				blob.server_SetTimeToDie(5 + XORRandom(6));
			}
		}
		
		
		this.Tag("dead");
		this.getSprite().Gib();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return ((blob.isCollidable() && !blob.hasTag("bullet") && blob.getTeamNum() != this.getTeamNum()) || (blob.hasTag("bunker") && blob.getTeamNum() != this.getTeamNum())) && ((blob.getName() == "wooden_platform" || blob.hasTag("door")) || (blob.getTeamNum() == this.getTeamNum() && !blob.getShape().isStatic())); 
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}