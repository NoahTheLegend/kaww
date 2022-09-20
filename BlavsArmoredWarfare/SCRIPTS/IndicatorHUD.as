#include "AllHashCodes.as"

const float timelineHeight = 6.0f;
const float timelineLeftEnd = 0.34f;
const float timelineRightEnd = 0.66f;

const float timelineLeftEnd_large = 0.24f;
const float timelineRightEnd_large = 0.76f;

void onRender( CRules@ this )
{
	if (g_videorecording) return;

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;

	s8 teamNum = p.getTeamNum();
	bool isSpectator = teamNum < 0;

	float screenWidth = getScreenWidth();

	CMap@ map = getMap();
	if (map == null) return;

	float mapWidth = map.tilemapwidth * 8.0f;
	float mapHeight = map.tilemapheight * 8.0f;

	float timelineLDist = screenWidth*(mapWidth > 1600 ? timelineLeftEnd_large : timelineLeftEnd);
	float timelineRDist = screenWidth*(mapWidth > 1600 ? timelineRightEnd_large : timelineRightEnd);
	float timelineLength = timelineRDist - timelineLDist;

	Vec2f timelineLPos = Vec2f(timelineLDist - 16, timelineHeight);
	Vec2f timelineRPos = Vec2f(timelineRDist - 16, timelineHeight);

	//draw tents
	GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineLPos, 1.0f, 0);
	GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineRPos, 1.0f, 1);

	//draw line	
	if (this.hasTag("animateGameOver"))
    {
        GUI::DrawRectangle(timelineLPos + Vec2f(10, 22), timelineRPos + Vec2f(24, 24), this.getTeamWon() == 0 ? SColor(0xff10abe7) : SColor(0xffd23921));
    }
    else
    {
    	GUI::DrawRectangle(timelineLPos + Vec2f(10, 22), timelineRPos + Vec2f(24, 24), SColor(0xbbffffff));
    }

	/*                                Height map wip
	u8 accuracy = 8; // 8: 1 to 1

	//generate rough heightmap
	array<int> heightmap(mapWidth/accuracy);
	for (int x = 0; x*accuracy < mapWidth; ++x)
	{
		heightmap[x] = map.getLandYAtX((x*accuracy) / map.tilesize);
	}
	heightmap.removeAt(heightmap.length-1); // remove last point

	u8 map_multiplier = (mapWidth/1) * 0.0037;

	Vec2f map_offset = timelineLPos;
	for (int i = 0; i < heightmap.length; ++i)
	{
		float x1 = i * map_multiplier;
		float x2 = Maths::Min((i+1) * map_multiplier, mapWidth);
		float height1 = heightmap[i] * 1;
		float height2 = heightmap[i+1] * 1;

		GUI::DrawLine2D(Vec2f(x1, height1) + map_offset,
						Vec2f(x2, height2) + map_offset,
						SColor(0xbbffffff));
	}*/

	//indicate objectives
	CBlob@[] objectiveList;
	getBlobsByName("pointflag", @objectiveList);

	int objectiveCount = objectiveList.length;
	
	for (uint i = 0; i < objectiveCount; i++)
	{
		CBlob@ point = objectiveList[i];
		if (point == null) continue;

		float curPointXPos = point.getPosition().x - 28;
		float indicatorProgress = curPointXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

		u8 icon_idx;
        u8 team_num = point.getTeamNum();
        u8 team_state = team_num; // team index | 255 neutral | 2 capping

        if (point.get_s8("teamcapping") != -1
        && point.get_s8("teamcapping") != team_num)
        {
            team_state = 2; // alert!!!
        }

		u8 bigger = 0;
		for (u8 j = 0; j < objectiveList.length; j++) // set offset from left depending on x coordinate
		{
			if (objectiveList[j] !is null)
			{
				if (point.getPosition().x > objectiveList[j].getPosition().x) bigger++;
			}
		}

		float flag_height = -6;

		if (team_state == 2)
    	{
    		f32 wave = Maths::Sin(getGameTime() / 3.0f) * 5.0f - 25.0f;
    		GUI::DrawIcon("KAWWGui.png", 1, Vec2f(16,32), indicatorPos + Vec2f(-2, flag_height + 64 + wave), 1.0f, team_num);
    	}
		GUI::DrawIcon("KAWWGui.png", 0, Vec2f(16,32), indicatorPos + Vec2f(-4, flag_height), 1.0f, team_num);
	}


	int playerCount = getPlayerCount();
	for (uint i = 0; i < playerCount; i++) // walking blobs
	{
		CPlayer@ curPlayer = getPlayer(i);
		if (curPlayer == null) continue;

		CBlob@ curBlob = curPlayer.getBlob();
		if (curBlob == null) continue;

		s8 curTeamNum = curPlayer.getTeamNum();
		if (!isSpectator && curTeamNum != teamNum) continue; // do not show enemy players unless spectator

		u8 frame = 0;
		if (curPlayer !is p) frame = getIndicatorFrame(curBlob.getName().getHash());

		float curBlobXPos = curBlob.getPosition().x - 28;
		float curBlobYPos = curBlob.getPosition().y;
		float indicatorProgress = curBlobXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		float verticalDeviation = curBlobYPos; // blav's soon(tm) heightmap <------
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

		GUI::DrawIcon("indicator_sheet_small.png", frame, Vec2f(16, 25), indicatorPos, 1.0f, curTeamNum);
	}

	//indicate vehicles
	CBlob@[] vehicleList;
	getBlobsByTag("vehicle", @vehicleList);

	int vehicleCount = vehicleList.length;
	//print ("count: "+ vehicleCount);
	
	for (uint i = 0; i < vehicleCount; i++)
	{
		CBlob@ curVehicle = vehicleList[i];
		if (curVehicle == null) continue;

		s8 vehicleTeamnum = curVehicle.getTeamNum();
		if (vehicleTeamnum < 0) continue; // do not show neutral vehicles, it crashes due to negative coloring

		if (!isSpectator && vehicleTeamnum != teamNum) continue; // do not show enemy vehicles unless spectator

		u8 frame = getIndicatorFrame(curVehicle.getName().getHash());
		if (frame == 0) continue;

		float curVehicleXPos = curVehicle.getPosition().x - 28;
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
		case _m60:
		frame = 1; break;

		case _revolver:
		case _techtruck:
		frame = 2; break;

		case _ranger:
		case _btr82a:
		frame = 3; break;

		case _shotgun:
		case _maus:
		frame = 4; break;

		case _sniper:
		case _t10:
		frame = 5; break;

		case _antitank:
		case _transporttruck:
		case _armory:
		frame = 6; break;

		case _mp5:
		case _pszh4:
		case _civcar:
		frame = 7; break;

		case _motorcycle:
		frame = 8; break;
	}

	return frame;
}

void onRestart(CRules@ this)
{
    this.Untag("animateGameOver");
}

void onStateChange(CRules@ this, const u8 oldState)
{
    if (this.isGameOver() && this.getTeamWon() >= 0)
    {
        this.Tag("animateGameOver");
        this.minimap = false;
    }
}

