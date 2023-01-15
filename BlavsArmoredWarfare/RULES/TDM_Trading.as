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
				if (getRules().get_string(killer.getUsername() + "_perk") == "Supply Chain")
				{
					coins *= 2;
				}
				killer.server_setCoins(killer.getCoins() + coins);

				if (getRules().get_string(killer.getUsername() + "_perk") == "Bloodthirsty")
				{
					// if killer is alive
					if (killer.getBlob() !is null)
					{
						killer.getBlob().server_Heal(4.0f);
						//killer.getBlob().server_SetHealth(killer.getBlob().getInitialHealth()); // heal to full hp
					}
				}
			}
		}

		if (getRules().get_string(victim.getUsername() + "_perk") == "Supply Chain")
		{
			victim.server_setCoins(Maths::Ceil(victim.getCoins() / 2)); // lose half of balance
		}
		else
		{
			victim.server_setCoins(victim.getCoins() - 2);
		}
	}
}