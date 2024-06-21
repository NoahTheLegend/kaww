#include "Hitters.as"

void onDie(CBlob@ this)
{
    if (!isServer()) return;

    AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			if (ap is null) continue;

            CBlob@ attached = ap.getOccupied();
            if (attached is null) continue;

            if (attached.hasTag("machinegun"))
            {
                AttachmentPoint@ mg_ap = attached.getAttachments().getAttachmentPointByName("GUNNER");
                if (mg_ap is null) continue;

                CBlob@ mgunner = mg_ap.getOccupied();
                if (mgunner is null) continue;

                if (mgunner.hasTag("player"))
                    @attached = @mgunner; 
            }

            if (!attached.hasTag("player")) continue;

            this.server_Hit(attached, attached.getPosition(), this.getOldVelocity(), 50.0f, Hitters::explosion, true);
            attached.server_Die();
		}
	}
}