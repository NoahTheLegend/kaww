void onInit(CBlob@ this)
{	
	this.SetFacingLeft(true);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("SEAT");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_up);
	}
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("SEAT");
	
	if (ap !is null)
	{
		if (ap.isKeyJustPressed(key_up))
		{
			if (isServer())
			{
				CBlob@ seated = ap.getOccupied();
				if (seated !is null)  seated.server_DetachFrom(this);
			}
		}
	}
}		

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}