#include "StructureList.as";

bool isInArea(Vec2f tl, Vec2f br, Vec2f mpos)
{
    return mpos.x >= tl.x && mpos.y >= tl.y && mpos.x <= br.x && mpos.y <= br.y;
}

void sendOpenMenu(CBlob@ this)
{
    printf("sent");
    CBitStream params;
    params.write_u16(this.getNetworkID());
    this.SendCommand(this.getCommandID("mason_open_menu"), params);
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

