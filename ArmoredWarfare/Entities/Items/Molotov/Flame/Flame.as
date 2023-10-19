#include "Hitters.as";
#include "HittersAW.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.4f);
	this.server_SetTimeToDie(2 + XORRandom(3));

	if(isServer())
	{
		this.getCurrentScript().tickFrequency = 15;
	}
	if(isClient())
	{
		this.getCurrentScript().tickFrequency = 2;
	}
	
	/*this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 200, 50));*/

	if(isClient())
	{
		this.getCurrentScript().runFlags |= Script::tick_onscreen;
	}

	this.Tag("trap");
}

void onTick(CBlob@ this)
{
	// print("" + this.getDamageOwnerPlayer().getUsername());

	if (isServer() && this.isInWater()) this.server_Die();

	if (isServer() && this.getTickSinceCreated() > 5) 
	{
		// getMap().server_setFireWorldspace(this.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), true);
		
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
	
		map.server_setFireWorldspace(pos, true);
		
		for (int i = 0; i < 3; i++)
		{
			Vec2f bpos = pos + Vec2f(12 - XORRandom(24), XORRandom(8));
			TileType t = map.getTile(bpos).type;
			map.server_setFireWorldspace(bpos, true);
		}
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius()*3, blobs);
		for (u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b is null) return;
			if (b.getName() == "mat_molotov" && !b.get_bool("active") && !b.isAttached() && !b.isInInventory())
			{
				CBitStream params;
				b.SendCommand(b.getCommandID("activate"), params);
			}
			else if (b.hasTag("flesh") || b.hasTag("weak vehicle") || b.hasTag("apc"))
			{
				if (getGameTime() % 8 == 0)
				{
					this.server_Hit(b, this.getPosition(), Vec2f(0, 0.33f), 0.65f, Hitters::fire, true);
				}
			}
			else if (b.getName() == "woodengate")
			{
				if (getGameTime() % 15 == 0)
				{
					this.server_Hit(b, this.getPosition(), Vec2f(0, 0.33f), 0.66f, Hitters::fire, true);
				}
			}
		}
	}

	if (isClient())
	{
		this.getSprite().SetFrame(XORRandom(6));
		ParticleAnimated("SmallFire", this.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), Vec2f(0, 0), 0, 1.0f, 2, 0.25f, false);
	}
}


bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (!blob.hasTag("flesh") && !blob.hasTag("trap") && !blob.hasTag("food") && !blob.hasTag("material") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer())
	{
		if (solid) 
		{
			Vec2f pos = this.getPosition();
			CMap@ map = getMap();
		
			map.server_setFireWorldspace(pos, true);
			
			for (int i = 0; i < 3; i++)
			{
				Vec2f bpos = pos + Vec2f(12 - XORRandom(24), XORRandom(8));
				TileType t = map.getTile(bpos).type;
				if (map.isTileGround(t) && t != CMap::tile_ground_d0 && (XORRandom(100) < 50 ? true : t != CMap::tile_ground_d1))
				{
					map.server_DestroyTile(bpos, 1, this);
				}
				else
				{
					map.server_setFireWorldspace(bpos, true);
				}
			}
		}
		else if (blob !is null && blob.isCollidable())
		{
			if (this.getTeamNum() != blob.getTeamNum()) this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.0f, Hitters::fire, false);
		}
	}
}