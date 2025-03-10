#define SERVER_ONLY
#include "CustomBlocks.as";

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
    if (!solid)
    {
        return;
    }

    CMap@ map = getMap();
    Vec2f vel = this.getOldVelocity();

    f32 surface_damage_mod = this.exists("surface_damage_mod") ? this.get_f32("surface_damage_mod") : 1.0f;

    if (vel.y * this.getMass() * surface_damage_mod >= 1000.0f)
    {
        f32 h = 4;
        f32 width = this.getWidth();
        for (f32 x = -width / 2; x <= width / 2; x += map.tilesize)
        {
            TileType tile_center = map.getTile(point1 + Vec2f(x, h)).type;

            if (isTileIce(tile_center))
            {
                TileType tile_under_center = map.getTile(point1 + Vec2f(x, h + 8)).type;

                if (!isSolid(map, tile_under_center))
                {
                    for (u8 i = 0; i < 4; i++) {map.server_DestroyTile(point1 + Vec2f(x, h), 15.0f, this);}
                }
            }
        }
    }
}