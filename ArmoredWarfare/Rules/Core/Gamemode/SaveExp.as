void SaveEXP(CRules@ this)
{
    ConfigFile cfg_playerexp;
    cfg_playerexp.loadFile("../Cache/AW/exp.cfg");
    if (cfg_playerexp is null) return;

	uint16 i;
    for (i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
		if (player !is null)
		{
			if (this.get_u32(player.getUsername() + "_exp") != 0)
			{
				cfg_playerexp.add_u32(player.getUsername(), this.get_u32(player.getUsername() + "_exp"));
			}
		}
    }

	cfg_playerexp.saveFile("AW/exp.cfg");
}