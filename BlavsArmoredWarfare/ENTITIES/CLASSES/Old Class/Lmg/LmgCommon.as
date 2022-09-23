//Crewman Include

namespace ArcherParams
{
	enum Aim
	{
		not_aiming = 0,
		readying,
		charging,
		fired,
		no_arrows,
		stabbing,
		legolas_ready,
		legolas_charging
	}

	const ::s32 ready_time = 11;

	const ::s32 shoot_period = 30;
	const ::s32 shoot_period_1 = ArcherParams::shoot_period / 3;
	const ::s32 shoot_period_2 = 2 * ArcherParams::shoot_period / 3;
	const ::s32 legolas_period = ArcherParams::shoot_period * 3;

	const ::s32 fired_time = 7;
	const ::f32 shoot_max_vel = 17.59f;

	const ::s32 legolas_charge_time = 5;
	const ::s32 legolas_arrows_count = 1;
	const ::s32 legolas_arrows_volley = 3;
	const ::s32 legolas_arrows_deviation = 5;
	const ::s32 legolas_time = 60;
}

//TODO: move vars into archer params namespace
const f32 archer_grapple_length = 72.0f;
const f32 archer_grapple_slack = 16.0f;
const f32 archer_grapple_throw_speed = 20.0f;

const f32 archer_grapple_force = 2.0f;
const f32 archer_grapple_accel_limit = 1.5f;
const f32 archer_grapple_stiffness = 0.1f;



class ArcherInfo
{
	s8 charge_time;
	u8 charge_state;
	bool has_arrow;
	u8 stab_delay;
	u8 fletch_cooldown;
	u8 arrow_type;

	u8 legolas_arrows;
	u8 legolas_time;
	bool isStabbing;
	
	bool grappling;
	u16 grapple_id;
	f32 grapple_ratio;
	f32 cache_angle;
	Vec2f grapple_pos;
	Vec2f grapple_vel;

	ArcherInfo()
	{
		charge_time = 0;
		charge_state = 0;
		has_arrow = false;
		stab_delay = 0;
		fletch_cooldown = 0;
		arrow_type = ArrowType::normal;
	}
};

const string[] arrowTypeNames = { "mat_7mmround" };

const string[] arrowNames = { "7.62mm rounds", };

const string[] arrowIcons = { "$Arrow$", };

bool hasArrows(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return false;
	}
	if (archer.arrow_type >= 0 && archer.arrow_type < arrowTypeNames.length)
	{
		return this.getBlobCount(arrowTypeNames[archer.arrow_type]) > 0;
	}
	return false;
}

bool hasArrows(CBlob@ this, u8 arrowType)
{
	return this.getBlobCount(arrowTypeNames[arrowType]) > 0;
}

bool hasAnyArrows(CBlob@ this)
{
	for (uint i = 0; i < ArrowType::count; i++)
	{
		if (hasArrows(this, i))
		{
			return true;
		}
	}
	return false;
}

void SetArrowType(CBlob@ this, const u8 type)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}
	archer.arrow_type = type;
}

u8 getArrowType(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return 0;
	}
	return archer.arrow_type;
}
