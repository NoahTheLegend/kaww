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
		int teamRightTickets = this.get_s16("teamRightTickets");
		int teamLeftTickets = this.get_s16("teamLeftTickets");

		bool tie = false;
		{
			if(teamRightTickets>teamLeftTickets)
				teamWonNumber = 1;
			else if(teamLeftTickets>teamRightTickets)
				teamWonNumber = 0;
			else
			{
				teamWonNumber = -1;
				tie = true;
			}
		}

		if (teamRightTickets == 0 && teamLeftTickets == 0)
		{
			u8 players_teamleft;
			u8 players_teamright;
			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				if (getPlayer(i) !is null && getPlayer(i).getBlob() !is null)
				{
					u8 teamleft = getRules().get_u8("teamleft");
					u8 teamright = getRules().get_u8("teamright");
					if (getPlayer(i).getBlob().getTeamNum() == teamleft) players_teamleft++;
					else if (getPlayer(i).getBlob().getTeamNum() == teamright) players_teamright++;
				}
			}

			if (players_teamleft > players_teamright) teamWonNumber = 0;
			else if (players_teamright > players_teamleft) teamWonNumber = 1;
			else
			{
				teamWonNumber = -1;
			}
		}

		if (teamWonNumber >= 0 && !tie)
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
		              color, Vec2f(10, 145), Vec2f(getScreenWidth() - 20, 205), true, false);
	}
}
