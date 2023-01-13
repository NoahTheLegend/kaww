//Rules timer!

// Requires game_end_time set originally

void onInit(CRules@ this)
{
	if (!this.exists("no timer"))
		this.set_bool("no timer", false);
	if (!this.exists("game_end_time"))
		this.set_u32("game_end_time", 0);
	if (!this.exists("end_in"))
		this.set_s32("end_in", 0);
}

void onTick(CRules@ this)
{
	if (!getNet().isServer() || !this.isMatchRunning() || this.get_bool("no timer"))
	{
		return;
	}

	u32 gameEndTime = this.get_u32("game_end_time");

	if (gameEndTime == 0) return; //-------------------- early out if no time.

	this.set_s32("end_in", (s32(gameEndTime) - s32(getGameTime())) / 30);
	this.Sync("end_in", true);

	if (getGameTime() > gameEndTime)
	{
		bool hasWinner = false;
		s8 teamWonNumber = -1;

		/*if (this.exists("team_wins_on_end"))
		{
			teamWonNumber = this.get_s8("team_wins_on_end");
		}*/

		//who has the most tickets left?
		int redTickets = this.get_s16("redTickets");
		int blueTickets = this.get_s16("blueTickets");

		bool is_siege = this.get_u8("siege") != 255;

		if (is_siege)
		{
			teamWonNumber = (this.get_u8("siege") == 0 ? 1 : 0);
			bool all_flags_capped = true;
			CBlob@[] flags;
        	getBlobsByName("pointflag", @flags);

			for (u8 i = 0; i < flags.length; i++)
			{
				CBlob@ b = flags[i];
				if (b is null) continue;
				if (b.getTeamNum() != this.get_u8("siege")) all_flags_capped = false;
			}

			if (all_flags_capped) teamWonNumber = -1;
		}
		else
		{
			if(redTickets>blueTickets)
				teamWonNumber = 1;
			else if(blueTickets>redTickets)
				teamWonNumber = 0;
			else teamWonNumber = -1;
		}

		if (redTickets == 0 && blueTickets == 0)
		{
			u8 players_blue;
			u8 players_red;
			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				if (getPlayer(i) !is null && getPlayer(i).getBlob() !is null)
				{
					if (getPlayer(i).getTeamNum() == 0) players_blue++;
					else if (getPlayer(i).getTeamNum() == 1) players_red++;
				}
			}

			if (players_blue > players_red) teamWonNumber = 0;
			else if (players_red > players_blue) teamWonNumber = 1;
			else
			{
				u16 blue_kills = this.get_u16("blue_kills");
				u16 red_kills = this.get_u16("red_kills");
				if (blue_kills > red_kills) teamWonNumber = 0;
				else if (red_kills > blue_kills) teamWonNumber = 1;
				else teamWonNumber = -1;
			}
		}

		if (teamWonNumber >= 0)
		{
			//ends the game and sets the winning team
			this.SetTeamWon(teamWonNumber);
			CTeam@ teamWon = this.getTeam(teamWonNumber);

			if (teamWon !is null)
			{
				hasWinner = true;
				this.SetGlobalMessage("Time is up!\n" + teamWon.getName() + " wins the game!\nWell done. Loading next map..." );
			}
		}

		if (!hasWinner)
		{
			this.SetGlobalMessage("Time is up!\nIt's a tie!");
		}

		//GAME OVER
		this.SetCurrentState(3);
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording) return;
	
	if (!this.isMatchRunning() || this.get_bool("no timer") || !this.exists("end_in")) return;

	s32 end_in = this.get_s32("end_in");

	if (end_in > 0)
	{
		s32 timeToEnd = end_in;

		s32 secondsToEnd = timeToEnd % 60;
		s32 MinutesToEnd = timeToEnd / 60;

		SColor color = SColor(255, 255, 255, 255);
		if (secondsToEnd%2==0)
		{
			if (MinutesToEnd < 3) color = SColor(255, 255, 75, 40);
			else if (MinutesToEnd < 10) color = SColor(255, 255, 255, 25);
		}

		drawRulesFont("Time left: " +
		              ((MinutesToEnd < 10) ? "0" + MinutesToEnd : "" + MinutesToEnd) +
		              ":" +
		              ((secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd),
		              color, Vec2f(10, 120), Vec2f(getScreenWidth() - 20, 180), true, false);
	}
}
