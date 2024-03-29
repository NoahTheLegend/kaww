// GenericDestruction.as

void onHealthChange(CBlob@ this, f32 health_old)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	Animation@ animation = sprite.getAnimation("destruction");
	if (animation is null) return;

    u8 frame = u8((this.getInitialHealth() - this.getHealth()) / (this.getInitialHealth() / sprite.animation.getFramesCount()));
	sprite.animation.frame = frame;
}