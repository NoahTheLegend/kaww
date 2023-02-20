bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
    if (forBlob is null)
    {
        return false;
    }
    return forBlob.getTeamNum() == this.getTeamNum() && !forBlob.isAttached();
}

