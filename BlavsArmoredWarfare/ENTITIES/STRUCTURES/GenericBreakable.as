
void onInit(CBlob@ this)
{
    this.Tag("destructable");
	this.Tag("builder always hit");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    return damage;
}