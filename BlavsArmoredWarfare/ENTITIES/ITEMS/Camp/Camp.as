void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-150); //background
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

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob)
	{
		//VV right here VV
		Vec2f pos2d = blob.getScreenPos() + Vec2f(-32, 34);
		GUI::SetFont("text");

		GUI::DrawText("next crate: " + blob.get_s16("spawn_timer"), pos2d, color_white);
	}
}