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
				killer.server_setCoins(killer.getCoins() + 1);
			}
		}

		victim.server_setCoins(victim.getCoins() - 1);
	}
}