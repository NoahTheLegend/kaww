#include "TeamColorCollections.as"

const int sw = getDriver().getScreenWidth();
const int sh = getDriver().getScreenHeight();

const SColor[] PingColors = {
	SColor(200,255,225,35),
	SColor(200,55,95,225),
	SColor(200,110,235,70),
	SColor(200,255,55,55),
	SColor(200,255,100,230),
	SColor(200,255,255,255)
};

const string[] PingCategories = {
	"MOVEMENT",
	"TACTIC",
	"ACTION",
	"ENEMY",
	"NOTIFY",
	"DRAW"
};

const string[] PingList = {
    // movement
    "Go there",
	"Attention",
    "Danger",
    // tactic
    "Retreat",
    "Attack",
    "Hold",
    // action
    "Take",
    "Capture",
    "Leave",
    // enemy
    "Incoming",
    "Help",
    "Fire",
    // alert
    "What",
    "Yes",
    "No",
	// draw
	"draw_Path", // keep order relative to Canvas@[] shapes array!
	"draw_Rectangle",
	"map_Map" // shows on indicator hud
};

const Canvas@[] shapes = {
	Path(),
	Rectangle()
};

const int render_margin = 64.0f; // extra area for rendering out of screen
const f32 subsection_size = 3; // how many pings in each section (3 is optimal, keep an empty line if you need less in a section)

// pings
const int ping_time = 120; // lifetime
const int ping_fadeout_time = 10; // doesn't add up to lifetime
const f32 ping_slidein_dist = 24.0f;

// specific pings
const int map_ping_time = 300;
const int map_ping_fadeout_time = 30;
const int canvas_ping_time = 240;
const int canvas_ping_fadeout_time = 15;

// rectangle
const f32 max_rect_perimeter = 256.0f;

// path ping
const u8 max_path_segments = 8;
const f32 max_path_segment_length = 128.0f;

void DrawPointer(Vec2f worldpos, u8 frame, SColor col)
{
	if (getLocalPlayer() is null) return;
	if (getCamera() is null) return;

	GUI::DrawIcon("PingPointer", frame, Vec2f(16,16),
		getDriver().getScreenPosFromWorldPos(worldpos) - Vec2f(25,25), 1.5f, col);
}

bool isOnScreen(Vec2f pos, f32 dist = 1)
{
	pos = getDriver().getScreenPosFromWorldPos(pos);
	return pos.x >= -render_margin - (dist * sw) && pos.y >= -render_margin - (dist * sh) && pos.x < (sw + render_margin) * dist && pos.y < (sh + render_margin) * dist;
}

string getFullCharacterName(CPlayer@ p)
{
	if (p is null) return "";

	string clan = p.getClantag();
	if (clan != "") clan = clan+" ";
	
	return clan+""+p.getCharacterName();
}

class Ping {
	Vec2f pos;
	Vec2f screen_pos;
	u8 type;

	u32 end_time;
	u8 fadeout_time;

	string caster;
	u8 team;

	Vec2f local_mpos;
	f32 fadeout;
	f32 lerp;
	int diff;

	Ping(Vec2f _pos, u8 _type, u32 _end_time, u8 _fadeout_time, string _caster, u8 _team)
	{
		pos = _pos;
		type = _type;
		end_time = getGameTime() + _end_time;
		fadeout_time = _fadeout_time;
		caster = _caster;
		team = _team;

		set();
	}

	void set()
	{
		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
		local_mpos = Vec2f(-128,-128);
		fadeout = 0;
		lerp = f32(ping_fadeout_time)/getTicksASecond();
		diff = 0;
	}

	void calculateFade()
	{
		diff = end_time - getGameTime();
		if (diff <= fadeout_time) fadeout = Maths::Lerp(fadeout, 0.0f, lerp);
		else fadeout = Maths::Lerp(fadeout, 1.0f, lerp);
	}

	void updateScreenPos()
	{
		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
	}

	void DrawCaster(Vec2f text_pos)
	{
		SColor white_col = color_white;
		white_col.setAlpha(155 * fadeout);

		GUI::SetFont("score-smaller");
		GUI::DrawTextCentered("| "+caster+" |", text_pos, white_col);
	}

	void render()
	{
		calculateFade();
		updateScreenPos();
		
		SColor type_col = PingColors[Maths::Floor(type/3)];
		SColor team_col = getNeonColor(team, 0);
		type_col.setAlpha(225 * fadeout);

		Vec2f text_pos = screen_pos - Vec2f(2, 80 - ping_slidein_dist * fadeout);

		GUI::SetFont("score-big");
		GUI::DrawTextCentered(PingList[type], text_pos, type_col);

		DrawCaster(text_pos + Vec2f(0,24));
		DrawPointer(pos, (diff/15)%2==0?2:3, type_col);
	}
};

class TextPing : Ping {
	string text;

	TextPing(Vec2f _pos, string _text, u32 _end_time, u8 _fadeout_time, string _caster, u8 _team)
	{
		pos = _pos;
		text = _text;
		end_time = getGameTime() + _end_time;
		fadeout_time = _fadeout_time;
		caster = _caster;
		team = _team;
		
		set();
	}

	void render()
	{
		calculateFade();
		updateScreenPos();
		
		SColor type_col = PingColors[Maths::Floor(type/3)];
		SColor team_col = getNeonColor(team, 0);
		type_col.setAlpha(225 * fadeout);

		Vec2f text_pos = screen_pos - Vec2f(2, 80 - ping_slidein_dist * fadeout);

		GUI::SetFont("score-big");
		GUI::DrawTextCentered(text, text_pos, type_col);

		DrawCaster(text_pos + Vec2f(0,24));
		DrawPointer(pos, (diff/15)%2==0?2:3, type_col);
	}
};

enum Shapes {
	path = 0,
	rectangle,
	total
};

class Canvas : Ping {
	u8 shape;
	bool static;
	Vec2f[] vertices;

	Canvas(u8 _shape)
	{
		shape = _shape;
	}

	void SetPingProps(Vec2f _pos, u8 _type, u32 _end_time, u8 _fadeout_time, string _caster, u8 _team)
	{
		this.pos = _pos;
		this.type = _type;
		this.end_time = getGameTime() + _end_time;
		this.fadeout_time = _fadeout_time;
		this.caster = _caster;
		this.team = _team;
		this.static = false;

		this.set();
	}

	void tick(CBlob@ blob, CControls@ controls) {}
	void render(CBlob@ blob, CControls@ controls) {}
};

class Path : Canvas {
	Path()
	{
		super(Shapes::path);
	}

	void tick(CBlob@ blob, CControls@ controls)
	{
		bool send = false;
		if (blob.isKeyJustPressed(key_taunts))
		{
			Vec2f mpos = controls.getMouseWorldPos();
			if (this.vertices.size() > 0)
			{
				Vec2f origin = this.vertices[this.vertices.size()-1];
				Vec2f vec = mpos-origin;
				if (vec.Length() > max_path_segment_length)
				{
					f32 angle = -vec.Angle();
					mpos = origin + Vec2f(max_path_segment_length, 0).RotateBy(angle);
				}
			}

			Sound::Play("snes_coin.ogg", mpos, 1.0f, 1.15f + XORRandom(51) * 0.001f);
			this.vertices.push_back(mpos);

			if (this.vertices.size() >= max_path_segments)
			{
				blob.Untag("drawing_ping");
				send = true;
			}
		}

		if (controls.isKeyJustPressed(KEY_LBUTTON) || controls.isKeyJustPressed(KEY_RBUTTON))
		{
			send = true;
		}

		if (send)
		{
			SendPathCanvas(blob, this.shape, this.vertices, this.team, canvas_ping_time, canvas_ping_fadeout_time);
		}
	}

	void render(CBlob@ blob, CControls@ controls) override
	{
		calculateFade();
		updateScreenPos();

		if (!this.static) this.fadeout = 1.0f;
		Driver@ driver = getDriver();

		//SColor col = getNeonColor(this.team, 0);
		SColor col = color_white;
		col.setAlpha(135 * this.fadeout);
		
		f32 cam = getCamera().targetDistance * driver.getResolutionScaleFactor();
		f32 scale = 0.33f * cam;
		Vec2f icon_offset = Vec2f(32,32)*scale;
		Vec2f impos = controls.getInterpMouseScreenPos();

		for (u8 i = 0; i < this.vertices.size(); i++)
		{
			Vec2f current = this.vertices[i];
			bool has_next = i < int(this.vertices.size())-1;
			Vec2f next = Vec2f_zero;

			if (has_next)
				next = this.vertices[i+1];
			else if (!this.static)
				next = driver.getWorldPosFromScreenPos(impos);

			f32 angle = -(next-current).Angle();
			f32 d = 1.0f * scale + 7.0f;

			if (!has_next && !this.static)
			{
				Vec2f vec = next-current;
				if (vec.Length() > max_path_segment_length)
					next = current + Vec2f(max_path_segment_length, 0).RotateBy(angle);

				Vec2f screen_next_pos = driver.getScreenPosFromWorldPos(next);
				GUI::SetFont("score-smaller");
				GUI::DrawTextCentered("DRAWING", screen_next_pos + Vec2f(-2, 24), SColor(33,255,255,255));
				GUI::DrawTextCentered("L|R - SEND", screen_next_pos + Vec2f(-2, 40), SColor(33,255,255,255));
				GUI::DrawIcon("PathNode.png", 0, Vec2f(32,32), screen_next_pos-icon_offset, scale, col);
			}

			if (next != Vec2f_zero)
			{
				Vec2f offset = Vec2f(d/2, 1.0f).RotateBy(angle);
				Vec2f edge = Vec2f(d, 0).RotateBy(angle);

				Vertex[] vertexes;
				// first triangle (outcome)
				// third is height
				vertexes.push_back(Vertex(
					current-offset+edge,
					0.0f,
					Vec2f(0.0f, 0.0f),
    			    col
				));
				vertexes.push_back(Vertex(
					current+offset,
					0.0f,
					Vec2f(0.0f, 0.0f),
    			    col
				));
				vertexes.push_back(Vertex(
					next-offset,
					0.0f,
					Vec2f(0.0f, 0.0f),
    			    col
				));
				// second triangle (income)
				vertexes.push_back(Vertex(
					next-offset,
					0.0f,
					Vec2f(0.0f, 0.0f),
    			    col
				));
				vertexes.push_back(Vertex(
					next+offset-edge,
					0.0f,
					Vec2f(0.0f, 0.0f),
    			    col
				));
				vertexes.push_back(Vertex(
					current+offset,
					0.0f,
					Vec2f(0.0f, 0.0f),
    			    col
				));

				Render::RawTriangles("pixel", vertexes);
			}

			GUI::DrawIcon("PathNode.png", 0, Vec2f(32,32),
				driver.getScreenPosFromWorldPos(current)-icon_offset,
					scale, col);
		}

		if (this.static)
			DrawCaster(this.screen_pos + Vec2f(0, 24));
	}
};

class Rectangle : Canvas {
	Rectangle()
	{
		super(Shapes::rectangle);
	}

	void tick(CBlob@ blob, CControls@ controls)
	{
		bool send = false;

		if (blob.isKeyJustPressed(key_taunts))
		{
			Vec2f mpos = controls.getMouseWorldPos();
			if (this.vertices.size() > 0)
			{
				Vec2f origin = this.vertices[this.vertices.size()-1];

				Vec2f tl = Vec2f(origin.x - max_rect_perimeter, origin.y - max_rect_perimeter);
				Vec2f br = Vec2f(origin.x + max_rect_perimeter, origin.y + max_rect_perimeter);

				if (mpos.x > br.x
				 || mpos.x < tl.x
				 || mpos.y > br.y
				 || mpos.y < tl.y)
				{
					mpos = Vec2f(Maths::Clamp(mpos.x, tl.x, br.x), Maths::Clamp(mpos.y, tl.y, br.y));
				}
			}

			Sound::Play("snes_coin.ogg", mpos, 1.0f, 1.15f + XORRandom(51) * 0.001f);
			this.vertices.push_back(mpos);

			if (this.vertices.size() >= 2)
			{
				blob.Untag("drawing_ping");
				send = true;
			}
		}

		if (controls.isKeyJustPressed(KEY_LBUTTON) || controls.isKeyJustPressed(KEY_RBUTTON))
		{
			send = true;
		}

		if (send)
		{
			SendRectangleCanvas(blob, this.shape, this.vertices, this.team, canvas_ping_time, canvas_ping_fadeout_time);
		}
	}

	void render(CBlob@ blob, CControls@ controls) override
	{
		if (this.vertices.size() == 0) return;

		calculateFade();
		updateScreenPos();

		if (!this.static) this.fadeout = 1.0f;
		Driver@ driver = getDriver();

		//SColor col = getNeonColor(this.team, 0);
		SColor col = color_white;
		col.setAlpha(135 * this.fadeout);
		
		f32 cam = getCamera().targetDistance * driver.getResolutionScaleFactor();
		f32 scale = 0.25f;
		Vec2f icon_offset = Vec2f(32,32)*scale*cam;
		Vec2f impos = controls.getInterpMouseScreenPos();
		f32 line_width = 1;

		Vec2f mpos = controls.getMouseWorldPos();
		Vec2f current = this.vertices[0];
		bool has_next = this.vertices.size() == 2;
		Vec2f next = Vec2f_zero;

		if (has_next)
			next = this.vertices[1];
		else if (!this.static)
			next = driver.getWorldPosFromScreenPos(impos);

		if (!has_next && !this.static)
		{
			Vec2f origin = current;

			Vec2f tl = Vec2f(origin.x - max_rect_perimeter, origin.y - max_rect_perimeter);
			Vec2f br = Vec2f(origin.x + max_rect_perimeter, origin.y + max_rect_perimeter);

			if (mpos.x > br.x
			 || mpos.x < tl.x
			 || mpos.y > br.y
			 || mpos.y < tl.y)
			{
				next = Vec2f(Maths::Clamp(mpos.x, tl.x, br.x), Maths::Clamp(mpos.y, tl.y, br.y));
			}

			Vec2f screen_next_pos = driver.getScreenPosFromWorldPos(next);
			 
			GUI::SetFont("score-smaller");
			GUI::DrawTextCentered("DRAWING", screen_next_pos + Vec2f(-2, 24), SColor(33,255,255,255));
			GUI::DrawTextCentered("L|R - SEND", screen_next_pos + Vec2f(-2, 40), SColor(33,255,255,255));
			GUI::DrawIcon("PathNode.png", 0, Vec2f(32,32), screen_next_pos-icon_offset, scale*cam, col);
		}

		GUI::DrawIcon("PathNode.png", 0, Vec2f(32,32),
			driver.getScreenPosFromWorldPos(current)-icon_offset,
				scale*cam, col);

		DrawVerticalRectangle(current, next, line_width, col, driver, scale);
		DrawHorizontalRectangle(current, next, line_width, col, driver, scale);
		DrawVerticalRectangle(next, current, line_width, col, driver, scale);
		DrawHorizontalRectangle(next, current, line_width, col, driver, scale);

		if (this.static)
		{
			DrawCaster(this.screen_pos + Vec2f(0, 24));

			GUI::DrawIcon("PathNode.png", 0, Vec2f(32,32),
				driver.getScreenPosFromWorldPos(next)-icon_offset,
					scale*cam, col);
		}
	}

	void DrawVerticalRectangle(Vec2f anchor, Vec2f next, f32 line_width, SColor col, Driver@ driver, f32 scale)
	{
	    Vec2f start_pos;
	    Vec2f end_pos;

	    if (next.y >= anchor.y)
	    {
	        start_pos = anchor + Vec2f(-line_width, 12 * scale);
	        end_pos = Vec2f(anchor.x + line_width, next.y - line_width);
	    }
	    else
	    {
	        start_pos = Vec2f(anchor.x, next.y) - Vec2f(line_width, -line_width);
	        end_pos = Vec2f(anchor.x + line_width, anchor.y - 12 * scale);
	    }
	
	    GUI::DrawRectangle(driver.getScreenPosFromWorldPos(start_pos), driver.getScreenPosFromWorldPos(end_pos), col);
	}
	
	
	void DrawHorizontalRectangle(Vec2f anchor, Vec2f next, f32 line_width, SColor col, Driver@ driver, f32 scale)
	{
	    Vec2f start_pos;
	    Vec2f end_pos;
	
	    if (next.x >= anchor.x)
	    {
	        start_pos = anchor + Vec2f(12 * scale, -line_width);
	        end_pos = Vec2f(next.x + line_width, anchor.y + line_width);
	    }
	    else
	    {
	        start_pos = Vec2f(next.x - line_width, anchor.y - line_width);
	        end_pos = anchor + Vec2f(-12 * scale, line_width);
	    }
	
	    GUI::DrawRectangle(driver.getScreenPosFromWorldPos(start_pos), driver.getScreenPosFromWorldPos(end_pos), col);
	}
}