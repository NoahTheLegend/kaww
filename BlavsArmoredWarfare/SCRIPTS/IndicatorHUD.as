#include "AllHashCodes.as"

const float timelineHeight = 10.0f;
const float timelineLeftEnd = 0.3f;
const float timelineRightEnd = 0.9f;

void onInit( CRules@ this )
{

}

void onTick( CRules@ this )
{

}

void onRender( CRules@ this )
{
	if (g_videorecording) return;

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;

	s8 teamNum = p.getTeamNum();
	if (teamNum < 0) return; // do not render for spectators for now

	float screenWidth = getScreenWidth();

	float timelineLDist = screenWidth*timelineLeftEnd;
	float timelineRDist = screenWidth*timelineRightEnd;
	float timelineLength = timelineRDist - timelineLDist;

	Vec2f timelineLPos = Vec2f(timelineLDist, timelineHeight);
	Vec2f timelineRPos = Vec2f(timelineRDist, timelineHeight);

	//draw flags
	GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineLPos, 1.0f, 0);
	GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineRPos, 1.0f, 1);

	CMap@ map = getMap();
	if (map == null) return;

	float mapWidth = map.tilemapwidth * 8.0f;

	int playerCount = getPlayerCount();
	for (uint i = 0; i < playerCount; i++) // walking blobs
	{
		CPlayer@ curPlayer = getPlayer(i);
		if (curPlayer == null) continue;

		CBlob@ curBlob = curPlayer.getBlob();
		if (curBlob == null) continue;

		s8 curTeamNum = curPlayer.getTeamNum();
		if (curTeamNum != teamNum) continue; // not in my team? do not show

		u8 frame = 0;
		if (curPlayer !is p) frame = getIndicatorFrame(curBlob.getName().getHash());

		float curBlobXPos = curBlob.getPosition().x;
		float indicatorProgress = curBlobXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

		GUI::DrawIcon("indicator_sheet_small.png", frame, Vec2f(16, 25), indicatorPos);
	}

	// indicate vehicles
	
	CBlob@[] vehicleList;
	getBlobsByTag("vehicle", @vehicleList);

	int vehicleCount = vehicleList.length;
	//print ("count: "+ vehicleCount);
	
	for (uint i = 0; i < vehicleCount; i++)
	{
		CBlob@ curVehicle = vehicleList[i];
		if (curVehicle == null) continue;

		s8 vehicleTeamnum = curVehicle.getTeamNum();
		if (vehicleTeamnum < 0 || vehicleTeamnum != teamNum) continue;

		u8 frame = getIndicatorFrame(curVehicle.getName().getHash());
		if (frame == 0) continue;

		float curVehicleXPos = curVehicle.getPosition().x;
		float indicatorProgress = curVehicleXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

		GUI::DrawIcon("indicator_sheet.png", frame, Vec2f(16, 25), indicatorPos, 1.0f, vehicleTeamnum);
	}
}

u8 getIndicatorFrame( int hash )
{
	u8 frame = 0;
	switch(hash)
	{
		case _slave:
		case _t10:
		case _m60:
		frame = 1;
		break;

		case _revolver:
		case _techtruck:
		frame = 2;
		break;

		case _ranger:
		case _pszh4:
		case _civcar:
		case _transporttruck:
		case _uh1:
		frame = 3;
		break;

		case _shotgun:
		case _maus:
		frame = 4;
		break;

		case _sniper: frame = 5;
		break;

		case _antitank: frame = 6;
		break;

		case _mp5: frame = 7;
		break;
	}

	return frame;
}