
namespace Perks
{
    enum Perks
    {
        none = 0,
        camouflage = 1,
        sharpshooter = 2,
        bloodthirsty = 3,
        operator = 4,
        lucky = 5,
        wealthy = 6,
        deathincarnate = 7,
        paratrooper = 8,
        bull = 9,
        fieldengineer = 10
    };
}

const string[] perks = { // i really dk how else to name it
    "",
    "Camouflage",
    "Sharp Shooter",
    "Bloodthirsty",
    "Operator",
    "Lucky",
    "Wealthy",
    "Death Incarnate",
    "Paratrooper",
    "Bull",
    "Field Engineer"
};

bool hasPerk(CPlayer@ player, u8 current)
{
    return getRules().get_string(player.getUsername() + "_perk") == perks[current];
}

bool hasPerk(CPlayer@ player, string current)
{
    return getRules().get_string(player.getUsername() + "_perk") == current;
}