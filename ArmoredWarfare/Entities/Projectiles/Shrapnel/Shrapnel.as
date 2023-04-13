#include "Hitters.as";
#include "Explosion.as";
#include "ParticleSparks.as";
#include "MakeDustParticle.as";

const Vec2f[] dir =
{
	Vec2f(8, 0),
	Vec2f(-8, 0),
	Vec2f(0, 8),
	Vec2f(0, -8)
};

void onInit(CBlob@ this)
{
	this.getSprite().SetFrameIndex(XORRandom(4));
	
	this.Tag("ignore fall");
	this.Tag("shrapnel");

	this.getShape().getConsts().collideWhenAttached = false;
}

void onTick(CBlob@ this)
{
	/*
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	if (map is null) return;
	
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, 4, @blobs);
	
	for (int i = 0; i < blobs.length; i++)
	{
		if (blobs[i] is null) return;
		if (blobs[i].hasTag("shrapnel")) return;
		if (blobs[i].hasTag("flesh") && blobs[i].getTeamNum() != this.getTeamNum()) continue;

		this.server_Hit(blobs[i], pos, Vec2f_zero, 1.25f+XORRandom(6)*0.1f, Hitters::spikes, true);
		this.server_Die();
	}
	*/
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	if (blob.hasTag("flesh") && blob.getTeamNum() == this.getTeamNum()) return;

	if (blob.hasTag("door") || blob.hasTag("platform"))
	{
		if (isServer())
		{
			this.server_Hit(blob, this.getPosition(), Vec2f_zero, 1.0f+XORRandom(6)*0.1f, Hitters::spikes, true);
		 	this.server_Die();
		}
		return;
	}

	if (solid)
	{
		if (isServer()) this.server_Die();
		return;
	}
	
	/*
	CMap@ map = getMap();
	for (int i = 0; i < dir.length; i++)
	{
		TileType tile = map.getTile(this.getPosition() + dir[i]).type;
		if (!map.isTileGround(tile) && !map.isTileGroundStuff(tile)) map.server_DestroyTile(this.getPosition() + dir[i], 1.0f);
	}
	*/
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return false;
}