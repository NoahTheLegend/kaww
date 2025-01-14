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

			case CMap::tile_scrap_v0:
			case CMap::tile_scrap_v1:
			case CMap::tile_scrap_v2:
			case CMap::tile_scrap_v3:
			case CMap::tile_scrap_v4:
			case CMap::tile_scrap_v5:
			case CMap::tile_scrap_v6:
			case CMap::tile_scrap_v7:
			case CMap::tile_scrap_v8:
			case CMap::tile_scrap_v9:
			case CMap::tile_scrap_v10:
			case CMap::tile_scrap_v11:
			case CMap::tile_scrap_v12:
			case CMap::tile_scrap_v13:
			case CMap::tile_scrap_v14:
			{
				Vec2f pos = map.getTileWorldPosition(index);

				map.server_SetTile(pos, CMap::tile_scrap_d0);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE);

				for (u8 i = 0; i < 4; i++)
				{
					scrap_Update(map, map.getTileWorldPosition(index) + directions[i]);
				}
				return CMap::tile_scrap_d0;
			}

			case CMap::tile_scrap_d0:
			case CMap::tile_scrap_d1:
			case CMap::tile_scrap_d2:
			case CMap::tile_scrap_d3:
			case CMap::tile_scrap_d4:
			case CMap::tile_scrap_d5:
				return oldTileType + 1;

			case CMap::tile_scrap_d6:
				return CMap::tile_empty;

			case CMap::tile_ice:
				return CMap::tile_ice_d2;

			case CMap::tile_ice_v0:
			case CMap::tile_ice_v1:
			case CMap::tile_ice_v2:
			case CMap::tile_ice_v3:
			case CMap::tile_ice_v4:
			case CMap::tile_ice_v5:
			case CMap::tile_ice_v6:
			case CMap::tile_ice_v7:
			case CMap::tile_ice_v8:
			case CMap::tile_ice_v9:
			case CMap::tile_ice_v10:
			case CMap::tile_ice_v11:
			case CMap::tile_ice_v12:
			case CMap::tile_ice_v13:
			case CMap::tile_ice_v14:
			{
				Vec2f pos = map.getTileWorldPosition(index);

				map.server_SetTile(pos, CMap::tile_ice_d2);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION | Tile::LIGHT_PASSES);
				map.RemoveTileFlag(index, Tile::LIGHT_SOURCE);

				for (u8 i = 0; i < 4; i++)
				{
					ice_Update(map, map.getTileWorldPosition(index) + directions[i]);
				}
				return CMap::tile_ice_d2;
			}

			case CMap::tile_ice_d0:
			case CMap::tile_ice_d1:
			case CMap::tile_ice_d2:
				return oldTileType + 1;

			case CMap::tile_ice_d3:
				return CMap::tile_empty;

			// unbreakable metal
			case CMap::tile_metal:
			case CMap::tile_metal_v0:
			case CMap::tile_metal_v1:
			case CMap::tile_metal_v2:
			case CMap::tile_metal_v3:
			case CMap::tile_metal_v4:
			case CMap::tile_metal_v5:
			case CMap::tile_metal_v6:
			case CMap::tile_metal_v7:
			case CMap::tile_metal_v8:
			case CMap::tile_metal_v9:
			case CMap::tile_metal_v10:
			case CMap::tile_metal_v11:
			case CMap::tile_metal_v12:
			case CMap::tile_metal_v13:
			case CMap::tile_metal_v14:
				OnMetalTileHit(map, index);
				return oldTileType;

			case CMap::tile_metal_d0:
			case CMap::tile_metal_d1:
			case CMap::tile_metal_d2:
			case CMap::tile_metal_d3:
			case CMap::tile_metal_d4:
			case CMap::tile_metal_d5:
			case CMap::tile_metal_d6:
			case CMap::tile_metal_d7:
				OnMetalTileHit(map, index);
				return oldTileType + 1;
			
			case CMap::tile_metal_d8:
				return CMap::tile_empty;
			
			// unbreakable metal back
			case CMap::tile_metal_back:
			case CMap::tile_metal_back_u:
			case CMap::tile_metal_back_d:
			case CMap::tile_metal_back_m:
				OnMetalBackTileHit(map, index);
				return oldTileType;

			case CMap::tile_metal_back_d0:
			case CMap::tile_metal_back_d1:
			case CMap::tile_metal_back_d2:
			case CMap::tile_metal_back_d3:
			case CMap::tile_metal_back_d4:
			case CMap::tile_metal_back_d5:
			case CMap::tile_metal_back_d6:
			case CMap::tile_metal_back_d7:
				OnMetalBackTileHit(map, index);
				return oldTileType + 1;

			case CMap::tile_metal_back_d8:
				return CMap::tile_empty;
        }
    }
    return map.getTile(index).type;
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
			else if (tile_old == CMap::tile_scrap_d6
						|| tile_old == CMap::tile_metal_d8
						|| tile_old == CMap::tile_metal_back_d8)
				OnScrapTileDestroyed(map, index);
			else if (tile_old == CMap::tile_ice_d3)
				OnIceTileDestroyed(map, index);

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
				map.SetTileSupport(index, 255);

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
				map.SetTileSupport(index, 255);

				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::WATER_PASSES | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
				OnCDirtTileHit(map, index);
				break;
			}

			case CMap::tile_scrap:
			{
				Vec2f pos = map.getTileWorldPosition(index);

				scrap_SetTile(map, pos);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);

				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);

				break;
			}

            case CMap::tile_scrap_v0:
			case CMap::tile_scrap_v1:
			case CMap::tile_scrap_v2:
			case CMap::tile_scrap_v3:
			case CMap::tile_scrap_v4:
			case CMap::tile_scrap_v5:
			case CMap::tile_scrap_v6:
			case CMap::tile_scrap_v7:
			case CMap::tile_scrap_v8:
			case CMap::tile_scrap_v9:
			case CMap::tile_scrap_v10:
			case CMap::tile_scrap_v11:
			case CMap::tile_scrap_v12:
			case CMap::tile_scrap_v13:
			case CMap::tile_scrap_v14:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				break;

			case CMap::tile_scrap_d0:
			case CMap::tile_scrap_d1:
			case CMap::tile_scrap_d2:
			case CMap::tile_scrap_d3:
			case CMap::tile_scrap_d4:
			case CMap::tile_scrap_d5:
			case CMap::tile_scrap_d6:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				OnScrapTileHit(map, index);
				break;

			case CMap::tile_ice:
			{
				Vec2f pos = map.getTileWorldPosition(index);

				ice_SetTile(map, pos);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION | Tile::LIGHT_PASSES);
				map.RemoveTileFlag(index, Tile::LIGHT_SOURCE | Tile::WATER_PASSES);

				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.3f);

				break;
			}

            case CMap::tile_ice_v0:
			case CMap::tile_ice_v1:
			case CMap::tile_ice_v2:
			case CMap::tile_ice_v3:
			case CMap::tile_ice_v4:
			case CMap::tile_ice_v5:
			case CMap::tile_ice_v6:
			case CMap::tile_ice_v7:
			case CMap::tile_ice_v8:
			case CMap::tile_ice_v9:
			case CMap::tile_ice_v10:
			case CMap::tile_ice_v11:
			case CMap::tile_ice_v12:
			case CMap::tile_ice_v13:
			case CMap::tile_ice_v14:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				break;

			case CMap::tile_ice_d0:
			case CMap::tile_ice_d1:
			case CMap::tile_ice_d2:
			case CMap::tile_ice_d3:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				OnIceTileHit(map, index);
				break;

			case CMap::tile_metal:
			{
				map.SetTileSupport(index, 255);
				Vec2f pos = map.getTileWorldPosition(index);

				metal_SetTile(map, pos);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);

				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.1f);

				break;
			}

            case CMap::tile_metal_v0:
			case CMap::tile_metal_v1:
			case CMap::tile_metal_v2:
			case CMap::tile_metal_v3:
			case CMap::tile_metal_v4:
			case CMap::tile_metal_v5:
			case CMap::tile_metal_v6:
			case CMap::tile_metal_v7:
			case CMap::tile_metal_v8:
			case CMap::tile_metal_v9:
			case CMap::tile_metal_v10:
			case CMap::tile_metal_v11:
			case CMap::tile_metal_v12:
			case CMap::tile_metal_v13:
			case CMap::tile_metal_v14:
				map.SetTileSupport(index, 255);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				break;

			case CMap::tile_metal_d0:
			case CMap::tile_metal_d1:
			case CMap::tile_metal_d2:
			case CMap::tile_metal_d3:
			case CMap::tile_metal_d4:
			case CMap::tile_metal_d5:
			case CMap::tile_metal_d6:
			case CMap::tile_metal_d7:
			case CMap::tile_metal_d8:
				map.SetTileSupport(index, 10);
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				map.RemoveTileFlag(index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::WATER_PASSES);
				OnMetalTileHit(map, index);
				break;

			case CMap::tile_metal_back:
			{
				Vec2f pos = map.getTileWorldPosition(index);
				OnMetalBackTileUpdate(false, true, map, pos);

				TileType up = map.getTile(pos - Vec2f( 0.0f, 8.0f)).type;
				TileType down = map.getTile(pos + Vec2f( 0.0f, 8.0f)).type;
				bool isUp = (up >= CMap::tile_metal_back && up <= CMap::tile_metal_back_m) ? true : false;
				bool isDown = (down >= CMap::tile_metal_back && down <= CMap::tile_metal_back_m) ? true : false;

				if (isUp && isDown)
					map.SetTile(index, CMap::tile_metal_back_m);
				else if (isUp || isDown)
				{
					if(isUp && !isDown)
						map.SetTile(index, CMap::tile_metal_back_u);
					if(!isUp && isDown)
						map.SetTile(index, CMap::tile_metal_back_d);
				}
				else
					map.SetTile(index, CMap::tile_metal_back);

				map.AddTileFlag(index, Tile::BACKGROUND | Tile::WATER_PASSES | Tile::LIGHT_PASSES);
				map.RemoveTileFlag(index, Tile::LIGHT_SOURCE | Tile::SOLID | Tile::COLLISION);
				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
				break;
			}

			case CMap::tile_metal_back_u:
			case CMap::tile_metal_back_d:
			case CMap::tile_metal_back_m:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				if (isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
				break;

			case CMap::tile_metal_back_d0:
			case CMap::tile_metal_back_d1:
			case CMap::tile_metal_back_d2:
			case CMap::tile_metal_back_d3:
			case CMap::tile_metal_back_d4:
			case CMap::tile_metal_back_d5:
			case CMap::tile_metal_back_d6:
			case CMap::tile_metal_back_d7:
			case CMap::tile_metal_back_d8:
				OnMetalBackTileHit(map, index);
				break;
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

	if (isServer())
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

void scrap_SetTile(CMap@ map, Vec2f pos)
{
	map.SetTile(map.getTileOffset(pos), CMap::tile_scrap + scrap_GetMask(map, pos));

	for (u8 i = 0; i < 4; i++)
	{
		scrap_Update(map, pos + directions[i]);
	}
}

u8 scrap_GetMask(CMap@ map, Vec2f pos)
{
	u8 mask = 0;

	for (u8 i = 0; i < 4; i++)
	{
		if (isScrapTile(map, pos + directions[i])) mask |= 1 << i;
	}

	return mask;
}

void scrap_Update(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	if (isScrapTile(map, pos))
		map.SetTile(map.getTileOffset(pos),CMap::tile_scrap+scrap_GetMask(map,pos));
}

void OnScrapTileHit(CMap@ map, u32 index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag( index, Tile::LIGHT_PASSES );

	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);
		Sound::Play("dig_stone.ogg", pos, 1.0f, 0.8f+XORRandom(11)*0.01f);
	}
}

void metal_SetTile(CMap@ map, Vec2f pos)
{
	map.SetTile(map.getTileOffset(pos), CMap::tile_metal + metal_GetMask(map, pos));

	for (u8 i = 0; i < 4; i++)
	{
		metal_Update(map, pos + directions[i]);
	}
}

u8 metal_GetMask(CMap@ map, Vec2f pos)
{
	u8 mask = 0;

	for (u8 i = 0; i < 4; i++)
	{
		if (isMetalTile(map, pos + directions[i])) mask |= 1 << i;
	}

	return mask;
}

void metal_Update(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	if (isMetalTile(map, pos))
		map.SetTile(map.getTileOffset(pos),CMap::tile_metal+metal_GetMask(map,pos));
}

void OnMetalTileHit(CMap@ map, u32 index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag( index, Tile::LIGHT_PASSES );

	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);
		Sound::Play("dig_stone.ogg", pos, 1.0f, 0.7f+XORRandom(6)*0.01f);
	}
}

void OnMetalBackTileHit(CMap@ map, u32 index)
{
	map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);

	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);

		Sound::Play("dig_stone.ogg", pos, 0.75f, 0.8f+XORRandom(6)*0.01f);
	}
}

void OnIronTileDestroyed(CMap@ map, u32 index)
{
	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);

		Sound::Play("destroy_stone.ogg", pos, 1.0f, 1.0f);
	}
}

void OnMetalBackTileUpdate(bool updateThis, bool updateOthers, CMap@ map, Vec2f pos)
{
	TileType up = map.getTile(pos - Vec2f( 0.0f, 8.0f)).type;
	TileType down = map.getTile(pos + Vec2f( 0.0f, 8.0f)).type;
	bool isUp = (up >= CMap::tile_metal_back && up <= CMap::tile_metal_back_m) ? true : false;
	bool isDown = (down >= CMap::tile_metal_back && down <= CMap::tile_metal_back_m) ? true : false;

	if(updateThis)
	{
		if(isUp && isDown)
			map.server_SetTile(pos, CMap::tile_metal_back_m);
		else if(isUp || isDown)
		{
			if(isUp && !isDown)
				map.server_SetTile(pos, CMap::tile_metal_back_u);
			if(!isUp && isDown)
				map.server_SetTile(pos, CMap::tile_metal_back_d);
		}
		else
			map.server_SetTile(pos, CMap::tile_metal_back);
	}
	if(updateOthers)
	{
		if(isUp)
			OnMetalBackTileUpdate(true, false, map, pos - Vec2f( 0.0f, 8.0f));
		if(isDown)
			OnMetalBackTileUpdate(true, false, map, pos + Vec2f( 0.0f, 8.0f));
	}
}

void ice_SetTile(CMap@ map, Vec2f pos)
{
	map.SetTile(map.getTileOffset(pos), CMap::tile_ice + ice_GetMask(map, pos));

	for (u8 i = 0; i < 4; i++)
	{
		ice_Update(map, pos + directions[i]);
	}
}

u8 ice_GetMask(CMap@ map, Vec2f pos)
{
	u8 mask = 0;

	for (u8 i = 0; i < 4; i++)
	{
		if (checkIceTile(map, pos + directions[i])) mask |= 1 << i;
	}

	return mask;
}

void ice_Update(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	if (checkIceTile(map, pos))
		map.SetTile(map.getTileOffset(pos),CMap::tile_ice+ice_GetMask(map,pos));
}

void OnIceTileHit(CMap@ map, u32 index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag(index, Tile::LIGHT_PASSES);

	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);

		Sound::Play("GlassBreak2.ogg", pos, 1.0f, 0.8f);
		customSparks(pos, 1, rnd_vel(2,1,10.0f), SColor(255,25,75+XORRandom(75),200+XORRandom(55)));
	}
}

void OnIceTileDestroyed(CMap@ map, u32 index)
{
	if (isClient())
	{
		Vec2f pos = map.getTileWorldPosition(index);

		Sound::Play("GlassBreak1.ogg", pos, 1.0f, 0.7f);
	}
}

void customSparks(Vec2f pos, int amount, Vec2f gravity, SColor col)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(XORRandom(16) * 0.1f * 1.0f + 0.5f, 0);
        vel.RotateBy(XORRandom(360) * 360.0f);

        CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.gravity = gravity;
        p.timeout = 15 + XORRandom(16);
        p.scale = 0.5f + XORRandom(51)*0.01f;
        p.damping = 0.95f;
    }
}

Vec2f rnd_vel(f32 max_x, f32 max_y, f32 level)
{
    max_x *= level;
    max_y *= level;
    return Vec2f((XORRandom(max_x*2)-max_x) / level, (XORRandom(max_y*2)-max_y) / level);
}