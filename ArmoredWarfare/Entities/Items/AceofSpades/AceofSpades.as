#include "PerksCommon.as";

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
	CPlayer@ p = blob.getPlayer();

	if (!blob.hasTag("flesh"))
	{
		this.server_Die();
		return;
	}
	if (p is null)
	{
		this.server_Die();
		return;
	}

	PerkStats@ stats;
	if (!p.get("PerkStats", @stats) || stats.id != 5)
	{
		this.server_Die();
		return;
	}
}