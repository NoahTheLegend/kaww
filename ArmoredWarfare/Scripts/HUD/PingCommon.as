#include "TeamColorCollections.as"

const SColor[] PingColors = {
	SColor(255,255,225,35),
	SColor(255,55,95,225),
	SColor(255,25,255,50),
	SColor(255,255,55,55),
	SColor(255,185,75,225)
};

const string[] PingCategories = {
	"MOVEMENT",
	"TACTIC",
	"ACTION",
	"ENEMY",
	"NOTIFY"
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
    "Fire at here",
    // alert
    "What",
    "Yes",
    "No",
    // other
    "total"
};

const f32 subsection_size = 3;
const int ping_time = 120;
const int ping_fadeout_time = 10;
const f32 ping_slidein_dist = 24.0f;

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

void DrawPointer(Vec2f worldpos, u8 frame, SColor col)
{
	if (getLocalPlayer() is null) return;
	if (getCamera() is null) return;

	GUI::DrawIcon("PingPointer", frame, Vec2f(16,16),
		getDriver().getScreenPosFromWorldPos(worldpos-Vec2f(10,10) / getCamera().targetDistance), 1.5f, col);
}