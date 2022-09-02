void onInit(CBlob@ this)
{	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(50);

	sprite.RewindEmitSound();
	sprite.SetEmitSound("FanfareRussian");
	sprite.SetEmitSoundPaused(false);
}

void onDie(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundPaused(true);
}