void onTick(CBlob@ this)
{
    Vec2f vel = this.getOldPosition() - this.getPosition();
    if (Maths::Abs(vel.x) <= 0.1f) return;

    if (!this.isAttached())
	{
		this.setAngleDegrees(this.getAngleDegrees()-vel.x*8.0f);
	}
}