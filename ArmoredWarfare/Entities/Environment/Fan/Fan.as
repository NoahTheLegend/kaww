void onInit(CSprite@ this)
{
	this.SetZ(-30);

	this.SetEmitSound("/Fan.ogg");
	this.SetEmitSoundPaused(true);
	this.SetEmitSoundSpeed(1);
	this.SetEmitSoundVolume(0.07f);
}
