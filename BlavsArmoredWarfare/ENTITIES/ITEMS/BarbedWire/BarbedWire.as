#include "MapFlags.as"
#include "Hitters.as"

void onInit(CBlob@ this)
{
    this.getSprite().getConsts().accurateLighting = false;  
	this.getSprite().RotateBy(XORRandom(4) * 90, Vec2f(0, 0));
	this.getSprite().SetZ(-50); //background
	this.Tag("has damage owner");

	// this.getCurrentScript().runFlags |= Script::tick_not_attached;
	
	this.Tag("builder always hit");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer() && blob !is null && blob.hasTag("flesh") && blob.getTeamNum() != this.getTeamNum() && !blob.isAttached())
	{
		this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.15f, Hitters::spikes, true);
	}
}

void onTick(CBlob@ this)
{
	if ((getGameTime()+this.getNetworkID())%300==0)
	{
		CMap@ map = this.getMap();
		bool kill = true;
		for (u8 i = 0; i < 4; i++)
		{
			switch (i)
			{
				case 0:
				{
					TileType t = map.getTile(this.getPosition()+Vec2f(0,8)).type;
					if (t != 0)
					{
						kill = false;
						break;
					}
				}
				case 1:
				{
					TileType t = map.getTile(this.getPosition()+Vec2f(8,0)).type;
					if (t != 0)
					{
						kill = false;
						break;
					}
				}
				case 2:
				{
					TileType t = map.getTile(this.getPosition()+Vec2f(-8,0)).type;
					if (t != 0)
					{
						kill = false;
						break;
					}
				}
				case 3:
				{
					TileType t = map.getTile(this.getPosition()+Vec2f(0,-8)).type;
					if (t != 0)
					{
						kill = false;
						break;
					}
				}
			}
		}
		if (isServer() && kill) this.server_Die();
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is null && hitterBlob !is this && (customData == Hitters::builder || customData == Hitters::sword))
	{
		if (isServer() && XORRandom(2)==0) this.server_Hit(hitterBlob, this.getPosition(), Vec2f(0, 0), 0.15f, Hitters::spikes, false);
	}
	if (isClient())
	{
		this.getSprite().PlaySound("dig_stone.ogg", 1.0f, 0.975f);
	}

	if (customData == Hitters::builder) damage *= 10;
	
	return damage;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}