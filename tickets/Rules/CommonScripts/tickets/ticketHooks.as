#include "RulesCore.as";
#include "TeamColour.as";

#include "tickets.as";

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

const u32 MIN_TICKETS = 40;
const u32 TICKETS_PER_PLAYER = 15;

void reset(CRules@ this){
	if(getNet().isServer()){
		u8 teamleft = getRules().get_u8("oldteamleft");
		u8 teamright = getRules().get_u8("oldteamright");
		//string configstr = "../Mods/tickets/Rules/CommonScripts/tickets/tickets.cfg";
		string configstr = "../Mods/ArmoredWarfare/tickets/settings/tickets.cfg";
		if (this.exists("ticketsconfig")){
			configstr = this.get_string("ticketsconfig");
		}
		ConfigFile cfg = ConfigFile( configstr );
		
		ticketsPerTeam = MIN_TICKETS;
		ticketsPerPlayerInTeam0 = TICKETS_PER_PLAYER;
		
		numTeamLeftTickets = cfg.read_s16("numTeamLeftTickets",0);
		numTeamRightTickets = cfg.read_s16("numTeamRightTickets",0);

		
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
    if (!GUI::isFontLoaded("big score font")) {
        GUI::LoadFont("big score font",
                      "GUI/Fonts/AveriaSerif-Bold.ttf", 
                      FONT_SIZE,
                      true);
					  reset(this);
    }
	if (!GUI::isFontLoaded("small score font")) {
        GUI::LoadFont("small score font",
                      "GUI/Fonts/AveriaSerif-Bold.ttf", 
                      11,
                      true);
					  reset(this);
    }
}

void onRestart(CRules@ this){
	reset(this);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData){

	int teamNum=victim.getTeamNum();
	checkGameOver(this, teamNum);

	if(this.isMatchRunning()){
		int numTickets=0;

		if(teamNum==0){
			numTickets=this.get_s16("teamLeftTickets");
		}else{
			numTickets=this.get_s16("teamRightTickets");
		}
		if(numTickets<=0){          //play sound if running/run out of tickets
			Sound::Play("/depleted.ogg");
			return;
		}else if(numTickets<=5){
			Sound::Play("/depleting.ogg");
			return;
		}
	}
}

void onPlayerLeave( CRules@ this, CPlayer@ player ){

	CBlob @blob = player.getBlob();
	if (blob !is null && !blob.hasTag("dead"))
	{
		int teamNum=player.getTeamNum();
		checkGameOver(this, teamNum);
	}

}

void onPlayerChangedTeam( CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam ){
	checkGameOver(this, oldteam);
}