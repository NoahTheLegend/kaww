void onInit(CBlob@ this)
{
	this.Tag("medium weight");
	this.Tag("trap"); // so bullets pass
	this.set_f32("hand_rotation_damp", 0.6f);
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point !is null)
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;
		
		CBlob@ b = point.getOccupied();
		if (b !is null)
		{
			Vec2f dir = b.getAimPos() - b.getPosition();
			f32 angle = dir.Angle();

			bool exposed = b.hasTag("machinegunner") || b.hasTag("collidewithbullets") || b.hasTag("can_shoot_if_attached");
			s8 ff = (this.isFacingLeft()?-1:1);

			sprite.SetOffset(Vec2f(-1,-3).RotateBy(-angle*ff)*ff);
			sprite.SetVisible(!b.isAttached() || exposed);

			if (b.isMyPlayer())
			{
				b.set_u32("dont_change_zoom", getGameTime()+1);
				b.Tag("binoculars");
			}
		}
		else
		{
			sprite.SetOffset(Vec2f_zero);
			sprite.SetVisible(true);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (!blob.hasTag("flesh") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}


f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached()) return 0;
	return damage;
}