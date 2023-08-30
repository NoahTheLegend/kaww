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
	bool has_regen = this.get_u32("regen") > getGameTime();
	this.add_u8("step", 1);

	if (this.get_u8("step") >= this.get_u8("step_max")
	|| (has_regen && this.get_u8("step") >= this.get_u8("step_max_temp")))
	{
		this.set_u8("step", 0);

		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			if (hasPerk(p, Perks::bloodthirsty))
			{
				return;
			}
		}

		if (this.getHealth() > this.getInitialHealth() * 0.33f || has_regen) // regen health when its above 33%
			this.server_Heal(0.05f + (has_regen ? this.get_f32("regen_amount") : 0));
	}
}