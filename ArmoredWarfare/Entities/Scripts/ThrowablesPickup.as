bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    f32 vellen = this.getVelocity().Length();
	return vellen <= 2.5f || this.isOnGround();
}