void onInit(CSprite@ this)
{
	this.SetZ(-30);

	this.SetEmitSound("/Fan.ogg");
	this.SetEmitSoundPaused(false);
	this.SetEmitSoundSpeed(1.1f+XORRandom(15)*0.01f);
	this.SetEmitSoundVolume(0.075f);
}
