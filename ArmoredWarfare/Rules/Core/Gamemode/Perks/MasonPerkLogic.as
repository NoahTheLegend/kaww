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
            printf("command opens cgridmenu at time "+getGameTime());
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
            
            printf("s "+selected);
        }
    }
}

Structure[] structures = {
    Structure("one"),
    Structure("two")
};

const Vec2f menu_pos = getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f);
const Vec2f menu_dim = Vec2f(structures.size() % 5, Maths::Floor(structures.size() / 5) + 1);

s32 selected = -1;

void RunSelectListener(CBlob@ this)
{
    CControls@ controls = this.getControls();
    if (controls is null) return;

    Vec2f pos = menu_pos;
    Vec2f dim = menu_dim;
    Vec2f aimpos = controls.getMouseScreenPos(); // giant hack incoming lmao
    if ((controls.mousePressed1 || controls.mousePressed2)
        && isInArea(pos, pos + Vec2f(dim.x * 50, dim.y * 50), aimpos))
    {
        selected = 1;
    }
    else selected = -1;
}

void openMasonMenu(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CGridMenu@ menu = CreateGridMenu(menu_pos, this, menu_dim, "Select structure");

	if (menu !is null)
	{
        printf("menu not null at "+getGameTime());
		menu.deleteAfterClick = true;
        
		for (u8 i = 0; i < structures.size(); i++)
        {
            Structure str = structures[i];

            CGridButton@ button = menu.AddButton("$ammo$", str.name, this.getCommandID("mason_select"), Vec2f(1, 1), params);
	        if (button !is null)
	        {
            
	        }
        }
	}
}