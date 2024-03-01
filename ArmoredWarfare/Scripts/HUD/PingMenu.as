#define CLIENT_ONLY

#include "PingCommon.as"

const int sw = getDriver().getScreenWidth();
const int sh = getDriver().getScreenHeight();

void onTick(CBlob@ this)
{

}

Vec2f keypress_pos = Vec2f_zero;

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;

	if (blob.isKeyPressed(key_action2))
	{
        CControls@ controls = getControls();
        if (controls is null) return;

		//Vec2f sc = getDriver().getScreenCenterPos();

        Vec2f mpos = controls.getMouseScreenPos();
        if (blob.isKeyJustPressed(key_action2)) keypress_pos = mpos;

		DrawCategories(mpos);
	}
    else
    {
        keypress_pos = Vec2f_zero;
        opened_category = -1;
    }
}

const int radius = 128.0f;
s8 opened_category = -1;

void DrawCategories(Vec2f mpos)
{
    GUI::SetFont("score-small");
    u8 total = PingCategories.size();

    for (u8 i = 0; i < total; i++)
    {
        f32 part = 360/total;
        f32 angle = i * part;

        Vec2f drawpos = keypress_pos + Vec2f(0, -radius).RotateBy(angle);
        f32 mangle = -(mpos-keypress_pos).Angle() + 90;
        
        f32 min = (90+angle - part/2);
        f32 max = (90+angle + part/2);

        bool selected = false;
        f32 diff = mangle - angle;
		diff += diff > 180 ? -360 : diff < -180 ? 360 : 0;

        if ((keypress_pos-mpos).Length() > 48.0f && diff < part/2 && diff > -part/2) selected = true;

        SColor col = SColor(25,255,255,255);
        if (selected)
        {
            col.setAlpha(75);
        }

        drawCone(min * Maths::Pi/180, max * Maths::Pi/180, col);
        GUI::DrawTextCentered(PingCategories[i], drawpos, PingColors[i]);
    }
}

void drawCone(f32 min, f32 max, SColor col)
{
	Driver@ driver = getDriver();
	Vec2f origin = keypress_pos;
	float ray_distance = radius * 1.75f;
	
	Vertex[] vertices;
	// Center vertex
	vertices.push_back(Vertex(
		driver.getWorldPosFromScreenPos(origin),
		0.0f,
		Vec2f(0.0f, 0.0f),
        col
	));

	// Small angle vertex
	Vec2f min_direction(Maths::Cos(min), Maths::Sin(min));
	vertices.push_back(Vertex(
		driver.getWorldPosFromScreenPos(origin - min_direction * ray_distance),
		0.0f,
		Vec2f(1.0f, 0.0f),
		SColor(0,255,255,255)
	));

	// Large angle vertex
	Vec2f max_direction(Maths::Cos(max), Maths::Sin(max));
	vertices.push_back(Vertex(
		driver.getWorldPosFromScreenPos(origin - max_direction * ray_distance),
		0.0f,
		Vec2f(0.0f, 1.0f),
		SColor(0,255,255,255)
	));

	Render::RawTriangles("pixel", vertices);
}