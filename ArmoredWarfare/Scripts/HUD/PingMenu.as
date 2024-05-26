#define CLIENT_ONLY
// whole script is running only by our local player
// check IndicatorHUD.as for handling ping logic
// todo: add pings to indicator map

#include "PingCommon.as";
#include "TeamColorCollections.as";

s8 ping_pointer_frame = 0;
u8 ping_pointer_framerate = 6;

Vec2f keypress_pos = Vec2f_zero; // screen pos
Vec2f keypress_worldpos = Vec2f_zero; // world pos

// section wheel
const int radius = 80.0f; // how far from keypress_pos
const f32 blind_area_range = 16.0f; // category selection blind area

// subsection ping list
const f32 subsection_radius = 96.0f; // how far from category_name
const f32 subsection_angle = 180.0f/(PingCategories.size()-1); // spread angle
const f32 endpoint = radius+subsection_radius/1.1f; // limit radius for cursor inside circle

// cooldown props
int cooldown = 0; // time during that we cant ping
const int cooldown_time = 5*30;
int load = 0; // current load
const int load_max = 200; // limit w/o cooldown
const int ping_cost = 75; // per one
int load_holdtime = 0;
const int load_holdtime_max = 60; // wait time before decreasing
const int draw_cost = 400;

// slide out lerp factor
const f32 lerp = 0.3f; // sections
const f32 lerp_fast = 0.5f; // ping list

// dont change these
s8 selected_section = -1;
s8 selected_ping = -1;
f32 lerp_section = 0;
f32 lerp_subsection = 0;

void onTick(CBlob@ this)
{
	if (!this.isMyPlayer()) return;
	CControls@ controls = getControls();
	if (controls is null) return;

	if (this.hasTag("drawing_ping"))
	{
		DrawStateTick(this, controls);
	}
	
	if (cooldown > 0)
	{
		cooldown--;
	}
	else
	{
		if (load_holdtime > 0) load_holdtime--;
		else if (load > 0) load--;
	}

	if (getGameTime()%ping_pointer_framerate==0)
	{
		ping_pointer_frame++;
		if (ping_pointer_frame > 3)
		{
			ping_pointer_frame = -3;
		}
	}
}

bool drawing = true;

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;

	CControls@ controls = getControls();
    if (controls is null) return;

	bool reset = false;
	bool open_menu = blob.isKeyPressed(key_taunts) && !controls.isKeyPressed(KEY_LSHIFT);

	if (blob.hasTag("drawing_ping"))
	{
		DrawState(blob, controls);
		drawing = true;
	}
	else if (open_menu ? !drawing : true)
	{
		drawing = false;

		if (open_menu)
		{ // render menu
			lerp_section = Maths::Lerp(lerp_section, 1.0f, lerp);

			// save origin pos
    	    Vec2f mpos = controls.getMouseScreenPos();
    	    if (blob.isKeyJustPressed(key_taunts))
			{
				keypress_pos = mpos;
				keypress_worldpos = getDriver().getWorldPosFromScreenPos(keypress_pos);
			}

			if (!isOnScreen(keypress_worldpos)) reset = true;
			else
			{
				// clamp mouse pos in bounds
				Vec2f impos = controls.getInterpMouseScreenPos(); // tor
				Vec2f mvec = (impos-keypress_pos);

				if (Maths::Floor(mvec.Length()) > endpoint)
				{
					f32 angle = Maths::ATan2(mvec.y, mvec.x) * (180.0 / 3.14159265); // getAngle() snaps angle to int if its == 90 || == 270
					controls.setMousePosition(keypress_pos + Vec2f(endpoint, 0).RotateBy(angle));
				}

				// draw
				SColor pointer_col = getNeonColor(blob.getTeamNum(), 0);

				DrawPointer(keypress_worldpos, Maths::Abs(ping_pointer_frame), pointer_col);
				DrawCategories(mpos);

				if (load != 0 || cooldown > 0) DrawLoad(keypress_pos);
			}
		}
		else if (blob.isKeyJustReleased(key_taunts) && cooldown == 0 && selected_section >= 0 && selected_ping >= 0)
		{ // send ping
			if (!blob.hasTag("send_ping"))
			{
				blob.Tag("send_ping");

				u8 ping = selected_section*subsection_size + selected_ping;

				if (PingList[ping].find("draw_") != -1)
					SetDrawState(blob, keypress_worldpos, selected_section, selected_ping);
				else
					SendPing(blob, keypress_worldpos, selected_section, selected_ping);
			}
		}
		else reset = true;
	}
    
	if (reset)
    {
		blob.Untag("send_ping");

		lerp_section = Maths::Lerp(lerp_section, 0.0f, lerp);
        keypress_pos = Vec2f_zero;
		keypress_worldpos = Vec2f_zero;
        selected_section = -1;
		selected_ping = -1;
    }
}

void DrawCategories(Vec2f mpos)
{
	if (getLocalPlayerBlob() is null) return;

    u8 total = PingCategories.size();
	bool was_selected = false;
	bool inactive = cooldown > 0;
	
    for (u8 i = 0; i < total; i++)
    {
		// calculate part's angle
        f32 part = 360/total;
        f32 angle = i * part;

        Vec2f drawpos = keypress_pos + Vec2f(0, -radius*lerp_section).RotateBy(angle);
        f32 mangle = -(mpos-keypress_pos).Angle() + 90; // (center -> mouse) vector angle
        
        f32 min = (90+angle - part/2);
        f32 max = (90+angle + part/2);

		SColor section_col = PingColors[i];

        bool selected = false;
		f32 diff = mangle - angle;
		if (!inactive) // not on cooldown
		{
			diff += diff > 180 ? -360 : diff < -180 ? 360 : 0;
       	 	if ((keypress_pos-mpos).Length() > blind_area_range && diff <= part/2 && diff > -part/2) selected = true;

        	SColor col = SColor(50,255,255,255);
			if (selected)
        		col.setAlpha(100);

			col.setAlpha(col.getAlpha()*lerp_section);
        	DrawCone(min * Maths::Pi/180, max * Maths::Pi/180, col);

			if (selected)
			{
				was_selected = true;

				if (selected_section != i) // last selected != new selected
				{
					lerp_subsection = 0;
					Sound::Play("select.ogg", getLocalPlayerBlob().getPosition(), 2.0f, 1.1f);
				}

				DrawPings(mpos, drawpos, angle, i);
				selected_section = i;
			}
		}
		else section_col = SColor(155,255,255,255);
		section_col.setAlpha(section_col.getAlpha()*lerp_section);

		GUI::SetFont("score-medium");
        GUI::DrawTextCentered(PingCategories[i], drawpos, section_col);
    }

	if (was_selected) lerp_subsection = Maths::Lerp(lerp_subsection, 1.0f, lerp_fast);
	else // reset
	{
		lerp_subsection = 0;
		selected_section = -1;
		selected_ping = -1;
	}
}

void DrawPings(Vec2f mpos, Vec2f drawpos, f32 angle, u8 section)
{
	f32 dist = radius;
	s8 closest_ping = -1;

	u8 section_pos = section*subsection_size;
	string[] subsection;

	for (u8 i = 0; i < subsection_size; i++)
	{
		string ping = PingList[section_pos+i];
		if (ping != "") subsection.push_back(ping);
	}

	if (subsection.size() % 2 == 0) angle += subsection_angle/subsection_size;
	for (u8 i = 0; i < subsection.size(); i++)
	{
		Vec2f subpos = drawpos + Vec2f(0, -subsection_radius*lerp_subsection).RotateBy(angle - (subsection.size()*subsection_angle)/subsection_size + i*subsection_angle);
		f32 len = Maths::Abs((subpos-mpos).Length());

		if (len < dist)
		{
			closest_ping = i;
			dist = len;
		}
	}

	for (u8 i = 0; i < subsection_size; i++)
	{
		if (selected_ping != closest_ping) // last selected != new selected
		{
			Sound::Play("LoadingTick1.ogg", getLocalPlayerBlob().getPosition(), 1.5f, 1.475f+XORRandom(51)*0.001f);
		}

		GUI::SetFont(closest_ping == i ? "score-medium" : "score-small");
		Vec2f subpos = drawpos + Vec2f(0, -subsection_radius*lerp_subsection).RotateBy(angle - (subsection_size*subsection_angle)/subsection_size + i*subsection_angle);
		
		string ping = PingList[section*subsection_size+i];
		int draw_prefix = ping.find("_");
		if (draw_prefix != -1)
		{
			ping = ping.substr(draw_prefix + 1);
		}

		GUI::DrawTextCentered(ping, subpos, PingColors[section]);
	}

	selected_ping = closest_ping;
}

void DrawCone(f32 min, f32 max, SColor col)
{
	Driver@ driver = getDriver();
	Vec2f origin = keypress_pos;
	float ray_distance = radius*2*lerp_section;
	
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

const u8 timer_frames = 28;
void DrawLoad(Vec2f pos)
{
	u8 frame = cooldown == 0 ? timer_frames - timer_frames * (f32(load)/load_max) : timer_frames - timer_frames * f32(cooldown)/cooldown_time;
	f32 scale = 0.75f;

	GUI::DrawIcon("TimerCircle.png", frame, Vec2f(32,32),
		pos - Vec2f(32,32) * scale, scale, SColor(55,255,255,255));
}

void SetDrawState(CBlob@ blob, Vec2f pos, u8 section, u8 ping_type)
{
	if (blob is null)
	{
		blob.Untag("drawing_ping");
		return;
	}

	blob.Tag("drawing_ping");
	u8 ping = section*subsection_size + ping_type;

	Canvas@ new = shapes[ping_type];
	if (new is null) return;

	new.SetPingProps(pos, ping_type, canvas_ping_time, canvas_ping_fadeout_time, getFullCharacterName(blob.getPlayer()), blob.getTeamNum());
	new.vertices = array<Vec2f>();
	new.vertices.push_back(pos);
	blob.set("ping_canvas", @new);
}

void DrawStateTick(CBlob@ this, CControls@ controls)
{
	Canvas@ canvas;
	if (!this.get("ping_canvas", @canvas) || canvas is null) return;

	canvas.tick(this, controls);
}

void DrawState(CBlob@ blob, CControls@ controls)
{
	Canvas@ canvas;
	if (!blob.get("ping_canvas", @canvas) || canvas is null) return;

	canvas.render(blob, controls);
}

void SendPing(CBlob@ blob, Vec2f pos, u8 section, u8 ping_type)
{
	CPlayer@ p = blob.getPlayer();
	if (p is null) return;

	// reminder: whole script is running just by our player
	u8 ping = section*subsection_size + ping_type;

	CBitStream params;
	params.write_u8(p.getTeamNum());
	params.write_Vec2f(pos);
	params.write_u8(ping);
	params.write_u32(ping_time);
	params.write_u8(ping_fadeout_time);
	params.write_string(getFullCharacterName(p));
	getRules().SendCommand(getRules().getCommandID("ping"), params);

	CControls@ controls = getControls();
	if (controls is null) return;
	
	controls.setMousePosition(keypress_pos);
	Load(ping_cost);
}

void SendPathCanvas(CBlob@ blob, u8 shape, Vec2f[] vertices, u8 team, u32 ping_time, u8 ping_fadeout_time)
{
	blob.Untag("drawing_ping");
	if (vertices.size() <= 1) return;

	CPlayer@ p = blob.getPlayer();
	if (p is null) return;

	CBitStream params;
	params.write_u8(shape);
	params.write_u8(team);
	params.write_u32(ping_time);
	params.write_u8(ping_fadeout_time);
	params.write_string(getFullCharacterName(p));

	u8 vsize = vertices.size();
	params.write_u8(vsize);
	for (u8 i = 0; i < vsize; i++)
	{
		params.write_Vec2f(vertices[i]);
	}

	getRules().SendCommand(getRules().getCommandID("ping_path"), params);
	Load(draw_cost);
}

void SendRectangleCanvas(CBlob@ blob, u8 shape, Vec2f[] vertices, u8 team, u32 ping_time, u8 ping_fadeout_time)
{
	blob.Untag("drawing_ping");
	if (vertices.size() <= 1) return;

	CPlayer@ p = blob.getPlayer();
	if (p is null) return;

	CBitStream params;
	params.write_u8(shape);
	params.write_u8(team);
	params.write_u32(ping_time);
	params.write_u8(ping_fadeout_time);
	params.write_string(getFullCharacterName(p));

	u8 vsize = vertices.size();
	params.write_u8(vsize);
	for (u8 i = 0; i < vsize; i++)
	{
		params.write_Vec2f(vertices[i]);
	}

	getRules().SendCommand(getRules().getCommandID("ping_rectangle"), params);
	Load(draw_cost);
}

void Load(f32 cost)
{
	if (isServer()) return; // local test

	load += cost;
	load_holdtime = load_holdtime_max;
	
	if (load >= load_max)
	{
		load = 0;
		load_holdtime = 0;
		cooldown = cooldown_time;
	}
}