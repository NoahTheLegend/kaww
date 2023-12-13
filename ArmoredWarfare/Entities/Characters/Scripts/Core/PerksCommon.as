#include "Perks.as";

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
        bull = 8,
        paratrooper = 9,
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
    "Bull",
    "Paratrooper",
    "Field Engineer"
};
// todo: rewrite these bools for new logic?
bool hasPerk(CPlayer@ player, u8 current)
{
    return getRules().get_string(player.getUsername() + "_perk") == perks[current];
}

bool hasPerk(CPlayer@ player, string current)
{
    return getRules().get_string(player.getUsername() + "_perk") == current;
}

void addPerk(CPlayer@ player, u8 perk)
{
    if (player is null) return;

    PerkStats reset();
    if (perk > 0)
    {
        switch (perk)
        {
            case 1:
            {
                player.set("PerkStats", @PerkCamouflage());
                break;
            }
            case 2:
            {
                player.set("PerkStats", @PerkSharpShooter());
                break;
            }
            case 3:
            {
                player.set("PerkStats", @PerkBloodthirsty());
                break;
            }
            case 4:
            {
                player.set("PerkStats", @PerkOperator());
                break;
            }
            case 5:
            {
                player.set("PerkStats", @PerkLucky());
                break;
            }
            case 6:
            {
                player.set("PerkStats", @PerkWealthy());
                break;
            }
            case 7:
            {
                player.set("PerkStats", @PerkDeathIncarnate());
                break;
            }
            case 8:
            {
                player.set("PerkStats", @PerkBull());
                break;
            }
            case 9:
            {
                player.set("PerkStats", @PerkParatrooper());
                break;
            }
            case 10:
            {
                player.set("PerkStats", @PerkFieldEngineer());
                break;
            }
        }
    }
    else player.set("PerkStats", @reset);
}
