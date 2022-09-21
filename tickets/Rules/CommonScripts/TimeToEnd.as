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
		}

		if (teamWonNumber >= 0)
		{
			//ends the game and sets the winning team
			this.SetTeamWon(teamWonNumber);
			CTeam@ teamWon = this.getTeam(teamWonNumber);

			if (teamWon !is null)
			{
				hasWinner = true;
				this.SetGlobalMessage("Time is up!\n" + teamWon.getName() + " wins the game!");
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
	if (!this.isMatchRunning() || this.get_bool("no timer") || !this.exists("end_in")) return;

	s32 end_in = this.get_s32("end_in");

	if (end_in > 0)
	{
		s32 timeToEnd = end_in;

		s32 secondsToEnd = timeToEnd % 60;
		s32 MinutesToEnd = timeToEnd / 60;
		drawRulesFont("Time left: " +
		              ((MinutesToEnd < 10) ? "0" + MinutesToEnd : "" + MinutesToEnd) +
		              ":" +
		              ((secondsToEnd < 10) ? "0" + secondsToEnd : "" + secondsToEnd),
		              SColor(255, 255, 255, 255), Vec2f(10, 140), Vec2f(getScreenWidth() - 20, 180), true, false);
	}
}
