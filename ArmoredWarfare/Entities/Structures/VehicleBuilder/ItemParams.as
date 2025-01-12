#include "Requirements.as"
#include "ShopCommon.as"
#include "GamemodeCheck.as"

// initial costs
const u16 c_standard_ammo = 1;
const u16 c_special_ammo = 3;
const u16 c_14mm_rounds = 3;
const u16 c_105mm_rounds = 4;
const u16 c_heat_warheads = 8;
const u16 c_frag_grenade = 3;
const u16 c_molotov = 2;
const u16 c_anti_tank_grenade = 5;
const u16 c_land_mine = 4;
const u16 c_c4 = 10;
const u16 c_burger = 1;
const u16 c_medkit = 2;
const u16 c_helmet = 3;
const u16 c_tank_trap = 4;
const u16 c_lantern = 20;
const u16 c_sponge = 50;
const u16 c_pipe_wrench = 5;
const u16 c_welding_tool = 12;
const u16 c_binoculars = 6;
const u16 c_small_bomb = 3;
const u16 c_ftw = 12;
const u16 c_907kg_bomb = 50;
const u16 c_5t_bomb = 300;

// build time
const u16 ct_standard_ammo = 0;
const u16 ct_special_ammo = 0;
const u16 ct_14mm_rounds = 0;
const u16 ct_105mm_rounds = 0;
const u16 ct_heat_warheads = 0;
const u16 ct_frag_grenade = 0;
const u16 ct_molotov = 0;
const u16 ct_anti_tank_grenade = 0;
const u16 ct_land_mine = 0;
const u16 ct_c4 = 0;
const u16 ct_burger = 0;
const u16 ct_medkit = 0;
const u16 ct_helmet = 0;
const u16 ct_tank_trap = 30;
const u16 ct_lantern = 0;
const u16 ct_sponge = 0;
const u16 ct_pipe_wrench = 0;
const u16 ct_welding_tool = 0;
const u16 ct_binoculars = 0;
const u16 ct_small_bomb = 0;
const u16 ct_ftw = 0;
const u16 ct_907kg_bomb = 90;
const u16 ct_5t_bomb = 270;

// names
const string n_standard_ammo = "Standard Ammo";
const string n_special_ammo = "Special Ammunition";
const string n_14mm_rounds = "14mm Rounds";
const string n_105mm_rounds = "105mm Rounds";
const string n_heat_warheads = "HEAT War Heads";
const string n_frag_grenade = "Frag Grenade";
const string n_molotov = "Molotov";
const string n_anti_tank_grenade = "Anti-Tank Grenade";
const string n_land_mine = "Land Mine";
const string n_c4 = "Craft a C-4 Explosive";
const string n_burger = "Burger";
const string n_medkit = "Medkit";
const string n_helmet = "Helmet";
const string n_tank_trap = "Tank Trap";
const string n_lantern = "Lantern";
const string n_sponge = "Sponge";
const string n_pipe_wrench = "Pipe Wrench";
const string n_welding_tool = "Welding Tool";
const string n_binoculars = "M22 Binoculars";
const string n_small_bomb = "Bomb";
const string n_ftw = "Construct a Firethrower";
const string n_907kg_bomb = "907 Kilogram-trotile Bomb";
const string n_5t_bomb = "5000 Kilogram-trotile Bomb";

// descriptions
const string d_standard_ammo = "Used by all small arms guns, and vehicle machineguns.";
const string d_special_ammo = "Special ammunition for advanced weapons.";
const string d_14mm_rounds = "Used by APCs.";
const string d_105mm_rounds = "Ammunition for tank main guns.";
const string d_heat_warheads = "HEAT Rockets, used with RPG or different vehicles.";
const string d_frag_grenade = "Press SPACE while holding to arm, ~4 seconds until boom. Ineffective against armored vehicles.";
const string d_molotov = "Press SPACE while holding to arm, ~4 seconds until boom. Effective against infantry.";
const string d_anti_tank_grenade = "Press SPACE while holding to arm, ~5 seconds until boom. Effective against vehicles.";
const string d_land_mine = "Takes a while to arm, once activated it will explode upon contact with the enemy.";
const string d_c4 = "A strong explosive, very effective against blocks and doors.\n\nTakes some time after activation to explode.\nCan be defused.";
const string d_burger = "Heal to full health instantly.";
const string d_medkit = "If hurt, press E to heal. 6 uses.";
const string d_helmet = "Standard issue helmet, take 40% less bullet damage, and occasionally bounce bullets.";
const string d_tank_trap = "Czech hedgehog, will harm and stop any enemy vehicle that collides with it.";
const string d_lantern = "A source of light.";
const string d_sponge = "Commonly used for washing vehicles.";
const string d_pipe_wrench = "Left click on vehicles to repair them. Limited uses.";
const string d_welding_tool = "A modernized solution for rapid repair.\nOnly for Mechanic class.\nRequires scrap to use.";
const string d_binoculars = "A pair of glasses with optical zooming.";
const string d_small_bomb = "Small explosive bombs.";
const string d_ftw = "Fire thrower.\nCan be attached to and detached from some vehicles.\n\nUses Special Ammunition.";
const string d_907kg_bomb = "A good way to damage enemy facilities.";
const string d_5t_bomb = "The best way to destroy enemy facilities.";

// blobnames
const string bn_standard_ammo = "ammo";
const string bn_special_ammo = "specammo";
const string bn_14mm_rounds = "mat_14mmround";
const string bn_105mm_rounds = "mat_bolts";
const string bn_heat_warheads = "mat_heatwarhead";
const string bn_frag_grenade = "grenade";
const string bn_molotov = "mat_molotov";
const string bn_anti_tank_grenade = "mat_atgrenade";
const string bn_land_mine = "mine";
const string bn_c4 = "c4";
const string bn_burger = "food";
const string bn_medkit = "medkit";
const string bn_helmet = "helmet";
const string bn_tank_trap = "tanktrap";
const string bn_lantern = "lantern";
const string bn_sponge = "sponge";
const string bn_pipe_wrench = "pipewrench";
const string bn_welding_tool = "weldingtool";
const string bn_binoculars = "binoculars";
const string bn_small_bomb = "mat_smallbomb";
const string bn_ftw = "firethrower";
const string bn_907kg_bomb = "mat_907kgbomb";
const string bn_5t_bomb = "mat_5tbomb";

// icon tokens
const string t_standard_ammo = "$ammo$";
const string t_special_ammo = "$specammo$";
const string t_14mm_rounds = "$mat_14mmround$";
const string t_105mm_rounds = "$mat_bolts$";
const string t_heat_warheads = "$mat_heatwarhead$";
const string t_frag_grenade = "$grenade$";
const string t_molotov = "$molotov$";
const string t_anti_tank_grenade = "$atgrenade$";
const string t_land_mine = "$mine$";
const string t_c4 = "$"+bn_c4+"$";
const string t_burger = "$food$";
const string t_medkit = "$medkit$";
const string t_helmet = "$helmet$";
const string t_tank_trap = "$tanktrap$";
const string t_lantern = "$lantern$";
const string t_sponge = "$sponge$";
const string t_pipe_wrench = "$pipewrench$";
const string t_welding_tool = "$weldingtool$";
const string t_binoculars = "$binoculars$";
const string t_small_bomb = "$mat_smallbomb$";
const string t_ftw = "$icon_ft$";
const string t_907kg_bomb = "$mat_907kgbomb$";
const string t_5t_bomb = "$mat_5tbomb$";

void makeDefaultAmmo(CBlob@ this)
{
    {
        ShopItem@ s = addShopItem(this, n_standard_ammo, t_standard_ammo, bn_standard_ammo, d_standard_ammo, true, false, false, ct_standard_ammo);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_standard_ammo);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_special_ammo, t_special_ammo, bn_special_ammo, d_special_ammo, true, false, false, ct_special_ammo);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_special_ammo);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_14mm_rounds, t_14mm_rounds, bn_14mm_rounds, d_14mm_rounds, true, false, false, ct_14mm_rounds);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_14mm_rounds);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_105mm_rounds, t_105mm_rounds, bn_105mm_rounds, d_105mm_rounds, true, false, false, ct_105mm_rounds);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_105mm_rounds);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_heat_warheads, t_heat_warheads, bn_heat_warheads, d_heat_warheads, true, false, false, ct_heat_warheads);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_heat_warheads);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeDefaultExplosives(CBlob@ this)
{
    {
        ShopItem@ s = addShopItem(this, n_frag_grenade, t_frag_grenade, bn_frag_grenade, d_frag_grenade, true, false, false, ct_frag_grenade);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_frag_grenade);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_molotov, t_molotov, bn_molotov, d_molotov, true, false, false, ct_molotov);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_molotov);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_anti_tank_grenade, t_anti_tank_grenade, bn_anti_tank_grenade, d_anti_tank_grenade, true, false, false, ct_anti_tank_grenade);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_anti_tank_grenade);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_land_mine, t_land_mine, bn_land_mine, d_land_mine, true, false, false, ct_land_mine);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_land_mine);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeDefaultGear(CBlob@ this)
{
    {
        ShopItem@ s = addShopItem(this, n_burger, t_burger, bn_burger, d_burger, true, false, false, ct_burger);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_burger);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_medkit, t_medkit, bn_medkit, d_medkit, true, false, false, ct_medkit);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_medkit);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_helmet, t_helmet, bn_helmet, d_helmet, true, false, false, ct_helmet);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_helmet);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeDefaultUtils(CBlob@ this)
{
    {
        ShopItem@ s = addShopItem(this, n_tank_trap, t_tank_trap, bn_tank_trap, d_tank_trap, false, false, false, ct_tank_trap);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_tank_trap);
        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_lantern, t_lantern, bn_lantern, d_lantern, false, false, true, ct_lantern);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", c_lantern);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_sponge, t_sponge, bn_sponge, d_sponge, false, false, true, ct_sponge);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", c_sponge);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeExtraUtils(CBlob@ this)
{
    {
        ShopItem@ s = addShopItem(this, n_pipe_wrench, t_pipe_wrench, bn_pipe_wrench, d_pipe_wrench, true, false, false, ct_pipe_wrench);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_pipe_wrench);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_welding_tool, t_welding_tool, bn_welding_tool, d_welding_tool, true, false, false, ct_welding_tool);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_welding_tool);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    {
        ShopItem@ s = addShopItem(this, n_binoculars, t_binoculars, bn_binoculars, d_binoculars, true, false, false, ct_binoculars);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_binoculars);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeSmallBombs(CBlob@ this, u8 discount = 0)
{
    {
        ShopItem@ s = addShopItem(this, n_small_bomb, t_small_bomb, bn_small_bomb, d_small_bomb, true, false, false, ct_small_bomb);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_small_bomb);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeBigBombs(CBlob@ this)
{
    {
        ShopItem@ s = addShopItem(this, n_907kg_bomb, t_907kg_bomb, bn_907kg_bomb, d_907kg_bomb, false, false, false, ct_907kg_bomb);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_907kg_bomb);
        AddRequirement(s.requirements, "gametime", "", "Unlocks at", 30*30 * 60);
        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
    if (isCTF())
    {
        ShopItem@ s = addShopItem(this, n_5t_bomb, t_5t_bomb, bn_5t_bomb, d_5t_bomb, false, false, false, ct_5t_bomb);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_5t_bomb);
        AddRequirement(s.requirements, "gametime", "", "Unlocks at", 30*30 * 60);
        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
}

void makeFirethrower(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_ftw, t_ftw, bn_ftw, d_ftw, false, true);
	item.customButton = true;
	item.buttonwidth = 1;
	item.buttonheight = 1;
	AddRequirement(item.requirements, b, s, ds, c_ftw - discount);
}

void makeC4(CBlob@ this, u8 discount = 0)
{
    ShopItem@ item = addShopItem(this, n_c4, t_c4, bn_c4, d_c4, true, false);
    item.customButton = true;
    item.buttonwidth = 1;
    item.buttonheight = 1;
    AddRequirement(item.requirements, b, s, ds, c_c4 - discount);
}