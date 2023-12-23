#include "PerksCommon.as";
#include "CustomBlocks.as";
#include "MasonPerkCommon.as";
#include "BlockCosts.as";

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
    if (!this.isMyPlayer() && !isServer()) return; // run only for myplay or server, isClient() prevents doublecommands on localhost
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

            bool reset;
            if (!params.saferead_bool(reset)) return;

            CBlob@ caller = getBlobByNetworkID(id);
            if (caller is null) return;

            if (reset) selected = -1;
            caller.set_s32("selected_structure", selected);
            caller.set_u32("selected_structure_time", getGameTime());
            caller.set_Vec2f("building_structure_pos", Vec2f(-1,-1));
            selected = -1;
        }
    }
    else if (cmd == this.getCommandID("mason_place_structure"))
    {
        if (isClient())
        {
            u16 id;
            if (!params.saferead_u16(id)) return;

            Vec2f pos;
            if (!params.saferead_Vec2f(pos)) return;

            CBlob@ caller = getBlobByNetworkID(id);
            if (caller is null) return;

            CSprite@ sprite = caller.getSprite();
            if (sprite !is null) sprite.PlaySound("ConstructShort", 0.75f+XORRandom(11)*0.01f, 0.95f+XORRandom(6)*0.01f);

            caller.set_Vec2f("building_structure_pos", pos);
            caller.set_u8("next_qte", XORRandom(qte.size()));
        }
    }
    else if (cmd == this.getCommandID("mason_place_block"))
    {
        u16 id;
        if (!params.saferead_u16(id)) return;

        bool can_place;
        if (!params.saferead_bool(can_place)) return;

        s32 selected;
        if (!params.saferead_s32(selected)) return;

        CBlob@ caller = getBlobByNetworkID(id);
        if (caller is null) return;

        if (isClient())
        {
            CSprite@ sprite = caller.getSprite();
            if (sprite !is null) sprite.PlaySound(can_place ? "coinpick.ogg" : "NoAmmo.ogg", can_place ? 2.5f : 0.75f, 1.0f+XORRandom(31)*0.01f);

            caller.set_u8("next_qte", XORRandom(qte.size()));
        }

        if (isServer())
        {
            if (!can_place)
            {
                resetSelection(this);
                return;
            }

            CMap@ map = getMap();
            Structure str = structures[selected];

            bool fl = this.isFacingLeft();
            Vec2f bpos = this.getPosition();

            Vec2f pos = this.get_Vec2f("building_structure_pos");
            Vec2f tilepos = map.getTileSpacePosition(pos);
            tilepos = map.getTileWorldPosition(tilepos);
            
            Vec2f match_pos = Vec2f_zero;
            int t = CMap::tile_empty;

            u8 sz = str.grid.size();
            for (int i = 0; i < sz; i++)
            {
                if ((i+1) % sz == 0 || i % sz == 0) continue;
                u8 szi = str.grid[i].size();
                for (int j = 0; j < szi; j++)
                {
                    Vec2f offset = tilepos;

                    offset += Vec2f((j-szi/2)*8, (i-sz/2)*8);

                    TileType newtile = str.grid[i][j];
                    TileType oldtile = map.getTile(offset).type;
                    
                    //ParticleAnimated("SmallExplosion", offset, Vec2f_zero, 0, 0.5f, 5, 0, false);
                    //map.server_SetTile(offset, newtile);

                    if (newtile != CMap::tile_empty
                        && (map.hasSupportAtPos(offset))
                        && !isTileCustomSolid(oldtile)
                        && oldtile != newtile)
                    {
                        match_pos = offset;
                        t = newtile;

                        break;
                    }
                }
            }

            string[] req_name;
            u16[]    req_quantity;

            switch (t)
            {
                case CMap::tile_castle:     
                {
                    req_name.push_back("mat_stone");
                    req_quantity.push_back(BlockCosts::stone);
                    break;
                }
	            case CMap::tile_castle_back:
                {
                    req_name.push_back("mat_stone");
                    req_quantity.push_back(BlockCosts::stone_bg);
                    break;
                }
	            case CMap::tile_wood:       
                {
                    req_name.push_back("mat_wood");
                    req_quantity.push_back(BlockCosts::wood);
                    break;
                }
	            case CMap::tile_wood_back:  
                {
                    req_name.push_back("mat_wood");
                    req_quantity.push_back(BlockCosts::wood_bg);
                    break;
                }
	            case CMap::tile_scrap:      
                {
                    req_name.push_back("mat_stone");
                    req_quantity.push_back(BlockCosts::scrap_stone);
                    req_name.push_back("mat_scrap");
                    req_quantity.push_back(BlockCosts::scrap_scrap);
                    break;
                }
            }

            for (u8 i = 0; i < req_name.size(); i++)
            {
                if (!caller.hasBlob(req_name[i], req_quantity[i]))
                {
                    can_place = false;
                    break;
                }
            }

            //ParticleAnimated("LargeSmoke", match_pos, Vec2f_zero, 0, 1.0f, 5, 0, false);

            if (can_place && t != CMap::tile_empty)
            {
                for (u8 i = 0; i < req_name.size(); i++)
                {
                    caller.TakeBlob(req_name[i], req_quantity[i]);
                }

                map.server_SetTile(match_pos, t);
            }
            else
            {
                resetSelection(this);
            }
        }
    }
}

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
    params.write_bool(false);

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