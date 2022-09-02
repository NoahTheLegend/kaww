#define SERVER_ONLY

// set "hit dmg modifier" in your blob to modify blob hit damage
// set "map dmg modifier" in your blob to modify map hit damage

#include "Hitters.as"

void onInit(CBlob@ this)
{
	if (!this.exists("hit dmg modifier"))
	{
		this.set_f32("hit dmg modifier", 1.0f);
	}

	if (!this.exists("map dmg modifier"))
	{
		this.set_f32("map dmg modifier", 1.0f);
	}

	if (!this.exists("hurtoncollide hitter"))
		this.set_u8("hurtoncollide hitter", Hitters::flying);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (solid)
	{
		Vec2f hitvel = this.getOldVelocity();
		Vec2f hitvec = point1 - this.getPosition();
		f32 coef = hitvec * hitvel;

		if (coef < 0.706f) // check we were flying at it
		{
			return;
		}

		f32 vellen = hitvel.Length();

		if (blob is null)
		{
			// map collision
			CMap@ map = this.getMap();
			point1 -= normal;
			TileType tile = map.getTile(point1).type;

			if (vellen > 0.1f &&
			        this.getMass() > 1.0f &&
			        (map.isTileCastle(tile) ||
			         map.isTileWood(tile)))
			{
				f32 vellen = this.getShape().vellen;
				f32 dmg = this.get_f32("map dmg modifier") * vellen * this.getMass() / 10000.0f;

				if (dmg > 0.1f && map.getSectorAtPosition(point1, "no build") is null)
				{
					map.server_DestroyTile(point1, dmg, this);
				}
			}
		}
		else if (blob.getTeamNum() != this.getTeamNum())
		{
			if (blob.hasTag("vehicle"))
			{
				blob.setVelocity(blob.getOldVelocity()*0.6f);
				this.setVelocity(this.getOldVelocity()*0.6f);
			}
		}
	}
}