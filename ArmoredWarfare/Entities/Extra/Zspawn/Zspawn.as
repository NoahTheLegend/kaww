void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 30; // every second

	this.set_s16("spawn_timer", 5);
}

void onTick(CBlob@ this)
{
	if (this.get_s16("spawn_timer") <= 0)
	{
		string type;
		if (XORRandom(17) == 0)
		{
			type = "boomer";
		}
		else
		{
			type = "lurker";			
		}

		if (isServer())
		{
			for (uint i = 0; i < XORRandom(4) + 2; i ++) {
				server_CreateBlob(type, -1, this.getPosition());
			}
			this.set_s16("spawn_timer", 4 + XORRandom(15));
		}
	}
	else
	{
		this.set_s16("spawn_timer", this.get_s16("spawn_timer") - 1);
	}			
}