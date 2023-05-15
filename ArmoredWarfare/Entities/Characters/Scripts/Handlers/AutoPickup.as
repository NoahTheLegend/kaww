#define SERVER_ONLY

#include "CratePickupCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.getShape().vellen > 1.0f)
	{
		return;
	}

	string blobName = blob.getName();
	if (blobName == this.get_string("ammo_prop"))
	{
		if (blobName == "ammo")
		{
			if (!this.hasBlob("ammo", 50)) this.server_PutInInventory(blob);
			return;
		}
		this.server_PutInInventory(blob);
	}
}
