
void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
    sprite.SetRelativeZ(this.getName() == "cranearm" ? -45.0f : -46.0f);

    this.Tag("heavy weight");
    this.Tag("trap");

    this.getShape().getConsts().mapCollisions = false;
    this.getShape().SetGravityScale(0);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return false;
}