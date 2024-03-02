
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
	"Attention!",
    "Danger!",
    // tactic
    "Retreat!",
    "Attack!",
    "Hold",
    // action
    "Take",
    "Capture",
    "Leave",
    // enemy
    "Incoming!",
    "Chase!",
    "Fire at!",
    // alert
    "What?",
    "Yes",
    "No",
    // other
    "total"
};

const int ping_time = 90;
const int ping_fadeout_time = 10;

class Ping {
	Vec2f pos;
	Vec2f screen_pos;
	u8 type;

	u32 end_time;
	u8 fadeout_time;

	string caster;
	u8 team;

	Ping(Vec2f _pos, u8 _type, u32 _end_time, u8 _fadeout_time, string _caster, u8 _team)
	{
		pos = _pos;
		type = _type;
		end_time = getGameTime() + _end_time;
		fadeout_time = _fadeout_time;
		caster = _caster;
		team = _team;

		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
	}

	void render()
	{
		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
		GUI::DrawText("hi amogus :33333", screen_pos, SColor(255,255,255,0));
	}
};