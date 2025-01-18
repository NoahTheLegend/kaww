#include "AllHashCodes.as";
#include "TeamColour.as";
#include "TeamColorCollections.as";
#include "PingCommon.as";
#include "GamemodeCheck.as";
#include "ArtilleryMarker.as";

const float timelineHeight = 22.0f;
const float timelineLeftEnd = 0.34f;
const float timelineRightEnd = 0.66f;

const float timelineLeftEnd_large = 0.24f;
const float timelineRightEnd_large = 0.76f;

int timeout = 900; // 15 seconds timeout for spectator indicator (render is called 60 times a second + staging may have more)
// dont remove timeout stuff, otherwise game will crash after map compiles

s8[] player_frames;
s8[] player_teams;
Vec2f[] player_indicator_pos;

s8[] vehicle_frames;
s8[] vehicle_teams;
Vec2f[] vehicle_indicator_pos;
u16[] vehicle_hpbar_ids;

s16 teamLeftTickets = 0;
s16 teamRightTickets = 0;

s8 teamNum = -1;
bool isSpectator = false;

float screenWidth = 1;
float mapWidth = 1;
float mapHeight = 1;
float timelineLDist = 1;
float timelineRDist = 1;
float timelineLength = 1;

bool hide_indicator = true;
bool ctf = false;
bool dtt  = false;
bool ptb = false;

Vec2f timelineLPos = Vec2f(1,1);
Vec2f timelineRPos = Vec2f(1,1);

void onTick(CRules@ this)
{
	if (g_videorecording) return;

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;
	CBlob@ local = p.getBlob();

	Update(p, local);
	ResetArrays();

	handlePlayers(p);
	handleVehicles();

	handleArtilleryExplosions(this);
	//printf(player_frames.size()+" "+player_teams.size()+" "+player_indicator_pos.size()+" "+vehicle_frames.size()+" "+vehicle_teams.size()+" "+vehicle_indicator_pos.size()+" "+vehicle_hpbar_ids.size());
}

void handleVehicles()
{
	//indicate vehicles
	CBlob@[] vehicleList;
	getBlobsByTag("vehicle", @vehicleList);

	int gt = getGameTime();
	int vehicleCount = vehicleList.length;
	for (uint i = 0; i < vehicleCount; i++)
	{
		CBlob@ curVehicle = vehicleList[i];
		if (curVehicle == null) continue;

		s8 vehicleTeamnum = curVehicle.getTeamNum();
		if (vehicleTeamnum < 0) continue; // do not show neutral vehicles, it crashes due to negative coloring
		
		bool our_team = vehicleTeamnum == teamNum;
		bool can_show_enemy_vehicle = curVehicle.exists("radar_mark") && curVehicle.get_u32("radar_mark") > gt;
		if ((!isSpectator && !our_team) && !can_show_enemy_vehicle) continue; // do not show enemy vehicles unless spectator

		u8 frame = getIndicatorFrame(curVehicle.getName().getHash());
		if (frame == 0) continue;

		float curVehicleXPos = curVehicle.getPosition().x - 28;
		float indicatorProgress = curVehicleXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);
		Vec2f custom_offset = Vec2f(0, 20);
		if (frame == 10 || frame == 11 || frame == 15) custom_offset = Vec2f(0, -48);
		else if (frame == 12) custom_offset = Vec2f(0, 34);

		u16 id = 0;
		if (curVehicle.hasTag("importantarmory")) // importantarmory HP
		{
			id = curVehicle.getNetworkID();
		}
		vehicle_hpbar_ids.push_back(id);

		vehicle_frames.push_back(frame);
		vehicle_teams.push_back(vehicleTeamnum);
		vehicle_indicator_pos.push_back(indicatorPos+custom_offset);
	}
}

void Update(CPlayer@ p, CBlob@ local)
{
	teamNum = p.getTeamNum();
	isSpectator = teamNum < 0;

	screenWidth = getScreenWidth();

	CMap@ map = getMap();
	if (map == null) return;

	CRules@ rules = getRules();

	mapWidth = map.tilemapwidth * 8.0f;
	mapHeight = map.tilemapheight * 8.0f;

	timelineLDist = screenWidth*(mapWidth > 2400 ? timelineLeftEnd_large : timelineLeftEnd) - 16;
	timelineRDist = screenWidth*(mapWidth > 2400 ? timelineRightEnd_large : timelineRightEnd);
	timelineLength = timelineRDist - timelineLDist;

	timelineLPos = Vec2f(timelineLDist - 16, timelineHeight);
	timelineRPos = Vec2f(timelineRDist - 16, timelineHeight);

	hide_indicator = !v_showminimap && local !is null && !local.isKeyPressed(key_map) || (local is null && !v_showminimap);
	ctf = isCTF();
	dtt = isDTT();
	ptb = isPTB();
}

void ResetArrays()
{
	player_frames = player_teams = vehicle_frames = vehicle_teams = array<s8>();
	player_indicator_pos = vehicle_indicator_pos = array<Vec2f>();
	vehicle_hpbar_ids = array<u16>();
}

void handlePlayers(CPlayer@ p)
{
	// players
	{
		int playerCount = getPlayerCount();
		for (uint i = 0; i < playerCount; i++)
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
					
					player_frames.push_back(0);
					player_teams.push_back(curTeamNum);
					player_indicator_pos.push_back(indicatorPos);
				}
				continue;
			}

			u8 frame = 0;
			if (curPlayer !is p) frame = getIndicatorFrame(curBlob.getName().getHash());

			float curBlobXPos = curBlob.getPosition().x - 28;
			float curBlobYPos = curBlob.getPosition().y;
			float indicatorProgress = curBlobXPos / Maths::Max(mapWidth, 1);
			float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;

			Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);

			player_frames.push_back(frame);
			player_teams.push_back(curTeamNum);
			player_indicator_pos.push_back(indicatorPos);			
		}
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording) return;

	renderPings(this);
	renderArtilleryExplosions(this);

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;
	CBlob@ local = p.getBlob();

	GUI::SetFont("score-smaller");
	CMap@ map = getMap();
	if (map !is null)
	{
		GUI::DrawTextCentered("" + map.tilemapwidth, Vec2f((timelineLDist + timelineRDist) / 2, timelineHeight - 10), SColor(255, 255, 255, 255));
	}
	
	if (!ctf
		&& !dtt)
	{
		u16 teamLeftKills = this.get_u16("teamleft_kills");
		u16 teamRightKills = this.get_u16("teamright_kills");

		teamLeftTickets=this.get_s16("teamLeftTickets");
		teamRightTickets=this.get_s16("teamRightTickets");

    	GUI::SetFont("score-big");

		u8 teamleft = this.get_u8("teamleft");
		u8 teamright = this.get_u8("teamright");

		//if (getGameTime()%30==0)  printf("GETTING TEAMS: "+teamleft+" ||| "+teamright);
		//if (getGameTime()%30==0) printf(""+(getNeonColor(teamleft, 0).getRed())+" "+(getNeonColor(teamleft, 0).getGreen())+" "+(getNeonColor(teamleft, 0).getBlue()));
		u8 PTBteam = defendersTeamPTB();

		if (PTBteam == 255)
		{
			if (teamLeftTickets > 0) GUI::DrawText(""+teamLeftTickets, timelineLPos+Vec2f(-48.0f, 0), getNeonColor(teamleft, 0));
			else GUI::DrawTextCentered("--", timelineLPos+Vec2f(-48.0f, 0), getNeonColor(teamleft, 0));

			if (teamRightTickets > 0) GUI::DrawText(""+teamRightTickets, timelineRPos+Vec2f(48.0f, 0), getNeonColor(teamright, 0));
			else GUI::DrawTextCentered("--", timelineRPos+Vec2f(48.0f, 0), getNeonColor(teamright, 0));
		}

		s16 ldiff = teamLeftTickets-teamRightTickets;
		s16 rdiff = teamRightTickets-teamLeftTickets;

		Vec2f diff_offset = Vec2f(ldiff > rdiff ? -48 : 48, hide_indicator ? 40 : 125);
		GUI::SetFont("score-medium");
		if (getGameTime() > 450)
		{
			string text;
			SColor textcol;

			if (PTBteam != 255)
			{
				text = "" + (PTBteam == teamleft ? teamRightTickets : teamLeftTickets);
				textcol = getNeonColor(PTBteam == teamleft ? teamright : teamleft, 0);
			}
			else
			{
				text = ldiff!=rdiff?"-"+Maths::Max(ldiff, rdiff):"||";
				textcol = getNeonColor(ldiff==rdiff?7:ldiff<rdiff?teamleft:teamright, 0);
			}
			if (teamLeftTickets == 0 && teamRightTickets == 0)
			{
				text = "Sudden death";
				textcol = SColor(255,255,0,0);
			}

			GUI::DrawTextCentered(text, Vec2f(screenWidth/2-7, diff_offset.y-16), textcol);
		}
	}

	f32 points_target = this.get_f32("ctf_points_target");
	if (ctf && points_target > 0)
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
		GUI::DrawTextCentered(Maths::Round(points_target*factor_left)+"  ---  "+Maths::Round(points_target*factor_right), slider_tl+Vec2f(1,32), text_col);
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

	//indicate respawns
	if (map is null) return;

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

	//indicate objectives
	CBlob@[] objectiveList;
	getBlobsByTag("pointflag", @objectiveList);

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

	uint player_frames_size = player_frames.size();

	if (player_frames_size == player_indicator_pos.size()
		&& player_frames_size == player_teams.size())
	{
		for (uint i = 0; i < player_indicator_pos.size(); i++) // walking blobs
		{
			bool my_player = player_frames[i] == 0;

			GUI::DrawIcon("indicator_sheet_small.png", player_frames[i], Vec2f(16, 25), player_indicator_pos[i], 1.0f, player_teams[i]);
			if (my_player && getLocalPlayerBlob() !is null)
			{
				GUI::SetFont("score-smaller");
				//f32 sc = getDriver().getWorldPosFromScreenPos(getDriver().getScreenCenterPos()).x;
				f32 sc = getLocalPlayerBlob().getPosition().x;
				int tile_dist = sc/8 - map.tilemapwidth/2;

				Vec2f text_pos = player_indicator_pos[i] + Vec2f(12, 34);
				GUI::DrawTextCentered(""+tile_dist+"", text_pos, getNeonColor(player_teams[i], 0));
			}
		}
	}
	
	uint vehicle_frames_size = vehicle_frames.size();

	if (vehicle_frames_size == vehicle_indicator_pos.size()
		&& vehicle_frames_size == vehicle_teams.size()
		&& vehicle_frames_size == vehicle_hpbar_ids.size())
	{
		for (uint i = 0; i < vehicle_frames.size(); i++)
		{
			if (vehicle_hpbar_ids[i] != 0)
			{
				CBlob@ curVehicle = getBlobByNetworkID(vehicle_hpbar_ids[i]);

				if (curVehicle !is null)
				{
					RenderHPBar(this, curVehicle, vehicle_indicator_pos[i]);
				}
			}

			GUI::DrawIcon("indicator_sheet.png", vehicle_frames[i], Vec2f(16, 25), vehicle_indicator_pos[i], 1.0f, vehicle_teams[i]);
		}
	}

	for (u16 i = 0; i < map_pings.size(); i++)
	{
		Ping@ ping = map_pings[i];
		if (ping is null || getGameTime() > ping.end_time)
		{
			map_pings.removeAt(i);
			i--;
			continue;	
		}

		Vec2f custom_offset = Vec2f(-7, 7);
		f32 x_pos = ping.pos.x;
		f32 indicatorProgress = x_pos / mapWidth;
		f32 indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;
		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight) + custom_offset;

		bool e = ((ping.end_time-getGameTime())/10+1)%2==0;

		ping.calculateFade();
		SColor col = getNeonColor(ping.team, 0);
		col.setAlpha(200 * ping.fadeout);
		SColor col_white = SColor(255,255,255,255);
		col_white.setAlpha(200 * ping.fadeout);

		GUI::DrawIcon("PingPointer.png", e?2:3, Vec2f(16,16), indicatorPos+Vec2f(1,0), 1, 1, ping.team, col);
		GUI::DrawRectangle(indicatorPos+Vec2f(16, 24), indicatorPos+Vec2f(17, 24 + 14 * ping.fadeout), col_white);

		CControls@ controls = getControls();
		
		Vec2f text_pos = indicatorPos + Vec2f(15, 44);
		string text = controls.getInterpMouseScreenPos().y < timelineHeight + 104
			? "" + int(x_pos/8 - map.tilemapwidth/2) : ping.caster;
		
		GUI::SetFont("score-smaller");
		GUI::DrawTextCentered(text, text_pos, col_white);
	}
}

u8 getIndicatorFrame(int hash)
{
	u8 frame = 0; // playerclasses have a different sprite sheet

	switch(hash)
	{
		case _mechanic:
		case _m60:
		case _e50:
		case _bc25t:
		case _obj430:
		frame = 1; break;

		case _ranger:
		case _lmg:
		case _techtruck:
		case _civcar:
		case _lada:
		case _humvee:
		frame = 2; break;

		case _shotgun:
		case _firebringer:
		case _btr82a:
		case _bmp:
		case _bradley:
		frame = 3; break;

		case _revolver:
		case _shielder:
		case _maus:
		case _pinkmaus:
		case _desertmaus:
		frame = 4; break;

		case _sniper:
		case _t10:
		case _m103:
		case _kingtiger:
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
		case _armedmotorcycle:
		frame = 8; break;
		
		case _bf109:
		case _bomberplane:
		frame = 11; break;

		case _barge:
		frame = 12; break;

		case _techbigtruck:
		frame = 13; break;

		case _artillery:
		case _m40:
		frame = 14; break; 

		case _uh1:
		case _mi24:
		case _nh90:
		frame = 10; break;
			
		case _ah1:
		frame = 15; break;

		case _grad:
		frame = 16; break;

		case _is7:
		frame = 17; break;

		case _leopard1:
		case _m1abrams:
		frame = 18; break;

		case _radarapc:
		frame = 19; break;

		case _outpost:
		frame = 9; break;
	}

	return frame;
}

void onInit(CRules@ this)
{
	Reset(this);

	this.addCommandID("ping");
	this.addCommandID("ping_rectangle");
	this.addCommandID("ping_path");
	this.addCommandID("ping_timer");
	this.addCommandID("ping_textonly");

	this.addCommandID("add_artillery_explosion");
}

void onRestart(CRules@ this)
{
	Reset(this);

	Ping@[] p_empty;
	Canvas@[] c_empty;
	pings = p_empty;
	canvass = c_empty;
}

void Reset(CRules@ this)
{
	this.Untag("animateGameOver");

	GenericArtilleryExplosion@[] artillery_explosions;
	this.set("artillery_explosions", @artillery_explosions);
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
	
	f32 percentage = 1.0f - float(returncount) / float(flag.getTeamNum() == 255 ? 3600 : 3600);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	const f32 perc  = float(returncount) / float(flag.getTeamNum() == 255 ? 3600/2 : 3600);

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

void handleArtilleryExplosions(CRules@ this) // ontick
{
	GenericArtilleryExplosion@[]@ artillery_explosions;
	if (!this.get("artillery_explosions", @artillery_explosions)) return;
	if (artillery_explosions.size() == 0)
	{
		return;
	}

	for (u16 i = 0; i < artillery_explosions.size(); i++)
	{
		GenericArtilleryExplosion@ artillery_explosion = artillery_explosions[i];
		if (artillery_explosion is null) continue;

		if (artillery_explosion.time == 0)
		{
			artillery_explosions.removeAt(i);
			i--;
			continue;
		}

		artillery_explosion.time--;
	}
}

void renderArtilleryExplosions(CRules@ this) // onrender
{
	if (getLocalPlayer() is null) return;

	GenericArtilleryExplosion@[]@ artillery_explosions;
	if (!this.get("artillery_explosions", @artillery_explosions)) return;
	if (artillery_explosions.size() == 0)
	{
		return;
	}

	for (u16 i = 0; i < artillery_explosions.size(); i++)
	{
		GenericArtilleryExplosion@ artillery_explosion = artillery_explosions[i];
		if (artillery_explosion is null) continue;

		Vec2f pos = artillery_explosion.pos;

		float curXPos = pos.x - 28;
		float indicatorProgress = curXPos / mapWidth;
		float indicatorDist = (indicatorProgress * timelineLength) + timelineLDist;

		Vec2f indicatorPos = Vec2f(indicatorDist, timelineHeight);
		GUI::DrawIcon("indicator_sheet.png", 27, Vec2f(16, 25), indicatorPos, artillery_explosion.scale, artillery_explosion.owner_pid == getLocalPlayer().getNetworkID() ? SColor(255,255,255,155) : SColor(255,255,255,255));
	}
}

Ping@[] map_pings;
Ping@[] pings;
Canvas@[] canvass;

void renderPings(CRules@ this)
{
	u32 gt = getGameTime();

	Vec2f sc = getDriver().getScreenCenterPos();

	Vec2f offset = Vec2f(64, 64);
	Vec2f stl = sc - Vec2f(sw, sh)/2 - offset;
	Vec2f sbr = sc + Vec2f(sw, sh)/2 + offset;

	for (int i = 0; i < pings.size(); i++)
	{
		Ping@ ping = pings[i];

		// remove if ping doesnt exist for whatever reason, or is expired already
		if (ping is null || gt > ping.end_time)
		{
			pings.removeAt(i);
			i--;
			continue;	
		}

		// don't draw if ping out of bounds
		if (!isOnScreen(ping.pos))
		{
			continue;
		}
		
		ping.render();
	}

	CBlob@ blob = getLocalPlayerBlob();
	if (blob is null) return;
	CControls@ controls = getControls();
	if (controls is null) return;

	for (int i = 0; i < canvass.size(); i++)
	{
		Canvas@ canvas = canvass[i];

		if (canvas is null || gt > canvas.end_time)
		{
			canvass.removeAt(i);
			i--;
			continue;	
		}

		if (!isOnScreen(canvas.pos, 2))
		{
			continue;
		}
		
		canvas.render(blob, controls);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add_artillery_explosion"))
	{
		Vec2f pos;
		if (!params.saferead_Vec2f(pos)) return;

		u32 time;
		if (!params.saferead_u32(time)) return;

		f32 scale;
		if (!params.saferead_f32(scale)) return;

		GenericArtilleryExplosion@[]@ artillery_explosions;
		if (!this.get("artillery_explosions", @artillery_explosions)) return;

		u16 pid = 0;
		if (!params.saferead_u16(pid)){};

		GenericArtilleryExplosion new_explosion(pos, time, scale, pid);
		artillery_explosions.push_back(@new_explosion);
	}
	else if (cmd == this.getCommandID("ping"))
	{
		u8 team;
		if (!params.saferead_u8(team)) return;

		if (isClient()) // ignore if enemy team
		{
			CPlayer@ local = getLocalPlayer();
			if (local is null || local.getTeamNum() != team) return;
		}

		Vec2f pos;
		if (!params.saferead_Vec2f(pos)) return;

		u8 type;
		if (!params.saferead_u8(type)) return;

		u32 end_time;
		if (!params.saferead_u32(end_time)) return;

		u8 fadeout_time;
		if (!params.saferead_u8(fadeout_time)) return;
		
		string caster;
		if (!params.saferead_string(caster)) return;

		if (isClient())
		{
			Ping@ ping = Ping(pos, type, end_time, fadeout_time, caster, team);
			if (PingList[type].find("map_") != -1)
			{
				ping.end_time = getGameTime() + map_ping_time;
				ping.fadeout_time = map_ping_fadeout_time;
				ping.fadeout = 0;
				map_pings.push_back(ping);
			}
			else
			{
				pings.push_back(ping);
			}

			Sound::Play("PopIn", pos, 1.0f, 1.0f);
		}
	}
	else if (cmd == this.getCommandID("ping_path"))
	{
		u8 shape;
		if (!params.saferead_u8(shape)) return;

		u8 team;
		if (!params.saferead_u8(team)) return;

		if (isClient()) // ignore if enemy team
		{
			CPlayer@ local = getLocalPlayer();
			if (local is null || local.getTeamNum() != team) return;
		}

		u32 end_time;
		if (!params.saferead_u32(end_time)) return;

		u8 fadeout_time;
		if (!params.saferead_u8(fadeout_time)) return;
		
		string caster;
		if (!params.saferead_string(caster)) return;

		u8 vsize;
		if (!params.saferead_u8(vsize)) return;

		Vec2f[] vertices;
		for (u8 i = 0; i < vsize; i++)
		{
			Vec2f current;
			if (!params.saferead_Vec2f(current)) continue;

			vertices.push_back(current);
		}
		
		if (vertices.size() <= 1) return;

		if (isClient())
		{
			Path path = Path();
			path.SetPingProps(vertices[0], shape, end_time, fadeout_time, caster, team);
			path.vertices = vertices;
			path.static = true;
			canvass.push_back(@path);

			Sound::Play("PopIn", vertices[0], 1.5f, 1.0f);
		}
	}
	else if (cmd == this.getCommandID("ping_rectangle"))
	{
		u8 shape;
		if (!params.saferead_u8(shape)) return;

		u8 team;
		if (!params.saferead_u8(team)) return;

		if (isClient()) // ignore if enemy team
		{
			CPlayer@ local = getLocalPlayer();
			if (local is null || local.getTeamNum() != team) return;
		}

		u32 end_time;
		if (!params.saferead_u32(end_time)) return;

		u8 fadeout_time;
		if (!params.saferead_u8(fadeout_time)) return;
		
		string caster;
		if (!params.saferead_string(caster)) return;

		u8 vsize;
		if (!params.saferead_u8(vsize)) return;

		Vec2f[] vertices;
		for (u8 i = 0; i < vsize; i++)
		{
			Vec2f current;
			if (!params.saferead_Vec2f(current)) continue;

			vertices.push_back(current);
		}
		
		if (vertices.size() != 2) return;

		if (isClient())
		{
			Rectangle rect = Rectangle();
			rect.SetPingProps(vertices[0], shape, end_time, fadeout_time, caster, team);
			rect.vertices = vertices;
			rect.static = true;
			canvass.push_back(@rect);

			Sound::Play("PopIn", vertices[0], 1.5f, 1.0f);
		}
	}
	else if (cmd == this.getCommandID("ping_textonly"))
	{
		u8 team;
		if (!params.saferead_u8(team)) return;

		if (isClient()) // DO NOT ignore if enemy team
		{
			CPlayer@ local = getLocalPlayer();
			if (local is null) return;
		}

		Vec2f pos;
		if (!params.saferead_Vec2f(pos)) return;

		string text;
		if (!params.saferead_string(text)) return;

		u32 end_time;
		if (!params.saferead_u32(end_time)) return;

		u8 fadeout_time;
		if (!params.saferead_u8(fadeout_time)) return;
		
		string caster;
		if (!params.saferead_string(caster)) return;

		if (isClient())
		{
			Ping@ ping = TextPing(pos, text, end_time, fadeout_time, caster, team);
			pings.push_back(ping);

			Sound::Play("PopIn", pos, 1.0f, 1.0f);
		}
	}
}

void SendPathCanvas(CBlob@ blob, u8 shape, Vec2f[] vertices, u8 team, u8 ping_time, u8 ping_fadeout_time)
{}

void SendRectangleCanvas(CBlob@ blob, u8 shape, Vec2f[] vertices, u8 team, u8 ping_time, u8 ping_fadeout_time)
{}

void SendTimerCanvas(CBlob@ blob, u8 shape, u8 team, u8 ping_time, u8 ping_fadeout_time)
{}