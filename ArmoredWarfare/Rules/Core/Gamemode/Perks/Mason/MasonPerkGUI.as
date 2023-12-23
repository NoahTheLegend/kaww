#include "MasonPerkCommon.as";

const int sw = getDriver().getScreenWidth();
const int sh = getDriver().getScreenHeight();

const Vec2f btn_pos = Vec2f(15, sh-235);
const Vec2f btn_size = Vec2f(100, 50);
const Vec2f extra    = Vec2f(4,4);

bool was_hover = false;
bool was_pressed_a3 = false;
bool was_pressed_lmb = false;
bool was_pressed_rmb = false;

void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    if (!blob.isMyPlayer()) return;
    CControls@ controls = blob.getControls();
    if (controls is null) return;

    u32 timing = blob.get_u32("selected_structure_time");

    Vec2f size = btn_size;
    Vec2f tl = btn_pos;
    Vec2f br = tl+btn_size;

    Vec2f mpos = controls.getMouseScreenPos();
    bool hover = isInArea(tl, br, mpos);
    bool a3 = blob.isKeyPressed(key_action3);
    bool pressed = (hover && a3) || (a3 && controls.isKeyPressed(KEY_LSHIFT)); //(controls.mousePressed1 || controls.mousePressed2);
    u8 alpha = pressed ? 200 : hover ? 125 : 35;

    if (hover)
    {
        if (!was_hover)
        {
            Sound::Play("select.ogg");
            was_hover = true;
        }
    }
    else was_hover = false;

    if (pressed)
    {
        if (!was_pressed_a3)
        {
            sendOpenMenu(blob);
            this.PlaySound("menuclick.ogg", 1.0f, 0.5f+XORRandom(6)*0.01f);
            was_pressed_a3 = true;
        }
    }
    else was_pressed_a3 = false;
    
    DrawSimpleButton(tl, br, SColor(0xffa5a5a5), SColor(0x00000000), hover, pressed, 2, 2, alpha);
    DrawSelected(this, blob, mpos, controls, timing);
    
    GUI::DrawIcon("MasonIcons.png", 0, Vec2f(32,32), tl+Vec2f(-4,-4), 1.0f, SColor(Maths::Min(255, alpha*2),255,255,255));
    GUI::DrawIcon("MasonIcons.png", 1, Vec2f(32,32), tl+Vec2f(48,0), 0.75f, SColor(Maths::Min(255, alpha*2),255,255,255));
    if (hover) GUI::DrawTextCentered("[SHIFT+SPACE]", tl + Vec2f(size.x/2-2, size.y + 9), SColor(50,255,255,255));
}


void DrawSimpleButton(Vec2f tl, Vec2f br, SColor color, SColor bordercolor, bool hover, bool pressed, f32 outer, f32 inner, u8 alpha)
{
    if (pressed)
    {
        tl += Vec2f(0,1);
        br += Vec2f(0,1);
    }
    Vec2f combined = Vec2f(inner,inner);

    color.setAlpha(alpha);
    bordercolor.setAlpha(alpha);

    u8 hv = hover && !pressed ? 50 : 25;
    GUI::DrawRectangle(tl-Vec2f(outer,outer), br+Vec2f(outer,outer), bordercolor); // draw a bit bigger rectangle for border effect
    GUI::DrawRectangle(tl, br, SColor(alpha, color.getRed()+hv, color.getGreen()+hv, color.getBlue()+hv)); // draw inner rectangle border
    
    if (pressed)
    {
        GUI::DrawRectangle(tl+Vec2f(inner,inner), br-Vec2f(inner,inner), bordercolor);
        combined = Vec2f(outer+inner,outer+inner);
    }

    hv = hover ? 25 : 0;
    GUI::DrawPane(tl+combined, br-combined, pressed ? SColor(color.getAlpha(), color.getRed()-25, color.getGreen()-25, color.getBlue()-25)
        : hover ? SColor(alpha, color.getRed()+hv, color.getGreen()+hv, color.getBlue()+hv) : color);
}

void DrawSelected(CSprite@ this, CBlob@ blob, Vec2f mpos, CControls@ controls, u32 timing)
{
    s32 selected = blob.get_s32("selected_structure");
    if (selected < 0) return;

    CCamera@ camera = getCamera();
    if (camera is null) return;
    f32 zoom = camera.targetDistance * getDriver().getResolutionScaleFactor() * getDriver().getResolutionScaleFactor();

    Vec2f bpos = blob.getPosition();

    CMap@ map = getMap();

    Vec2f buildpos = blob.get_Vec2f("building_structure_pos");
    bool building = buildpos.x > 0;

    Vec2f aimpos = building ? buildpos : blob.getAimPos();
    Vec2f tile_aimpos = map.getTileSpacePosition(aimpos);
    tile_aimpos = map.getTileWorldPosition(tile_aimpos);
    Vec2f drawpos = getDriver().getScreenPosFromWorldPos(tile_aimpos);

    Structure str = structures[selected];

    u8 sz = str.grid.size();
    for (int i = 0; i < sz; i++)
    {
        u8 szi = str.grid[i].size();
        for (int j = 0; j < szi; j++)
        {
            Vec2f tilepos = drawpos + Vec2f((f32(j)-szi/2)*16*zoom, (i-sz/2)*16*zoom);
            SColor col = SColor(150,75,255,75);

            Vec2f world_tilepos = tile_aimpos + Vec2f((j-szi/2)*8, (i-sz/2)*8);
            TileType t = map.getTile(world_tilepos).type;

            if (!isTileCustomSolid(t))
            {
                if ((world_tilepos-bpos).Length() > build_range
                    || !map.hasSupportAtPos(world_tilepos))
                {
                    col.setAlpha(50);
                    col.setRed(255);
                    col.setGreen(75);
                }

                u16 num = str.grid[i][j];
                if (num == 0) col.setAlpha(0);

                GUI::DrawIcon("World.png", num, Vec2f(8,8), tilepos, zoom, col);
            }
        }
    }

    if (!building)
    {
        bool pressed_a1 = (controls.mousePressed1);
        if (pressed_a1 && timing < getGameTime()-5 && getHUD() !is null && !getHUD().hasMenus())
        {
            if (!was_pressed_lmb)
            {
                sendPlaceStructure(blob, tile_aimpos);
                was_pressed_lmb = true;
            }
        }
        else was_pressed_lmb = false;
    }
    else
    {
        DrawQTE(this, blob, drawpos, zoom, controls);
    }

    bool pressed_a2 = (controls.mousePressed2);
    if (pressed_a2 && timing < getGameTime()-5 && getHUD() !is null && !getHUD().hasMenus())
    {
        if (!was_pressed_rmb)
        {
            resetSelection(blob);
            was_pressed_rmb = true;
        }
    }
    else was_pressed_rmb = false;

    GUI::DrawTextCentered("Selection: "+selected, Vec2f(500,500), SColor(255,255,255,0));
}

bool was_pressed_qte = false;

void DrawQTE(CSprite@ this, CBlob@ blob, Vec2f drawpos, f32 zoom, CControls@ controls)
{
    u8 required_button = blob.get_u8("next_qte");
    bool wrong = true;
    bool correct_qte = controls.lastKeyPressed == qte[required_button];
    bool pressed_qte = controls.lastKeyPressed >= qte[0] && controls.lastKeyPressed <= qte[qte.size()-1];

    if (pressed_qte && getHUD() !is null && !getHUD().hasMenus())
    {
        if (!was_pressed_qte)
        {
            sendPlaceBlock(blob, correct_qte);
            was_pressed_qte = true;
        }
    }
    else was_pressed_qte = false;

    GUI::DrawIcon("Keys.png", required_button + ((getGameTime() / 5) % 2 == 0 ? qte.size() : 0), Vec2f(16,16), drawpos - Vec2f(0, 64) * zoom, zoom, SColor(255,255,255,255));
}