void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(90.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));

	//this.getCurrentScript().runFlags |= Script::tick_inwater;
	//this.getCurrentScript().tickFrequency = 4;
}

void onTick(CBlob@ this)
{
	if (XORRandom(4) == 0)
	{
		this.SetLightRadius(80.0f + XORRandom(5));
	}
}

void Light(CBlob@ this, bool on)
{
	if (!on)
	{
		this.SetLight(false);
		this.getSprite().SetAnimation("nofire");
	}
	else
	{
		this.SetLight(true);
		this.getSprite().SetAnimation("fire");
	}
	this.getSprite().PlaySound("SparkleShort.ogg");
}