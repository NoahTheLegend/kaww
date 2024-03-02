#define CLIENT_ONLY

#include "PingCommon.as";
#include "TeamColorCollections.as";

const int sw = getDriver().getScreenWidth();
const int sh = getDriver().getScreenHeight();

s8 ping_pointer_frame = 0;
u8 ping_pointer_framerate = 6;

Vec2f keypress_pos = Vec2f_zero;
Vec2f keypress_worldpos = Vec2f_zero;

const int radius = 100.0f;
const f32 blind_area_range = 8.0f;

s8 selected_section = -1;
s8 selected_ping = -1;

const f32 subsection_radius = 72.0f;
const f32 subsection_angle = 360.0f/(PingCategories.size()+2);
const f32 subsection_size = 3;
const f32 subsection_select_radius = 24.0f;
const f32 endpoint = radius+subsection_radius-subsection_select_radius/2; // limit radius for cursor inside circle

f32 lerp_subsection = 0;

void onTick(CBlob@ this)
{
	if (!this.isMyPlayer()) return;

	if (getGameTime()%ping_pointer_framerate==0)
	{
		ping_pointer_frame++;
		if (ping_pointer_frame > 3)
		{
			ping_pointer_frame = -3;
		}
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;

	CControls@ controls = getControls();
    if (controls is null) return;

	if (blob.isKeyPressed(key_taunts))
	{
		//Vec2f sc = getDriver().getScreenCenterPos();

        Vec2f mpos = controls.getMouseScreenPos();
        if (blob.isKeyJustPressed(key_taunts))
		{
			keypress_pos = mpos;
			keypress_worldpos = getDriver().getWorldPosFromScreenPos(keypress_pos);
		}
		
		Vec2f impos = controls.getInterpMouseScreenPos(); // tor
		Vec2f mvec = (impos-keypress_pos);
		if (mvec.Length() > endpoint)
		{
			controls.setMousePosition(keypress_pos + Vec2f(endpoint, 0).RotateBy(-mvec.Angle()));
		}

		DrawPointer(keypress_worldpos);
		DrawCategories(mpos);
	}
	else if (blob.isKeyJustReleased(key_taunts) && selected_section >= 0 && selected_ping >= 0)
	{
		if (!blob.hasTag("send_ping"))
		{
			blob.Tag("send_ping");
			SendPing(blob, keypress_worldpos, selected_section, selected_ping);
		}
	}
    else
    {
		blob.Untag("send_ping");

        keypress_pos = Vec2f_zero;
		keypress_worldpos = Vec2f_zero;
        selected_section = -1;
		selected_ping = -1;
    }
}

void DrawPointer(Vec2f worldpos)
{
	if (getLocalPlayer() is null) return;

	GUI::DrawIcon("PingPointer", Maths::Abs(ping_pointer_frame), Vec2f(16,16),
		getDriver().getScreenPosFromWorldPos(worldpos-Vec2f(10,10)), 1.5f, getNeonColor(getLocalPlayer().getTeamNum(), 0));
}

void DrawCategories(Vec2f mpos)
{
	if (getLocalPlayerBlob() is null) return;

    u8 total = PingCategories.size();
	bool was_selected = false;
	
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

        if ((keypress_pos-mpos).Length() > blind_area_range && diff <= part/2 && diff > -part/2) selected = true;

        SColor col = SColor(25,255,255,255);
        if (selected)
        	col.setAlpha(75);

        drawCone(min * Maths::Pi/180, max * Maths::Pi/180, col);

		if (selected)
		{
			was_selected = true;
			DrawPings(mpos, drawpos, angle, i);

			if (selected_section != i)
			{
				Sound::Play("select.ogg", getLocalPlayerBlob().getPosition(), 2.0f, 1.1f);
			}

			selected_section = i;
		}

		GUI::SetFont("score-medium");
        GUI::DrawTextCentered(PingCategories[i], drawpos, PingColors[i]);
    }

	if (!was_selected)
	{
		selected_section = -1;
		selected_ping = -1;
	}
}

void DrawPings(Vec2f mpos, Vec2f drawpos, f32 angle, u8 section)
{
	bool was_selected = false;

	for (u8 i = 0; i < subsection_size; i++)
	{
		GUI::SetFont("score-small");
		Vec2f subpos = drawpos + Vec2f(0, -subsection_radius).RotateBy(angle - (subsection_size*subsection_angle)/subsection_size + i*subsection_angle);
	
		if ((subpos - mpos).Length() < subsection_select_radius)
		{
			was_selected = true;
			GUI::SetFont("score-medium");

			if (selected_ping != i)
			{
				Sound::Play("LoadingTick1.ogg", getLocalPlayerBlob().getPosition(), 1.5f, 1.475f+XORRandom(51)*0.001f);
			}
			
			selected_ping = i;
		}
		
		GUI::DrawTextCentered(PingList[section*subsection_size+i], subpos, PingColors[section]);
	}

	if (!was_selected)
	{
		selected_ping = -1;
	}
}

void drawCone(f32 min, f32 max, SColor col)
{
	Driver@ driver = getDriver();
	Vec2f origin = keypress_pos;
	float ray_distance = radius * 2;
	
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

void SendPing(CBlob@ blob, Vec2f pos, u8 section, u8 ping)
{
	CPlayer@ p = blob.getPlayer();
	if (p is null) return;

	// reminder: whole script is running just by our player
	CBitStream params;
	params.write_u8(p.getTeamNum());
	params.write_Vec2f(pos);
	params.write_u8(section*subsection_size + ping);
	params.write_u32(ping_time);
	params.write_u8(ping_fadeout_time);
	params.write_string(p.getClantag()+" "+p.getCharacterName());
	getRules().SendCommand(getRules().getCommandID("ping"), params);

	CControls@ controls = getControls();
	if (controls is null) return;

	controls.setMousePosition(keypress_pos);
}