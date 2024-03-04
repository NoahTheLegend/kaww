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
	"draw_Rectangle",
	"draw_Path",
	"draw_Timer"
};

const int render_margin = 64.0f; // extra area for rendering out of screen
const f32 subsection_size = 3;

const int ping_time = 120;
const int ping_fadeout_time = 10;
const f32 ping_slidein_dist = 24.0f;

const int canvas_ping_time = 240;
const int canvas_ping_fadeout_time = 10;

const u8 max_path_segments = 6;

void DrawPointer(Vec2f worldpos, u8 frame, SColor col)
{
	if (getLocalPlayer() is null) return;
	if (getCamera() is null) return;

	GUI::DrawIcon("PingPointer", frame, Vec2f(16,16),
		getDriver().getScreenPosFromWorldPos(worldpos-Vec2f(10,10) / getCamera().targetDistance), 1.5f, col);
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

enum Shapes {
	path = 0,
	rectangle,
	timer,
	total
};

const Canvas@[] shapes = {
	Rectangle(),
	Path(),
	Timer()
};

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

	Ping(Vec2f _pos, u8 _type, u32 _end_time, u8 _fadeout_time, string _caster, u8 _team)
	{
		pos = _pos;
		type = _type;
		end_time = getGameTime() + _end_time;
		fadeout_time = _fadeout_time;
		caster = _caster;
		team = _team;

		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
		local_mpos = Vec2f(-128,-128);
		fadeout = 0;
		lerp = f32(ping_fadeout_time)/getTicksASecond();
	}

	void render()
	{
		int diff = end_time - getGameTime();
		if (diff <= fadeout_time) fadeout = Maths::Lerp(fadeout, 0.0f, lerp);
		else fadeout = Maths::Lerp(fadeout, 1.0f, lerp);

		SColor type_col = PingColors[Maths::Floor(type/3)];
		SColor team_col = getNeonColor(team, 0);
		SColor white_col = color_white;
		
		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
		Vec2f text_pos = screen_pos - Vec2f(2, 80 - ping_slidein_dist * fadeout);

		type_col.setAlpha(225 * fadeout);
		white_col.setAlpha(155 * fadeout);

		GUI::SetFont("score-big");
		GUI::DrawTextCentered(PingList[type], text_pos, type_col);

		GUI::SetFont("score-smaller");
		GUI::DrawTextCentered("| "+caster+" |", text_pos + Vec2f(0, 24), white_col);

		DrawPointer(pos, (diff/15)%2==0?2:3, type_col);
	}
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
		this.end_time = _end_time;
		this.fadeout_time = _fadeout_time;
		this.caster = _caster;
		this.team = _team;
		this.static = false;

		this.screen_pos = getDriver().getScreenPosFromWorldPos(this.pos);
	}

	void tick(CBlob@ blob, CControls@ controls) {}
	void render(CBlob@ blob, CControls@ controls) {}
};

class Path : Canvas {
	f32 max_node_length;

	Path()
	{
		this.max_node_length = 128.0f;
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
				if (vec.Length() > this.max_node_length)
				{
					f32 angle = -vec.Angle();
					mpos = origin + Vec2f(this.max_node_length, 0).RotateBy(angle);
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
			SendPathCanvas(blob, this.shape, this.vertices, this.team, this.end_time, this.fadeout_time);
		}
	}

	void render(CBlob@ blob, CControls@ controls) override
	{
		Driver@ driver = getDriver();
		this.screen_pos = driver.getScreenPosFromWorldPos(this.pos);

		SColor col = getNeonColor(this.team, 0);
		col.setAlpha(135);
		
		f32 cam = getCamera().targetDistance;
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
				next = getDriver().getWorldPosFromScreenPos(impos);

			f32 angle = -(next-current).Angle();
			f32 d = 1.0f * scale + 7.0f;

			if (!has_next && !this.static)
			{
				Vec2f vec = next-current;
				if (vec.Length() > this.max_node_length)
					next = current + Vec2f(this.max_node_length, 0).RotateBy(angle);

				Vec2f screen_next_pos = getDriver().getScreenPosFromWorldPos(next);
				GUI::SetFont("score-smaller");
				GUI::DrawTextCentered("DRAWING", screen_next_pos + Vec2f(-2, 24), SColor(33,255,255,255));
				GUI::DrawTextCentered("RMB - SEND", screen_next_pos + Vec2f(-2, 40), SColor(33,255,255,255));
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
				getDriver().getScreenPosFromWorldPos(current)-icon_offset,
					scale, col);
		}
	}
};

class Rectangle : Canvas {
	Rectangle()
	{
		super(Shapes::rectangle);
	}
}

class Timer : Canvas {
	Timer()
	{
		super(Shapes::timer);
	}
}