namespace SpawnCmd
{
	enum Cmd
	{
		buildMenu = 1,
		changeClass = 2,
		lockedItem = 3,
		buildPerkMenu = 4,
		changePerk = 5,
	}
}

void write_classchange(CBitStream@ params, u16 callerID, string config)
{
	params.write_u16(callerID);
	params.write_string(config);
}

void write_perkchange(CBitStream@ params, u16 callerID, u8 num, string config)
{
	params.write_u16(callerID);
	params.write_u8(num);
	params.write_string(config);
}
