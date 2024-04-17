void onInit(CBlob@ this)
{
	this.Tag("medium weight");
	this.Tag("trap"); // so bullets pass
	this.set_f32("hand_rotation_damp", 0.55f);
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;
	
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point !is null)
	{
		CBlob@ b = point.getOccupied();
		if (b !is null)
		{
			Vec2f dir = b.getAimPos() - b.getPosition();
			f32 angle = dir.Angle();

			bool exposed = b.hasTag("machinegunner") || b.hasTag("collidewithbullets") || b.hasTag("can_shoot_if_attached");
			s8 ff = (this.isFacingLeft()?-1:1);

			sprite.SetOffset(Vec2f(-1,-2.5f).RotateBy(-angle*ff)*ff);

			if (b.isMyPlayer())
			{
				b.set_u32("far_zoom", getGameTime()+1);
				b.Tag("binoculars");
			}
		}
		else
		{
			sprite.SetOffset(Vec2f(2,2.5f));
		}
	}
	else
	{
		sprite.SetOffset(Vec2f(2,2.5f));
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

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	sprite.SetVisible(false);
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	sprite.SetVisible(true);
}