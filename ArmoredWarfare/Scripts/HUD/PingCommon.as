
const SColor[] PingColors = {
	SColor(255,25,255,50),
	SColor(255,55,95,225),
	SColor(255,225,185,15),
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

enum PingList {
	// movement
	attention = 0,
	goto,
	danger,
	// tactic
	retreat,
	attack,
	hold,
	// action
	take,
	capture,
	leave,
	// enemy
	incoming,
	chase,
	fireat,
	// alert
	what,
	yes,
	no,
	ammo,
	// other
	total
};

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
		end_time = _end_time;
		fadeout_time = _fadeout_time;
		caster = _caster;
		team = _team;

		screen_pos = getDriver().getScreenPosFromWorldPos(pos);
	}

	void render()
	{
		GUI::DrawText("hi amogus :33333", screen_pos, SColor(255,255,255,0));
	}
};