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

void reset(CRules@ this){

	if(getNet().isServer()){

		//string configstr = "../Mods/tickets/Rules/CommonScripts/tickets/tickets.cfg";
		string configstr = "../Mods/ArmoredWarfare/tickets/settings/tickets.cfg";
		if (this.exists("ticketsconfig")){
			configstr = this.get_string("ticketsconfig");
		}
		ConfigFile cfg = ConfigFile( configstr );
		
		ticketsPerTeam = cfg.read_s16("ticketsPerTeam",40);
		ticketsPerPlayer = cfg.read_s16("ticketsPerPlayer",0);
		ticketsPerPlayerInTeam0 = cfg.read_s16("ticketsPerPlayerInTeam0",0);
		
		numTeamLeftTickets = cfg.read_s16("numTeamLeftTickets",0);
		numTeamRightTickets = cfg.read_s16("numTeamRightTickets",0);

		numTeamLeftTicketsPerPlayerInTeam = cfg.read_s16("numTeamLeftTicketsPerPlayerInTeam",0);
		numTeamRightTicketsPerPlayerInTeam = cfg.read_s16("numTeamRightTicketsPerPlayerInTeam",0);
		numTeamLeftTicketsPerPlayerInGame = cfg.read_s16("numTeamLeftTicketsPerPlayerInGame",0);
		numTeamRightTicketsPerPlayerInGame = cfg.read_s16("numTeamRightTicketsPerPlayerInGame",0);

		
		RulesCore@ core;
		this.get("core", @core);
		if (core is null) print("core is null!!!");
		

		s16 teamRightTickets=ticketsPerTeam;
		s16 teamLeftTickets=ticketsPerTeam;

		int playersInGame=getPlayersCount();

		teamLeftTickets+=(ticketsPerPlayer*playersInGame);
		teamRightTickets+=(ticketsPerPlayer*playersInGame);
		teamLeftTickets+=(ticketsPerPlayerInTeam0*(core.getTeam(0).players_count));
		teamRightTickets+=(ticketsPerPlayerInTeam0*(core.getTeam(0).players_count));

		teamLeftTickets+=numTeamLeftTickets;
		teamRightTickets+=numTeamRightTickets;
		teamLeftTickets+=(numTeamLeftTicketsPerPlayerInTeam*core.getTeam(0).players_count);
		teamRightTickets+=(numTeamRightTicketsPerPlayerInTeam*core.getTeam(1).players_count);
		teamLeftTickets+=(numTeamLeftTicketsPerPlayerInGame*playersInGame);
		teamRightTickets+=(numTeamRightTicketsPerPlayerInGame*playersInGame);

		this.set_s16("teamRightTickets", teamRightTickets);
		this.set_s16("teamLeftTickets", teamLeftTickets);
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