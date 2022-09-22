void onInit(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();

    sprite.SetEmitSound("EngineRun_mid.ogg");
	//sprite.SetEmitSoundSpeed(1.0f);
    //sprite.SetEmitSoundVolume(0.2f);
	sprite.SetEmitSoundPaused(false);

    this.getShape().SetGravityScale(0.0f);
}

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();

    sprite.SetEmitSoundSpeed(Maths::Min(0.00005f + Maths::Abs(this.getVelocity().getLength() * 1.00f), 1.0f) * 1.0);
}