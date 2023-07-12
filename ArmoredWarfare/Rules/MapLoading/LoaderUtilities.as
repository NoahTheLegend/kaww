// LoaderUtilities.as

#include "DummyCommon.as";
#include "CustomBlocks.as";

bool onMapTileCollapse(CMap@ map, u32 offset)
{
	if(isDummyTile(map.getTile(offset).type))
	{
		CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));
		if(blob !is null)
		{
			blob.server_Die();
		}
	}
	return true;
}

const Vec2f[] directions =
{
	Vec2f(0, -8),
	Vec2f(0, 8),
	Vec2f(8, 0),
	Vec2f(-8, 0)
};

TileType server_onTileHit(CMap@ map, f32 damage, u32 index, TileType oldTileType)
{
    if(map.getTile(index).type > 255)
	{
		switch(oldTileType)
		{
            case CMap::tile_cdirt:
			case CMap::tile_cdirt_v0:
			case CMap::tile_cdirt_v1:
			case CMap::tile_cdirt_v2:
			case CMap::tile_cdirt_v3:
			case CMap::tile_cdirt_v4:
			{
				Vec2f pos = map.getTileWorldPosition(index);

				//map.server_SetTile(pos, CMap::tile_cdirt_d0);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE);

				//for (u8 i = 0; i < 4; i++)
				//{
				//	cdirt_Update(map, map.getTileWorldPosition(index) + directions[i]);
				//}
				return CMap::tile_cdirt_d0;
			}
            case CMap::tile_cdirt_d0:
            case CMap::tile_cdirt_d1:
            case CMap::tile_cdirt_d2:
			{
                return oldTileType + 1;
			}

            case CMap::tile_cdirt_d3:
                return CMap::tile_ground_back;

			case CMap::tile_scrap:
				return CMap::tile_scrap_d0;

			case CMap::tile_scrap_d0:
			case CMap::tile_scrap_d1:
			case CMap::tile_scrap_d2:
			case CMap::tile_scrap_d3:
			case CMap::tile_scrap_d4:
			case CMap::tile_scrap_d5:
				return oldTileType + 1;

			case CMap::tile_scrap_d6:
				return CMap::tile_empty;
        }
    }
    return map.getTile(index).type;
}

void cdirt_SetTile(CMap@ map, Vec2f pos)
{
	map.SetTile(map.getTileOffset(pos), CMap::tile_cdirt + cdirt_GetMask(map, pos));

	for (u8 i = 0; i < 4; i++)
	{
		cdirt_Update(map, pos + directions[i]);
	}
}

u8 cdirt_GetMask(CMap@ map, Vec2f pos)
{
	u8 mask = 0;

	for (u8 i = 0; i < 4; i++)
	{
		if (isCDirtTile(map, pos + directions[directions.length-i-1])) mask = (i==2?0:i>0?i-1:i);
	}

	return mask;
}

void cdirt_Update(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	if (isCDirtTile(map, pos))
		map.SetTile(map.getTileOffset(pos),CMap::tile_cdirt+cdirt_GetMask(map, pos));
}

bool isCDirtTile(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_cdirt && tile <= CMap::tile_cdirt_d3;
}

void OnCDirtTileHit(CMap@ map, u32 index)
{
    map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);

	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);
		for (int i = 0; i < 3; i++)
		{
			Vec2f vel = getRandomVelocity( 0.6f, 2.0f, 180.0f);
			vel.y = -Maths::Abs(vel.y)+Maths::Abs(vel.x)/4.0f-2.0f-float(XORRandom(100))/100.0f;
			SColor color = (XORRandom(10) % 2 == 1) ? SColor(255, 122, 108, 47)
			: SColor(255, 168, 155, 93);
			ParticlePixel(pos+Vec2f(4, 0), vel, color, true);
		}
	}
	Sound::Play("dig_dirt" + (1 + XORRandom(3)) + ".ogg", map.getTileWorldPosition(index), 1.0f, 0.9f);
}



void scrap_SetTile(CMap@ map, Vec2f pos)
{
	map.SetTile(map.getTileOffset(pos), CMap::tile_scrap);
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);
}

bool isScrapTile(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_scrap && tile <= CMap::tile_scrap_d6;
}

void OnScrapTileHit(CMap@ map, u32 index)
{
    map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);
	Vec2f pos = map.getTileWorldPosition(index);

	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);
		for (int i = 0; i < 3; i++)
		{
			Vec2f vel = getRandomVelocity( 0.6f, 2.0f, 180.0f);
			vel.y = -Maths::Abs(vel.y)+Maths::Abs(vel.x)/4.0f-2.0f-float(XORRandom(100))/100.0f;
			SColor color = (XORRandom(10) % 2 == 1) ? SColor(255, 170, 108, 47)
			: SColor(255, 218, 155, 93);
			ParticlePixel(pos+Vec2f(4, 0), vel, color, true);
		}
	}
	Sound::Play("dig_stone.ogg", pos, 1.0f, 0.9f);
}



void OnCDirtTileDestroyed(CMap@ map, u32 index)
{
	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);
		for (int i = 0; i < 3; i++)
		{
			Vec2f vel = getRandomVelocity( 0.6f, 2.0f, 180.0f);
			vel.y = -Maths::Abs(vel.y)+Maths::Abs(vel.x)/4.0f-2.0f-float(XORRandom(100))/100.0f;
			SColor color = (XORRandom(10) % 2 == 1) ? SColor(255, 122, 108, 47)
			: SColor(255, 168, 155, 93);
			ParticlePixel(pos+Vec2f(4, 0), vel, color, true);
		}
        ParticleAnimated("Smoke.png", pos+Vec2f(4, 0),
		Vec2f(0, 0), 0.0f, 1.0f, 3, 0.0f, false);
		Sound::Play("destroy_dirt.ogg", pos, 1.0f, 1.0f);
	}
}

void OnScrapTileDestroyed(CMap@ map, u32 index)
{
	Vec2f pos = map.getTileWorldPosition(index);
	if (isClient())
	{
		for (int i = 0; i < 3; i++)
		{
			Vec2f vel = getRandomVelocity( 0.6f, 2.0f, 180.0f);
			vel.y = -Maths::Abs(vel.y)+Maths::Abs(vel.x)/4.0f-2.0f-float(XORRandom(100))/100.0f;
			SColor color = (XORRandom(10) % 2 == 1) ? SColor(255, 166, 108, 47)
			: SColor(255, 210, 155, 93);
			ParticlePixel(pos+Vec2f(4, 0), vel, color, true);
		}
		Sound::Play("dig_stone.ogg", pos, 1.0f, 0.85f);
		Sound::Play("destroy_wall.ogg", pos, 1.0f, 1.15f);
	}
	if(isServer())
	{
		CBlob@ scrap = server_CreateBlobNoInit("mat_scrap");
		if (scrap !is null)
		{
			scrap.server_setTeamNum(-1);
			scrap.setPosition(pos);
			scrap.Init();
			scrap.server_SetQuantity(1);
			
			
		}
	}
}

void onSetTile(CMap@ map, u32 index, TileType tile_new, TileType tile_old)
{
    if (isClient() && (tile_new == CMap::tile_ground || tile_new == CMap::tile_cdirt)) Sound::Play("dig_dirt" + (1 + XORRandom(3)) + ".ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
	Vec2f pos = map.getTileWorldPosition(index);

    switch(tile_new)
	{
		case CMap::tile_empty:
		case CMap::tile_ground_back:
		{
			if(tile_old == CMap::tile_cdirt_d3)
				OnCDirtTileDestroyed(map, index);
			else if (tile_old == CMap::tile_scrap_d6)
				OnScrapTileDestroyed(map, index);

			break;
		}
	}

    if (map.getTile(index).type > 255)
	{
		u32 id = tile_new;
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			case CMap::tile_cdirt:
			{
				Vec2f pos = map.getTileWorldPosition(index);
				cdirt_SetTile(map, pos);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::WATER_PASSES | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);

				//if (isClient()) Sound::Play("dig_dirt.ogg", map.getTileWorldPosition(index), 1.0f, 1.15f);
				break;
			}
            case CMap::tile_cdirt_v0:
            case CMap::tile_cdirt_v1:
            case CMap::tile_cdirt_v2:
            case CMap::tile_cdirt_v3:
            case CMap::tile_cdirt_v4:
			case CMap::tile_cdirt_d0:
			case CMap::tile_cdirt_d1:
			case CMap::tile_cdirt_d2:
			case CMap::tile_cdirt_d3:
            {
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::WATER_PASSES | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
				OnCDirtTileHit(map, index);
				break;
			}

            case CMap::tile_scrap:
			{
				Vec2f pos = map.getTileWorldPosition(index);
				map.server_SetTile(pos, CMap::tile_scrap);
				scrap_SetTile(map, pos);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::WATER_PASSES | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);

				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.2f);
				break;
			}
            case CMap::tile_scrap_d0:
            case CMap::tile_scrap_d1:
            case CMap::tile_scrap_d2:
            case CMap::tile_scrap_d3:
            case CMap::tile_scrap_d4:
            case CMap::tile_scrap_d5:
            case CMap::tile_scrap_d6:
            {
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::WATER_PASSES | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
				OnScrapTileHit(map, index);
				break;
			}
        }
    }

	if(isDummyTile(tile_new))
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			case Dummy::SOLID:
			case Dummy::OBSTRUCTOR:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			case Dummy::BACKGROUND:
			case Dummy::OBSTRUCTOR_BACKGROUND:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				break;
			case Dummy::LADDER:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::LADDER | Tile::WATER_PASSES);
				break;
			case Dummy::PLATFORM:
				map.AddTileFlag(index, Tile::PLATFORM);
				break;
		}
	}
}