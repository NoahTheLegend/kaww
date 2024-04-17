void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("autoturret");
	this.Tag("grad");
	this.Tag("blocks bullet");

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.RemoveSpriteLayer("arm");
	sprite.RemoveSpriteLayer("turret");

	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 32, 80);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(14);

		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(2.5f);
		}
	}

	CSpriteLayer@ tur = sprite.addSpriteLayer("turret", sprite.getConsts().filename, 32, 80);

	if (tur !is null)
	{
		Animation@ anim = tur.addAnimation("default", 0, false);
		anim.AddFrame(15);
	}

	sprite.SetEmitSoundSpeed(0.75f);
}