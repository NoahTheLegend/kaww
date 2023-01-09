// Combat builder common

// Script by Blav

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		attack_blob,
		goto_blob,
		find_healing,
		find_drill,
		dodge_spike,
		runaway
	};
};

const f32 SEEK_RANGE = 700.0f;
const f32 ENEMY_RANGE = 400.0f;

// Show emotes?
const bool USE_EMOTES = true;