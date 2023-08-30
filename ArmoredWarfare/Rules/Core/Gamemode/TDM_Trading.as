#define SERVER_ONLY

#include "PerksCommon.as";

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
				if (hasPerk(killer, Perks::wealthy))
				{
					coins = 6;
				}
				killer.server_setCoins(killer.getCoins() + coins);

				if (hasPerk(killer, Perks::bloodthirsty))
				{
					// if killer is alive
					if (killer.getBlob() !is null)
					{
						killer.getBlob().server_Heal(2.0f);
						//killer.getBlob().server_SetHealth(killer.getBlob().getInitialHealth()); // heal to full hp
					}
				}
			}
		}

		if (hasPerk(victim, Perks::wealthy))
		{
			victim.server_setCoins(Maths::Ceil(victim.getCoins() * 0.66f)); 
		}
		else
		{
			victim.server_setCoins(victim.getCoins() - 2);
		}

		if (killer !is null && killer.getBlob() !is null && hasPerk(killer, Perks::bull))
		{
			killer.getBlob().set_u32("bull_boost", getGameTime()+150);
			killer.getBlob().Sync("bull_boost", true);
		}
	}
}