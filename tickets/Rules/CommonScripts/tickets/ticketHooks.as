#include "RulesCore.as";
#include "TeamColour.as";

#include "tickets.as";

int redTicketsLeft;
int blueTicketsLeft;

s16 ticketsPerTeam;
s16 ticketsPerPlayer;
s16 ticketsPerPlayerInTeam0;

bool unevenTickets;
s16 numBlueTickets;
s16 numRedTickets;

s16 numBlueTicketsPerPlayerInTeam;
s16 numRedTicketsPerPlayerInTeam;
s16 numBlueTicketsPerPlayerInGame;
s16 numRedTicketsPerPlayerInGame;

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
		
		numBlueTickets = cfg.read_s16("numBlueTickets",0);
		numRedTickets = cfg.read_s16("numRedTickets",0);

		numBlueTicketsPerPlayerInTeam = cfg.read_s16("numBlueTicketsPerPlayerInTeam",0);
		numRedTicketsPerPlayerInTeam = cfg.read_s16("numRedTicketsPerPlayerInTeam",0);
		numBlueTicketsPerPlayerInGame = cfg.read_s16("numBlueTicketsPerPlayerInGame",0);
		numRedTicketsPerPlayerInGame = cfg.read_s16("numRedTicketsPerPlayerInGame",0);

		
		RulesCore@ core;
		this.get("core", @core);
		if(core is null) print("core is null!!!");
		

		s16 redTickets=ticketsPerTeam;
		s16 blueTickets=ticketsPerTeam;

		int playersInGame=getPlayersCount();

		blueTickets+=(ticketsPerPlayer*playersInGame);
		redTickets+=(ticketsPerPlayer*playersInGame);
		blueTickets+=(ticketsPerPlayerInTeam0*(core.getTeam(0).players_count));
		redTickets+=(ticketsPerPlayerInTeam0*(core.getTeam(0).players_count));

		blueTickets+=numBlueTickets;
		redTickets+=numRedTickets;
		blueTickets+=(numBlueTicketsPerPlayerInTeam*core.getTeam(0).players_count);
		redTickets+=(numRedTicketsPerPlayerInTeam*core.getTeam(1).players_count);
		blueTickets+=(numBlueTicketsPerPlayerInGame*playersInGame);
		redTickets+=(numRedTicketsPerPlayerInGame*playersInGame);

		this.set_s16("redTickets", redTickets);
		this.set_s16("blueTickets", blueTickets);
		this.Sync("redTickets", true);
		this.Sync("blueTickets", true);

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
}

void onRestart(CRules@ this){
	reset(this);
}

void onRender(CRules@ this){

	CBlob@ b = getBlobByName("pointflag");
	if (b !is null) return;
	s16 blueTickets=0;
	s16 redTickets=0;

	blueTickets=this.get_s16("blueTickets");
	redTickets=this.get_s16("redTickets");

    GUI::SetFont("big score font");
	GUI::DrawText( ""+redTickets, Vec2f(232,98), getTeamColor(1) );		//shows tickets just above bottom left HUD
	GUI::DrawText( ""+blueTickets, Vec2f(232,34), getTeamColor(0) );

}


void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData){

	int teamNum=victim.getTeamNum();
	checkGameOver(this, teamNum);

	if(this.isMatchRunning()){
		int numTickets=0;

		if(teamNum==0){
			numTickets=this.get_s16("blueTickets");
		}else{
			numTickets=this.get_s16("redTickets");
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