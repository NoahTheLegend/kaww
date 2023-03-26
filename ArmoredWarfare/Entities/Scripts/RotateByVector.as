
void onTick(CBlob@ this)
{
    if (this.hasTag("change rotation"))
    {
        Vec2f vel = this.getOldPosition() - this.getPosition();
        if (vel.Length() > 1.0f)
            this.setAngleDegrees(-vel.Angle()-270);
        if (this.isOnGround()) this.Untag("change rotation");
    }
}