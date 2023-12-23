#include "StructureList.as";
#include "CustomBlocks.as";

Structure[] structures = {
    Structure(0, "Bridge (short)", "structure_bridge_short.png"),
    Structure(0, "Bridge (medium)", "structure_bridge_medium.png")
};

const Vec2f menu_pos = getDriver().getScreenCenterPos();
const Vec2f menu_dim = Vec2f(5%structures.size()+1, Maths::Floor(structures.size() / 5)+1);
const Vec2f img_size = Vec2f(32,32);

const f32 build_range = 96.0f;

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
    this.SendCommand(this.getCommandID("mason_place_block"), params);
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