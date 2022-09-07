#define SERVER_ONLY

#include "TDM_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";
//#include "Alert.as";

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
			this.SetGlobalMessage( this.getTeam(0).getName() + " wins the game!" );
			return true;
		}else if(teamNum==0){
			if(this.get_s16("blueTickets")>0) return false;
			if(isPlayersLeft(this, teamNum)) return false;
			if(this.getCurrentState()==GAME_OVER) return true;
			this.SetTeamWon( 1 ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(1).getName() + " wins the game!" );
			return true;
		}
	
	return false;			//team not red or blue (probably spectator so dont want to check game over)
}

ConfigFile cfg_playercoins;
ConfigFile cfg_playertechs;

string cost_config_file = "tdm_vars.cfg";

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("flag_cap_won"))
    {
		u8 team;
		if (!params.saferead_u8(team)) return;

		this.SetTeamWon(team);
		this.SetCurrentState(GAME_OVER);
		this.SetGlobalMessage(this.getTeam(team).getName() + " wins the game!" );
    }
}

void Config(TDMCore@ this)
{
	CRules@ rules = getRules();

	//load cfg
	if (rules.exists("tdm_costs_config"))
		cost_config_file = rules.get_string("tdm_costs_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	//how long to wait for everyone to spawn in?
	s32 warmUpTimeSeconds = cfg.read_s32("warmUpTimeSeconds", 35);
	this.warmUpTime = (getTicksASecond() * warmUpTimeSeconds);
	this.gametime = getGameTime() + this.warmUpTime;

	//how many kills needed to win the match, per player on the smallest team
	this.kills_to_win_per_player = cfg.read_s32("killsPerPlayer", 2);
	this.sudden_death = this.kills_to_win_per_player <= 0;

	//how long for the game to play out?
	f32 gameDurationMinutes = 25.0f + getPlayersCount()*1.0; //cfg.read_f32("gameDurationMinutes", 7.0f)
	this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes) + this.warmUpTime;

	//spawn after death time - set in gamemode.cfg, or override here
	f32 spawnTimeSeconds = cfg.read_f32("spawnTimeSeconds", 5);//Maths::Min(3, 8-(getPlayersCount()/3))); //rules.playerrespawn_seconds
	this.spawnTime = (getTicksASecond() * spawnTimeSeconds);

	//how many players have to be in for the game to start
	this.minimum_players_in_team = 1;

	//whether to scramble each game or not
	this.scramble_teams = cfg.read_bool("scrambleTeams", true);
	this.all_death_counts_as_kill = cfg.read_bool("dying_counts", false);

	s32 scramble_maps = cfg.read_s32("scramble_maps", -1);
	if(scramble_maps != -1) {
		sv_mapcycle_shuffle = (scramble_maps != 0);
	}

	// modifies if the fall damage velocity is higher or lower - TDM has lower velocity
	rules.set_f32("fall vel modifier", cfg.read_f32("fall_dmg_nerf", 0.9f)); //lower than normal
}

//TDM spawn system

shared class TDMSpawns : RespawnSystem
{
	TDMCore@ TDM_core;

	bool force;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@TDM_core = cast < TDMCore@ > (core);
	}

	void Update()
	{
		for (uint team_num = 0; team_num < TDM_core.teams.length; ++team_num)
		{
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (TDM_core.teams[team_num]);

			for (uint i = 0; i < team.spawns.length; i++)
			{
				TDMPlayerInfo@ info = cast < TDMPlayerInfo@ > (team.spawns[i]);

				UpdateSpawnTime(info, i);
				DoSpawnPlayer(info);
			}
		}
	}

	void UpdateSpawnTime(TDMPlayerInfo@ info, int i)
	{
		//default
		u8 spawn_property = 254;

		//flag for no respawn
		bool huge_respawn = info.can_spawn_time >= 0x00ffffff;
		bool no_respawn = TDM_core.rules.isMatchRunning() ? huge_respawn : false;
		if (no_respawn)
		{
			spawn_property = 253;
		}

		if (i == 0 && info !is null && info.can_spawn_time > 0 && !no_respawn)
		{
			if (huge_respawn)
			{
				info.can_spawn_time = 5;
			}

			info.can_spawn_time--;
			spawn_property = u8(Maths::Min(250, (info.can_spawn_time / 30)));
		}

		string propname = "tdm spawn time " + info.username;
		TDM_core.rules.set_u8(propname, spawn_property);
		if (info !is null && info.can_spawn_time >= 0)
		{
			TDM_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));
		}
	}

	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		if (force || (canSpawnPlayer(p_info) && (ticketsRemaining(getRules(), p_info.team) > 0) || getPlayersCount() < 2))
		{
			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

			if (player is null)
			{
				RemovePlayerFromSpawn(p_info);
				return;
			}
			if (player.getTeamNum() != int(p_info.team))
			{
				player.server_setTeamNum(p_info.team);
			}

			// remove previous players blob
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer(null);
				blob.server_Die();
			}

			CBlob@ playerBlob = SpawnPlayerIntoWorld(getSpawnLocation(p_info), p_info);

			if (playerBlob !is null)
			{
				// spawn resources
				p_info.spawnsCount++;
				RemovePlayerFromSpawn(player);
				if (getGameTime() >= 300 && !getRules().isWarmup())
				{
					//CBlob@ b = getBlobByName("pointflag");
					//if (b is null)
						decrementTickets(getRules(), playerBlob.getTeamNum());
				}

				if (getMap().getMapName() == "KAWWTraining.png")
				{	
					playerBlob.server_setTeamNum(2);
				}	
			}
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		TDMPlayerInfo@ info = cast < TDMPlayerInfo@ > (p_info);

		if (info is null) {return false;}

		if (force) { return true; }

		return info.can_spawn_time == 0;
	}

	Vec2f getSpawnLocation(PlayerInfo@ p_info)
	{
		CBlob@[] spawns;
		CBlob@[] teamspawns;

		if (getBlobsByName("tent", @spawns))
		{
			for (uint step = 0; step < spawns.length; ++step)
			{
				if (spawns[step].getTeamNum() == s32(p_info.team) || getMap().getMapName() == "KAWWTraining.png")
				{
					teamspawns.push_back(spawns[step]);
				}
			}
		}

		if (teamspawns.length > 0)
		{
			int spawnindex = XORRandom(997) % teamspawns.length;
			return teamspawns[spawnindex].getPosition();
		}

		return Vec2f(0, 0);
	}

	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
	}

	void RemovePlayerFromSpawn(PlayerInfo@ p_info)
	{
		TDMPlayerInfo@ info = cast < TDMPlayerInfo@ > (p_info);

		if (info is null) {return;}

		string propname = "tdm spawn time " + info.username;

		for (uint i = 0; i < TDM_core.teams.length; i++)
		{
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (TDM_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				team.spawns.erase(pos);
				break;
			}
		}

		TDM_core.rules.set_u8(propname, 255);   //not respawning
		TDM_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));

		info.can_spawn_time = 0;
	}

	void AddPlayerToSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		u32 tickspawndelay = (Maths::Max(4, 8-(getPlayersCount()/3)))*30;

		TDMPlayerInfo@ info = cast < TDMPlayerInfo@ > (core.getInfoFromPlayer(player));

		if (info is null) {return;}

		if (info.team < TDM_core.teams.length)
		{
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (TDM_core.teams[info.team]);

			info.can_spawn_time = tickspawndelay;
			team.spawns.push_back(info);
		}
	}

	bool isSpawning(CPlayer@ player)
	{
		TDMPlayerInfo@ info = cast < TDMPlayerInfo@ > (core.getInfoFromPlayer(player));
		for (uint i = 0; i < TDM_core.teams.length; i++)
		{
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (TDM_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				return true;
			}
		}
		return false;
	}
};

shared class TDMCore : RulesCore
{
	s32 warmUpTime;
	s32 gameDuration;
	s32 spawnTime;
	s32 minimum_players_in_team;
	s32 kills_to_win;
	s32 kills_to_win_per_player;
	bool all_death_counts_as_kill;
	bool sudden_death;

	s32 players_in_small_team;
	bool scramble_teams;

	TDMSpawns@ tdm_spawns;

	TDMCore() {}

	TDMCore(CRules@ _rules, RespawnSystem@ _respawns)
    {
        super(_rules, _respawns);
        
        for(u8 team_num = 0; team_num < teams.length; team_num++)
        {
            TDMTeamInfo@ team = cast < TDMTeamInfo@ > (teams[team_num]);
            for(u16 i = 0; i < team.spawns.size(); i++)
            {
                TDMPlayerInfo@ info = cast < TDMPlayerInfo@ > (team.spawns[i]);
                info.blob_name = (XORRandom(512) >= 256 ? "ranger" : "shotgun");
            }
        }
    }

	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		gametime = getGameTime() + 100;
		@tdm_spawns = cast < TDMSpawns@ > (_respawns);
		server_CreateBlob("Entities/Meta/TDMMusic.cfg");
		players_in_small_team = -1;
		all_death_counts_as_kill = false;
		sudden_death = false;

		sv_mapautocycle = true;
	}

	int gametime;
	void Update()
	{
		//HUD
		// lets save the CPU and do this only once in a while
		if (getGameTime() % 16 == 0)
		{
			updateHUD();
		}

		if (rules.isGameOver()) { return; }

		s32 ticksToStart = gametime - getGameTime();

		tdm_spawns.force = false;

		if (ticksToStart <= 0 && (rules.isWarmup()))
		{
			rules.SetCurrentState(GAME);
		}
		else if (ticksToStart > 0 && rules.isWarmup()) //is the start of the game, spawn everyone + give mats
		{
			rules.SetGlobalMessage(""); //Starting in {SEC} seconds!
			//rules.AddGlobalMessageReplacement("SEC", "" + ((ticksToStart / 30) + 1));
			tdm_spawns.force = true;

			//set kills and cache #players in smaller team

			if (players_in_small_team == -1 || (getGameTime() % 30) == 4)
			{
				players_in_small_team = 100;

				for (uint team_num = 0; team_num < teams.length; ++team_num)
				{
					TDMTeamInfo@ team = cast < TDMTeamInfo@ > (teams[team_num]);

					if (team.players_count < players_in_small_team)
					{
						players_in_small_team = team.players_count;
					}
				}

				kills_to_win = Maths::Max(players_in_small_team, 1) * kills_to_win_per_player;
			}
		}

		if ((rules.isIntermission() || rules.isWarmup()) && (!allTeamsHavePlayers()))  //CHECK IF TEAMS HAVE ENOUGH PLAYERS
		{
			gametime = getGameTime() + warmUpTime;
			rules.set_u32("game_end_time", gametime + gameDuration);
			rules.SetGlobalMessage("Waiting for someone else to join the game.");
			tdm_spawns.force = true;
		}
		else if (rules.isMatchRunning() && getMap().getMapName() == "KAWWTraining.png")
		{
			rules.SetGlobalMessage("Type !start to begin the match!");
		}
		else if (rules.isMatchRunning())
		{
			rules.SetGlobalMessage("");
		}

		RulesCore::Update(); //update respawns
		if (getPlayersCount() >= 6) CheckTeamWon();
	}

	void updateHUD()
	{
		bool hidekills = (rules.isIntermission() || rules.isWarmup());
		CBitStream serialised_team_hud;
		serialised_team_hud.write_u16(0x5afe); //check bits

		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			TDM_HUD hud;
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (teams[team_num]);
			hud.team_num = team_num;
			hud.kills = team.kills;
			hud.kills_limit = -1;
			if (!hidekills)
			{
				if (kills_to_win <= 0)
					hud.kills_limit = -2;
				else
					hud.kills_limit = kills_to_win;
			}

			string temp = "";

			for (uint player_num = 0; player_num < players.length; ++player_num)
			{
				TDMPlayerInfo@ player = cast < TDMPlayerInfo@ > (players[player_num]);

				if (player.team == team_num)
				{
					CPlayer@ e_player = getPlayerByUsername(player.username);

					if (e_player !is null)
					{
						CBlob@ player_blob = e_player.getBlob();
						bool blob_alive = player_blob !is null && player_blob.getHealth() > 0.0f;

						if (blob_alive)
						{
							string player_char = "k"; //default to sword

							if (player_blob.getName() == "archer")
							{
								player_char = "k";
							}

							temp += player_char;
						}
						else
						{
							temp += "s";
						}
					}
				}
			}

			hud.unit_pattern = temp;

			bool set_spawn_time = false;
			if (team.spawns.length > 0 && !rules.isIntermission())
			{
				u32 st = cast < TDMPlayerInfo@ > (team.spawns[0]).can_spawn_time;
				if (st < 200)
				{
					hud.spawn_time = (st / 30);
					set_spawn_time = true;
				}
			}
			if (!set_spawn_time)
			{
				hud.spawn_time = 255;
			}

			hud.Serialise(serialised_team_hud);
		}

		rules.set_CBitStream("tdm_serialised_team_hud", serialised_team_hud);
		rules.Sync("tdm_serialised_team_hud", true);
	}

	//HELPERS

	bool allTeamsHavePlayers()
	{
		for (uint i = 0; i < teams.length; i++)
		{
			if (teams[i].players_count < minimum_players_in_team)
			{
				return false;
			}
		}

		return true;
	}

	//team stuff

	void AddTeam(CTeam@ team)
	{
		TDMTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
	{
		TDMPlayerInfo p(player.getUsername(), player.getTeamNum(), player.isBot() ? "ranger" : (XORRandom(512) >= 256 ? "ranger" : "ranger"));
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
	}

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
    {
        if (!rules.isMatchRunning() && !all_death_counts_as_kill) return;

        if (victim !is null)
        {
            if (killer !is null && killer.getTeamNum() != victim.getTeamNum())
            {
                addKill(killer.getTeamNum());
            }
            else if (all_death_counts_as_kill)
            {
                for (int i = 0; i < rules.getTeamsNum(); i++)
                {
                    if (i != victim.getTeamNum())
                    {
                        addKill(i);
                    }
                }
            }
        }
    }

	void onSetPlayer(CBlob@ blob, CPlayer@ player)
	{
		if (blob !is null && player !is null)
		{
			GiveSpawnResources(blob, player);
		}
	}

	//setup the TDM bases

	void SetupBase(CBlob@ base)
	{
		if (base is null)
		{
			return;
		}
	}

	void SetupBases()
	{
		const string base_name = "tent";

		string map_name = getMap().getMapName();
		
		// destroy all previous spawns if present
		CBlob@[] oldBases;
		getBlobsByName(base_name, @oldBases);

		for (uint i = 0; i < oldBases.length; i++)
		{
			oldBases[i].server_Die();
		}
		
		//spawn the spawns :D
		CMap@ map = getMap();

		if (map !is null)
		{
			Vec2f[] respawnPositions;
			Vec2f respawnPos;

			if (map_name == "KAWWTraining.png")
			{
				if (!getMap().getMarkers("training main spawn", respawnPositions))
				{
					respawnPos = Vec2f(50.0f, map.getLandYAtX(50.0f / map.tilesize) * map.tilesize - 32.0f);
					SetupBase(server_CreateBlob(base_name, 2, respawnPos));
				}
			}
			else
			{
				//BLUE
				if (!getMap().getMarkers("blue main spawn", respawnPositions))
				{
					respawnPos = Vec2f(150.0f, map.getLandYAtX(150.0f / map.tilesize) * map.tilesize - 32.0f);
					SetupBase(server_CreateBlob(base_name, 0, respawnPos));
				}
				else
				{
					for (uint i = 0; i < respawnPositions.length; i++)
					{
						respawnPos = respawnPositions[i];
						SetupBase(server_CreateBlob(base_name, 0, respawnPos));
					}
				}

				respawnPositions.clear();

				//RED
				if (!getMap().getMarkers("red main spawn", respawnPositions))
				{
					respawnPos = Vec2f(map.tilemapwidth * map.tilesize - 150.0f, map.getLandYAtX(map.tilemapwidth - (150.0f / map.tilesize)) * map.tilesize - 32.0f);
					SetupBase(server_CreateBlob(base_name, 1, respawnPos));
				}
				else
				{
					for (uint i = 0; i < respawnPositions.length; i++)
					{
						respawnPos = respawnPositions[i];
						SetupBase(server_CreateBlob(base_name, 1, respawnPos));
					}
				}
			}

			respawnPositions.clear();
		}
		
		rules.SetCurrentState(WARMUP);
	}

	//checks
	void CheckTeamWon()
	{
		if (!rules.isMatchRunning()) { return; }

		//print("ROUND: " + rules.get_u8("current_round"));

		int winteamIndex = -1;
		TDMTeamInfo@ winteam = null;
		s8 team_wins_on_end = -1;

		int highkills = 0;
		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (teams[team_num]);

			if (team.kills > highkills)
			{
				highkills = team.kills;
				team_wins_on_end = team_num;

				if (team.kills >= kills_to_win)
				{
					@winteam = team;
					winteamIndex = team_num;
				}
			}
			else if (team.kills > 0 && team.kills == highkills)
			{
				team_wins_on_end = -1;
			}
		}

		//sudden death mode - check if anyone survives
		if (sudden_death)
		{
			//clear the winning team - we'll find that ourselves
			@winteam = null;
			winteamIndex = -1;

			//set up an array of which teams are alive
			array<bool> teams_alive;
			s32 teams_alive_count = 0;
			for (int i = 0; i < teams.length; i++)
				teams_alive.push_back(false);

			//check with each player
			for (int i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				CBlob@ b = p.getBlob();
				s32 team = p.getTeamNum();
				if (b !is null && !b.hasTag("dead") && //blob alive
				        team >= 0 && team < teams.length) //team sensible
				{
					if (!teams_alive[team])
					{
						teams_alive[team] = true;
						teams_alive_count++;
					}
				}
			}

			//only one team remains!
			if (teams_alive_count == 1)
			{
				for (int i = 0; i < teams.length; i++)
				{
					if (teams_alive[i])
					{
						@winteam = cast < TDMTeamInfo@ > (teams[i]);
						winteamIndex = i;
						team_wins_on_end = i;
					}
				}
			}
			//no teams survived, draw
			if (teams_alive_count == 0)
			{
				rules.SetTeamWon(-1);   //game over!
				rules.SetCurrentState(GAME_OVER);
				rules.SetGlobalMessage("It's a tie!");
				return;
			}
		}

		rules.set_s8("team_wins_on_end", team_wins_on_end);

		if (winteamIndex >= 0)
		{
			// add winning team coins
			if (rules.isMatchRunning())
			{
				CBlob@[] players;
				getBlobsByTag("player", @players);
				for (uint i = 0; i < players.length; i++)
				{
					CPlayer@ player = players[i].getPlayer();
					if (player !is null)
					{
						if (player.getTeamNum() == winteamIndex)
						{
							player.server_setCoins(player.getCoins() + 30);
						}	
					}
				}
			}

			rules.SetTeamWon(winteamIndex);   //game over!
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage("{WINNING_TEAM} wins the round!");
			rules.AddGlobalMessageReplacement("WINNING_TEAM", winteam.name);
			SetCorrectMapTypeShared();
		}
	}

	void addKill(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			TDMTeamInfo@ team_info = cast < TDMTeamInfo@ > (teams[team]);
			team_info.kills++;
		}
	}

	void GiveSpawnResources(CBlob@ blob, CPlayer@ player)
	{
		if (!(blob.getName() == "antitank") && blob.getName() == "revolver" || blob.getName() == "medic" || blob.getName() == "mp5" || blob.getName() == "sniper" || blob.getName() == "ranger" || blob.getName() == "shotgun")
		{
			// first check if its in surroundings
			CBlob@[] blobsInRadius;
			CMap@ map = getMap();
			bool found = false;
			if (!blob.hasBlob("mat_7mmround", 1))
			{
				if (map.getBlobsInRadius(blob.getPosition(), 100.0f, @blobsInRadius))
				{
					for (uint i = 0; i < blobsInRadius.length; i++)
					{
						CBlob @b = blobsInRadius[i];
						if (b.getName() == "mat_7mmround")
						{
							found = true;
							if (!found)
							{
								blob.server_PutInInventory(b);
							}
							else
							{
								b.server_Die();
							}
						}
					}
				}

				if (!found)
				{
					CBlob@ mat = server_CreateBlob("mat_7mmround");
					if (mat !is null)
					{
						if (!blob.server_PutInInventory(mat))
						{
							mat.setPosition(blob.getPosition());
						}
					}
				}
			}
		}
	}


	void SetCorrectMapTypeShared()
	{
		if (getPlayersCount() <= 4)
		{
			LoadMapCycle("MAPS/mapcyclesmaller.cfg");
			print(">Loading smaller map");
		}
		else if (getPlayersCount() < 11)
		{
			LoadMapCycle("MAPS/mapcycle.cfg");
			print(">Loading medium map");
		}
		else
		{
			LoadMapCycle("MAPS/mapcyclelarger.cfg");
			print(">Loading larger map");
		}
	}
};

void SetCorrectMapType()
{
	if (getPlayersCount() <= 4)
	{
		LoadMapCycle("MAPS/mapcyclesmaller.cfg");
		print(">Loading smaller map");
	}
	else if (getPlayersCount() < 11)
	{
		LoadMapCycle("MAPS/mapcycle.cfg");
		print(">Loading medium map");
	}
	else
	{
		LoadMapCycle("MAPS/mapcyclelarger.cfg");
		print(">Loading larger map");
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    if (player == null) { return; }

    if (player.getCoins() != 0)
    {
        cfg_playercoins.add_u32(player.getUsername(), player.getCoins());
    }
    else if (cfg_playercoins.exists(player.getUsername()))
    {
        cfg_playercoins.remove(player.getUsername());
    }
}

//pass stuff to the core from each of the hooks
void Reset(CRules@ this)
{
	SetCorrectMapType();

	string configstr = "Rules/CTF/ctf_vars.cfg";
	ConfigFile cfg = ConfigFile(configstr);
	if (cfg.read_s32("game_time") != -2)
	{
		Reset(this);
	}

	TDMSpawns spawns();
	TDMCore core(this, spawns);
	Config(core);
	core.SetupBases();
	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time", getGameTime() + core.gameDuration);
	this.set_s32("restart_rules_after_game_time", (core.spawnTime < 0 ? 5 : 10) * 20);

	u8 randtime = XORRandom(101); // 0 to 100
	if (randtime < 11) // bad conditions / night
	{
		printf("night");
		getMap().SetDayTime(Maths::Abs(-0.18 + XORRandom(5)*0.05f));
	}
	else if (randtime < 38) // moderate or normal
	{
		printf("moderate");
		getMap().SetDayTime(0.4f + XORRandom(30)*0.05f);
	}
	else // normal daytime
	{
		printf("normal");
		getMap().SetDayTime(0.8f);
	}
	print("TIME: " + getMap().getDayTime());
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    uint32 playercoins = 0;
    if (cfg_playercoins.exists(player.getUsername()))
    {
        playercoins = cfg_playercoins.read_u32(player.getUsername());
    }

    player.server_setCoins(40);

    print("New player joined.");
}

void onTick(CRules@ this)
{
	if (getGameTime() % 1800 == 0)
    {
    	uint16 i;
    	
        for (i = 0; i < getPlayerCount(); i++)
        {
            CPlayer@ player = getPlayer(i);
            if (player.getCoins() != 0)
            {
                cfg_playercoins.add_u32(player.getUsername(), (player.getCoins()));
            }
        }

        cfg_playercoins.saveFile("KAWW_Coins.cfg");
    }
	if (getGameTime()%150==0) //every 5 seconds give a coin
	{
		if (this.get_s16("blueTickets") > 120) 
		{
			this.set_s16("blueTickets", 120);
			this.Sync("blueTickets", true);
		}
		if (this.get_s16("redTickets") > 120)
		{
			this.set_s16("redTickets", 120);
			this.Sync("redTickets", true);
		}
		for (u16 i = 0; i < getPlayerCount(); i++)
        {
            CPlayer@ player = getPlayer(i);
			if (player is null) continue;
            if (isServer())
            {
                player.server_setCoins(player.getCoins()+1);
            }
        }
	}
}

void onInit(CRules@ this)
{
	this.set_u8("current_round", 1);

	//this.addCommandID("send_chat");

	if ( !cfg_playercoins.loadFile("../Cache/KAWW_Coins.cfg") )
    {
        cfg_playercoins = ConfigFile("KAWW_Coins.cfg");
    }

    if ( !cfg_playertechs.loadFile("../Cache/KAWW_Techs.cfg") )
    {
        cfg_playertechs = ConfigFile("KAWW_Techs.cfg");
    }

	this.addCommandID("flag_cap_won");

	Reset(this);
}