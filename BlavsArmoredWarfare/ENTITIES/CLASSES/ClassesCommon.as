void InAirLogic(CBlob@ this)
{
	if (!this.isOnGround() && !this.isOnLadder())
	{
		this.set_u8("inaccuracy", this.get_u8("inaccuracy") + 6);
		if (this.get_u8("inaccuracy") > inaccuracycap) { this.set_u8("inaccuracy", inaccuracycap); }
		this.setVelocity(Vec2f(this.getVelocity().x*0.92f, this.getVelocity().y));
	}
}