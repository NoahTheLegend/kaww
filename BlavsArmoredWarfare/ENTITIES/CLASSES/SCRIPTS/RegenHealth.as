#define SERVER_ONLY

// regen hp

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
	bool is_vamp;
	CPlayer@ p = this.getPlayer();
	if (p !is null)
	{
		if (getRules().get_string(p.getUsername() + "_perk") == "Bloodthirsty")
		{
			this.server_Heal(XORRandom(16)*0.01f);
			is_vamp = true;
		}
	}

	if (this.getHealth() > this.getInitialHealth() * 0.33f || is_vamp) // regen health when its above 33%
		this.server_Heal(0.05f);
}