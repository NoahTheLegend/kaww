#include "MasonPerkCommon.as";

const int sw = getDriver().getScreenWidth();
const int sh = getDriver().getScreenHeight();

const Vec2f menu_pos = Vec2f(15, sh-235);
const Vec2f btn_size = Vec2f(100, 50);
const Vec2f extra    = Vec2f(4,4);

bool was_hover = false;
bool was_pressed = false;

void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    if (!blob.isMyPlayer()) return;
    CControls@ controls = blob.getControls();
    if (controls is null) return;

    Vec2f size = btn_size;
    Vec2f tl = menu_pos;
    Vec2f br = tl+btn_size;

    Vec2f aimpos = controls.getMouseScreenPos();
    bool hover = isInArea(tl, br, aimpos);
    bool pressed = hover && (controls.mousePressed1 || controls.mousePressed2);
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
        if (!was_pressed)
        {
            sendOpenMenu(blob);
            this.PlaySound("menuclick.ogg", 1.0f, 0.5f+XORRandom(6)*0.01f);
            was_pressed = true;
        }
    }
    else was_pressed = false;
    
    DrawSimpleButton(tl, br, SColor(0xffa5a5a5), SColor(0x00000000), hover, pressed, 2, 2, alpha);
    GUI::DrawIcon("MasonIcons.png", 0, Vec2f(32,32), tl+Vec2f(-4,-4), 1.0f, SColor(Maths::Min(255, alpha*2),255,255,255));
    GUI::DrawIcon("MasonIcons.png", 1, Vec2f(32,32), tl+Vec2f(48,0), 0.75f, SColor(Maths::Min(255, alpha*2),255,255,255));
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