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
		tile_scrap_v0,
		tile_scrap_v1,
		tile_scrap_v2,
		tile_scrap_v3,
		tile_scrap_v4,
		tile_scrap_v5,
		tile_scrap_v6,
		tile_scrap_v7,
		tile_scrap_v8,
		tile_scrap_v9,
		tile_scrap_v10,
		tile_scrap_v11,
		tile_scrap_v12,
		tile_scrap_v13,
		tile_scrap_v14,
		tile_scrap_d0 = tile_scrap + 16,
		tile_scrap_d1,
		tile_scrap_d2,
		tile_scrap_d3,
		tile_scrap_d4,
		tile_scrap_d5,
		tile_scrap_d6,

		tile_metal = 432,
		tile_metal_v0,
		tile_metal_v1,
		tile_metal_v2,
		tile_metal_v3,
		tile_metal_v4,
		tile_metal_v5,
		tile_metal_v6,
		tile_metal_v7,
		tile_metal_v8,
		tile_metal_v9,
		tile_metal_v10,
		tile_metal_v11,
		tile_metal_v12,
		tile_metal_v13,
		tile_metal_v14,
		tile_metal_d0 = tile_metal + 16,
		tile_metal_d1,
		tile_metal_d2,
		tile_metal_d3,
		tile_metal_d4,
		tile_metal_d5,
		tile_metal_d6,
		tile_metal_d7,
		tile_metal_d8,

		tile_metal_back = tile_metal_d0 + 16,
		tile_metal_back_u,
		tile_metal_back_d,
		tile_metal_back_m,
		tile_metal_back_d0,
		tile_metal_back_d1,
		tile_metal_back_d2,
		tile_metal_back_d3,
		tile_metal_back_d4,
		tile_metal_back_d5,
		tile_metal_back_d6,
		tile_metal_back_d7,
		tile_metal_back_d8,

		tile_ice = tile_metal_back + 16,
		tile_ice_v0,
		tile_ice_v1,
		tile_ice_v2,
		tile_ice_v3,
		tile_ice_v4,
		tile_ice_v5,
		tile_ice_v6,
		tile_ice_v7,
		tile_ice_v8,
		tile_ice_v9,
		tile_ice_v10,
		tile_ice_v11,
		tile_ice_v12,
		tile_ice_v13,
		tile_ice_v14,
		tile_ice_d0 = tile_ice + 16,
		tile_ice_d1,
		tile_ice_d2,
		tile_ice_d3
	};
};

bool isTileCustomSolid(TileType tile)
{
	return (isTileCompactedDirt(tile) || isTileScrap(tile) || getMap().isTileSolid(tile));
}

bool isTileCompactedDirt(TileType tile)
{
	return tile >= CMap::tile_cdirt && tile <= CMap::tile_cdirt_d3;
}

bool isTileScrap(TileType tile)
{
	return tile >= CMap::tile_scrap && tile <= CMap::tile_scrap_d6;
}

enum blobTileMap
{
	platform_up = -50,
	platform_right = -51,
	platform_down = -52,
	platform_left = -53
};

CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position)
{
	return server_CreateBlob(name, team, position);
}

CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position, const bool fixed)
{
	CBlob@ blob = server_CreateBlob(name, team, position);
	blob.getShape().SetStatic(fixed);

	return blob;
}

CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position, s16 angle)
{
	CBlob@ blob = server_CreateBlob(name, team, position);
	blob.setAngleDegrees(angle);

	return blob;
}

CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position, s16 angle, const bool fixed)
{
	CBlob@ blob = spawnBlob(map, name, team, position, angle);
	if (blob is null) return null;
	
	blob.getShape().SetStatic(fixed);

	return blob;
}

CBlob@ spawnBlob(CMap@ map, const string& in name, Vec2f offset, u8 team = 255, bool attached_to_map = false, Vec2f posOffset = Vec2f_zero, s16 angle = 0)
{ 
	return spawnBlob(map, name, team, getSpawnPosition(map, map.getTileOffset(offset)) + posOffset, angle, attached_to_map);
}

CBlob@ spawnBlob(CMap@ map, const string& in name, int offset, u8 team = 255, bool attached_to_map = false, Vec2f posOffset = Vec2f_zero, s16 angle = 0)
{ 
	return spawnBlob(map, name, team, getSpawnPosition(map, offset) + posOffset, angle, attached_to_map);
}

u8 getTeamFromChannel(u8 channel)
{
	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	// only the bits we want
	channel &= 0x0F;
	return channel == 0 ? teamleft : channel == 1 ? teamright : 7;
}

u8 getChannelFromTeam(u8 team)
{
	return (team > 7)? 0x0F : team;
}

u16 getAngleFromChannel(u8 channel)
{
	// only the bits we want
	channel &= 0x30;

	switch(channel)
	{
		case 16: return 90;
		case 32: return 180;
		case 48: return 270;
	}

	return 0;
}

u8 getChannelFromAngle(u16 angle)
{
	switch(angle)
	{
		case  90: return 16;
		case 180: return 32;
		case 270: return 48;
	}

	return 0;
}

Vec2f getSpawnPosition(CMap@ map, int offset)
{
	Vec2f pos = map.getTileWorldPosition(offset);
	f32 tile_offset = map.tilesize * 0.5f;
	pos.x += tile_offset;
	pos.y += tile_offset;
	return pos;
}

bool isCDirtTile(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_cdirt && tile <= CMap::tile_cdirt_d3;
}

bool isCDirtTile(TileType tile)
{
	return tile >= CMap::tile_cdirt && tile <= CMap::tile_cdirt_d3;
}

bool isScrapTile(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_scrap && tile <= CMap::tile_scrap_v14;
}

bool isScrapTile(TileType tile)
{
	return tile >= CMap::tile_scrap && tile <= CMap::tile_scrap_v14;
}

bool isMetalTile(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_metal && tile <= CMap::tile_metal_v14;
}

bool isMetalTile(TileType tile)
{
	return tile >= CMap::tile_metal && tile <= CMap::tile_metal_v14;
}

bool isMetalBackTile(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_metal_back && tile <= CMap::tile_metal_back_d8;
}

bool isMetalBackTile(TileType tile)
{
	return tile >= CMap::tile_metal_back && tile <= CMap::tile_metal_back_d8;
}

bool isTileIce(u32 tile)
{
	return tile >= CMap::tile_ice && tile <= CMap::tile_ice_d3;
}

bool isTileIce(CMap@ map, Vec2f pos)
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_ice && tile <= CMap::tile_ice_d3;
}

bool checkIceTile(CMap@ map, Vec2f pos) 
{
	u16 tile = map.getTile(pos).type;
	return tile >= CMap::tile_ice && tile <= CMap::tile_ice_v14;
}

bool isTileExposure(u32 index)
{
	return index == CMap::tile_empty;
}

bool isSolid(CMap@ map, u32 type) // thin ice is not solid
{
	return map.isTileSolid(type) || map.isTileGround(type) || isTileIce(type)
		|| isMetalTile(type) || isScrapTile(type) || isMetalBackTile(type)
		|| isCDirtTile(type);
}