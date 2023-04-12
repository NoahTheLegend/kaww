// used for hacking the sprite sync of actual parachute
// since the one is done client-side via spritelayer and 
// offscreen init doesnt work for our client
// i.e. OMG THIS PLAYER IS FLYING BUT HE HAS NO PARACHUTE HACKER

void onInit(CSprite@ this)
{
	this.SetRelativeZ(-100);
	this.SetAnimation("invisible");
	this.SetVisible(false);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	CAttachment@ aps = blob.getAttachments();
	if (aps !is null)
	{
		AttachmentPoint@ ap = aps.getAttachmentPointByName("PARACHUTE");
		if (ap !is null && ap.getOccupied() !is null)
		{
			CBlob@ at = ap.getOccupied();
			if (at.isOnGround() || at.isInWater() || at.isOnLadder() || at.hasTag("dead"))
			{
				blob.server_Die();	
				return;
			}

			if (at.isMyPlayer())
			{
				// don't show this if its our player, otherwise we will
				// see this moving serverside and our player clientside
				// uses spritelayer for clientside (that is never invisible)

				this.SetAnimation("invisible");
				this.SetVisible(false);
				return;
			}
			else
			{
				this.SetAnimation("default");
				this.SetVisible(true);
			}

			if (!at.isAttached())
			{
				this.SetFacingLeft(false);
				this.SetOffset(blob.getVelocity()*-1 + Vec2f(0.0f, -23.0f + Maths::Sin(getGameTime() / 5.0f)) + Vec2f(-1,0));
				f32 parachute_angle = (Maths::Sin((at.getOldVelocity().x + at.getVelocity().x)/2)*-10);
				parachute_angle = parachute_angle;
				this.ResetTransform();
				this.RotateBy(parachute_angle, Vec2f(0.5, 35.0));
				this.SetVisible(true);
			}
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ ap)
{
	this.server_Die();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}