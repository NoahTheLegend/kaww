#define SERVER_ONLY

#include "TDM_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";
#include "Hitters.as";
#include "HittersAW.as";
#include "PlayerRankInfo.as";

const u8 MAX_BOTS = 8; // fills while server's pop is lesser than value

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
			printf("decrease by 2");
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
			printf("decrease by 2");
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
			this.SetTeamWon( teamleft ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(teamleft).getName() + " wins the game!\n\nWell done. Loading next map..." );
			return true;
		}else if(teamNum==this.get_u8("teamright")){
			if(this.get_s16("teamLeftTickets")>0) return false;
			if(isPlayersLeft(this, teamNum)) return false;
			if(this.getCurrentState()==GAME_OVER) return true;
			this.SetTeamWon( teamright ); //game over!
			this.SetCurrentState(GAME_OVER);
			this.SetGlobalMessage( this.getTeam(teamright).getName() + " wins the game!\n\nWell done. Loading next map..." );
			return true;
		}
	
	return false;
}

string cost_config_file = "tdm_vars.cfg";

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
	f32 gameDurationMinutes = 15.0f + getPlayersCount()*3.0; //cfg.read_f32("gameDurationMinutes", 7.0f)
	
	// basic time
	this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes) + this.warmUpTime;
	// tdm map time
	if (getMap() !is null && getMap().tilemapwidth <= 300)  this.gameDuration = (getTicksASecond() * 60 * 15.0f) + this.warmUpTime;
	// siege time
	CBlob@[] vehbuilders;
    getBlobsByName("vehiclebuilder", @vehbuilders);
    if (vehbuilders.length == 1) 
    {
		CBlob@[] flags;
        getBlobsByName("pointflag", @flags);
		if (flags.length > 1)
		{
			this.gameDuration = (getTicksASecond() * 60 * (10.0f+(0.5*flags.length)+(0.25f*getPlayersCount()))) + this.warmUpTime;
		}
	}

	//this.gameDuration = (getTicksASecond() * 60 * 1.25f);

	//spawn after death time - set in gamemode.cfg, or override here
	f32 spawnTimeSeconds = cfg.read_f32("spawnTimeSeconds", 2); 
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
			if (team_num != getRules().get_u8("teamleft") && team_num != getRules().get_u8("teamright"))
			{
				continue;
			}
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
				player.server_setTeamNum(int(p_info.team));
				printf("New player team: "+int(p_info.team));
			}

			bool isTDM = (getMap().tilemapwidth <= 300);

			string[] blocked_classes = {
				"lmg",
				"firebringer",
				"rpg"
			}; // i berate myself for doing this in so way but i am too lazy to bind this small feature to InitClasses()
			if (player.exists("last_class")
				&& (!isTDM || blocked_classes.find(player.get_string("last_class")) == -1))
			{
				p_info.blob_name = player.get_string("last_class");
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
					CBlob@ b = getBlobByName("pointflag");
					CBlob@[] tents;
					getBlobsByName("tent", @tents);
					if (!(XORRandom(100) < 50 && getRules().get_string(player.getUsername()+"_perk") == "Death Incarnate"))
					{
						if (b is null && tents.length > 0)
							decrementTickets(getRules(), playerBlob.getTeamNum());
					}
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

		CPlayer@ p = getPlayerByUsername(p_info.username);
		//printf(""+p.get_u16("spawnpick"));
		//if (p is null || getBlobByNetworkID(p.get_u16("spawnpick")) is null)
		//{
		//	printf("NULL");
		//}
		CBlob@ sp = getBlobByNetworkID(p.get_u16("spawnpick"));
		if (p !is null && sp !is null
		&& sp.get_u16("capture time") == 0
		&& p.getTeamNum() == sp.getTeamNum())
		{// && getBlobByNetworkID(p.get_u16("spawnpick")).hasTag("spawn")
			//printf("done");
			CBlob@ b = getBlobByNetworkID(p.get_u16("spawnpick"));
			if (b.getName() == "outpost") b.server_Hit(b, b.getPosition(), Vec2f(0,0), b.getInitialHealth()/(b.get_u16("max_respawns")+1), Hitters::builder);
			teamspawns.push_back(b);
			return b.getPosition();
		}
		else if (getBlobsByName("tent", @spawns) || getBlobsByTag("importantarmory", @spawns))
		{
			for (uint step = 0; step < spawns.length; ++step)
			{
				if (spawns[step].getTeamNum() == s32(p_info.team))
				{
					teamspawns.push_back(spawns[step]);
				}
			}
			//printf("wtf?");
		}
		//printf("out");

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

		bool federation_power = getRules().get_bool("enable_powers") && player.getTeamNum() == 1; // team 1 buff
    	u32 extra_amount = 0;
    	if (federation_power) extra_amount = 30;

		if (info.team < TDM_core.teams.length)
		{
			TDMTeamInfo@ team = cast < TDMTeamInfo@ > (TDM_core.teams[info.team]);

			info.can_spawn_time = tickspawndelay-extra_amount;
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

				//print("1" + info);
				//print("2" + team.spawns[i]);

				array<string> classes = {
					"revolver",
					"ranger",
					"shotgun",
					"sniper",
					"mp5",
					"lmg",
					"shielder"
					};
				
				float exp = _rules.get_u32(info.username + "_exp");
				int unlocked = 0;

				// Calculate the exp required to reach each level
				for (int i = 1; i <= 6; i++)
				{
					if (exp >= getExpToNextLevelShared(i)) unlocked ++;
					else break;
				}
				unlocked = Maths::Min(unlocked, 4);
				int index = Maths::Min(XORRandom(classes.length), unlocked);
				string line = classes[index];

				if (_rules.get_string("map_name") == "Abacus") {
					line = "revolver";
				}

                info.blob_name = line;
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

		if ((rules.get_string("map_name") != "Abacus") && ((rules.isIntermission() || rules.isWarmup()) && (!allTeamsHavePlayers())))  //CHECK IF TEAMS HAVE ENOUGH PLAYERS
		{
			gametime = getGameTime() + warmUpTime;
			rules.set_u32("game_end_time", gametime + gameDuration);
			rules.SetGlobalMessage("Waiting for someone else to join the game.");
			tdm_spawns.force = true;
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

						if (blob_alive) temp += "k";
						else temp += "s";
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
			u8 teamleft = getRules().get_u8("teamleft");
			u8 teamright = getRules().get_u8("teamright");

			if (teams[i].index != teamleft && teams[i].index != teamright) continue;
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
		array<string> classes = {
		"revolver",
		"ranger",
		"shotgun",
		"sniper",
		"mp5"
		};
		
		float exp = getRules().get_u32(player.getUsername() + "_exp");
		int unlocked = 0;

		// Calculate the exp required to reach each level
		for (int i = 1; i <= 6; i++)
		{
			if (exp >= getExpToNextLevelShared(i)) unlocked ++;
			else break;
		}
		unlocked = Maths::Min(unlocked, 4);
		int index = Maths::Min(XORRandom(classes.length), unlocked);
		string line = classes[index];

		if (getRules().get_string("map_name") == "Abacus") {
			line = "revolver";
		}

		TDMPlayerInfo p(player.getUsername(), player.getTeamNum(), line);
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
				if (victim.getTeamNum() == getRules().get_u8("teamright"))
				{
					rules.add_u16("teamleft_kills", 1);
					rules.Sync("teamleft_kills", true);
				}
				else if (victim.getTeamNum() == getRules().get_u8("teamleft"))
				{
					rules.add_u16("teamright_kills", 1);
					rules.Sync("teamright_kills", true);
				}
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
		if (!blob.isBot() && getPlayersCount() == 1)
		{
			getRules().Tag("firstjoin");
		}
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
		Vec2f[] respawnPositions;
		Vec2f[] temp;
		CBlob@[] tents;
        getBlobsByName("tent", @tents);
		string spawn_prop = "tent";
		// adding markers directly to array will cause doubled blue tents if there are more than 1
		if (!getMap().getMarkers("blue main spawn", temp) && !getMap().getMarkers("red main spawn", temp))
			spawn_prop = "importantarmory";
		//else
		//{
			//getMap().getMarkers("blue main spawn", respawnPositions);
			//getMap().getMarkers("red main spawn", respawnPositions);
		//}

		const string base_name = spawn_prop;

		string map_name = getMap().getMapName();
		
		// destroy all previous spawns if present
		if (spawn_prop != "importantarmory")
		{
			CBlob@[] oldBases;
			getBlobsByName(base_name, @oldBases);

			for (uint i = 0; i < oldBases.length; i++)
			{
				oldBases[i].server_Die();
			}
		}
		
		string[] maps = {
			"Desert.png",
		   	"WinterFactory.png",
		   	"Touge.png",
		   	"Mortar.png",
		   	"Syria.png",
		   	"Cavern.png",
		   	"Selfish_goldy.png",
		   	"Goldy_KAWW_Megalith.png",
		   	"Valley.png",
		   	"Foothills.png",
		   	"PlainHills.png",
		   	"Worldwar.png",
		   	"Classic.png",
		   	"SmallClassic.png",
		   	"Moats.png",
		   	"Canyon.png",
		   	"OldTouge.png",
		   	"Fugue.png",
		   	"Vietnam.png",
		   	"FragFest.png",
		   	"Florida.png",
		   	"SoldiercombatTDM.png",
		   	"Flattening.png",
		   	"RooftopTanks_v2.png",
		};

		//spawn the spawns :D
		CMap@ map = getMap();

		if (map !is null)
		{
			Vec2f respawnPos;
			if (map.tilemapwidth == 0 || map.tilemapheight == 0)
			{
				warn("tilemapwidth|height is 0!!!");
				LoadMap(maps[XORRandom(maps.length)]);
				return;
			}

			//BLUE
			if (!getMap().getMarkers("blue main spawn", respawnPositions))
			{
				respawnPos = Vec2f(150.0f, map.getLandYAtX(150.0f / map.tilesize) * map.tilesize - 32.0f);
				if (spawn_prop != "importantarmory")  SetupBase(server_CreateBlob(base_name, getRules().get_u8("teamleft"), respawnPos));
			}
			else
			{
				for (uint i = 0; i < respawnPositions.length; i++)
				{
					respawnPos = respawnPositions[i];
					if (spawn_prop != "importantarmory")  SetupBase(server_CreateBlob(base_name, getRules().get_u8("teamleft"), respawnPos));
				}
			}

			respawnPositions.clear();

			//RED
			if (!getMap().getMarkers("red main spawn", respawnPositions))
			{
				respawnPos = Vec2f(map.tilemapwidth * map.tilesize - 150.0f, map.getLandYAtX(map.tilemapwidth - (150.0f / map.tilesize)) * map.tilesize - 32.0f);
				if (spawn_prop != "importantarmory")  SetupBase(server_CreateBlob(base_name, getRules().get_u8("teamright"), respawnPos));
			}
			else
			{
				for (uint i = 0; i < respawnPositions.length; i++)
				{
					respawnPos = respawnPositions[i];
					if (spawn_prop != "importantarmory") SetupBase(server_CreateBlob(base_name, getRules().get_u8("teamright"), respawnPos));
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

		int winteamIndex = -1;
		TDMTeamInfo@ winteam = null;
		s8 team_wins_on_end = -1;

		CBlob@[] flags;
		getBlobsByName("pointflag", @flags);
		bool flags_wincondition = flags.length > 0;

		if (flags_wincondition && getGameTime() >= rules.get_u32("game_end_time"))
		{
			if (rules.getCurrentState() != GAME_OVER)
			{
				CBlob@[] flags;
				getBlobsByName("pointflag", @flags);
	
				u8 teamright_flags = 0;
				u8 teamleft_flags = 0;
	
				for (u8 i = 0; i < flags.length; i++)
				{
					CBlob@ flag = flags[i];
					if (flag is null) continue;
					if (flag.getTeamNum() > 6) continue;
					flag.getTeamNum() == rules.get_u8("teamleft") ? teamleft_flags++ : teamright_flags++;
				}
				if (teamright_flags != teamleft_flags)
				{
					u8 team_won = (teamright_flags > teamleft_flags ? 1 : 0);
					CTeam@ teamis = rules.getTeam(team_won);
					rules.SetTeamWon(team_won);   //game over!
					rules.SetCurrentState(GAME_OVER);
					if (teamis !is null) rules.SetGlobalMessage(teamis.getName() + " wins the game!\nWell done. Loading next map..." );
				}
				else
				{
					rules.SetTeamWon(-1);   //game over!
					rules.SetCurrentState(GAME_OVER);
					rules.SetGlobalMessage("It's a tie!");
					return;
				}
			}
		}
		else if (getGameTime() >= rules.get_u32("game_end_time"))
		{
			if (rules.getCurrentState() != GAME_OVER)
			{
				u8 teamleft = getRules().get_u8("teamleft");
				u8 teamright = getRules().get_u8("teamright");
				//u16 teamleft_kills = getRules().get_u16("teamleft_kills");
				//u16 teamright_kills = getRules().get_u16("teamright_kills");
//
				//if (teamright_kills != teamleft_kills)
				//{
				//	u8 team_won = (teamright_kills > teamleft_kills ? 1 : 0);
				//	team_wins_on_end = team_won;
				//	CTeam@ teamis = rules.getTeam(team_won);
				//	rules.SetTeamWon(team_won);   //game over!
				//	rules.SetCurrentState(GAME_OVER);
				//	if (teamis !is null) rules.SetGlobalMessage(teamis.getName() + " wins the game! They have more kills!" );
				//}

				u16 teamleft_tickets = getRules().get_s16("teamLeftTickets");
				u16 teamright_tickets = getRules().get_s16("teamRightTickets");
				if (teamleft_tickets > teamright_tickets)
				{
					team_wins_on_end = 0;
					CTeam@ teamis = rules.getTeam(teamleft);
					rules.SetTeamWon(teamleft);   //game over!
					rules.SetCurrentState(GAME_OVER);
					if (teamis !is null) rules.SetGlobalMessage(teamis.getName() + " wins the game! They have more kills!" );		
				}
				else if (teamleft_tickets < teamright_tickets)
				{
					team_wins_on_end = 1;
					CTeam@ teamis = rules.getTeam(teamright);
					rules.SetTeamWon(teamright);   //game over!
					rules.SetCurrentState(GAME_OVER);
					if (teamis !is null) rules.SetGlobalMessage(teamis.getName() + " wins the game! They have more kills!" );		
				}
				else
				{
					rules.SetTeamWon(-1);   //game over!
					rules.SetCurrentState(GAME_OVER);
					rules.SetGlobalMessage("It's a tie!");
					return;
				}
				rules.set_s8("team_wins_on_end", team_wins_on_end);
				return;
			}
		}
		
		

		if (!flags_wincondition)
		{
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
				rules.SetTeamWon(winteamIndex);   //game over!
				rules.SetCurrentState(GAME_OVER);
				rules.SetGlobalMessage("{WINNING_TEAM} wins the game!\n\nWell done. Loading next map..." );
				rules.AddGlobalMessageReplacement("WINNING_TEAM", winteam.name);
				SetCorrectMapTypeShared();
			}
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
		if (!(blob.getName() == "rpg" || blob.getName() == "firebringer"))
		{
			// first check if its in surroundings
			CBlob@[] blobsInRadius;
			CMap@ map = getMap();
			bool found = false;
			if (!blob.hasBlob("ammo", 1))
			{
				if (map.getBlobsInRadius(blob.getPosition(), 164.0f, @blobsInRadius))
				{
					for (uint i = 0; i < blobsInRadius.length; i++)
					{
						CBlob @b = blobsInRadius[i];
						if (b.getName() == "ammo")
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

				{
					CBlob@ mat = server_CreateBlob("ammo");
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
		if (getPlayersCount() <= 8)
		{
			error("LOADING MAPCYCLE: SMALL");
			LoadMapCycle("mapcyclesmaller.cfg");
		}
		else if (getPlayersCount() <= 14)
		{
			error("LOADING MAPCYCLE: AVERAGE");
			LoadMapCycle("mapcycle.cfg");
		}
		else
		{
			error("LOADING MAPCYCLE: LARGE");
			LoadMapCycle("mapcyclelarger.cfg");
		}
	}
};

void SetCorrectMapType(const int pcount)
{
	if (pcount <= 8)
	{
		error("LOADING MAPCYCLE: SMALL");
		LoadMapCycle("mapcyclesmaller.cfg");
	}
	else if (pcount <= 14)
	{
		error("LOADING MAPCYCLE: AVERAGE");
		LoadMapCycle("mapcycle.cfg");
	}
	else
	{
		error("LOADING MAPCYCLE: LARGE");
		LoadMapCycle("mapcyclelarger.cfg");
	}
}

//pass stuff to the core from each of the hooks
void Reset(CRules@ this)
{
	this.set_u16("teamleft_kills", 0);
	this.set_u16("teamright_kills", 0);
	this.Sync("teamleft_kills", true);
	this.Sync("teamright_kills", true);

	SetCorrectMapType(getPlayersCount());

	if (getMap() !is null)
	{
		bool isTDM = (getMap().tilemapwidth <= 300);
		this.set_bool("enable_powers", !isTDM);
		this.Sync("enable_powers", true);
	}
	else
	{
		this.set_bool("enable_powers", true);
		this.Sync("enable_powers", true);
	}
	
	if (this.get_string("map_name") == "Abacus") {
		for (u16 i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p is null) continue;
			if (isServer()) p.server_setCoins(0);
		}
	} else {
		for (u16 i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p is null) continue;
			if (isServer()) p.server_setCoins(40);
		}
	}

	TDMSpawns spawns();
	TDMCore core(this, spawns);
	Config(core);
	core.SetupBases();
	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time", getGameTime() + core.gameDuration);
	this.set_s32("restart_rules_after_game_time", (core.spawnTime < 0 ? 5 : 10) * 30);

	u8 brightmod = getRules().get_u8("brightmod");
	// 0 full bright
	// 50 normal
	// 100 dark

	if (getMap() is null) return;
	u8 randtime = XORRandom(100) + 1; // 1 to 100
	if (randtime < 11) // bad conditions / night
	{
		getMap().SetDayTime(Maths::Abs(-0.18 + XORRandom(5)*0.05f));
	}
	else if (randtime < 38) // moderate or normal
	{
		getMap().SetDayTime(0.4f + XORRandom(30)*0.05f);
	}
	else // normal daytime
	{
		getMap().SetDayTime(0.8f);
	}

	if (brightmod == 100)
	{
		getMap().SetDayTime(0.5f);
	}
	if (brightmod == 0)
	{
		getMap().SetDayTime(0.03f);
	}
}

void onRestart(CRules@ this)
{
	WriteMatchInfo(this);
	Reset(this);
	this.set_u32("warn_extended_time", 0);
	this.set_bool("show_warn_extended_time", false);
}

u16 blobscreated = 0;
u16 blobsdestroyed = 0;

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (!isServer()) return;
	if (blob is null) return;

	string name = blob.getName();
	blobscreated++;
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (!isServer()) return;
	if (blob is null) return;

	string name = blob.getName();
	blobsdestroyed++;
}

void WriteMatchInfo(CRules@ this)
{
	if (!isServer()) return;
	if (getMap() is null) 
	{
		warn("Could not write match info: map is null");
		return;
	}
	
	this.add_u32("matches_passed", 1);
	this.add_u8("match_info", 1);
	if (this.get_u8("match_info") >= 5) this.set_u8("match_info", 0);

	u8 current = this.get_u8("match_info");
	error("SAVING FILE "+current);

	ConfigFile matches = ConfigFile();

	matches.add_string("map", getMap().getMapName());
	matches.add_u32("matches passed", this.get_u32("matches_passed"));
	int bots = 0;
	string[] players;
	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p is null) continue;
		if (p.isBot()) bots++;
		players.push_back(p.getCharacterName()+" | "+p.getUsername());
	}
	const u8 step = this.get_u8("match_info");
	const u8 playercount = getPlayersCount();
	matches.add_u32("playercount", playercount);
	matches.add_u32("botscount", bots);
	matches.addArray_string("players: ", players);
	matches.add_u32("gametime", getGameTime());
	matches.add_u32("step", step);
	matches.add_string("blobs", "created: "+blobscreated+" destroyed: "+blobsdestroyed);
	matches.saveFile("AW/matchinfo"+current+".cfg");
	matches.saveFile("AW/lastmatchinfo.cfg");

	blobscreated = 0;
	blobsdestroyed = 0;
}

const string[] names = {
	"narc-cop",
	"recruit-duck",
	"private-wolf",
	"megalith-goliath",
	"trilemma-mighty",
	"frenzy-man",
	"dread-light",
	"captin-cook",
	"sweety-rat",
	"dread-antson",
	"parachute-eagle",
	"aexetan-love",
	"astro-power",
	"prince-poppy",
	"grown-man",
	"bitchy-ranger",
	"giga-chad",
	"respectful-man",
	"furry-lover",
	"beer-enjoyer",
	"bronze-style",
	"sapphire-colossus",
	"godzilla-white",
	"duck-smith",
	"anvil-hands",
	"rock-listener",
	"nova-moon",
	"red-mushroom",
	"customer-guy",
	"purple-alien",
	"jumpy-froggy",
	"bio-spark",
	"burning-leo",
	"knuckle-joe",
	"sir-kibble",
	"combat-cobra",
	"strike-viper",
	"commando-clown",
	"klaus-cellerman",
	"betel-goose"
};

string uppercaseFirstLetter(string &in str)
{
    str[0] = str.toUpper()[0];
    return str;
}

string getRandomCharName()
{
	bool hasNumbersAtEnd = XORRandom(2)==0; // botname982
	bool upperCase = XORRandom(100)>33; // BotName
	bool underline = XORRandom(2)==0; // bot name // actually just space between
	bool viceVersa = XORRandom(3)==0; // more variance
	bool shuffle = XORRandom(2)==0; // get lastname from another pair
	
	string finalName = "Bot";
	string name = names[XORRandom(names.length)];
	string[] spl = name.split("-");
	
	string firstName = spl[0];
	string lastName = spl[1];

	if (shuffle)
	{
		string temp = names[XORRandom(names.length)];
		string[] spltemp = temp.split("-");
		lastName = spltemp[1];
	}
	if (viceVersa)
	{
		string temp = firstName;
		firstName = lastName;
		lastName = temp;
	}
	if (upperCase)
	{
		firstName = uppercaseFirstLetter(firstName);
		lastName = uppercaseFirstLetter(lastName);

		//string[] firstNameSpl = firstName.split(""); // crashes the game
		//firstName = "";
		//for (u8 i = 0; i < firstNameSpl.length; i++)
		//{
		//	if (i==0) firstNameSpl[i].toUpper();
		//	firstName = firstName+firstNameSpl[i];
		//}

		//string[] lastNameSpl = lastName.split("");
		//lastName = "";
		//for (u8 i = 0; i < lastNameSpl.length; i++)
		//{
		//	if (i==0) lastNameSpl[i].toUpper();
		//	lastName = lastName+lastNameSpl[i];
		//}
	}
	
	finalName = firstName+(underline?" ":"")+lastName;
	
	if (hasNumbersAtEnd)
	{
		finalName = finalName+(XORRandom(1000));
	}

	return finalName;
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	/*
	if (isServer())
	{
		int localtime = Time_Local();
		int regtime = player.getRegistrationTime();

		int reg_month = Time_Month(regtime);
		int reg_day = Time_MonthDate(regtime);
		int reg_year = Time_Year(regtime);

		int loc_month = Time_Month(localtime);
		int loc_day = Time_MonthDate(localtime);
		int loc_year = Time_Year(localtime);

		string[] exclusive_players = {
			"RazerZF",
			"simon2005"
		}; // Add exceptions here
	
		bool is_exclusive = false;
		for (u16 i = 0; i < exclusive_players.length; i++)
		{
			if (exclusive_players[i] == player.getUsername())
				is_exclusive = true;
		}

		//time is sec(60) * min(60) * hours(24)* daysfrom 1970-jan-01
		// 1 day = 86400  and  30 days = 2592000
		if (!is_exclusive && (localtime - regtime)<=2592000) // Ban people registered last 30days
		{
			CSecurity@ security = getSecurity();
			bool newban = security.checkAccess_Feature(player, "newban");
			//in security folder inside normal.cfg add newban; to end of features=
			// inside preium.cfg add newban; to end of features= if you want preium uses to also registered less than 2 months to be ban

			printf("new player Account age:"+ regtime + " regdate:" + reg_year + "-" + reg_month + "-" + reg_day + " checkAccess_Feature:" + newban + " HWID: "+player.server_getHWID());
			if(newban)
			{
				printf("|");
				printf("|");
				printf("|");
				printf("BANNING PLAYER WITH TOO YOUNG ACCOUNT AGE: "+player.getUsername());
				printf("|");
				printf("|");
				printf("|");
				BanPlayer(player, 60*100);
			}

		}
	}
	*/

	if (isServer() && player !is null && player.isBot())
	{
		player.server_setCharacterName(getRandomCharName());
		getRules().set_u32(player.getUsername() + "_exp", 2500+XORRandom(1250));
	}

	this.Sync("oldteamleft", true);
	this.Sync("oldteamright", true);
	this.Sync("teamleft", true);
	this.Sync("teamright", true);

	//if (getPlayersCount() == 5 || getPlayersCount() == 4)
	//{
	//	LoadMapCycle("MAPS/mapcycle.cfg");
	//}
	//else if (getPlayersCount() == 8 || getPlayersCount() == 9)
	//{
	//	LoadMapCycle("MAPS/mapcyclelarger.cfg");
	//}

    player.server_setCoins(40);

	if (cfg_playerexp.exists(player.getUsername()))
    {
		this.set_u32(player.getUsername() + "_exp", cfg_playerexp.read_u32(player.getUsername()));
	}
	else{
		this.set_u32(player.getUsername() + "_exp", 0);
	}

	if (player.getUsername() == "TheCustomerMan")
	{
		this.set_u32(player.getUsername() + "_exp", 38000);
	}

	float exp = this.get_u32(player.getUsername() + "_exp");
	this.Sync(player.getUsername() + "_exp", true);

	string rank = RANKS[0];

	// Calculate the exp required to reach each level
	for (int i = 1; i <= RANKS.length; i++)
	{
		if (exp >= getExpToNextLevel(i + 1)) {
			rank = RANKS[Maths::Min(i, RANKS.length-1)];
		}
		else {
			break;
			this.set_string(player.getUsername() + "_last_lvlup", rank);
		}
	}

	if (isServer())
	{
		print("New player joined ----------- Username: " + player.getUsername() + " IP: " + player.server_getIP());
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    if (player == null)
    	{ return; }

    if (this.get_u32(player.getUsername() + "_exp") > 0) // has more than 0 exp
    {
        cfg_playerexp.add_u32(player.getUsername(), this.get_u32(player.getUsername() + "_exp"));
    }
    //else if (cfg_playerexp.exists(player.getUsername())) // 0 exp for some reason, remove from cfg
    //{
    //    cfg_playerexp.remove(player.getUsername()); // could be destructive
    //} // passes randomly for some people sometimes

	if (getPlayersCount() == 1 || getPlayersCount() == 0)
	{
		warn("Last player left, quitting the game");
		if (isServer())
		{
			QuitGame();
			//printf("tried to quitgame tdm.as line 1353");
		}
	}

	if (isServer())
	{
		print("Player left ----------- Username: " + player.getUsername() + " IP: " + player.server_getIP());
	}
}

void onTick(CRules@ this)
{
	g_screenshake = true;

	//if (isServer() && getGameTime() > 5)
	//{
	//	u16 count = 0;
	//	u16 tempcount = 0;
	//	string name;
	//	u16 len = lastblobs.length;
	//	for (u16 i = 0; i < len; i++)
	//	{
	//		for (u16 j = 0; j < len; j++)
	//		{
	//			if (lastblobs[i] == lastblobs[j])
	//			{
	//				tempcount++;
	//				if (j == len-i && count < tempcount)
	//				{
	//					count = tempcount;
	//					name = lastblobs[i];
	//				}
	//			}
	//		}
	//		tempcount = 0;
	//	}
	//	string[] empty;
	//	lastblobs = empty;
//
	//	if (count > 30)
	//	{
	//		printf("WARNING: BLOB SPAMMED - "+count+" OF "+name);
	//		ConfigFile cfg = ConfigFile();
	//		if (!cfg.loadFile("../Cache/crash.cfg"))
	//		{
	//			cfg.add_string(name, name+": "+count);
	//			cfg.saveFile("crash.cfg");
	//		}
	//	}
	//}

	if (getGameTime() == 1)
	{
		ConfigFile map_ratios;
		if (isServer() && getMap() !is null && map_ratios !is null)
		{
 			if (!map_ratios.loadFile("../Cache/AW/mapratios.cfg"))
    		{
    		    map_ratios = ConfigFile("AW/mapratios.cfg");
    		}
			string mapname = getMap().getMapName();
			u16 current_amount = map_ratios.read_u16(mapname, 1);
			map_ratios.add_u16(mapname, current_amount+1);
			map_ratios.saveFile("AW/mapratios.cfg");
		}

		u16 count = 10 + getPlayersCount();
		if (this.get_s16("teamLeftTickets") == 0 && this.get_s16("teamRightTickets") == 0)
		{
			this.set_s16("teamLeftTickets", 10);
			this.set_s16("teamRightTickets", 10);
			this.Sync("teamLeftTickets", true);
			this.Sync("teamRightTickets", true);
		}
		else if (this.get_s16("teamLeftTickets") > count && this.get_s16("teamRightTickets") > count
		&& getMap() !is null && getMap().tilemapwidth <= 300)
		{
			this.set_s16("teamLeftTickets", count);
			this.set_s16("teamRightTickets", count);
			this.Sync("teamLeftTickets", true);
			this.Sync("teamRightTickets", true);
		}
	}
//
	//if (getGameTime() == 300)
	//{
	//	if (isServer() && blobcount >= 55000)
	//	{
	//		//for (u8 i = 0; i < getPlayersCount(); i++)
	//		//{
	//		//	CPlayer@ p = getPlayer(i);
	//		//	if (p !is null) getNet().DisconnectPlayer(p);
	//		//}
    //	
	//		SaveEXP(this);
//
	//		QuitGame();
	//	}
	//}
	//
	if (getGameTime() == 10)
	{
		u8 bots = 0; // count bots
		for (u8 i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p !is null && p.isBot())
			{
				bots++;
			}
		}

		if (bots > 0) // kickbots
		{
			u8 shouldkick = Maths::Abs(MAX_BOTS - (getPlayersCount_NotSpectator() + bots));
			
			if (shouldkick > 0)
			{
				int teamleftcount = 0;
				int teamrightcount = 0;
				for (u16 i = 0; i < getPlayerCount(); i++)
				{
					if (getPlayer(i).getTeamNum() == this.get_u8("teamleft"))
					{
						teamleftcount ++;
					}
					if (getPlayer(i).getTeamNum() == this.get_u8("teamright"))
					{
						teamrightcount ++;
					}
				}

				u8 kickteamflip = 0;
				if 		(teamleftcount > teamrightcount) { kickteamflip = this.get_u8("teamleft"); } // blue has more
				else if (teamleftcount < teamrightcount) { kickteamflip = this.get_u8("teamright"); } // red has more
				else 	{ kickteamflip = XORRandom(1); } // pick randomly
				
				//print("teamleftcount: " + teamleftcount);
				//print("teamrightcount: " + teamrightcount);

				// still a small issue with this in some cases
				
				for (u16 i = 0; i < getPlayerCount(); i++)
				{
					// shave off of applicable team
					CPlayer@ p = getPlayer(i);
					if (p !is null && p.isBot())
					{
						if (p.getTeamNum() == kickteamflip)
						{
							KickPlayer(p);
							shouldkick--;

							kickteamflip = Maths::Abs(p.getTeamNum() - 1);

							if (shouldkick < 1)
                            {
                                break;
                            }
						}
					}
				}
			}
		}
	}

	if (getGameTime() == 20 || this.hasTag("firstjoin"))
	{
		this.Untag("firstjoin");
		if (!this.hasTag("togglebots"))
		{
			// Bots are enabled
			// Fill server with bots on lowpop
			u8 bots = 0; // count bots
			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p !is null && p.isBot())
				{
					bots++;
				}
			}

			u8 playercount = getPlayersCount_NotSpectator();

			if (playercount > 0)
			{
				if (playercount + bots <= MAX_BOTS) // add bots
				{
					s8 remaining_bots = MAX_BOTS - (playercount + bots);
					for (u8 i = 0; i < remaining_bots; i++)
					{
						AddBot("Bot");
					}
				}
			}
		}
	}
	
	if (getGameTime() % 30 == 0)
	{
		CBlob@[] flags;
		getBlobsByName("pointflag", @flags);

		u8 teamleft_flags = 0;
		u8 teamright_flags = 0;
		for (u8 i = 0; i < flags.length; i++)
		{
			if (flags[i] !is null)
			{
				if (flags[i].getTeamNum() == this.get_u8("teamleft")) teamleft_flags++;
				else if (flags[i].getTeamNum() == this.get_u8("teamright")) teamright_flags++;
			}
		}
	}

	if (getGameTime() >= 1 && !this.hasTag("synced_time"))
	{
		TDMSpawns spawns();
		TDMCore core(this, spawns);
		Config(core);
		this.Tag("synced_time");
	}
	if (getGameTime()%150==0) //every 150 ticks give a coin
	{
		if (this.get_s16("teamLeftTickets") > 200) 
		{
			this.set_s16("teamLeftTickets", 200);
			this.Sync("teamLeftTickets", true);
		}
		if (this.get_s16("teamRightTickets") > 200)
		{
			this.set_s16("teamRightTickets", 200);
			this.Sync("teamRightTickets", true);
		}
		if (this.get_string("map_name") != "Abacus")
		{
			for (u16 i = 0; i < getPlayerCount(); i++)
			{
				CPlayer@ player = getPlayer(i);
				if (player is null || player.getBlob() is null) continue;
				if (isServer())
				{
					bool imperialists_power = getRules().get_bool("enable_powers") && player.getTeamNum() == 5; // team 5 buff
   					u8 extra_amount = 0;
   					if (imperialists_power && XORRandom(3)==0)
					{
						extra_amount = 1;
					}
					
					if (this.get_string(player.getUsername() + "_perk") == "Wealthy")
					{
						player.server_setCoins(player.getCoins()+2+extra_amount); // double
					}
					else
					{
						player.server_setCoins(player.getCoins()+1+extra_amount);
					}
				}
			}
		}
	}

	if (getGameTime() % 9000 == 0) // auto save exp every 5 minutes
    {
    	SaveEXP(this);
    }
}

void SaveEXP(CRules@ this)
{
	uint16 i;
    	
    for (i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
		if (player !is null)
		{
			if (this.get_u32(player.getUsername() + "_exp") != 0)
			{
				cfg_playerexp.add_u32(player.getUsername(), this.get_u32(player.getUsername() + "_exp"));
			}
		}
    }
	cfg_playerexp.saveFile("AW/exp.cfg");
}

void onInit(CRules@ this)
{
    if ( !cfg_playerexp.loadFile("../Cache/AW/exp.cfg") )
    {
        cfg_playerexp = ConfigFile("AW/exp.cfg");
    }

	this.set_u32("matches_passed", 0);
	this.set_u8("match_info", 0);

	if (isClient() && isServer()) this.Tag("togglebots"); // disable them on local automatically
	Reset(this);

	this.set("maptypes-classic", ClassicMaps);
	this.set("maptypes-large", LargeMaps);
	this.set("maptypes-average", AverageMaps);
	this.set("maptypes-flag", FlagMaps);
	this.set("maptypes-truck", TruckMaps);
	this.set("maptypes-tdm", TdmMaps);
}

const string[] ClassicMaps = {
	"Desert.png",
	"WinterFactory.png",
	"Touge.png",
	"Mortar.png",
	"Syria.png",
	"Selfish_goldy.png",
	"ClassicFlagless.png",
	"Moats.png"
};

const string[] LargeMaps = {
	"Desert.png",
	"WinterFactory.png",
	"Touge.png",
	"Mortar.png",
	"Syria.png",
	"Cavern.png",
	"Selfish_goldy.png",
	"Goldy_KAWW_Megalith.png",
	"Valley.png",
	"Foothills.png",
	"PlainHills.png",
	"Worldwar.png",
	"Classic.png",
	"SmallClassic.png",
	"Moats.png",
	"Canyon.png",
	"OldTouge.png",
	"Fugue.png",
	"Vietnam.png",
	"FragFest.png",
	"Florida.png",
	"SoldiercombatTDM.png",
	"Flattening.png",
	"RooftopTanks_v2.png",
	"Goldy_KAWW_Sewage.png",
	"BloodGulch.png",
	"WorldwarFlagless.png",
	"ClassicFlagless.png",
	"BridgeWater.png",
	"SiegeBeachWater_v2.png"
	"Taiga.png",
	"Spaceport.png",
	"SeaHalt.png"
	//"FrogsLudendorff.png"
};

const string[] AverageMaps = {
	"SmallCity.png",
	"SmallClassic.png",
	"SmallDesert.png",
	"SmallFactory.png",
	"SmallMoats.png",
	"SmallMortar.png",
	"SmallTouge.png",
	"PlainHills.png",
	"BloodGulch.png",
	"SoldiercombatTDM.png",
	"TheSmallCityTDM.png",
	"BridgeTDM.png",
	"KingslyCastleTDM.png",
	"TesfoMineTDM.png",
	"Airplane.png",
	"Battleship.png",
	"KnollTDM.png",
	"LandscapingTDM.png",
	"SoldiercombatTDM.png",
	"TheCityTDM.png",
	"TriPointTDM.png"
};

const string[] FlagMaps = {
	"WinterFactory.png",
	"Bridge.png",
	"Classic.png",
	"Goldy_KAWW_Megalith.png",
	"Mortar.png",
	"PlainHills.png",
	"Worldwar.png",
	"TriPointTDM.png"
};

const string[] TruckMaps = {
	"OldTouge.png",
	"Fugue.png",
	"Cavern.png",
	"Florida.png",
	"BloodGulch.png"
};

const string[] TdmMaps = {
	"DesertedTDM.png",
	"AztecTDM.png",
	"LandscapingTDM.png",
	"SmallSoldiercombatTDM.png",
	"TheSmallCityTDM.png",
	"KingslyCastleTDM.png",
	"BridgeTDM.png",
	"TrainTDM.png",
	"Airplane.png",
	"FarmTDM.png",
	"FarmOldTDM.png",
	"DesertedTDM.png",
	"DesertedFlagTDM.png",
	"TesfoMineTDM.png",
	"TomeTDM.png",
	"Battleship.png"
};