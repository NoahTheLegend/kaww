void onInit(CSprite@ this)
{
	this.SetZ(-30);

	this.SetEmitSound("/Fan.ogg");
	this.SetEmitSoundPaused(false);
	this.SetEmitSoundSpeed(1.1f+XORRandom(15)*0.01f);
	this.SetEmitSoundVolume(0.075f);
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;
	if ((getGameTime()+this.getNetworkID()) % 60 != 0 || this.getTickSinceCreated() < 30) return;
	CShape@ shape = this.getShape();
	if (shape is null) return;
	
	if (!shape.isOverlappingTileBackground(true) && !shape.isOverlappingTileSolid(true))
	{
		this.server_Die();
	}
}