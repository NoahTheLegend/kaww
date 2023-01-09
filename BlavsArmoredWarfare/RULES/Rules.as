#define SERVER_ONLY
// RULES.as

// Config coin storage file
ConfigFile cfg_playercoins;

// 100 : aprox ~3 sec
u16 spawntimer = 200; //150 old

// Init welcome message
const string welcomeTag = "welcome box";
const string menu_prop = "open menu";


///          [ON INITIALIZATION]
///		~ Default class
///		~ Coin storage init
///
void onInit(CRules@ this)
{
	// Default class on spawn
	if (!this.exists("default class"))
	{
		this.set_string("default class", "skirmisher");
	}
	
    // Coin Storage System Initializing
    if ( !cfg_playercoins.loadFile("../Cache/Dunes_Coins.cfg") )
    {
        cfg_playercoins = ConfigFile("Dunes_Coins.cfg");
    }

    onRestart(this);
}


///          [ON PLAYER REQUEST SPAWN]
///		~ Set repawn timer
///
void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	// Only start respawning if you are not already respawning
	if (this.get_u16(player.getUsername() + "_timer") == 0)
	{
		this.set_u16(player.getUsername() + "_timer", spawntimer); 
	}
}


///          [Respawn]
///		~ Respawning
///		~ Setting correct team
///
CBlob@ Respawn(CRules@ this, CPlayer@ player)
{
	if (player !is null)
	{
		// Make an occupied teams array. 255 is too high to ever be used as a team, so it is the default
		array<uint8> teamarray(getPlayerCount(), 255);
		
		// For every player
		int i;
		for (i = 0; i < teamarray.get_length(); i++)
		{
			// Get the player
			CPlayer@ _player = getPlayer(i);

			// If the player doesn't exist, there is no team to add
			if (_player == null)
			{
				continue;
			}
			// If the player my own player, leave it blank (if your in your own team there is no need to say its occupied)
			else if(_player.getUsername() == player.getUsername())
			{
				continue;
			}
			
			// In the occupied team array, put the players team in.
			teamarray[i] = _player.getTeamNum();
		}

		// The variable which stores the team that will be assigned to the player
		uint8 assignedteam = 0;
		
		bool myteamoccupied = false;

		// For every player
		for (i = 0; i < teamarray.get_length(); i++)
		{
			// If another player has the same team as this player
			if (teamarray[i] == player.getTeamNum())
			{
				// Find a new team
				myteamoccupied = true;
				break;
			}
		}
		
		// If the players team is occupied, find a new team.
		if (myteamoccupied == true)
		{
			// Start checking every team if it has a player
			// For every possible team (excluding 0)
			for (i = 1; i < 255; i++)
			{
				// The team is not occupied by default
				bool occupied = false;
				// For every player
				for (int q = 0; q < teamarray.get_length(); q++)
				{
					//Are they in this team?
					if (teamarray[q] == i)
					{
						//This team is occupied, so lets stop checking this team
						occupied = true;
						break;
					}
				}
				
				//If the team we are currently checking is not occupied
				if (occupied == false)
				{
					//Assign the team to be the current team we are checking, and lets stop checking for teams without members
					assignedteam = i;
					break;
				}
			}
			player.server_setTeamNum(assignedteam);
		}
	
		// Remove previous players blob
		CBlob @blob = player.getBlob();

		if (blob !is null)
		{
			CBlob @blob = player.getBlob();
			blob.server_SetPlayer(null);
			blob.server_Die();
		}

		// Create player blob with correct class, team, and location.
		CBlob @newBlob = server_CreateBlob(this.get_string("default class"), player.getTeamNum(), getSpawnLocation(player));
		Sound::Play("/respawn.ogg", getSpawnLocation(player), 1.2f, 1.0f);
		newBlob.server_SetPlayer(player);
		return newBlob;
	}
	return null;
}


// ;) fix to vaults 
void LoadVaults()// Thanks vamist - Numan
{
	CMap@ map = getMap();
	if (map is null)
	{
		warning("map is null");
		return;
	}

	Vec2f[] vaultpos;

	if (map.getMarkers("npcvault", vaultpos))
	{
		for (uint i = 0; i < vaultpos.length; i++)
		{
			server_CreateBlob("npcvault", -1, vaultpos[i]);
		}
	}
}


///          [Get Spawn Location]
///		~ Get spawn locations & get bed spawn locations
///
Vec2f getSpawnLocation(CPlayer@ player)
{
	CMap@ map = getMap();
	Vec2f[] spawnpoints;
	CBlob@[] bedspawnpoints;

	if (getBlobsByName("bed", @bedspawnpoints))
	{
		for (uint i = 0; i < bedspawnpoints.length; i++)
		{
			CBlob@ b = bedspawnpoints[i];

			if (player.getTeamNum() == b.getTeamNum())
			{
				return bedspawnpoints[i].getPosition();
			}
		}
	}
    if (map.getMarkers("dunes_spawn", spawnpoints)) 
    {
        return spawnpoints[XORRandom(spawnpoints.length)];
    }
	warning("map is null; no spawn location");
	return Vec2f(0, 0);

}


///          [ON TICK]
///		~ Manage all spawn timers
///		~ Periodic coin saving
///		~ Guard aggro
///		~ Manage all agro timers
///		~ Welcome box tagging
///
void onTick(CRules@ this)
{
	// Spawn timer
	// For every player 
    uint16 i;
	for (i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player == null)
			{ continue; }
		
		// Get the timer for this player
		u16 timeleft = this.get_u16(player.getUsername() + "_timer");
		
		// If the timer is off, next player
		if (timeleft == 0)
			{ continue; }
		
		// When the timer reaches one (1), then respawn
		if (timeleft == 1)
		{ 
			// Zero (0) means the timer is off
			this.set_u16(player.getUsername() + "_timer", 0);
			Respawn(this, player);

			// Don't do anything further and go to the next player
			continue;
		}

		// Reduce timeleft by one (1). So, -1
		timeleft--;

		// Assign the new timeleft to the player
		this.set_u16(player.getUsername() + "_timer", timeleft);
	}

    // Coin saving system. Set coins in the .cfg every minute
    // Once every one (1) minute
	if (getGameTime() % 1800 == 0)
    {
    	// For every player
        for (i = 0; i < getPlayerCount(); i++)
        {
        	// Get the player
            CPlayer@ player = getPlayer(i);
            if (player.getCoins() != 0)
            {
            	// Set the players current coin amount
                cfg_playercoins.add_u32(player.getUsername(), (player.getCoins()));
            }
        }

        // Save the .cfg file
        cfg_playercoins.saveFile("Dunes_Coins.cfg");
    }

    // Market guard aggro system
    // Reduce player aggro time and sets aggro if the player is in the zone
    // For each player
    for (i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
        // If player doesn't exist, move on to next one
        if (player == null)
        	{ continue; }

        string username = player.getUsername();
        uint16 playerdangertime = this.get_u16(username + "_bad");
        
        // Check if a player is in a guardedarea while being wanted, and if so, make the guards chase/attack them
        uint16 g_count = this.get_u16("g_count");
        // If there is a guard area
        if (g_count != 0 && playerdangertime == 1)
        {
            CBlob@ player_blob = player.getBlob();
            // If player's blob doesn't exist, move on to next one
            if (player_blob == null)
            	{ continue; }

            Vec2f blobPos = player_blob.getPosition();
            for (uint16 j = 0; j < g_count; j += 2)
            {
            	// Get area point
                Vec2f g_pos1 = this.get_Vec2f("g_pos" + j);
                // Get area2 point, the second point we check between
                Vec2f g_pos2 = this.get_Vec2f("g_pos" + (j + 1));
                // If the player is in the area
                if(g_pos1.x < blobPos.x && g_pos2.x > blobPos.x && g_pos1.y < blobPos.y && g_pos2.y > blobPos.y)
                {
                    string username = player.getUsername();
                    playerdangertime = 20 * 30;
                }
            }
        }

        // If the player does not currently have the guards mad at them, stop ticking down (i.e don't make them not wanted).
        if (playerdangertime <= 1)
        	{ continue; }

        // Reduce the players aggro time by one (1)
        playerdangertime -= 1;
        this.set_u16(player.getUsername() + "_bad", playerdangertime); 
    }

    CPlayer@ local = getLocalPlayer();

    if (local is null)
    	{ return; }

    if (getControls().isKeyJustPressed(KEY_F2)) 
    {
        if (local.hasTag(menu_prop))
        {
        	// Turn off box
            local.Untag(menu_prop);
        }
        else
        {
        	// Turn on box
            local.Tag(menu_prop);
        }
    }
}


///          [ON PLAYER DIE]
///		~ Clamp "_bad" var
///
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	CRules@ rules = getRules();
	if (rules.get_u16(victim.getUsername() + "_bad") > 1) {
		rules.set_u16(victim.getUsername() + "_bad", 1);
	}
}


///          [ON NEW PLAYER JOIN]
///		~ Set random fake name
///		~ Assign exception names
///		~ Set their team
///		~ Load their coins, and set
///
string[] playernames = { "Muhammad", "Ahmed", "Abdul", "Aladdin", "Ali", "Amir", "Amiri", "Hamid", "Jahid", "Kahlil", "Mohammad", "Masoud", "Nadir", "Sahar", "Sitar", "Samir", "Talal", "Sultan", "Tamir", "Talib", "Ziyad", "Jabar", "Abu al Khayr", "Abu", "Muhammad Ali" };
void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	player.Tag(menu_prop);
    player.Sync(menu_prop, true);

	if (player == null)
		{ return; }

	player.Tag(welcomeTag);
    player.Sync(welcomeTag, true);

	player.server_setTeamNum(0);

	// The 2 is not needed
	Random@ r = Random(getGameTime() + 2);
	string username = player.getUsername();
	
	string assigned_name = playernames[r.NextRanged(playernames.get_length())];

	if (username == "Yeti5000707")
		{ assigned_name = "Muhammad Jr";}	
	else if (username == "FrothyFruitbat")
		{ assigned_name = "Muhammad";}
	else if (username == "the1sad1numanator")
		{ assigned_name = "Numi"; }
	
	this.set_string(username+0, assigned_name);

	// Respawn time, the slightly longer time is buffer time, to make the respawn less of a whip
	this.set_u16(player.getUsername() + "_timer", 4);

    uint32 playercoins = 0;
    if (cfg_playercoins.exists(player.getUsername()))
    {
        playercoins = cfg_playercoins.read_u32(player.getUsername());
    }

    player.server_setCoins(playercoins);
}


///          [ON PLAYER LEAVE]
///		~ Save coins w/ tax
///		~ Remove all of their beds
///
void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    if (player == null)
    	{ return; }

    if (player.getCoins() != 0)
    {
    	// Set players coins. With a 5% tax removed from total
        cfg_playercoins.add_u32(player.getUsername(), (player.getCoins() * 0.97));
    }
    else if (cfg_playercoins.exists(player.getUsername()))
    {
        cfg_playercoins.remove(player.getUsername());
    }

    //bed
    CMap@ map = getMap();
	CBlob@[] beds;

	if (getBlobsByName("bed", @beds))
	{
		for (uint i = 0; i < beds.length; i++)
		{
			CBlob@ b = beds[i];

			if (player.getTeamNum() == b.getTeamNum())
			{
				b.server_Die();
			}
		}
	}
}


///          [ON RESTART]
///		~ Reset rules
///
void onRestart(CRules@ this)
{
	Reset(this);
}


///          [RESET]
///		~ Set spawn-in times
///		~ Refresh reputations
///		~ Create guarded areas
///		~ Music init
///
void Reset(CRules@ this)
{
	// Music
	server_CreateBlob("dunesmusic");

	//For every player 
    uint16 i;
    for (i = 0; i < getPlayerCount(); i++)
    {
    	//Get the player
        CPlayer@ player = getPlayer(i);
        if(player == null)
            { continue; }

        this.set_u16(player.getUsername() + "_timer", 1);
        this.set_u16(player.getUsername() + "_bad", 0);
    }

    // Commence guard areas
    uint16 g_count = this.get_u16("g_count");
    if (g_count == 0)
    	{ return; }
    
    array<Vec2f> guardPoints(g_count);

    CMap@ map = getMap();
    
    // Get all markers
    for (i = 0; i < g_count; i++)
    {
        Vec2f g_pos;
        if(!map.getMarker("GuardPoint" + i, g_pos))
        	{ break; }
        guardPoints[i] = g_pos;
    }
    
    // Sort from lowest x pos to highest x pos
    for (i = 0; i < g_count; i++)
    {
        for (uint16 j = 0; j < g_count - 1; j++)
        {
            if (guardPoints[j].x > guardPoints[j + 1].x)
            {
                Vec2f temp = guardPoints[j];
                guardPoints[j] = guardPoints[j + 1];
                guardPoints[j + 1] = temp;
            }
        }
    }

    // Assign guard areas, i += 2 is done to prevent an addition area from being added without a guard area friend
    for (i = 0; i < g_count; i += 2)
    {
        this.set_Vec2f("g_pos" + i, guardPoints[i]);
        this.set_Vec2f("g_pos" + (i + 1), guardPoints[i + 1]);
    }

	LoadVaults();

	CRules@ rules = getRules();

	ConfigFile cfg = ConfigFile();

	rules.set_f32("fall vel modifier", cfg.read_f32("fall_dmg_nerf", 0.9f));
}