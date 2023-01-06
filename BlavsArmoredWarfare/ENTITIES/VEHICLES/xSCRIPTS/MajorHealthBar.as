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
	if (blob.hasTag("falling")) return;

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();

	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, -40);
	const f32 y = blob.getHeight() * 8.8f;
	const f32 initialHealth = blob.getInitialHealth();
	Vec2f dim = Vec2f((initialHealth*1.75)+40, 15);

	CMap@ map = getMap();
	bool inGround = map.isTileSolid(blob.getPosition());

	if (blob.hasTag("dead"))
		{ return; }

	if (inGround)
		{ return; }

	if (initialHealth > 0.0f)
	{
		const f32 perc  = blob.getHealth() / initialHealth;
		const f32 perc2 = blob.get_f32(linadj_hp) / initialHealth;

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

			GUI::SetFont("text");

			GUI::DrawShadowedText(Maths::Ceil((blob.getHealth() / blob.getInitialHealth()) * (blob.getInitialHealth() * 100)) + "/" + blob.getInitialHealth() * 100, Vec2f(pos2d.x - dim.x + 3, pos2d.y + y - 1), SColor(0xffffffff));

			GUI::DrawShadowedText(blob.getInventoryName(), Vec2f(pos2d.x - dim.x - 3, pos2d.y + y - 1 + 15), SColor(0xffffffff));
		}
	}

	GUI::SetFont("menu");
	
	//GUI::DrawShadowedText("WP", pos2d + Vec2f(this.isFacingLeft() ? 128.0f : -128.0f, 0).RotateBy(blob.getAngleDegrees()), SColor(0xffffffff));
	//if (blob.getName() == "t10" && getLocalPlayer() !is null && getLocalPlayer().getUsername() == "NoahTheLegend" && getLocalPlayer().isMyPlayer())
	//{
	//GUI::DrawShadowedText("RPM: " + Maths::Round(blob.get_f32("engine_RPM")), Vec2f(pos2d.x - dim.x - 3, pos2d.y + y - 1 + 65), SColor(0xffffffff));
	//GUI::DrawShadowedText("RPM TARGET: " + Maths::Round(blob.get_s32("engine_RPMtarget")), Vec2f(pos2d.x - dim.x - 3, pos2d.y + y - 1 + 80), SColor(0xffffffff));
	//GUI::DrawShadowedText("ENGINE THROTTLE: " + Maths::Round(blob.get_f32("engine_throttle")), Vec2f(pos2d.x - dim.x - 3, pos2d.y + y - 1 + 95), SColor(0xffffffff));
	//}
	//GUI::DrawLine2D(Vec2f(pos2d.x, pos2d.y + y - 1 + 165), Vec2f(pos2d.x + ((blob.get_f32("engine_throttle")-0.35) * 1000), pos2d.y + y - 1 + 165), SColor(0xffffffff));
	//GUI::DrawLine2D(Vec2f(pos2d.x - dim.x, pos2d.y + y - 1 + 169), Vec2f(pos2d.x - dim.x + 500, pos2d.y + y - 1 + 169), SColor(0xffcdb692));
}