#include "TeamColorCollections.as"

void onRender(CSprite@ this)
{
	if (g_videorecording) return;

	CBlob@ blob = this.getBlob();
	if (blob.getHealth() == 0.01f) return;

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();

	//Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 55);
	Vec2f oldpos = blob.getOldPosition();
	Vec2f pos = blob.getPosition();
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) + Vec2f(0, 55);
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

	if (initialHealth > 0.0f)
	{
		u8 team = blob.getTeamNum();
		SColor color_light = getNeonColor(team, 0);
		SColor color_mid = getNeonColor(team, 1);
		SColor color_dark = getNeonColor(team, 2);

		if (perc >= 0.0f)
		{
			// Border
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 1,                        pos2d.y + y - 1),
								Vec2f(pos2d.x + dim.x + 1,                        pos2d.y + y + dim.y + 0));

			

			// Red portion
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2,                        pos2d.y + y + 0),
								Vec2f(pos2d.x + dim.x - 1,                        pos2d.y + y + dim.y - 1), color_dark);

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