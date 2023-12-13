// info for ranks
// very controversial code, overhaul in v5.0?

// The base amount of exp required to reach level 2
const int LEVEL_2_EXP = 25;

// The exp multiplier for each subsequent level
const float EXP_MULTIPLIER = 3.8; //  2.61 with no plateau

// Value to round off each level
const int ROUNDER = 25;
const int ROUNDER2 = 500;

const float PLATEAU = 0.82f;
const float MAX_LEVEL = 9000.0f; //sergeant-major


const string[] RANKS = {"Recruit",              // new player
                        "Private",
                        "Gefreiter",
                        "Corporal",
                        "Master Corporal",
                        "Sergeant",  
                        "Staff Sergeant",
                        "Master Sergeant",
                        "First Sergeant", 
                        "Sergeant-Major",
                        "Warrant Officer 1",
                        "Warrant Officer 2",
                        "Warrant Officer 3",
                        "Warrant Officer 4",
                        "Third Lieutenant",
                        "Second Lieutenant",
                        "First Lieutenant",
                        "Captain",
                        "Major",
                        "Lieutenant Colonel",
                        "Colonel",
                        "General-Brigadier",
                        "General-Major",
                        "General-Lieutenant",
                        "Army Chief"
                        };

shared int[] getLevels() // +- LINEAR PROGRESSION
{
    int[] list = {
        25, // +25 Ranger               | Private
        100, // +75 Shotgun             | Refreiter
        250, // +150 Sniper             | Corporal
        450, // +200 RPG                | Master Corporal
        800, // +350 MP5                | Sergeant
        1250, // +450                   | Staff Sergeant
        1800, // +550                   | Master Sergeant
        2500, // +700                   | First Sergeant
        3350, // +850                   | Sergeant-Major
        5000, // +1650                  | W. Officer 1
        7500, // +2500                  | W. Officer 2
        11000, // +3500                 | W. Officer 3
        16500, // +5500                 | W. Officer 4
        23000, // +6500                 | Third Leiutenant
        30000, // +7000                 | Second Lieutenant
        38000, // +8000                 | First Lieutenant
        47000, // +9000                 | Captain
        57500, // +10500                | Major
        68500, // +11000                | Lieutenant Colonel
        80000, // +11500                | Colonel
        92500, // +12500                | General-Brigadier
        106000, // +13500               | General-Major
        121000, // +15000               | General-Lieutenant
        150000, // +29000               | Army Chief
        999999 // +NaN                  | Filler
    };
    return list;
}

// Calculate the exp required to reach the next level
shared int getExpToNextLevelShared(u32 level)
{
    int[] LEVELS = getLevels();
    if (level < LEVELS.length)
    {
        return LEVELS[level-1];
    }

    int mod = ROUNDER;
    if (level > 4)
    {
        mod = ROUNDER2;
    }

    float mod_plateau = PLATEAU;

    // i am retarded
    if (level > 8)
    {
        mod_plateau *= 0.67f;
    }
    else if (level > 7)
    {
        mod_plateau *= 0.7f;
    }
    else if (level > 6)
    {
        mod_plateau *= 0.76f;
    }
    else if (level > 5)
    {
        mod_plateau *= 0.85f;
    }
 
    return int(Maths::Round(LEVEL_2_EXP * Maths::Pow(EXP_MULTIPLIER * mod_plateau, level - 1) / mod) * mod);
}

// Calculate the exp required to reach the next level
int getExpToNextLevel(u32 level)
{
    int[] LEVELS = getLevels();
    if (level < LEVELS.length)
    {
        return LEVELS[level-1];
    }

    int mod = ROUNDER;
    if (level > 4)
    {
        mod = ROUNDER2;
    }

    float mod_plateau = PLATEAU;

    // i am retarded
    if (level > 8)
    {
        mod_plateau *= 0.67f;
    }
    else if (level > 7)
    {
        mod_plateau *= 0.7f;
    }
    else if (level > 6)
    {
        mod_plateau *= 0.76f;
    }
    else if (level > 5)
    {
        mod_plateau *= 0.85f;
    }
    
    return int(Maths::Round(LEVEL_2_EXP * Maths::Pow(EXP_MULTIPLIER * mod_plateau, level - 1) / mod) * mod);
}

// Calculate the exp required to reach my current level
int getExpToMyLevel(u32 level)
{
    int[] LEVELS = getLevels();
    if (level < LEVELS.length)
    {
        return LEVELS[(level-2)];
    }

    int mod = ROUNDER;
    if (level-1 > 4)
    {
        mod = ROUNDER2;
    }

    float mod_plateau = PLATEAU;
    
    if (level-1 > 8)
    {
       mod_plateau *= 0.67f;
    }
    else if (level-1 > 7)
    {
       mod_plateau *= 0.7f;
    }
    else if (level-1 > 6)
    {
       mod_plateau *= 0.76f;
    }
    else if (level-1 > 5)
    {
        mod_plateau *= 0.85f;
    }
	if (level == 1) return 0;
    return int(Maths::Clamp(Maths::Round(LEVEL_2_EXP * Maths::Pow(EXP_MULTIPLIER * mod_plateau, level - 2) / mod) * mod, 0, MAX_LEVEL));
}

// Get the player's current rank name
string getRankName(u32 level)
{
    return RANKS[level - 1];
}

void CheckRankUps(CRules@ rules, u32 exp, CBlob@ blob)
{    
    if (blob is null) return;
    CPlayer@ player = blob.getPlayer();
    if (player is null) return;

    int level = 1;
    string rank = RANKS[0];

    if (exp > 0)
    {
        // Calculate the exp required to reach each level
        for (int i = 1; i <= RANKS.length; i++)
        {
            if (exp >= getExpToNextLevel(i))
            {
                level = i + 1;
                rank = RANKS[Maths::Min(i, RANKS.length-1)];
            }
            else
            {
                break;
            }
        }
    }
	
    string oldrank = "Na";
    if (rules.get_string(player.getUsername() + "_last_lvlup") != "")
    {
        oldrank = rules.get_string(player.getUsername() + "_last_lvlup");
    }
    else {
        rules.set_string(player.getUsername() + "_last_lvlup", rank);
        oldrank = rank;
    }

    if (isServer() && rank != oldrank) // means that we leveled up
    {
        CBitStream params;
        params.write_u8(level);
        params.write_string(rank);
        blob.SendCommand(blob.getCommandID("levelup_effects"), params);
    }
}