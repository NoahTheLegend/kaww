#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "Accolades.as"

void onInit(CBlob@ this)
{
	if(this.get_string("reload_script") != "helmet")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this)
{
    CSpriteLayer@ helmet = this.getSprite().addSpriteLayer("helmet", "Helmet.png", 16, 16);
   
    if (helmet !is null)
    {
        helmet.addAnimation("default", 0, true);
		int[] frames = {0, 1, 2, 3, 4, 5};
		helmet.animation.AddFrames(frames);
		
		helmet.SetVisible(true);
        helmet.SetRelativeZ(0.28f);
        CSpriteLayer@ head = this.getSprite().getSpriteLayer("head");
        if (head !is null)
        {
            helmet.SetRelativeZ(head.getRelativeZ()+1.0f);
        }

        int tn = this.getTeamNum();
        int idx = tn == 0 ? 0 : tn == 1 ? 2 : tn == 2 ? 4 : 0;
        helmet.SetFrameIndex(idx);

        if (this.getPlayer() !is null)
        {
            for (u8 i = 0; i < getPatreonMembers().length; i++)
            {
                string name = getPatreonMembers()[i];
                if (name == this.getPlayer().getUsername())
                {
                    helmet.SetFrameIndex(idx + 1);
                }
            }
        }
        if(this.getSprite().isFacingLeft())
            helmet.SetFacingLeft(true);
    }
}
 
void onTick(CBlob@ this)
{
    if(this.get_string("reload_script") == "helmet")
    {
        UpdateScript(this);
        this.set_string("reload_script", "");
    }
 
    CSpriteLayer@ helmet = this.getSprite().getSpriteLayer("helmet");
   
    if (helmet !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -1);
        helmet.SetOffset(headoffset);
    }
}