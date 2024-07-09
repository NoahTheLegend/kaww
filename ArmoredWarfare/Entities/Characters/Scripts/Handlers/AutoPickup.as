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
		CPlayer@ p = this.getPlayer();
		if (blobName == "ammo" && p !is null)
		{
			if (!this.hasBlob("ammo", p.get_u32("ammo_autopickup")))
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					u16 iq = inv.getCount("ammo");
					u16 bq = blob.getQuantity();
					int missing = p.get_u32("ammo_autopickup") - iq;

					if (bq <= missing)
					{
						this.server_PutInInventory(blob);
					}
					else
					{
						CBlob@ ammo = server_CreateBlob("ammo");
						if (ammo !is null)
						{
							ammo.server_SetQuantity(missing);
							blob.server_SetQuantity(bq - missing);

							if (!this.server_PutInInventory(ammo))
								ammo.server_Die();
						}
					}
				}
			}
			return;
		}

		this.server_PutInInventory(blob);
	}
}
