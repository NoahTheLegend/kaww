#include "CustomBlocks.as";

///Minimap Code
// Almost 100% accurately replicates the legacy minimap drawer
// This is due to it being a port of the legacy code, provided by Geti

void CalculateMinimapColour( CMap@ map, u32 offset, TileType tile, SColor &out col)
{
	int X = offset % map.tilemapwidth;
	int Y = offset/map.tilemapwidth;

	Vec2f pos = Vec2f(X, Y);

	float ts = map.tilesize;
	Tile ctile = map.getTile(pos * ts);

	bool show_gold = getRules().get_bool("show_gold");

	///Colours

	const SColor color_minimap_solid_edge   (0xff844715);
	const SColor color_minimap_solid        (0xffc4873a);
	const SColor color_minimap_back_edge    (0xffcf8c3c); //yep, same as above
	const SColor color_minimap_back         (0xffdb984a);
	const SColor color_minimap_open         (0xffe3fafd);
	const SColor color_minimap_gold         (0xfff7cb6f); 
	const SColor color_minimap_gold_edge    (0xfff9b21f);
	const SColor color_minimap_gold_exposed (0xfff5a909);

	const SColor color_minimap_water        (0xff2cafde);
	const SColor color_minimap_fire         (0xffd5543f);

	//neighbours
	Tile tile_l = map.getTile(MiniMap::clampInsideMap(pos * ts - Vec2f(ts, 0), map));
	Tile tile_r = map.getTile(MiniMap::clampInsideMap(pos * ts + Vec2f(ts, 0), map));
	Tile tile_u = map.getTile(MiniMap::clampInsideMap(pos * ts - Vec2f(0, ts), map));
	Tile tile_d = map.getTile(MiniMap::clampInsideMap(pos * ts + Vec2f(0, ts), map));

	///figure out the correct colour
	if (
		//always solid
		map.isTileGround( tile ) || map.isTileStone( tile ) ||
        map.isTileBedrock( tile ) || map.isTileThickStone( tile ) ||
        map.isTileCastle( tile ) || map.isTileWood( tile ) ||
        //only solid if we're not showing gold separately
        (!show_gold && map.isTileGold( tile ))
    ) {
		//Foreground
		col = color_minimap_solid;

		//Edge
		if( MiniMap::isForegroundOutlineTile(tile_u, map) || MiniMap::isForegroundOutlineTile(tile_d, map) ||
		    MiniMap::isForegroundOutlineTile(tile_l, map) || MiniMap::isForegroundOutlineTile(tile_r, map) )
		{
			col = color_minimap_solid_edge;
		}
		else if(
			show_gold && (
				MiniMap::isGoldOutlineTile(tile_u, map, false) || MiniMap::isGoldOutlineTile(tile_d, map, false) ||
			    MiniMap::isGoldOutlineTile(tile_l, map, false) || MiniMap::isGoldOutlineTile(tile_r, map, false)
			)
		) {
			col = color_minimap_gold_edge;
		}
	}
	else if(map.isTileBackground(ctile) && !map.isTileGrass(tile))
	{
		//Background
		col = color_minimap_back;

		//Edge
		if( MiniMap::isBackgroundOutlineTile(tile_u, map) || MiniMap::isBackgroundOutlineTile(tile_d, map) ||
		    MiniMap::isBackgroundOutlineTile(tile_l, map) || MiniMap::isBackgroundOutlineTile(tile_r, map) )
		{
			col = color_minimap_back_edge;
		}
	}
	else if(show_gold && map.isTileGold(tile))
	{
		//Gold
		col = color_minimap_gold;

		//Edge
		if( MiniMap::isGoldOutlineTile(tile_u, map, true) || MiniMap::isGoldOutlineTile(tile_d, map, true) ||
		    MiniMap::isGoldOutlineTile(tile_l, map, true) || MiniMap::isGoldOutlineTile(tile_r, map, true) )
		{
			col = color_minimap_gold_exposed;
		}
	}
	else
	{
		//Sky
		col = color_minimap_open;
	}

	bool air = tile == CMap::tile_empty;
	if (!air)
	{
		// TODO: Shove damage frame numbers into an enum
		switch(tile)
		{
			case CMap::tile_cdirt:
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
				col = SColor(255, 135, 55, 15);
				break;
			}
			
			case CMap::tile_scrap:
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
			case CMap::tile_scrap_d0:
			case CMap::tile_scrap_d1:
			case CMap::tile_scrap_d2:
			case CMap::tile_scrap_d3:
			case CMap::tile_scrap_d4:
			case CMap::tile_scrap_d5:
			case CMap::tile_scrap_d6:
			{
				col = SColor(255, 206, 118, 74);
				break;
			}

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
			case CMap::tile_metal_d0:
			case CMap::tile_metal_d1:
			case CMap::tile_metal_d2:
			case CMap::tile_metal_d3:
			case CMap::tile_metal_d4:
			case CMap::tile_metal_d5:
			case CMap::tile_metal_d6:
			case CMap::tile_metal_d7:
			case CMap::tile_metal_d8:
			{
				col = SColor(255, 107, 114, 115);
				break;
			}

			case CMap::tile_metal_back:
			case CMap::tile_metal_back_u:
			case CMap::tile_metal_back_d:
			case CMap::tile_metal_back_m:
			case CMap::tile_metal_back_d0:
			case CMap::tile_metal_back_d1:
			case CMap::tile_metal_back_d2:
			case CMap::tile_metal_back_d3:
			case CMap::tile_metal_back_d4:
			case CMap::tile_metal_back_d5:
			case CMap::tile_metal_back_d6:
			case CMap::tile_metal_back_d7:
			case CMap::tile_metal_back_d8:
			{
				col = SColor(255, 65, 65, 65);
				break;
			}
		}
	}

	///Tint the map based on Fire/Water State
	if (map.isInWater( pos * ts ))
	{
		col = col.getInterpolated(color_minimap_water,0.5f);
	}
	else if (map.isInFire( pos * ts ))
	{
		col = col.getInterpolated(color_minimap_fire,0.5f);
	}
}

//(avoid conflict with any other functions)
namespace MiniMap
{
	Vec2f clampInsideMap(Vec2f pos, CMap@ map)
	{
		return Vec2f(
			Maths::Clamp(pos.x, 0, (map.tilemapwidth - 0.1f) * map.tilesize),
			Maths::Clamp(pos.y, 0, (map.tilemapheight - 0.1f) * map.tilesize)
		);
	}

	bool isForegroundOutlineTile(Tile tile, CMap@ map)
	{
		return !map.isTileSolid(tile);
	}

	bool isOpenAirTile(Tile tile, CMap@ map)
	{
		return tile.type == CMap::tile_empty ||
			map.isTileGrass(tile.type);
	}

	bool isBackgroundOutlineTile(Tile tile, CMap@ map)
	{
		return isOpenAirTile(tile, map);
	}

	bool isGoldOutlineTile(Tile tile, CMap@ map, bool is_gold)
	{
		return is_gold ?
			!map.isTileSolid(tile.type) :
			map.isTileGold(tile.type);
	}

	//setup the minimap as required on server or client
	void Initialise()
	{
		CRules@ rules = getRules();
		CMap@ map = getMap();

		//add sync script
		//done here to avoid needing to modify gamemode.cfg
		if (!rules.hasScript("MinimapSync.as"))
		{
			rules.AddScript("MinimapSync.as");
		}

		//init appropriately
		if (isServer())
		{
			//load values from cfg
			ConfigFile cfg();
			cfg.loadFile("Base/Rules/MinimapSettings.cfg");

			map.legacyTileMinimap = cfg.read_bool("legacy_minimap", false);
			bool show_gold = cfg.read_bool("show_gold", true);

			//write out values for serialisation
			rules.set_bool("legacy_minimap", map.legacyTileMinimap);
			rules.set_bool("show_gold", show_gold);
		}
		else
		{
			//write defaults for now
			map.legacyTileMinimap = false;
			rules.set_bool("show_gold", true);
		}
	}
}