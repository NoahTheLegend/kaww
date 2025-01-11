void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("respawn_if_crew_present");
	this.Tag("has mount");
	this.Tag("blocks bullet");
	

	this.getSprite().SetOffset(Vec2f(4,0));

	// override spritelayers here
	/*CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(20);
	}*/
}
