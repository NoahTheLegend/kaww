
void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
    sprite.SetRelativeZ(this.getName() == "cranearm" ? -45.0f : -46.0f);

    this.Tag("heavy weight");

    CShape@ shape = this.getShape();
    shape.getConsts().mapCollisions = false;
    shape.SetGravityScale(0);
    shape.getConsts().net_threshold_multiplier = 0.5f;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return false;
}