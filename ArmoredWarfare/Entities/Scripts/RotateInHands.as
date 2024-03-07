#define SERVER_ONLY

void onTick(CBlob@ this)
{
    if (!this.hasTag("hand_rotation")) return;

	f32 hand_angle_offset = this.get_f32("hand_angle");
	this.setAngleDegrees(hand_angle_offset);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ ap)
{
    this.Tag("hand_rotation");
    this.set_f32("hand_angle", 0);

    if (!isClient()) return;
    this.getSprite().ResetTransform();
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ ap)
{
    this.Untag("hand_rotation");
}