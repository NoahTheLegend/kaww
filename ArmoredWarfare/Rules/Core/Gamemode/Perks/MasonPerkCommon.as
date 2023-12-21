
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

class Structure
{
    string name;

    Structure(string _name)
    {
        name = _name;
    }
}