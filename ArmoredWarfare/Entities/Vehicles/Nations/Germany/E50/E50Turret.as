void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("respawn_if_crew_present");
	this.Tag("blocks bullet");

	this.getSprite().SetOffset(Vec2f(4,0));
}