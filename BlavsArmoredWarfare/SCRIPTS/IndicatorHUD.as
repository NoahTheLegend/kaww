#include "AllHashCodes.as"

const float timelineHeight = 10.0f;
const float timelineLeftEnd = 0.3f;
const float timelineRightEnd = 0.9f;

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
	GUI::DrawIcon("indicator_sheet.png", 12, Vec2f(16, 25), timelineLPos, 1.0f, 0);
	GUI::DrawIcon("indicator_sheet.png", 12, Vec2f(16, 25), timelineRPos, 1.0f, 1);

	CMap@ map = getMap();
	if (map == null) return;

	float mapWidth = map.tilemapwidth * 8.0f;

	int playerCount = getPlayerCount();
	for (uint i = 0; i < playerCount; i++)
	{
		CPlayer@ curPlayer = getPlayer(i);
		if (curPlayer == null) continue;

		CBlob@ curBlob = curPlayer.getBlob();
		if (curBlob == null) continue;

		s8 curTeamNum = curPlayer.getTeamNum();
		u8 frame = 0;

		if (curTeamNum != teamNum) continue; // not in my team? do not show

		if (curPlayer is p)
		{
			frame = 11;
		}
		else
		{
			frame = getIndicatorFrame(curBlob.getName().getHash());
		}

		float curBlobXPos = curBlob.getPosition().x;
		float indicatorProgress = curBlobXPos / mapWidth;
		float indicatorDist = indicatorProgress * timelineLength;
		indicatorDist += timelineLDist;
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

		GUI::DrawIcon("indicator_sheet.png", frame, Vec2f(16, 25), indicatorPos);
	}
}

u8 getIndicatorFrame( int hash )
{
	u8 frame = 0;
	switch(hash)
	{
		case _slave: frame = 8;
		break;

		case _revolver: frame = 7;
		break;

		case _ranger: frame = 9;
		break;

		case _shotgun: frame = 5;
		break;

		case _sniper: frame = 6;
		break;

		case _antitank: frame = 10;
		break;

		case _mp5: frame = 4;
		break;
	}

	return frame;
}