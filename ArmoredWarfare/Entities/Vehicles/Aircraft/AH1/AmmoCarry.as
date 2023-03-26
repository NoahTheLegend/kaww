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