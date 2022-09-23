
void onTick(CBlob@ this)
{
    if (isServer() && getGameTime()%10==0)
    {
        CBlob@[] mgs;
        getBlobsByName("heavygun", @mgs);

        for (u16 i = 0; i < mgs.length; i++)
        {
            CBlob@ mg = mgs[i];
            if (mg is null) continue;
            if (!mg.isAttached() && mg.hasAttached() && mg.getDistanceTo(this) < 20.0f)
            {
                //printf("e");
                AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("BOW");
                if (ap !is null && ap.getOccupied() is null)
                {
                    this.server_AttachTo(mg, ap);
                }
            }
        }
    }
}