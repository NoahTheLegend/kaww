void onInit(CBlob@ this)
{
	this.addCommandID("release traps");

	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("apc");
	this.Tag("respawn_if_crew_present");
	this.Tag("blocks bullet");

	this.getSprite().SetOffset(Vec2f(-4,0));
}