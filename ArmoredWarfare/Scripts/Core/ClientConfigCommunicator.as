
void onInit(CRules@ this)
{
    this.addCommandID("sync_clientconfig");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
    if (!isServer()) return;

    if (cmd == this.getCommandID("sync_clientconfig"))
    {
        u16 pid;
        if (!params.saferead_u16(pid)) return;

        CPlayer@ p = getPlayerByNetworkId(pid);
        if (p is null) return;

        u32 ammo_autopickup = params.read_u32();
        p.set_u32("ammo_autopickup", ammo_autopickup);
    }
}