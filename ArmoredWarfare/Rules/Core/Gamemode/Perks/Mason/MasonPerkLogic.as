#include "PerksCommon.as";
#include "CustomBlocks.as";
#include "MasonPerkCommon.as";
#include "BlockCosts.as";
#include "PlacementCommon.as";

f32 mat_discount = 1;

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
        sprite.RemoveScript("MasonPerkLogic.as");
        this.RemoveScript("MasonPerkLogic.as");
    }
}

bool lock_sound = false;

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
            bool admin = this.getPlayer() !is null && this.getPlayer().isMod();

            //if(admin)printf("enter_select");
            u16 id;
            if (!params.saferead_u16(id)) return;
            //if(admin)printf("id_pass");
            bool reset;
            if (!params.saferead_bool(reset)) return;
            //if(admin)printf("reset_pass");

            CBlob@ caller = getBlobByNetworkID(id);
            if (caller is null) return;
            //if(admin)printf("caller_pass,selected:"+selected);

            if (reset) selected = -1;
            caller.set_s32("selected_structure", selected);
            caller.set_u32("selected_structure_time", getGameTime());
            caller.set_Vec2f("building_structure_pos", Vec2f(-1,-1));
            caller.set_f32("build_pitch", 0);
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

        Vec2f pos;
        if (!params.saferead_Vec2f(pos)) return;

        CBlob@ caller = getBlobByNetworkID(id);
        if (caller is null) return;

        //bool is_blob = false;

        if (isServer())
        {
            if (!can_place)
            {
                sendPlaceBlockClient(this, id, can_place, "NoAmmo.ogg");
                //resetSelection(this);
                return;
            }

            CMap@ map = getMap();
            Structure str = structures[selected];

            bool fl = this.isFacingLeft();
            Vec2f bpos = this.getPosition();

            Vec2f tilepos = map.getTileSpacePosition(pos);
            tilepos = map.getTileWorldPosition(tilepos);
            
            Vec2f match_pos = Vec2f_zero;
            int t = CMap::tile_empty;

            bool has_requirements = false;
            string[] req_name;
            u16[]    req_quantity;
            Vec2f nullvec = Vec2f_zero; // staging bug, requires initialized Vec2f
            
            u8 sz = str.grid.size();
            for (int i = 0; i < sz; i++)
            {
                if (has_requirements) break;
                if ((i+1) % sz == 0 || i % sz == 0) continue;
                u8 szi = str.grid[i].size();

                for (int j = 0; j < szi; j++)
                {
                    if (has_requirements) break;
                    Vec2f offset = tilepos;

                    offset += Vec2f((j-szi/2)*8 + 1, (i-sz/2)*8 + 1);

                    TileType newtile = str.grid[i][j];
                    TileType oldtile = map.getTile(offset).type;
                    
                    //ParticleAnimated("SmallExplosion", offset, Vec2f_zero, 0, 0.5f, 5, 0, false);
                    //map.server_SetTile(offset, newtile);
                    bool buildable_at_pos = (isBuildableAtPos(caller, offset, newtile, null, false)
                        && !fakeHasTileSolidBlobs(offset)
                        && ((!isTileCustomSolid(newtile))
                            || !isBuildRayBlocked(caller.getPosition(), offset, nullvec)));

                    if (newtile != CMap::tile_empty
                        && (map.hasSupportAtPos(offset))
                        && !isTileCustomSolid(oldtile)
                        && oldtile != newtile
                        && (offset - caller.getPosition()).Length() <= build_range
                        && buildable_at_pos)
                    {
                        req_name.clear();
                        req_quantity.clear();

                        switch (newtile)
                        {
                            case CMap::tile_castle:     
                            {
                                req_name.push_back("mat_stone");
                                req_quantity.push_back(BlockCosts::stone / mat_discount);
                                break;
                            }
	                        case CMap::tile_castle_back:
                            {
                                req_name.push_back("mat_stone");
                                req_quantity.push_back(BlockCosts::stone_bg / mat_discount);
                                break;
                            }
	                        case CMap::tile_wood:       
                            {
                                req_name.push_back("mat_wood");
                                req_quantity.push_back(BlockCosts::wood / mat_discount);
                                break;
                            }
	                        case CMap::tile_wood_back:  
                            {
                                req_name.push_back("mat_wood");
                                req_quantity.push_back(BlockCosts::wood_bg / mat_discount);
                                break;
                            }
	                        case CMap::tile_scrap:      
                            {
                                req_name.push_back("mat_stone");
                                req_quantity.push_back(BlockCosts::scrap_stone / mat_discount);
                                req_name.push_back("mat_scrap");
                                req_quantity.push_back(BlockCosts::scrap_scrap / mat_discount);
                                break;
                            }
                        }

                        u8 matched_reqs = 0;
                        for (u8 k = 0; k < req_name.size(); k++)
                        {
                            bool has_reqs = caller.hasBlob(req_name[k], req_quantity[k] / mat_discount);
                            if (has_reqs)
                            {
                                matched_reqs++;
                                //printf(req_name[k]+req_quantity[k]);
                            }
                        }


                        if (matched_reqs > 0 && matched_reqs == req_name.size())
                        {
                            match_pos = offset;
                            t = newtile;

                            has_requirements = true;
                            break; // enough resources
                        }
                    }
                }
            }

            u8 blob_team = 255;
            u16 blob_deg = 0;
            string blob_name = "";
            string place_sound = "NoAmmo.ogg";

            switch (t)
            {
                case CMap::tile_castle:     
                {
                    place_sound = "build_wall2.ogg";
                    break;
                }
	            case CMap::tile_castle_back:
                {
                    place_sound = "build_wall.ogg";
                    break;
                }
	            case CMap::tile_wood:       
                {
                    place_sound = "build_wood.ogg";
                    break;
                }
	            case CMap::tile_wood_back:  
                {
                    place_sound = "build_wood.ogg";
                    break;
                }
	            case CMap::tile_scrap:      
                {
                    place_sound = "build_wall2.ogg";
                    break;
                }
            }

            //ParticleAnimated("LargeSmoke", match_pos, Vec2f_zero, 0, 1.0f, 5, 0, false);

            bool place_block = can_place && t != CMap::tile_empty && has_requirements;
            sendPlaceBlockClient(this, id, place_block, place_sound);
            
            if (place_block)
            {
                for (u8 i = 0; i < req_name.size(); i++)
                {
                    caller.TakeBlob(req_name[i], req_quantity[i]);
                }

                //if (is_blob) spawnBlob(map, blob_name, match_pos, blob_team, true, Vec2f_zero, blob_deg);
                
                map.server_SetTile(match_pos, t);
            }
            //else
            //{
            //    resetSelection(this);
            //}
        }
    }
    else if (cmd == this.getCommandID("mason_place_block_client"))
    {
        if (!isClient()) return;

        u16 id;
        if (!params.saferead_u16(id)) return;

        bool can_place;
        if (!params.saferead_bool(can_place)) return;

        string sound;
        if (!params.saferead_string(sound)) return;

        CBlob@ caller = getBlobByNetworkID(id);
        if (caller is null || !caller.isMyPlayer()) return;
        
        CSprite@ sprite = caller.getSprite();
        if (sprite !is null)
        {
            if (can_place)
            {
                sprite.PlaySound(sound, 1.0f, 1.0f + caller.get_f32("build_pitch"));
                lock_sound = false;
            }
            else if (!lock_sound)
            {
                sprite.PlaySound("NoAmmo.ogg", 0.75f, 1.0f+XORRandom(31)*0.01f);
                lock_sound = true;
            }
        }
    }
}

s32 selected = -1;

void RunSelectListener(CBlob@ this)
{
    if (!this.isMyPlayer()) return;
    
    CControls@ controls = this.getControls();
    if (controls is null) return;

    if (getHUD() !is null && !getHUD().hasMenus()) return;

    Vec2f pos = menu_pos;
    Vec2f dim = menu_dim;
    Vec2f aimpos = controls.getMouseScreenPos();

    int tile_size = 48;
    aimpos.x += (dim.x % 2 == 1 ? tile_size/2 : 0);
    aimpos.y += (dim.y % 2 == 1 ? tile_size : 0);

    Vec2f dir = (aimpos-pos);
    selected = Maths::Floor(dim.x/2) + (dir.x) / tile_size + Maths::Floor(((dir.y+tile_size*1.5f) / tile_size))*menu_grid_width;
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

            CGridButton@ button = menu.AddButton(str.icon, str.name,this.getCommandID("mason_select"), Vec2f(1, 1), params);
	        if (button !is null)
	        {
                //button.hoverText = str.icon;
	        }
        }
	}
}


//f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
//{
//    if (isServer())
//    {
//        resetSelection(this);
//    }
//
//    return damage;
//}

/*
void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;
    if (!blob.isMyPlayer()) return;
    CControls@ controls = getControls();
    if (controls is null) return;
    if (getHUD() !is null && !getHUD().hasMenus()) return;

    if(selected >= 0 && selected < structures.size())
    {
        f32 scale = 3;
        GUI::DrawIcon(structures[selected].filename, 0, Vec2f(24,24), Vec2f( getDriver().getScreenCenterPos().x + (-24 * scale), getDriver().getScreenHeight() * 0.7f), scale);
    }
}
*/