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

	if (this.getName() == "antitank" && blobName == "mat_heatwarhead")
	{
		this.server_PutInInventory(blob);
	}
	if (this.getName() != "antitank" && blobName == "mat_7mmround")
	{
		if (!this.hasBlob("mat_7mmround", 50)) this.server_PutInInventory(blob);
		
	}
}
