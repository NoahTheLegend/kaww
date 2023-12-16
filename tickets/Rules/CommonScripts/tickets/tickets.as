#include "RulesCore.as";
#include "TDM_Structs";

ConfigFile cfg_playerexp;

shared int ticketsRemaining(CRules@ this, int team){
	u8 teamleft = this.get_u8("teamleft");
	u8 teamright = this.get_u8("teamright");
	if(team==teamleft){
		return this.get_s16("teamLeftTickets");
	}else if(team==teamright){
		return this.get_s16("teamRightTickets");
	}
	return 1;
}

shared int decrementTickets(CRules@ this, int team){			//returns 1 if no tickets left, 0 otherwise
	s16 numTickets;

	//double check idk why its passing
	CBlob@ b = getBlobByName("pointflag");
	if (b is null) @b = getBlobByName("pointflagt2");
	CBlob@ t = getBlobByName("tent");
	if (b !is null || t is null) return 0;

	u8 teamleft = this.get_u8("teamleft");
	u8 teamright = this.get_u8("teamright");

	if(team==teamleft){
		numTickets=this.get_s16("teamLeftTickets");
		if(numTickets<=0)return 1;
		numTickets--;

		if (numTickets==0)
		{
			this.set_s16("teamRightTickets", this.get_s16("teamRightTickets") / 2);
			this.Sync("teamRightTickets", true);
		} 

		this.set_s16("teamLeftTickets", numTickets);
		this.Sync("teamLeftTickets", true);
		return 0;
	}else if(team==teamright){
		numTickets=this.get_s16("teamRightTickets");
		if(numTickets<=0)return 1;
		numTickets--;

		if (numTickets==0)
		{
			this.set_s16("teamLeftTickets", this.get_s16("teamLeftTickets") / 2);
			this.Sync("teamRightTickets", true);
		} 

		this.set_s16("teamRightTickets", numTickets);
		this.Sync("teamRightTickets", true);
		return 0;
	}
	return 1;
}

shared bool isPlayersLeft(CRules@ this, int team){			//checks if spawning players or alive players

	CBlob@[] team_blobs;
 
	CBlob@[] player_blobs;
	getBlobsByTag( "player", @player_blobs );
 
	for(uint i=0; i<player_blobs.length; i++ ){
		if (player_blobs[i] !is null && player_blobs[i].getTeamNum()==team && !player_blobs[i].hasTag("dead")){
			return true;
		}
	}
	return false;
}

shared bool checkGameOver(CRules@ this, int teamNum){
		u8 teamleft = getRules().get_u8("teamleft");
		u8 teamright = getRules().get_u8("teamright");
		if(teamNum==this.get_u8("teamleft")){					//if one team is dead, other wins (no consideration for more teams)
			if(this.get_s16("teamRightTickets")>0) return false;
			if(isPlayersLeft(this, teamNum)) return false;
			if(this.getCurrentState()==GAME_OVER) return true;
			this.SetTeamWon( 0 ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(teamleft).getName() + " wins the game!\n\nWell done. Loading next map..." );
			return true;
		}else if(teamNum==this.get_u8("teamright")){
			if(this.get_s16("teamLeftTickets")>0) return false;
			if(isPlayersLeft(this, teamNum)) return false;
			if(this.getCurrentState()==GAME_OVER) return true;
			this.SetTeamWon( 1 ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(teamright).getName() + " wins the game!\n\nWell done. Loading next map..." );
			return true;
		}
	
	return false;
}