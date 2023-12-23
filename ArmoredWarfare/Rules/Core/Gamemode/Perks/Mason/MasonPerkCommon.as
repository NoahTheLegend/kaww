#include "StructureList.as";
#include "CustomBlocks.as";

//Structure(, "", "structure_.png"),
Structure[] structures = {
    Structure(0, "Refinery (layout)", "structure_refinery_layout.png"),
    Structure(1, "Bridge (short)", "structure_bridge_short.png"),
    Structure(2, "Bridge (medium)", "structure_bridge_medium.png"),
    Structure(3, "Ledge (left)", "structure_ledge_left.png"),
    Structure(4, "Ledge (right)", "structure_ledge_right.png"),
    Structure(6, "Stone Wall (small)", "structure_wall_small.png"),
    Structure(6, "Bunker (pit)", "structure_bunker_pit.png"),
    Structure(7, "Bunker (dome)", "structure_bunker_dome.png"),
    Structure(8, "Tower (cheap)", "structure_tower_cheap.png"),
    Structure(9, "Tower (armored)", "structure_tower_expensive.png"),
    Structure(10, "Pillar (wooden)", "structure_wooden_column.png"),
    Structure(11, "Pillar (stone)", "structure_stone_column.png"),
    Structure(12, "Support bracing (wooden)", "structure_wooden_support.png"),
    Structure(13, "Square (stone)", "structure_stone_bg_square.png"),
    Structure(14, "Room (stone)", "structure_stone_room.png"),
};

const Vec2f menu_pos = getDriver().getScreenCenterPos();
const Vec2f menu_dim = Vec2f(Maths::Min(5, structures.size()), Maths::Floor(structures.size() / 5));
const Vec2f img_size = Vec2f(32,32);

const f32 build_range = 64.0f;

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

    resetQTE(this);
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

    resetQTE(this);
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