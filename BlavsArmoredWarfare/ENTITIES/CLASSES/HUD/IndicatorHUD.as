#include "AllHashCodes.as"
#include "TeamColour.as";

const float timelineHeight = 22.0f;
const float timelineLeftEnd = 0.34f;
const float timelineRightEnd = 0.66f;

const float timelineLeftEnd_large = 0.24f;
const float timelineRightEnd_large = 0.76f;

void onRender( CRules@ this )
{
	if (g_videorecording) return;

	s16 blueTickets=0;
	s16 redTickets=0;

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

	if (getBlobByName("pointflag") is null && getBlobByName("importantarmory") is null)
	{
		blueTickets=this.get_s16("blueTickets");
		redTickets=this.get_s16("redTickets");

    	GUI::SetFont("big score font");
		if (blueTickets > 0) GUI::DrawText(""+blueTickets, timelineLPos+Vec2f(-48.0f, 0), getTeamColor(0));
		else GUI::DrawText("--", timelineLPos+Vec2f(-48.0f, 0), getTeamColor(0));
		if (redTickets > 0) GUI::DrawText(""+redTickets, timelineRPos+Vec2f(48.0f, 0), getTeamColor(1));
		else GUI::DrawText("--", timelineRPos+Vec2f(48.0f, 0), getTeamColor(1));
	}

	//draw tents
	//GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineLPos, 1.0f, 0);
	//GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineRPos, 1.0f, 1);

	//draw line	
	if (this.hasTag("animateGameOver"))
    {
        GUI::DrawRectangle(timelineLPos + Vec2f(10, 22), timelineRPos + Vec2f(28, 24), this.getTeamWon() == 0 ? SColor(0xff10abe7) : SColor(0xffd23921));
    }
    else
    {
    	GUI::DrawRectangle(timelineLPos + Vec2f(10, 22), timelineRPos + Vec2f(36, 24), SColor(0x77ffffff));
    }
	/*
	                                //Height map wip
	u8 accuracy = 4; // 8: 1 to 1
//if (!getMap().rayCastSolidNoBlobs(pos, hit_pos))
	//generate rough heightmap
	array<int> heightmap(mapWidth/accuracy);
	for (int x = 0; x*accuracy < mapWidth; x++)
	{
		Vec2f end;
		getMap().rayCastSolidNoBlobs(Vec2f(x*accuracy, 0), Vec2f(x*accuracy, map.tilemapheight * map.tilesize), end);
		heightmap[x] = end.y;
		//heightmap[x] = map.getLandYAtX((x*accuracy) / map.tilesize);
	}
	
	heightmap.removeAt(heightmap.length-1); // remove last point
// goal 445 width
	u8 map_multiplier = mapWidth * 0.00022;
	//map_multiplier = (200 / heightmap.length);
	//print("s " + 200 / x);
	//print("S " + heightmap.length);
	//(mapWidth/1) * 0.00022;
	
	Vec2f map_offset = timelineLPos;
	for (int i = 0; i < heightmap.length; ++i)
	{
		float x1 = i * map_multiplier;
		float x2 = Maths::Min((i+1) * map_multiplier, mapWidth);
		float height1 = heightmap[i] * 0.1;
		float height2 = heightmap[i+1] * 0.1;

		GUI::DrawLine2D(Vec2f(x1, height1) + map_offset,
						Vec2f(x2, height2) + map_offset,
						SColor(0xbbffffff));
	}
	*/

	//indicate objectives
	CBlob@[] objectiveList;
	getBlobsByName("pointflag", @objectiveList);

	int objectiveCount = objectiveList.length;

	CBlob@[] tents;
	getBlobsByName("tent", @tents);
	for (uint i = 0; i < tents.length; i++)
	{
		CBlob@ curBlob = tents[i];
		if (curBlob is null) continue;

		float curBlobXPos = curBlob.getPosition().x - 28;
		float curBlobYPos = curBlob.getPosition().y;
		float indicatorProgress = curBlobXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		float verticalDeviation = curBlobYPos; // blav's soon(tm) heightmap <------
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

		GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), indicatorPos, 1.0f, curBlob.getTeamNum());
	}
	
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

		float flag_height = -8;

		if (team_state == 2)
    	{
    		f32 wave = Maths::Sin(getGameTime() / 3.0f) * 5.0f - 25.0f;
    		GUI::DrawIcon("KAWWGui.png", 1, Vec2f(16,32), indicatorPos + Vec2f(-2, flag_height + 64 + wave), 1.0f, team_num);
    	}
		GUI::DrawIcon("KAWWGui.png", 0, Vec2f(16,32), indicatorPos + Vec2f(-4, flag_height), 1.0f, team_num);

		RenderBar(this, point, indicatorPos + Vec2f(-4, flag_height));
	}

	//if (!v_fastrender)
	{
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
		Vec2f custom_offset = Vec2f(0,8);
		if (frame == 10 || frame == 11) custom_offset = Vec2f(0, -48);
		else if (frame == 12) custom_offset = Vec2f(0, 24);

		GUI::DrawIcon("indicator_sheet.png", frame, Vec2f(16, 25), indicatorPos + custom_offset, 1.0f, vehicleTeamnum);
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
		case _civcar:
		frame = 2; break;

		case _ranger:
		case _btr82a:
		case _bradley:
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
		case _importantarmory:
		frame = 6; break;

		case _mp5:
		case _pszh4:
		frame = 7; break;

		case _motorcycle:
		frame = 8; break;
		
		case _bf109:
		case _bomberplane:
		frame = 11; break;

		case _barge:
		frame = 12; break;

		case _techbigtruck:
		frame = 13; break;

		case _artillery:
		frame = 14; break; 

		case _uh1:
		frame = 10; break;

		case _outpost:
		frame = 9; break;
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

void RenderBar(CRules@ this, CBlob@ flag, Vec2f position)
{
	if (flag is null) return;

	u16 returncount = flag.get_u16("capture time");
	if (returncount == 0) return;

	GUI::SetFont("menu");

	// adjust vertical offset depending on zoom
	Vec2f pos2d = position;
	
	f32 wave = Maths::Sin(getGameTime() / 5.0f) * 5.0f - 25.0f;

	Vec2f pos = pos2d + Vec2f(18.0f, 80.0f);
	Vec2f dimension = Vec2f(45.0f - 8.0f, 12.0f);
	const f32 y = 0.0f;
	
	f32 percentage = 1.0f - float(returncount) / float(flag.getTeamNum() == 255 ? 3000 : 3000);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	const f32 perc  = float(returncount) / float(flag.getTeamNum() == 255 ? 3000/2 : 3000);

	SColor color_light;
	SColor color_mid;
	SColor color_dark;

	SColor color_team;

	if (flag.getTeamNum() == 1 && returncount > 0 || flag.getTeamNum() == 0 && returncount == 0 || flag.getTeamNum() == 255 && flag.get_s8("teamcapping") == 0)
	{
		color_light = 0xff2cafde;
		color_mid	= 0xff1d85ab; //  0xff1d85ab
		color_dark	= 0xff1a4e83;
	}
	
	if (flag.getTeamNum() == 0 && returncount > 0 || flag.getTeamNum() == 1 && returncount == 0 || flag.getTeamNum() == 255 && flag.get_s8("teamcapping") == 1)
	{
		color_light = 0xffd5543f;
		color_mid	= 0xffb73333; // 0xffb73333
		color_dark	= 0xff941b1b;
	}

	if (flag.getTeamNum() == 0)
	{
		color_team = 0xff2cafde;
	}
	if (flag.getTeamNum() == 1)
	{
		color_team = 0xffd5543f;
	}
	if (flag.getTeamNum() == 255)
	{
		color_team = 0xff1c2525;//ff36373f;
	}

	// Border
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 1,                        pos.y + y - 1),
					   Vec2f(pos.x + dimension.x + 0,                        pos.y + y + dimension.y - 1), SColor(0xb0313131));

	
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 0),
					   Vec2f(pos.x + dimension.x - 1,                        pos.y + y + dimension.y - 2), color_team);


	// whiteness
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 1,                        pos.y + y + 0),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x + 0, pos.y + y + dimension.y - 2), SColor(0xffffffff));
	// growing outline
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 1,                        pos.y + y - 1),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x + 0, pos.y + y + dimension.y - 1), SColor(perc*255, 255, 255, 255));

	// Health meter trim
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 0),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 1, pos.y + y + dimension.y - 2), color_mid);

	// Health meter inside
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 6,                        pos.y + y + 0),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 5, pos.y + y + dimension.y - 3), color_light);

}
