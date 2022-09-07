void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	this.set_TileType("background tile", CMap::tile_wood_back);
	this.getSprite().getConsts().accurateLighting = true;
	this.getShape().getConsts().mapCollisions = false;

	this.getSprite().SetZ(-50); //background

	this.Tag("builder always hit");
	if (this.getTeamNum() == 0)
	{
		this.Tag("BlueUpgrade");
	}
	else
	{
		this.Tag("RedUpgrade");
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum()) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onDie(CBlob@ this)
{
	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());
}