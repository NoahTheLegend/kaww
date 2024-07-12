void onInit(CBlob@ this)
{
	this.addCommandID("release traps");

	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("apc");
	this.Tag("blocks bullet");

	this.getSprite().SetOffset(Vec2f(-4,0));
}