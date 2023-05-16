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

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (!isServer()) return;

	if (!blob.hasTag("flesh"))
	{
		this.server_Die();
		return;
	}
	if (blob.getPlayer() is null)
	{
		this.server_Die();
		return;
	}
	if (getRules().get_string(blob.getPlayer().getUsername() + "_perk") != "Lucky")
	{
		this.server_Die();
		return;
	}
}