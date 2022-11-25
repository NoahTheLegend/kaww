#define SERVER_ONLY

// regen hp back to

const string max_prop = "regen maximum";
const string rate_prop = "regen rate";

void onInit(CBlob@ this)
{
	if (!this.exists(max_prop))
		this.set_f32(max_prop, this.getInitialHealth());

	this.getCurrentScript().tickFrequency = 45;
}

void onTick(CBlob@ this)
{
	if (this.getHealth() > this.getInitialHealth() * 0.33f) // regen health when its above 33%
		this.server_Heal(0.05f);
}