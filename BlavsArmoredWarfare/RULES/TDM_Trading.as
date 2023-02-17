#define SERVER_ONLY

string cost_config_file = "tdm_vars.cfg";

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null)
	{
		if (killer !is null)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				int coins = 2;
				if (getRules().get_string(killer.getUsername() + "_perk") == "Wealthy")
				{
					coins = 6;
				}
				killer.server_setCoins(killer.getCoins() + coins);

				if (getRules().get_string(killer.getUsername() + "_perk") == "Bloodthirsty")
				{
					// if killer is alive
					if (killer.getBlob() !is null)
					{
						killer.getBlob().server_Heal(3.0f);
						//killer.getBlob().server_SetHealth(killer.getBlob().getInitialHealth()); // heal to full hp
					}
				}
			}
		}

		if (getRules().get_string(victim.getUsername() + "_perk") == "Wealthy")
		{
			victim.server_setCoins(Maths::Ceil(victim.getCoins() * 0.75f)); 
		}
		else
		{
			victim.server_setCoins(victim.getCoins() - 2);
		}

		if (killer !is null && killer.getBlob() !is null && getRules().get_string(killer.getUsername() + "_perk") == "Bull")
		{
			killer.getBlob().set_u32("bull_boost", getGameTime()+150);
		}
	}
}