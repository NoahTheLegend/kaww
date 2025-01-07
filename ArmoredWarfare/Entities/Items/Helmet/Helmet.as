void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    u8 tn = blob.getTeamNum();
    this.animation.frame = tn == 0 ? 0 : tn == 1 ? 2 : tn == 2 ? 4 : 0;

    blob.inventoryIconFrame = this.animation.frame;
}

void onChangeTeam(CBlob@ this, u8 oldTeam)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u8 tn = this.getTeamNum();
    sprite.animation.frame = tn == 0 ? 0 : tn == 1 ? 2 : tn == 2 ? 4 : 0;

    this.inventoryIconFrame = sprite.animation.frame;
}