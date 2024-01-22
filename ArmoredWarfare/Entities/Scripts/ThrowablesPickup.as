bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    CShape@ shape = this.getShape();
	return shape !is null && shape.vellen < 2.0f;
}