#include "StructureList.as";
#include "CustomBlocks.as";

//Structure(, "", "structure_.png"),
Structure[] structures = {
    Structure(0, "Refinery (horizontal)", "structure_refinery1_layout.png"),
    Structure(0, "Refinery (vertical)", "structure_refinery_layout.png"),
    Structure(0, "Bridge (short)", "structure_bridge_short.png"),
    Structure(0, "Bridge (medium)", "structure_bridge_medium.png"),
    Structure(0, "Ledge (left)", "structure_ledge_left.png"),
    Structure(0, "Ledge (right)", "structure_ledge_right.png"),
    Structure(0, "Obstacle (left)", "structure_obstacle_left.png"),
    Structure(0, "Obstacle (right)", "structure_obstacle_right.png"),
    Structure(0, "Wooden Wall (small)", "structure_wall_small_wooden.png"),
    Structure(0, "Stone Wall (small)", "structure_wall_small.png"),
    Structure(0, "Pillar (wooden)", "structure_wooden_column.png"),
    Structure(0, "Pillar (stone)", "structure_stone_column.png"),
    Structure(0, "Bunker (left)", "structure_bunker_left.png"),
    Structure(0, "Bunker (right)", "structure_bunker_right.png"),
    Structure(0, "Tower (cheap)", "structure_tower_cheap.png"),
    Structure(0, "Tower (armored)", "structure_tower_expensive.png"),
    Structure(0, "Support bracing (wooden)", "structure_wooden_support.png"),
    Structure(0, "Square (stone)", "structure_stone_bg_square.png"),
    Structure(0, "Room (stone)", "structure_stone_room.png"),
    Structure(0, "Reinforced Brick", "structure_reinforced_brick.png"),
    Structure(0, "Free Armor", "structure_free_armor.png"),
    Structure(0, "Free Armor Cell Left", "structure_free_armor_cell_left.png"),
    Structure(0, "Free Armor Cell Right", "structure_free_armor_cell_right.png"),
    Structure(0, "Free Armor Upper", "structure_free_armor_upper.png"),
    Structure(0, "Cell", "structure_cell.png"),
    Structure(0, "Heavy Cell Left", "structure_heavy_cell_left.png"),
    Structure(0, "Heavy Cell Right", "structure_heavy_cell_right.png"),
    Structure(0, "Down Tower", "structure_down_tower.png"),
    Structure(0, "Medium Bunker Left", "structure_medium_bunker_left.png"),
    Structure(0, "Medium Bunker Right", "structure_medium_bunker_right.png"),
    Structure(0, "Middle Bunker Left", "structure_middle_bunker_left.png"),
    Structure(0, "Middle Bunker Right", "structure_moddle_bunker_right.png"),
    Structure(0, "Station Left", "structure_station_left.png"),
    Structure(0, "Station Right", "structure_station_right.png"),
    Structure(0, "Upper Bunker Left", "structure_upper_bunker_left.png"),
    Structure(0, "Upper Bunker Right", "structure_upper_bunker_right.png"),
    Structure(0, "Up Armor", "structure_up_armor.png"),
    Structure(0, "Pit", "structure_pit.png"),
    Structure(0, "Tunnel (horizontal)", "structure_tunnel.png"),
    Structure(0, "Tunnel (vertical)", "structure_tunnel_vertical.png")
};

const int menu_grid_width = 8;
const Vec2f menu_pos = getDriver().getScreenCenterPos();
const Vec2f menu_dim = Vec2f(Maths::Min(menu_grid_width, structures.size()), Maths::Ceil(f32(structures.size()) / menu_grid_width));
const Vec2f img_size = Vec2f(32,32);

const f32 build_range = 80.0f;

bool isInArea(Vec2f tl, Vec2f br, Vec2f mpos)
{
    return mpos.x >= tl.x && mpos.y >= tl.y && mpos.x <= br.x && mpos.y <= br.y;
}

void sendOpenMenu(CBlob@ this)
{
    CBitStream params;
    params.write_u16(this.getNetworkID());
    this.SendCommand(this.getCommandID("mason_open_menu"), params);
}

void sendPlaceStructure(CBlob@ this, Vec2f pos)
{
    CBitStream params;
    params.write_u16(this.getNetworkID());
    params.write_Vec2f(pos);
    this.SendCommand(this.getCommandID("mason_place_structure"), params);

    //resetQTE(this);
}

void resetSelection(CBlob@ this)
{
    CBitStream params;
    params.write_u16(this.getNetworkID());
    params.write_bool(true);
    this.SendCommand(this.getCommandID("mason_select"), params);
}

void sendPlaceBlock(CBlob@ this, bool is_correct)
{
    CBitStream params;
    params.write_u16(this.getNetworkID());
    params.write_bool(is_correct);
    params.write_s32(this.get_s32("selected_structure"));
    params.write_Vec2f(this.get_Vec2f("building_structure_pos"));
    this.SendCommand(this.getCommandID("mason_place_block"), params);
}

void resetQTE(CBlob@ this)
{
    this.set_u8("next_qte", XORRandom(qte.size()));
    this.add_f32("build_pitch", 0.01f);
}

void sendPlaceBlockClient(CBlob@ this, u16 id, bool can_place, string sound)
{
    CBitStream params;
    params.write_u16(id);
    params.write_bool(can_place);
    params.write_string(sound);
    this.SendCommand(this.getCommandID("mason_place_block_client"), params);
}

class Structure
{
    u8 id;
    string name;
    string filename;
    string icon;
    u16[][] grid;

    Structure(u8 _id, string _name, string _filename)
    {
        this.id = _id;
        this.name = _name;
        this.filename = "Rules/Core/Gamemode/Perks/Mason/Structures/"+_filename;
        grid = buildTileGrid(this.filename);

        makeIcon(_filename);
    }

    void makeIcon(string icon_name)
    {
        this.icon = "$"+icon_name+"$";
        AddIconToken(this.icon, icon_name, Vec2f(24, 24), 0);
    }
}

const array<EKEY_CODE> qte = {KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5}; // key 6 optional