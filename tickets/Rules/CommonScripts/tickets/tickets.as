#include "RulesCore.as";
#include "TDM_Structs";

shared int ticketsRemaining(CRules@ this, int team){
	if(team==0){
		return this.get_s16("blueTickets");
	}else if(team==1){
		return this.get_s16("redTickets");
	}
	return 1;
}


shared int decrementTickets(CRules@ this, int team){			//returns 1 if no tickets left, 0 otherwise
	s16 numTickets;

	if(team==0){
		numTickets=this.get_s16("blueTickets");
		if(numTickets<=0)return 1;
		numTickets--;

		this.set_s16("blueTickets", numTickets);
		this.Sync("blueTickets", true);
		return 0;
	}else if(team==1){
		numTickets=this.get_s16("redTickets");
		if(numTickets<=0)return 1;
		numTickets--;

		this.set_s16("redTickets", numTickets);
		this.Sync("redTickets", true);
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

		if(teamNum==1){					//if one team is dead, other wins (no consideration for more teams)
			if(this.get_s16("redTickets")>0) return false;
			if(isPlayersLeft(this, teamNum)) return false;
			if(this.getCurrentState()==GAME_OVER) return true;
			this.SetTeamWon( 0 ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(0).getName() + " wins the game!\nWell done. Loading next map..." );
			return true;
		}else if(teamNum==0){
			if(this.get_s16("blueTickets")>0) return false;
			if(isPlayersLeft(this, teamNum)) return false;
			if(this.getCurrentState()==GAME_OVER) return true;
			this.SetTeamWon( 1 ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(1).getName() + " wins the game!\nWell done. Loading next map..." );
			return true;
		}
	
	return false;			//team not red or blue (probably spectator so dont want to check game over)
}