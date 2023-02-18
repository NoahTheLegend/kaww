void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-151); //background
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;

	this.set_s16("spawn_timer", 5 + XORRandom(10));
	this.addCommandID("sync_timer");
}

void onTick(CBlob@ this)
{	
	if (this.get_s16("spawn_timer") <= 0)
	{
		CBlob@[] crateblobs;
		getBlobsByTag(""+this.getNetworkID(), @crateblobs);

		if (crateblobs.length == 0)
		{
			if (isServer())
			{
				CBlob@ b = server_CreateBlob("lootcrate",-1,this.getPosition() + Vec2f(XORRandom(24) - 12, XORRandom(8) - 8));

				if (b !is null)
				{
					b.Tag(""+this.getNetworkID());
					b.setVelocity(Vec2f(XORRandom(3)-1.0f, -1.5f));
				}

				this.set_s16("spawn_timer", 45+XORRandom(11));
				CBitStream params;
				params.write_s16(this.get_s16("spawn_timer"));
				this.SendCommand(this.getCommandID("sync_timer"), params);
				//this.Sync("spawn_timer", true);
			}
		}
	}
	else
	{
		this.set_s16("spawn_timer", this.get_s16("spawn_timer") - (getPlayersCount() > 12 ? 2 : 1 ));
	}			
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync_timer"))
	{
		if (isClient())
		{
			s16 timer;
			if (!params.saferead_s16(timer)) return;
			this.set_s16("spawn_timer", timer);
		}
	}
}