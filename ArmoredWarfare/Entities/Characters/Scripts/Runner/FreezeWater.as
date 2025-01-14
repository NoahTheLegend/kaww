#define SERVER_ONLY

#include "CustomBlocks.as";

int map_width = 0;
int map_height = 0;
Vec2f[] water_tiles;

void onInit(CRules@ this)
{
    onRestart(this);
}

void onRestart(CRules@ this)
{
    CMap@ map = getMap();
    if (map is null) return;

    map_width = map.tilemapwidth;
    map_height = map.tilemapheight;
    
    Vec2f[] empty;
    water_tiles = empty;

    max_iters_per_tick = map_width;
    current_offset = 0;
}

int max_iters_per_tick = 0;
int current_offset = 0;

int search_height = 1;
int interval = 10;
const f32 unfreeze_chance = 0.5f;

void onTick(CRules@ this)
{
    if (getGameTime() % interval == 0 && getBlobByName("info_snow") !is null && find_water_tiles_at_map())
    {
        CMap@ map = getMap();

        for (int i = 0; i < water_tiles.length; i++)
        {
            Vec2f tile_pos = water_tiles[i];

            if (map.isInWater(tile_pos))
            {
                CBlob@[] blobs;
                map.getBlobsInRadius(tile_pos, 4.0f, @blobs);

                bool ignore_tile = false;
                for (int j = 0; j < blobs.length; j++)
                {
                    CBlob@ blob = blobs[j];
                    if (blob !is null && blob.hasTag("player"))
                    {
                        ignore_tile = true;
                        break;
                    }
                }

                if (!ignore_tile) map.server_SetTile(tile_pos, CMap::tile_ice);
            }
        }

        onRestart(this);
    }
}

bool find_water_tiles_at_map()
{
    CMap@ map = getMap();
    if (map is null) return false;

    int tiles_count = map_width * map_height;
    int iters = 0;

    while (iters < max_iters_per_tick && current_offset < tiles_count)
    {
        int tile_idx = current_offset;
        Vec2f tile_pos = map.getTileWorldPosition(tile_idx) + Vec2f(4,4);

        Tile tile = map.getTile(tile_idx);
        Tile tile_above = map.getTile(tile_idx - map_width);
        Tile tile_below = map.getTile(tile_idx + map_width);


        if (map.isInWater(tile_pos) && !map.isInWater(tile_pos - Vec2f(0, 8))
            &&  !isSolid(map, tile.type) && !isSolid(map, tile_above.type)
            && (map.isInWater(tile_pos + Vec2f(0,8)) || isSolid(map, tile_below.type)))
        {
            if (XORRandom(100) < (1.0f-unfreeze_chance) * 100.0f)
                water_tiles.push_back(tile_pos);
        }

        current_offset++;
        iters++;
    }

    if (current_offset >= tiles_count)
    {
        return true;
    }

    return false;
}