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
		tile_scrap_d6
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