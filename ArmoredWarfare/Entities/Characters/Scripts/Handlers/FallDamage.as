//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base

#include "Hitters.as";
#include "HittersAW.as";
#include "KnockedCommon.as";
#include "FallDamageCommon.as";
#include "PerksCommon.as";
#include "CustomBlocks.as";

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || this.isInInventory())
	{
		return;
	}

	if (blob !is null && (blob.hasTag("player") || blob.hasTag("no falldamage")))
	{
		return; //no falldamage when stomping
	}

	f32 vely = this.getOldVelocity().y;

	if (vely < 0 || Maths::Abs(normal.x) > Maths::Abs(normal.y) * 2) { return; }

	CPlayer@ p = this.getPlayer();
	PerkStats@ stats;
	if (p !is null && p.get("PerkStats", @stats))
	{
		vely *= stats.fall_damage_take_mod;
    }

	CMap@ map = this.getMap();
	Vec2f vel = this.getOldVelocity();

	if (isServer() && vel.y > 6.0f)
	{
		TileType tc = map.getTile(point1+Vec2f(0,4)).type;
        TileType tl = map.getTile(point1-Vec2f(8,-4)).type;
        TileType tr = map.getTile(point1+Vec2f(8,4)).type;

        if (isTileIce(tc))
        {
            TileType utc = map.getTile(point1+Vec2f(0,12)).type;
            TileType utl = map.getTile(point1-Vec2f(8,-12)).type;
            TileType utr = map.getTile(point1+Vec2f(8,12)).type;

            if (!isSolid(map, utc))
                for (u8 i = 0; i < 4; i++) {map.server_DestroyTile(point1+Vec2f(0,4), 15.0f, this);}
            if (isTileIce(tl) && !isSolid(map, utl))
                for (u8 i = 0; i < 4; i++) {map.server_DestroyTile(point1-Vec2f(8,-4), 15.0f, this);}
            if (isTileIce(tr) && !isSolid(map, utr))
                for (u8 i = 0; i < 4; i++) {map.server_DestroyTile(point1+Vec2f(8,4), 15.0f, this);}
        }
	}

	f32 damage = FallDamageAmount(vely);
	if (damage != 0.0f) //interesting value
	{
		bool doknockdown = true;

		if (damage > 0.0f)
		{
			// check if we aren't touching a trampoline
			CBlob@[] overlapping;

			if (this.getOverlapping(@overlapping))
			{
				for (uint i = 0; i < overlapping.length; i++)
				{
					CBlob@ b = overlapping[i];

					if (b.hasTag("no falldamage"))
					{
						return;
					}
				}
			}

			if (damage > 0.1f)
			{
				this.server_Hit(this, point1, normal, damage, Hitters::fall);
			}
			else
			{
				doknockdown = false;
			}
		}

		// stun on fall
		const u8 knockdown_time = 12;

		if (doknockdown && setKnocked(this, knockdown_time))
		{
			if (damage < this.getHealth()) //not dead
				Sound::Play("/BreakBone", this.getPosition());
			else
			{
				Sound::Play("/FallDeath.ogg", this.getPosition());
			}
		}
	}
}
