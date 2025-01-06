void onInit(CBlob@ this)
{
    if (getNet().isServer())
	{
		for (u8 i = 0; i < 3; i++)
		{
			CBlob@ ammo = server_CreateBlob("ammo");
			if (ammo !is null)
			{
				if (!this.server_PutInInventory(ammo))
					ammo.server_Die();
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
    if (forBlob is null)
    {
        return false;
    }
    return forBlob.getTeamNum() == this.getTeamNum() && !forBlob.isAttached();
}

void onTick(CBlob@ this)
{
    if (isServer() && !this.isAttached())
    {
        this.server_Die();
    }
}