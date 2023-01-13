const string linadj_hp = "linear adjustment";

void onInit(CBlob@ this)
{
	// Set to current/init hp
	this.set_f32(linadj_hp, this.getHealth());
}

void onTick(CBlob@ this)
{
	if (g_videorecording) return;
	
	// Get init hp
	const f32 initialHealth = this.getInitialHealth();

	// Slowly match to real hp
	if ((this.get_f32(linadj_hp) != this.getHealth()))
	{
		if (this.get_f32(linadj_hp) + 0.075 < this.getHealth())
		{
			this.set_f32(linadj_hp, this.get_f32(linadj_hp) + 0.075);
		}
		else if (this.get_f32(linadj_hp) - 0.075 > this.getHealth())
		{
			this.set_f32(linadj_hp, this.get_f32(linadj_hp) - 0.075);
		}
	}
}

void onRender(CSprite@ this)
{
	if (g_videorecording) return;

	CBlob@ blob = this.getBlob();
	CPlayer@ local = getLocalPlayer();
	if (local !is null && local.getTeamNum() != blob.getTeamNum())
		if (blob.get_u32("disguise") > getGameTime()) return;

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();

	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 55 - (blob.getName() == "bradleyturret" ? 30 : 0));
	Vec2f dim = Vec2f(55, 12);
	const f32 y = blob.getHeight() * 1.0f;
	const f32 initialHealth = blob.getInitialHealth();

	CMap@ map = getMap();
	bool inGround = map.isTileSolid(blob.getPosition());

	if (blob.hasTag("dead"))
		{ return; }

	if (inGround)
		{ return; }

	const f32 renderRadius = (blob.getRadius()) * 1.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	
	const f32 perc  = blob.getHealth() / initialHealth;
	const f32 perc2 = blob.get_f32(linadj_hp) / initialHealth;

	if (mouseOnBlob || Maths::Abs(perc - perc2) > 0.03)
	{
		if (initialHealth > 0.0f)
		{
			SColor color_light;
			SColor color_mid;
			SColor color_dark;

			if (blob.getTeamNum() == 0)
			{
				color_light = 0xff2cafde;
				color_mid	= 0xff1d85ab;
				color_dark	= 0xff1a4e83;
			}
			else
			{
				color_light = 0xffd5543f;
				color_mid	= 0xffb73333;
				color_dark	= 0xff941b1b;
			}

			if (perc >= 0.0f)
			{
				// Border
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 1,                        pos2d.y + y - 1),
								   Vec2f(pos2d.x + dim.x + 1,                        pos2d.y + y + dim.y + 0));

				

				// Red portion
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2,                        pos2d.y + y + 0),
								   Vec2f(pos2d.x + dim.x - 1,                        pos2d.y + y + dim.y - 1), color_dark);
				//      tracer thing   perc2
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 1,                        pos2d.y + y + 0),
								   Vec2f(pos2d.x - dim.x + perc2 * 2.0f * dim.x - 3, pos2d.y + y + dim.y - 2), SColor(0xffdeba76)); //0xffdeba76



				// whiteness
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 0,                        pos2d.y + y + 0),
								   Vec2f(pos2d.x - dim.x + perc  * 2.0f * dim.x + 0, pos2d.y + y + dim.y - 2), SColor(0xffffffff));


				// Health meter trim
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 1,                        pos2d.y + y + 0),
								   Vec2f(pos2d.x - dim.x + perc  * 2.0f * dim.x - 1, pos2d.y + y + dim.y - 2), color_mid);
				// Health meter inside
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 5,                        pos2d.y + y + 0),
								   Vec2f(pos2d.x - dim.x + perc  * 2.0f * dim.x - 5, pos2d.y + y + dim.y - 3), color_light);

				//GUI::DrawShadowedText(Maths::Ceil((blob.getHealth() / blob.getInitialHealth()) * (blob.getInitialHealth() * 100)) + "/" + blob.getInitialHealth() * 100, Vec2f(pos2d.x - dim.x + 3, pos2d.y + y - 3), SColor(0xffffffff));

				GUI::SetFont("text");
				GUI::DrawShadowedText(blob.getInventoryName(), Vec2f(pos2d.x - dim.x + 3, pos2d.y + y - 3), SColor(0xffffffff));
			}
		}
	}
}