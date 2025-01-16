#define SERVER_ONLY

#include "PerksCommon.as";

// regen hp

const string max_prop = "regen maximum";
const string rate_prop = "regen rate";

void onInit(CBlob@ this)
{
	if (!this.exists(max_prop))
		this.set_f32(max_prop, this.getInitialHealth());
	
	this.set_u8("step", 0);
	this.set_u8("step_max", 9); // 5 * 9 = 45, old tickfrequency
	this.set_u32("regen", 0);

	this.getCurrentScript().tickFrequency = 5;
}

void onTick(CBlob@ this)
{
	bool do_regen = this.get_u32("regen") > getGameTime();
	this.add_u8("step", 1);

	f32 amount = 0.05f;
	f32 factor = 1.0f;

	if (this.get_u8("step") >= this.get_u8("step_max")
	|| (do_regen && this.get_u8("step") >= this.get_u8("step_max_temp")))
	{
		this.set_u8("step", 0);

		bool stats_loaded = false;
		PerkStats@ stats;

		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			if (p.get("PerkStats", @stats) && stats !is null)
				stats_loaded = true;

			if (stats_loaded)
			{
				amount = stats.regen_amount;
				factor *= stats.heal_factor;
			}
		}

		bool federation_power = getRules().get_bool("enable_powers") && this.getTeamNum() == 1;
		f32 power_factor = federation_power ? 1.1f : 1.0f;

		factor *= power_factor;

		if (this.getHealth() > this.getInitialHealth() * 0.33f || do_regen) // regen health when its above 33%
		{
			this.server_Heal((amount + (do_regen ? this.get_f32("regen_amount") : 0)) * factor);

			if (do_regen && stats_loaded && stats.name == "Lucky")
			{
				if (this.hasBlob("aceofspades", 1)) this.TakeBlob("aceofspades", 1);
				this.set_u32("aceofspades_timer", getGameTime()+stats.aos_healed_time_regen);
			}
		}
	}
}