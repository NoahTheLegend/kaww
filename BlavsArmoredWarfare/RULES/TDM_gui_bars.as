/*
SColor color_blue(255, 30, 30, 250);
SColor color_red(255, 250, 30, 30);

u16 blue_team_kills = 0;
u16 red_team_kills = 0;

void onRender(CRules@ this)
{
    GUI::SetFont("menu");
    GUI::DrawTextCentered( "KILLS:", Vec2f(getScreenWidth()/2,16), color_white );

    GUI::DrawText( ""+this.get_u16("blue_kills"), Vec2f(-25 + getScreenWidth()/2, 30), color_blue );
    GUI::DrawText( ""+this.get_u16("red_kills"), Vec2f(15 + getScreenWidth()/2, 30), color_red );
}

void onRender(CRules@ this)
{
	CBlob@ blob = this.getBlob();

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();

	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 60);
	Vec2f dim = Vec2f(96, 24);
	const f32 y = blob.getHeight() * 2.1f;
	const f32 initialHealth = blob.getInitialHealth();

	CMap@ map = getMap();
	bool inGround = map.isTileSolid(blob.getPosition());

	if (inGround)
		{ return; }

	if (initialHealth > 0.0f)
	{
		const f32 perc  = blob.getHealth() / initialHealth;

		if (perc >= 0.0f)
		{
			// Border
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2,                        pos2d.y + y - 2),
							   Vec2f(pos2d.x + dim.x + 2,                        pos2d.y + y + dim.y + 2));
			// Red portion
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2,                        pos2d.y + y + 2),
							   Vec2f(pos2d.x + dim.x,                            pos2d.y + y + dim.y - 2), SColor(0xff852d29));
			// Health meter trim
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 1,                        pos2d.y + y + 1),
							   Vec2f(pos2d.x - dim.x + perc  * 2.0f * dim.x - 1, pos2d.y + y + dim.y - 1), SColor(0xff56d534));
			// Health meter inside
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 3,                        pos2d.y + y + 3),
							   Vec2f(pos2d.x - dim.x + perc  * 2.0f * dim.x - 3, pos2d.y + y + dim.y - 3), SColor(0xff43b22e));
		}
	}
}