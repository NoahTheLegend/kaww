void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-150); //background
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 35;

	this.set_s16("spawn_timer", 25 + XORRandom(20));
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	
	if (this.get_s16("spawn_timer") <= 0)
	{
		CBlob@[] crateblobs;
		getBlobsByName("lootcrate", @crateblobs);

		if (crateblobs.length <= 16)
		{
			if (!isServer())
				return;

			CBlob@ b = server_CreateBlob("lootcrate",-1,this.getPosition() + Vec2f(XORRandom(24) - 12, XORRandom(8) - 8));

			this.set_s16("spawn_timer", 100);
		}
	}
	else
	{
		this.set_s16("spawn_timer", this.get_s16("spawn_timer") - (getPlayersCount() > 7 ? 4 : (getPlayersCount() < 5 ? 1 : 2)));
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
		Vec2f dim = Vec2f(24, 8);
		const f32 y = blob.getHeight() * 2.4f;
		const f32 initialHealth = blob.getInitialHealth();
		if (initialHealth > 0.0f)
		{
			const f32 perc = blob.get_s16("spawn_timer") / 100.0f;
			if (perc >= 0.0f)
			{
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xfffefefe));
			}
		}
	}
}

