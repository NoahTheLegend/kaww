void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-150); //background
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;

	this.set_s16("spawn_timer", 5 + XORRandom(10));
}

void onTick(CBlob@ this)
{	
	if (this.get_s16("spawn_timer") <= 0)
	{
		CBlob@[] crateblobs;
		getBlobsByName("lootcrate", @crateblobs);

		if (crateblobs.length <= 16)
		{
			if (!isServer())
				return;

			CBlob@ b = server_CreateBlob("lootcrate",-1,this.getPosition() + Vec2f(XORRandom(24) - 12, XORRandom(8) - 8));

			if (b !is null)
			{
				b.setVelocity(Vec2f(XORRandom(3)-1.0f, -1.5f));
			}

			this.set_s16("spawn_timer", 60); // one minute,    or 30 sec with higher pop
			this.Sync("spawn_timer", true);
		}
	}
	else
	{
		this.set_s16("spawn_timer", this.get_s16("spawn_timer") - (getPlayersCount() > 12 ? 2 : 1 ));
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
		Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 20);
		GUI::SetFont("text");

		GUI::DrawText("until next crate: " + (blob.get_s16("spawn_timer")*(getPlayersCount() > 12 ? 0.5 : 1 )), pos2d, color_white);
	}
}