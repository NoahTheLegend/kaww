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
    "Chase",
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

const f32 subsection_size = 3;
const int ping_time = 120;
const int ping_fadeout_time = 10;
const f32 ping_slidein_dist = 24.0f;

void DrawPointer(Vec2f worldpos, u8 frame, SColor col)
{
	if (getLocalPlayer() is null) return;
	if (getCamera() is null) return;

	GUI::DrawIcon("PingPointer", frame, Vec2f(16,16),
		getDriver().getScreenPosFromWorldPos(worldpos-Vec2f(10,10) / getCamera().targetDistance), 1.5f, col);
}

bool isOnScreen(Vec2f pos)
{
	pos = getDriver().getScreenPosFromWorldPos(pos);
	return pos.x >= 0 && pos.y >= 0 && pos.x < sw && pos.y < sh;
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

		this.screen_pos = getDriver().getScreenPosFromWorldPos(this.pos);
	}

	void tick(CBlob@ blob, CControls@ controls) {}
	void render() override {}
};

class Path : Canvas {
	Path()
	{
		super(Shapes::path);
	}

	void tick(CBlob@ blob, CControls@ controls)
	{
		if (blob.isKeyJustPressed(key_taunts))
		{
			Vec2f mpos = controls.getMouseWorldPos();
			this.vertices.push_back(mpos);
		}
	}

	void render() override
	{
		Driver@ driver = getDriver();
		this.screen_pos = driver.getScreenPosFromWorldPos(this.pos);

		SColor col = color_white;
		col.setAlpha(155);

		for (u8 i = 0; i < this.vertices.size(); i++)
		{
			Vec2f current = this.vertices[i];
			bool has_next = i < int(this.vertices.size())-1;
			
			if (has_next)
			{
				Vec2f next = this.vertices[i+1];
				f32 angle = -(next-current).Angle();

				Vec2f offset = Vec2f(0,-8).RotateBy(angle);
				Vertex[] vertexes;
				// Center vertex
				vertexes.push_back(Vertex(
					current-offset,
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
				

				Render::RawTriangles("pixel", vertexes);
			}

			GUI::SetFont("score-medium");
			GUI::DrawTextCentered(""+i, driver.getScreenPosFromWorldPos(current), SColor(255,255,255,0));
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