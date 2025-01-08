void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("autoturret");
	this.Tag("blocks bullet");
	
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.RemoveSpriteLayer("arm");
	sprite.RemoveSpriteLayer("turret");
	sprite.SetRelativeZ(4.0f);

	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 32, 80);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(14);

		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(-2.0f);
		}
	}

	CSpriteLayer@ tur = sprite.addSpriteLayer("turret", sprite.getConsts().filename, 32, 80);
	if (tur !is null)
	{
		Animation@ anim = tur.addAnimation("default", 0, false);
		anim.AddFrame(15);

		CSpriteLayer@ tur = this.getSprite().getSpriteLayer("tur");
		if (tur !is null)
		{
			tur.SetRelativeZ(3.0f);
		}
	}

	sprite.SetEmitSoundSpeed(1.25f);
}