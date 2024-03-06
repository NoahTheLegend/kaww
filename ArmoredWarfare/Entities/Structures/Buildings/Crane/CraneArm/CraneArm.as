
void onInit(CBlob@ this)
{
    bool main = this.getName() == "cranearm";

	CSprite@ sprite = this.getSprite();
    sprite.SetRelativeZ(main ? -45.0f : -46.0f);

    this.Tag("heavy weight");

    CShape@ shape = this.getShape();
    shape.getConsts().mapCollisions = false;
    shape.SetGravityScale(0);
    shape.getConsts().net_threshold_multiplier = 0.5f;

    if (main)
    {
        sprite.SetEmitSound("crane_rotary_loop.ogg");
        sprite.SetEmitSoundSpeed(1.0f);
	    sprite.SetRelativeZ(75.0f);
    }
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return false;
}