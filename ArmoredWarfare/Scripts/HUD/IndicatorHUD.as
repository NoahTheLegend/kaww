#include "AllHashCodes.as"
#include "TeamColour.as";
#include "TeamColorCollections.as";

const float timelineHeight = 22.0f;
const float timelineLeftEnd = 0.34f;
const float timelineRightEnd = 0.66f;

const float timelineLeftEnd_large = 0.24f;
const float timelineRightEnd_large = 0.76f;

int timeout = 900; // 15 seconds timeout for spectator indicator (render is called 60 times a second + staging may have more)
// dont remove timeout stuff, otherwise game will crash after map compiles

void onRender( CRules@ this )
{
	if (g_videorecording) return;

	s16 teamLeftTickets=0;
	s16 teamRightTickets=0;

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;
	CBlob@ local = p.getBlob();

	s8 teamNum = p.getTeamNum();
	bool isSpectator = teamNum < 0;

	float screenWidth = getScreenWidth();

	CMap@ map = getMap();
	if (map == null) return;

	float mapWidth = map.tilemapwidth * 8.0f;
	float mapHeight = map.tilemapheight * 8.0f;

	float timelineLDist = screenWidth*(mapWidth > 2400 ? timelineLeftEnd_large : timelineLeftEnd) - 16;
	float timelineRDist = screenWidth*(mapWidth > 2400 ? timelineRightEnd_large : timelineRightEnd);
	float timelineLength = timelineRDist - timelineLDist;

	Vec2f timelineLPos = Vec2f(timelineLDist - 16, timelineHeight);
	Vec2f timelineRPos = Vec2f(timelineRDist - 16, timelineHeight);

	bool hide_indicator = !v_showminimap && local !is null && !local.isKeyPressed(key_map) || (local is null && !v_showminimap);
	bool isCTF = getBlobByName("pointflag") !is null || getBlobByName("pointflagt2") !is null;
	bool isDTT = getBlobByName("importantarmory") !is null || getBlobByName("importantarmoryt2") !is null;
	
	if (!isCTF
		&& !isDTT)
	{
		u16 teamLeftKills = this.get_u16("teamleft_kills");
		u16 teamRightKills = this.get_u16("teamright_kills");

		GUI::SetFont("menu");
		GUI::DrawTextCentered(""+teamRightKills, timelineLPos+Vec2f(-78.0f, 35), getNeonColor(7, 0));
		GUI::DrawTextCentered(""+teamLeftKills, timelineRPos+Vec2f(122.0f, 35), getNeonColor(7, 0));
		GUI::DrawIcon("DeathIncarnate.png", 0, Vec2f(16,16), timelineLPos+Vec2f(-115.0f, 21), 0.85f, 0);
		GUI::DrawIcon("DeathIncarnate.png", 0, Vec2f(16,16), timelineRPos+Vec2f(135.0f, 21), 0.85f, 0);

		teamLeftTickets=this.get_s16("teamLeftTickets");
		teamRightTickets=this.get_s16("teamRightTickets");

    	GUI::SetFont("big score font");
		u8 teamleft = this.get_u8("teamleft");
		u8 teamright = this.get_u8("teamright");
		//if (getGameTime()%30==0)  printf("GETTING TEAMS: "+teamleft+" ||| "+teamright);
		//if (getGameTime()%30==0) printf(""+(getNeonColor(teamleft, 0).getRed())+" "+(getNeonColor(teamleft, 0).getGreen())+" "+(getNeonColor(teamleft, 0).getBlue()));
		if (teamLeftTickets > 0) GUI::DrawText(""+teamLeftTickets, timelineLPos+Vec2f(-48.0f, 0), getNeonColor(teamleft, 0));
		else GUI::DrawTextCentered("--", timelineLPos+Vec2f(-48.0f, 0), getNeonColor(teamleft, 0));
		if (teamRightTickets > 0) GUI::DrawText(""+teamRightTickets, timelineRPos+Vec2f(48.0f, 0), getNeonColor(teamright, 0));
		else GUI::DrawTextCentered("--", timelineRPos+Vec2f(48.0f, 0), getNeonColor(teamright, 0));

		s16 ldiff = teamLeftTickets-teamRightTickets;
		s16 rdiff = teamRightTickets-teamLeftTickets;

		Vec2f diff_offset = Vec2f(ldiff > rdiff ? -48 : 48, hide_indicator ? 40 : 125);
		if (getGameTime() > 450) GUI::DrawTextCentered(ldiff!=rdiff?"-"+Maths::Max(ldiff, rdiff):"||", Vec2f(screenWidth/2-7, diff_offset.y), getNeonColor(ldiff==rdiff?7:ldiff<rdiff?teamleft:teamright, 0));
	}

	f32 points_target = this.get_f32("ctf_points_target");
	if (isCTF && points_target > 0)
	{
		Vec2f gauge_dim = Vec2f(Maths::Min(timelineRDist-timelineLDist, 500), 24);
		Vec2f ctf_pos = Vec2f(screenWidth/2, 125);

		Vec2f ctf_tl = ctf_pos - (gauge_dim/2);
		Vec2f ctf_br = ctf_pos + (gauge_dim/2);

		f32 points_left_target = this.get_f32("ctf_points_left");
		f32 points_left = Maths::Lerp(this.get_f32("ctf_points_left_lerp"), points_left_target, 0.15f);
		this.set_f32("ctf_points_left_lerp", points_left);
		
		f32 points_right = points_target - points_left;

		f32 factor_left = points_left/points_target;
		//factor_left = Maths::Sin(getGameTime()*0.01f)/2+0.5f;
		f32 factor_right = 1.0f-factor_left;

		// bg
		GUI::DrawRectangle(ctf_tl, ctf_br, SColor(0x75000000));

		// draw points
		Vec2f vec_dist_left  = Vec2f(ctf_br.x-gauge_dim.x*factor_right, ctf_br.y);
		Vec2f vec_dist_right = Vec2f(ctf_tl.x+gauge_dim.x*factor_left, ctf_tl.y);

		Vec2f lrect_pos_tl = ctf_tl + Vec2f(0,2);
		Vec2f lrect_pos_br = vec_dist_left - Vec2f(0,2);
		Vec2f rrect_pos_tl = vec_dist_right + Vec2f(0,2);
		Vec2f rrect_pos_br = ctf_br - Vec2f(0,2);
		Vec2f frame_thickness = Vec2f(3,3);
		Vec2f inframe_thickness = Vec2f(0,5);

		SColor col_mid_left   = getNeonColor(teamleft,  1);
		SColor col_mid_right  = getNeonColor(teamright, 1);

		SColor col_dark_left  = getNeonColor(teamleft,  2);
		SColor col_dark_right = getNeonColor(teamright, 2);

		SColor col_pane_left  = getNeonColor(teamleft,  3);
		SColor col_pane_right = getNeonColor(teamright, 3);

		// frame
		GUI::DrawRectangle(lrect_pos_tl, lrect_pos_br, col_dark_left);
		GUI::DrawRectangle(rrect_pos_tl, rrect_pos_br, col_dark_right);
		// inner
		GUI::DrawRectangle(lrect_pos_tl+frame_thickness, lrect_pos_br-frame_thickness, col_pane_left);
		GUI::DrawRectangle(lrect_pos_tl+inframe_thickness, lrect_pos_br-inframe_thickness, col_mid_left);

		GUI::DrawRectangle(rrect_pos_tl+frame_thickness, rrect_pos_br-frame_thickness, col_pane_right);
		GUI::DrawRectangle(rrect_pos_tl+inframe_thickness, rrect_pos_br-inframe_thickness, col_mid_right);

		Vec2f slider_tl = ctf_tl+Vec2f(gauge_dim.x*factor_left-4,0);
		Vec2f slider_br = ctf_br-Vec2f(gauge_dim.x*factor_right-4,0);

		SColor text_col = SColor(0xffcfcd00);
		s8 left = this.get_s8("ctf_dominance");

		if (left != -1)
		{
			// animarrow :D
			// still much less icons than in scoreboard render
			u8 fill = 32;
			f32 fade_dist = 8.0f;

			f32 movedir = -fill;
			u8 arricon = 0;
			Vec2f coeff_tl = ctf_tl;
			Vec2f coeff_br = slider_br;
			f32 arrfactor = factor_left;
			f32 mp = getGameTime()%fill;
			text_col = col_pane_left;

			if (left == 1)
			{
				movedir = fill;
				arricon = 1;
				coeff_tl = slider_tl;
				coeff_br = ctf_br;
				arrfactor = factor_right;
				mp *= -1.0f;
				text_col = col_pane_right;
			}
			
			u8 extra_width = 1;
			Vec2f extra = Vec2f(fill*extra_width, 0);
			
			for (u8 i = 0; i < Maths::Ceil(gauge_dim.x/fill)*arrfactor + extra_width+1; i++)
			{
				// kinda hard to implement a proper fade-in/out, will do someday
				// for now its bound to pos.x and fade edges
				Vec2f arr_pos = coeff_tl - extra + Vec2f(fill*i+mp,4);

				f32 edgemod = 0.0f;
				if (arr_pos.x + 4 > coeff_tl.x) edgemod = (arr_pos.x + 4 - coeff_tl.x)  / fade_dist;
				if (arr_pos.x > coeff_br.x - fade_dist*3) edgemod = (coeff_br.x - fade_dist*2 - arr_pos.x) / fade_dist;
				edgemod = Maths::Clamp(edgemod, 0.0f, 1.0f);
				//SColor arrcol = col_dark_left;
				//arrcol.setAlpha(125*edgemod);

				GUI::DrawIcon("MovingIndicatorArrow.png", arricon, Vec2f(16,16), arr_pos, 0.5f, SColor(125*edgemod,0,0,0));
			}
		}

		// side rivets
		GUI::DrawPane(ctf_tl-Vec2f(4,1), ctf_tl-Vec2f(-4,-gauge_dim.y-1), col_dark_left);
		GUI::DrawPane(ctf_br-Vec2f(4, gauge_dim.y+1),ctf_br-Vec2f(-4,-1), col_dark_right);

		// middle slider
		GUI::DrawPane(slider_tl, slider_br, 0x25000000);

		GUI::SetFont("menu");
		GUI::DrawTextCentered(Maths::Round(points_target*factor_left)+"  ---  "+Maths::Round(points_target*factor_right), slider_tl+Vec2f(1,31), text_col);
	}

	if (hide_indicator) return;

	//draw tents
	//GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineLPos, 1.0f, 0);
	//GUI::DrawIcon("indicator_sheet.png", 0, Vec2f(16, 25), timelineRPos, 1.0f, 1);

	//draw line	
	if (this.hasTag("animateGameOver"))
    {
		CPlayer@ local = getLocalPlayer();

        GUI::DrawRectangle(timelineLPos + Vec2f(10, 22), timelineRPos + Vec2f(28, 24), this.getTeamWon() == local.getTeamNum() ? SColor(0xff33ee33) : SColor(0xffd23921));
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
	getBlobsByTag("pointflag", @objectiveList);

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
        u8 team_state = -1; // team index | 255 neutral | 2 capping

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

			s8 curTeamNum = curPlayer.getTeamNum();
			if (!isSpectator && curTeamNum != teamNum) continue; // do not show enemy players unless spectator

			CBlob@ curBlob = curPlayer.getBlob();
			if (curBlob !is null && !curBlob.hasTag("player")) continue;

			if (curBlob == null)
			{
				if (timeout > 0) timeout--; // otherwise crashes on map compiling
				if (curPlayer is p && getCamera() !is null && timeout <= 0)
				{
					float curBlobXPos = getCamera().getPosition().x;
					float indicatorProgress = curBlobXPos / mapWidth;
					float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
					Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

					GUI::DrawIcon("indicator_sheet_small.png", 0, Vec2f(16, 25), indicatorPos, 1.0f, curTeamNum);
				}
				continue;
			}

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

		if (curVehicle.hasTag("importantarmory")) // importantarmory HP
		{
			RenderHPBar(this, curVehicle, indicatorPos + custom_offset);
		}

		GUI::DrawIcon("indicator_sheet.png", frame, Vec2f(16, 25), indicatorPos + custom_offset, 1.0f, vehicleTeamnum);
	}
}

u8 getIndicatorFrame( int hash )
{
	u8 frame = 0;
	switch(hash)
	{
		case _mechanic:
		case _m60:
		case _bc25t:
		frame = 1; break;

		case _revolver:
		case _shielder:
		case _techtruck:
		case _civcar:
		frame = 2; break;

		case _ranger:
		case _lmg:
		case _btr82a:
		case _bradley:
		frame = 3; break;

		case _shotgun:
		case _firebringer:
		case _maus:
		case _pinkmaus:
		case _desertmaus:
		frame = 4; break;

		case _sniper:
		case _t10:
		frame = 5; break;

		case _rpg:
		case _transporttruck:
		case _armory:
		case _importantarmory:
		case _importantarmoryt2:
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
		case _ah1:
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

void RenderHPBar(CRules@ this, CBlob@ vehicle, Vec2f position)
{
	if (vehicle is null) return;

	f32 returncount = vehicle.getInitialHealth();

	GUI::SetFont("menu");

	// adjust vertical offset depending on zoom
	Vec2f pos2d = position;

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	Vec2f pos = pos2d + Vec2f(15.0f, 58.0f);
	Vec2f dimension = Vec2f(28.0, 12.0f);
	const f32 y = 0.0f;
	
	f32 percentage = 1.0f - returncount / vehicle.getHealth();
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	const f32 perc  = vehicle.getHealth()/returncount;

	SColor color_light;
	SColor color_mid;
	SColor color_dark;

	SColor color_team;

	if (vehicle.getTeamNum() == teamleft && returncount >= 0 || vehicle.getTeamNum() == 255 && vehicle.get_s8("teamcapping") == teamleft)
	{
		color_light = getNeonColor(teamleft, 0);
		color_mid	= getNeonColor(teamleft, 1);
		color_dark	= getNeonColor(teamleft, 2);
	}
	
	if (vehicle.getTeamNum() == teamright && returncount >= 0 || vehicle.getTeamNum() == 255 && vehicle.get_s8("teamcapping") == teamright)
	{
		color_light = getNeonColor(teamright, 0);
		color_mid	= getNeonColor(teamright, 1);
		color_dark	= getNeonColor(teamright, 2);
	}

	if (vehicle.getTeamNum() == teamleft)
	{
		color_team = getNeonColor(teamleft, 0);
	}

	if (vehicle.getTeamNum() == teamright)
	{
		color_team = getNeonColor(teamright, 0);
	}
	if (vehicle.getTeamNum() == 255)
	{
		color_team = 0xff1c2525;//ff36373f;
	}

	// Border
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 1,                        pos.y + y - 1),
					   Vec2f(pos.x + dimension.x + 0,                        pos.y + y + dimension.y - 1), SColor(0xb0313131));

	
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 0),
					   Vec2f(pos.x + dimension.x - 1,                        pos.y + y + dimension.y - 2), color_dark);


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

void RenderBar(CRules@ this, CBlob@ flag, Vec2f position)
{
	if (flag is null) return;

	u16 returncount = flag.get_f32("capture time");
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
	
	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	if (flag.getTeamNum() == teamright && returncount > 0 || flag.getTeamNum() == teamleft && returncount == 0 || flag.getTeamNum() == 255 && flag.get_s8("teamcapping") == teamleft)
	{
		color_light = getNeonColor(teamleft, 0);
		color_mid	= getNeonColor(teamleft, 1);
		color_dark	= getNeonColor(teamleft, 2);
	}
	
	if (flag.getTeamNum() == teamleft && returncount > 0 || flag.getTeamNum() == teamright && returncount == 0 || flag.getTeamNum() == 255 && flag.get_s8("teamcapping") == teamright)
	{
		color_light = getNeonColor(teamright, 0);
		color_mid	= getNeonColor(teamright, 1);
		color_dark	= getNeonColor(teamright, 2);
	}

	if (flag.getTeamNum() == teamleft)
	{
		color_team = getNeonColor(teamleft, 0);
	}
	if (flag.getTeamNum() == teamright)
	{
		color_team = getNeonColor(teamright, 0);
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