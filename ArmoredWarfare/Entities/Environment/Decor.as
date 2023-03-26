void onInit(CSprite@ this){
	Animation@ animation = this.getAnimation("default");
	if (animation is null) return;
	Vec2f pos =	this.getBlob().getPosition();
	this.animation.frame = XORRandom(animation.getFramesCount());
	this.SetFacingLeft(XORRandom(2) == 0);
	this.SetZ(-20);
	CBlob@ blob = this.getBlob();
	if (blob !is null) blob.Tag("bush");
}