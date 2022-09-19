//Missile Include

const string targetNetIDString = "target_net_ID";
const string hasTargetTicksString = "has_target_ticks";

const string has_ordinance_update_ID = "has_ordinance_update";
const string homing_target_update_ID = "homing_target_update";

const string lastAbsoluteVelString = "last_absoulte_vel";

const string quickHomingTag = "quick_homing";

namespace JavelinParams
{
	// movement general
	const ::f32 main_engine_force = 0.35f;
	const ::f32 secondary_engine_force = 0.18f;
	const ::f32 rcs_force = 0.15f;
	const ::f32 turn_speed = 14.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 max_speed = 16.0f; // 0 = infinite speed

	//targeting
	const ::u32 lose_target_ticks = 90; //ticks until targetblob is null again
}

class MissileInfo
{
	// movement general
	f32 main_engine_force;
	f32 secondary_engine_force;
	f32 rcs_force;
	f32 turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	f32 max_speed; // 0 = infinite speed

	//targeting
	u32 lose_target_ticks; //ticks until targetblob is null again

	MissileInfo()
	{
		//movement general
		main_engine_force = 3.0f;
		secondary_engine_force = 2.0f;
		rcs_force = 1.0f;
		turn_speed = 1.0f;
		max_speed = 200.0f;

		//targeting
		lose_target_ticks = 30;
	}
};