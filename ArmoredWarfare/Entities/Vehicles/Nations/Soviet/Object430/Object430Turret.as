void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("has mount");
	this.Tag("blocks bullet");

	this.getSprite().SetOffset(Vec2f(4,0));
}
