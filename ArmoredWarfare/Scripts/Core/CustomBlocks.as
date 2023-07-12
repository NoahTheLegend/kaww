namespace CMap
{
	enum CustomTiles
	{ 
		tile_cdirt = 384,
		tile_cdirt_v0 = 385,
		tile_cdirt_v1 = 386,
		tile_cdirt_v2 = 387,
		tile_cdirt_v3 = 388,
		tile_cdirt_v4 = 389,
		tile_cdirt_d0 = 396,
		tile_cdirt_d1 = 397,
		tile_cdirt_d2 = 398,
		tile_cdirt_d3 = 399,

		tile_scrap = 400,
		tile_scrap_d0,
		tile_scrap_d1,
		tile_scrap_d2,
		tile_scrap_d3,
		tile_scrap_d4,
		tile_scrap_d5,
		tile_scrap_d6
	};
};

bool isTileCustomSolid(TileType tile)
{
	return (isTileCompactedDirt(tile) || isTileScrap(tile));
}

bool isTileCompactedDirt(TileType tile)
{
	return tile >= CMap::tile_cdirt && tile <= CMap::tile_cdirt_d3;
}

bool isTileScrap(TileType tile)
{
	return tile >= CMap::tile_scrap && tile <= CMap::tile_scrap_d6;
}