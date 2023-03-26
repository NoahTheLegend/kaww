void onTick(CBlob@ this)
{
	if (!isServer()) return;
	if (this.isAttached())
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (ap !is null && ap.getOccupied() !is null)
		{
			ap.getOccupied().server_PutInInventory(this);
			return;
		}
	}
	else
		this.server_Die();
}