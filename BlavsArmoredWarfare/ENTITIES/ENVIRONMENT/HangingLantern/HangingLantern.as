void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(80.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	this.Tag("destructable");
	this.Tag("builder always hit");

	this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
	if (!getMap().hasSupportAtPos(this.getPosition()))
	{
		this.server_Die();
	}
}