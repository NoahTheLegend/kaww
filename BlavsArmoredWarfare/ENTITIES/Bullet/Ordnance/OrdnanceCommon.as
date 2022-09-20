//Missile Include

const string launchOrdnanceIDString = "launch_ordnance";
const string launcherDeathIDString = "launcher_die";
const string launcherUpdateStateIDString = "launcher_state_sync";
const string quickHomingTag = "quick_homing";

namespace JavelinParams
{
	// movement general
	const ::f32 main_engine_force = 0.5f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.1f;
	const ::f32 turn_speed = 10.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 max_speed = 10.0f; // 0 = infinite speed

	// factors
	const ::f32 gravity_scale = 0.6f;

	//targeting
	const ::u32 lose_target_ticks = 90; //ticks until targetblob is null again
}

namespace GutseekerParams
{
	// movement general
	const ::f32 main_engine_force = 0.7f;
	const ::f32 max_speed = 15.0f; // 0 = infinite speed
	const ::f32 turn_speed = 20.0f; // degrees per tick, 0 = instant (30 ticks a second)

	// factors
	const ::f32 gravity_scale = 0.6f;
}

class MissileInfo
{
	// movement general
	f32 main_engine_force;
	f32 secondary_engine_force;
	f32 rcs_force;
	f32 turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	f32 max_speed; // 0 = infinite speed

	// factors
	f32 gravity_scale;

	//targeting
	u32 lose_target_ticks; //ticks until targetblob is null again
	u16[] target_netid_list; // NetID array

	MissileInfo()
	{
		//movement general
		main_engine_force = 3.0f;
		secondary_engine_force = 2.0f;
		rcs_force = 1.0f;
		turn_speed = 1.0f;
		max_speed = 200.0f;

		// factors
		gravity_scale = 1.0f;

		//targeting
		lose_target_ticks = 30;
	}
};

shared class LauncherInfo
{
	float progress_speed;

	u16[] found_targets_id; // NetID array

	LauncherInfo()
	{
		progress_speed = 0.1f;
	}
};

void launcherDie( CBlob@ this )
{
	this.SendCommand(this.getCommandID(launcherDeathIDString));
}