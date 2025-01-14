Tile getSurfaceTile(CBlob@ this)
{
    Tile empty = Tile();
    empty.type = 0;

    if (this is null) return empty;

    CMap@ map = getMap();
    if (map is null) return empty;

    return map.getTile(this.getPosition()+Vec2f(0, this.getRadius() + 4.0f));
}

void getSurfaceTiles(CBlob@ this, TileType &out t1, TileType &out t2)
{
    if (this is null) return;
    
    CMap@ map = getMap();
    if (map is null) return;

    Vec2f pos = this.getPosition();
    f32 rad = this.getRadius();
    t1 = map.getTile(pos+Vec2f(-4.0f, rad + 4.0f)).type;
    t2 = map.getTile(pos+Vec2f(4.0f, rad + 4.0f)).type;
}