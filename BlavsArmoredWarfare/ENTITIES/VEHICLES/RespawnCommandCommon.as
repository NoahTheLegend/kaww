namespace SpawnCmd
{
	enum Cmd
	{
		buildMenu = 1,
		changeClass = 2,
		lockedClass = 3,
	}
}

void write_classchange(CBitStream@ params, u16 callerID, string config)
{
	params.write_u16(callerID);
	params.write_string(config);
}
