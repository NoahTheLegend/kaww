#include "PerksCommon.as";
#include "CustomBlocks.as";
#include "MasonPerkCommon.as";

// command ids are initialized in InfantryLogic.as
void onTick(CBlob@ this)
{
    bool removeAfterThis = false;

    CSprite@ sprite = this.getSprite();
    if (sprite is null) removeAfterThis = true;

    CPlayer@ p = this.getPlayer();
    if (p is null) removeAfterThis = true;

    if (!removeAfterThis)
    {
	    PerkStats@ stats;
	    if (p.get("PerkStats", @stats) && stats.id == Perks::mason)
	    {
            this.set_bool("access_mason_menu", true);
            RunSelectListener(this);
        }
        else
        {
            removeAfterThis = true;
        }
    }

    if (removeAfterThis)
    {
        sprite.RemoveScript("MasonPerkGUI.as");
        this.RemoveScript("MasonPerkLogic.as");
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (!this.isMyPlayer() || !isServer()) return;
    if (cmd == this.getCommandID("mason_open_menu"))
    {
        if (isClient())
        {
            u16 id;
            if (!params.saferead_u16(id)) return;
           
            CBlob@ caller = getBlobByNetworkID(id);
            if (caller is null) return;

            openMasonMenu(this, caller);
        }
    }
    else if (cmd == this.getCommandID("mason_select"))
    {
        if (isClient())
        {
            u16 id;
            if (!params.saferead_u16(id)) return;

            CBlob@ caller = getBlobByNetworkID(id);
            if (caller is null) return;

            printf("selected: "+selected);
            if (selected >= 0 && selected < structures.size())
            {
                Structure str = structures[selected];

                string test;
                Vec2f pos = this.getPosition() - Vec2f(0,img_size.y*8/2-16);
                
                for (u8 i = 0; i < str.grid.size(); i++)
                {
                    for (u8 j = 0; j < str.grid[i].size(); j++)
                    {
                        getMap().server_SetTile(Vec2f(pos.x + j*8, pos.y + i*8), str.grid[i][j]);
                    }
                }
            }

            selected = -1;
        }
    }
}

Structure[] structures = {
    Structure(0, "Bridge (short)", "structure_bridge_short.png"),
    Structure(0, "Bridge (short)", "structure_bridge_short.png")
};

const Vec2f menu_pos = getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f);
const Vec2f menu_dim = Vec2f(5%structures.size()+1, Maths::Floor(structures.size() / 5)+1);
const Vec2f img_size = Vec2f(32,32);

s32 selected = -1;

void RunSelectListener(CBlob@ this)
{
    CControls@ controls = this.getControls();
    if (controls is null) return;

    if (getHUD() !is null && !getHUD().hasMenus()) return;

    Vec2f pos = menu_pos;
    Vec2f dim = menu_dim;
    Vec2f aimpos = controls.getMouseScreenPos();

    int tile_size = 48;
    
    Vec2f dir = (aimpos-pos);
    selected = Maths::Floor(dim.x/2) + (dir.x) / tile_size + Maths::Floor(((dir.y+tile_size*1.5f) / tile_size) - 1)*5;
    //printf("hovering at "+selected);
}

void openMasonMenu(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CGridMenu@ menu = CreateGridMenu(menu_pos, this, menu_dim, "Select structure");

	if (menu !is null)
	{
		menu.deleteAfterClick = true;

        CControls@ controls = this.getControls();
        if (controls !is null)
        {
            controls.setMousePosition(getDriver().getScreenCenterPos());
        }
        
		for (u8 i = 0; i < structures.size(); i++)
        {
            Structure str = structures[i];

            CGridButton@ button = menu.AddButton(str.icon, str.name, this.getCommandID("mason_select"), Vec2f(1, 1), params);
	        if (button !is null)
	        {
            
	        }
        }
	}
}