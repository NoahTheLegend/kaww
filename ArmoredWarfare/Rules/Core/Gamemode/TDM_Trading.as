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
				bool stats_loaded = false;
				PerkStats@ stats;
				if (killer.get("PerkStats", @stats) && stats !is null)
					stats_loaded = true;

				int coins = 2;
				if (stats_loaded)
				{
					coins = stats.kill_coins;
				}
				killer.server_setCoins(killer.getCoins() + coins);

				if (stats_loaded && stats.id == Perks::bloodthirsty)
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

		PerkStats@ vstats;
		if (victim.get("PerkStats", @vstats) && vstats !is null)
		{
			if (vstats.id == Perks::wealthy) victim.server_setCoins(Maths::Ceil(victim.getCoins() * 0.66f));
			else victim.server_setCoins(victim.getCoins() - 2);
		}

		PerkStats@ kstats;
		if (killer !is null && killer.getBlob() !is null && killer.get("PerkStats", @kstats) && kstats.id == Perks::bull)
		{
			killer.getBlob().set_u32("bull_boost", getGameTime()+kstats.kill_bonus_time);
			killer.getBlob().Sync("bull_boost", true);
		}
	}
}