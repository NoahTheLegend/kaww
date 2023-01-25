#include "PixelOffsets.as"
#include "RunnerTextures.as"

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
		int[] frames = {0};
		helmet.animation.AddFrames(frames);
		
		helmet.SetVisible(true);
        helmet.SetRelativeZ(0.2f);
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