void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();
    if (shape is null) return;
    
    if (!shape.isOverlappingTileBackground(true) && !shape.isOverlappingTileSolid(true))
	{
		this.server_Hit(this, this.getPosition(), Vec2f_zero, 10.0f, 0, true);
	}
}