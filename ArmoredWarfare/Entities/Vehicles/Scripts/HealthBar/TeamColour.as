#include "TeamColorCollections.as";

SColor getTeamColor(int team)
{
	SColor teamCol; //get the team colour of the attacker

	switch (team)
	{
		case 0: teamCol = getNeonColor(0, 0); break;

		case 1: teamCol = getNeonColor(1, 0); break;

		case 2: teamCol = getNeonColor(2, 0); break;

		case 3: teamCol = getNeonColor(3, 0); break;

		case 4: teamCol = getNeonColor(4, 0); break;

		case 5: teamCol = getNeonColor(5, 0); break;

		case 6: teamCol = getNeonColor(6, 0); break;

		case 7: teamCol.set(0xffc4cfa1); break;

		default: teamCol.set(0xff888888);
	}
	return teamCol;
}
