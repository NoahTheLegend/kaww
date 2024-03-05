#include "RulesCore.as";
#include "TeamColour.as";
#include "Hitters.as";
#include "PerksCommon.as";

int teamRightTicketsLeft;
int teamLeftTicketsLeft;

s16 ticketsPerTeam;
s16 ticketsPerPlayer;
s16 ticketsPerPlayerInTeam0;

bool unevenTickets;
s16 numTeamLeftTickets;
s16 numTeamRightTickets;

s16 numTeamLeftTicketsPerPlayerInTeam;
s16 numTeamRightTicketsPerPlayerInTeam;
s16 numTeamLeftTicketsPerPlayerInGame;
s16 numTeamRightTicketsPerPlayerInGame;

const u8 FONT_SIZE = 27;

const u32 MIN_TICKETS = 25;
const u32 TICKETS_PER_PLAYER = 12;

void reset(CRules@ this)
{
	if (getNet().isServer())
	{
		u8 teamleft = getRules().get_u8("oldteamleft");
		u8 teamright = getRules().get_u8("oldteamright");
		//string configstr = "../Mods/tickets/Rules/CommonScripts/tickets/tickets.cfg";
		//string configstr = "../Mods/ArmoredWarfare/tickets/settings/tickets.cfg";
		//if (this.exists("ticketsconfig")){
		//	configstr = this.get_string("ticketsconfig");
		//}
		//ConfigFile cfg = ConfigFile( configstr );
		
		ticketsPerTeam = MIN_TICKETS;
		ticketsPerPlayerInTeam0 = TICKETS_PER_PLAYER;
		
		//numTeamLeftTickets = cfg.read_s16("numTeamLeftTickets",0);
		//numTeamRightTickets = cfg.read_s16("numTeamRightTickets",0);

		
		RulesCore@ core;
		this.get("core", @core);
		if (core is null) print("core is null!!!");
		
		u8 templeft = 0;
		u8 tempright = 0;
		for (u8 i = 0; i < getPlayersCount(); i++)
		{
			if (getPlayer(i) is null) continue;
			if (getPlayer(i).getTeamNum() == teamleft)
				templeft++;
			else if (getPlayer(i).getTeamNum() == teamright)
				tempright++;
		}
		u8 players_count = templeft+tempright;
		u8 players_in_team_count = Maths::Min(templeft, tempright);

		s16 teamRightTickets=ticketsPerTeam;
		s16 teamLeftTickets=ticketsPerTeam;

		int playersInGame=getPlayersCount();
		
		teamLeftTickets+=(ticketsPerPlayerInTeam0*players_in_team_count);
		teamRightTickets+=(ticketsPerPlayerInTeam0*players_in_team_count);	


		this.set_s16("teamRightTickets", teamRightTickets);
		this.set_s16("teamLeftTickets", teamLeftTickets);;
		this.Sync("teamRightTickets", true);
		this.Sync("teamLeftTickets", true);
	}
}

void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("score-big"))
	{
        GUI::LoadFont("score-big",
                      "GUI/Fonts/AveriaSerif-Bold.ttf", 
                      FONT_SIZE,
                      true);
					  reset(this);
    }
	if (!GUI::isFontLoaded("small score font"))
	{
        GUI::LoadFont("small score font",
                      "GUI/Fonts/AveriaSerif-Bold.ttf", 
                      11,
                      true);
					  reset(this);
    }
}

void onRestart(CRules@ this)
{
	reset(this);
}

void onTick(CRules@ this)
{
	// if many people go spectator, only one ticket will be consumed, needs a proper solution later
	s8 prop = this.get_s8("decrement_ticket_by_team");
	if (prop != -1)
	{
		decrementTickets(this, prop);
		this.set_s8("decrement_ticket_by_team", -1);
	}
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim is null) return;

	int vTeamNum = victim.getTeamNum();
	int kTeamNum = vTeamNum;
	int lTeamNum = -1;

	u8 teamleft = this.get_u8("teamleft");
	u8 teamright = this.get_u8("teamright");

	if (killer !is null) kTeamNum = killer.getTeamNum();
	if (getLocalPlayer() !is null) lTeamNum = getLocalPlayer().getTeamNum();

	bool stats_loaded = false;
    PerkStats@ stats = getPerkStats(victim, stats_loaded);

	int perk_id = 0;
	if (stats_loaded) perk_id = stats.id;
	
	if (perk_id == Perks::deathincarnate && (customData == Hitters::suicide || XORRandom(100) > 50))
	{
		return;
	}

	if (this.isMatchRunning() && getGameTime() >= 300)
	{
		decrementTickets(this, vTeamNum);
		/*
		if (!isClient()) return;
		if (vTeamNum == teamleft)
		{
			int numTickets=0;
			if (vTeamNum == teamleft && lTeamNum == teamleft)
			{
				numTickets=this.get_s16("teamLeftTickets");
			}
			else if (vTeamNum == teamright && lTeamNum == teamright)
			{
				numTickets=this.get_s16("teamRightTickets");
			}

			if (numTickets <= 0)
			{   //play sound if running/run out of tickets
				Sound::Play("/depleted.ogg");
			}
			else if (numTickets <= 5)
			{
				Sound::Play("/depleting.ogg");
			}
		}
		*/
	}
}

void onPlayerLeave( CRules@ this, CPlayer@ player ){

	CBlob@ blob = player.getBlob();
	if (blob !is null && !blob.hasTag("dead"))
	{
		int teamNum = player.getTeamNum();
		checkGameOver(this, teamNum);
	}

}

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	checkGameOver(this, oldteam);
}

int decrementTickets(CRules@ this, int team)
{	//returns 1 if no tickets left, 0 otherwise
	s16 numTickets;

	//double check idk why its passing
	CBlob@ b = getBlobByName("pointflag");
	if (b is null) @b = getBlobByName("pointflagt2");

	CBlob@ t = getBlobByName("tent");
	if (b !is null || t is null) return 0;

	u8 teamleft = this.get_u8("teamleft");
	u8 teamright = this.get_u8("teamright");

	if (team == teamleft)
	{
		numTickets = this.get_s16("teamLeftTickets");
		if (numTickets <= 0)
		{
			checkGameOver(this, team);
			return 1;
		}

		if (numTickets==1)
		{
			this.set_s16("teamRightTickets", this.get_s16("teamRightTickets") / 2);
			this.Sync("teamRightTickets", true);
			//printf("decrease by 2");
		} 
		numTickets--;

		this.set_s16("teamLeftTickets", numTickets);
		this.Sync("teamLeftTickets", true);

		checkGameOver(this, team);

		return 0;
	}
	else if (team == teamright)
	{
		numTickets = this.get_s16("teamRightTickets");
		if (numTickets <= 0)
		{
			checkGameOver(this, team);
			return 1;
		}

		if (numTickets==1)
		{
			this.set_s16("teamLeftTickets", this.get_s16("teamLeftTickets") / 2);
			this.Sync("teamRightTickets", true);
			//printf("decrease by 2");
		} 
		numTickets--;

		this.set_s16("teamRightTickets", numTickets);
		this.Sync("teamRightTickets", true);

		checkGameOver(this, team);

		return 0;
	}

	return 1;
}

bool isPlayersLeft(CRules@ this, int team)
{	//checks if spawning players or alive players
	CBlob@[] team_blobs;
 
	CBlob@[] player_blobs;
	getBlobsByTag( "player", @player_blobs );
 
	for (uint i=0; i<player_blobs.length; i++ )
	{
		if (player_blobs[i] !is null && player_blobs[i].getTeamNum()==team && !player_blobs[i].hasTag("dead"))
		{
			return true;
		}
	}
	return false;
}

bool checkGameOver(CRules@ this, int teamNum)
{
		u8 teamleft = getRules().get_u8("teamleft");
		u8 teamright = getRules().get_u8("teamright");

		if (teamNum == this.get_u8("teamleft"))
		{	// left team lost?
			if (this.get_s16("teamLeftTickets") > 0)    return false;
			if (isPlayersLeft(this, teamNum)) 		    return false;
			if (this.getCurrentState() == GAME_OVER)    return true;

			this.SetTeamWon(teamright); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage(this.getTeam(teamright).getName() + " wins the game!\n\nWell done. Loading next map...");

			return true;
		}
		else if (teamNum == this.get_u8("teamright"))
		{	// right team lost?
			if(this.get_s16("teamRightTickets") > 0)	 return false;
			if(isPlayersLeft(this, teamNum)) 	   	 return false;
			if(this.getCurrentState() == GAME_OVER)  return true;

			this.SetTeamWon(teamleft); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage(this.getTeam(teamleft).getName() + " wins the game!\n\nWell done. Loading next map...");

			return true;
		}
	
	return false;
}