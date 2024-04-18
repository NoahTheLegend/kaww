#include "PerksCommon.as";

void onInit(CRules@ this)
{
    this.addCommandID("sync_perks_to_player");
}

/*void onTick(CRules@ this)
{
    if (!isServer()) return;

    for (u8 i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
        if (player is null || player.isBot()) continue;
        if (player.hasTag("synced_perks")) continue;

        player.Tag("synced_perks");

        CBitStream params;
        params.write_u16(player.getNetworkID());

        u16[] ids;
        string[] player_perks;

        for (u8 j = 0; j < getPlayersCount(); j++)
        {
            CPlayer@ p = getPlayer(j);
            if (p is null || p is player) continue;
            string perk = this.get_string(p.getUsername()+"_perk");

            ids.push_back(p.getNetworkID());
            player_perks.push_back(perk);
        }

        u8 size = ids.size();
        params.write_u8(size);

        for (u8 j = 0; j < size; j++)
        {
            params.write_u16(ids[j]);
            params.write_string(player_perks[j]);
        }

        if (size > 0)
        {
            this.SendCommand(this.getCommandID("sync_perks_to_player"), params, player);
        }
    }
}*/

/*
void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    if (!isServer()) return;
    if (player is null) return;
    
    CBitStream params;
    params.write_u16(player.getNetworkID());

    u16[] ids;
    string[] player_perks;

    for (u8 i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        if (p is null || p is player) continue;
        string perk = this.get_string(p.getUsername()+"_perk");

        ids.push_back(p.getNetworkID());
        player_perks.push_back(perk);
    }

    u8 size = ids.size();
    params.write_u8(size);

    for (u8 i = 0; i < size; i++)
    {
        params.write_u16(ids[i]);
        params.write_string(player_perks[i]);
    }
    
    if (size > 0)
    {
        this.SendCommand(this.getCommandID("sync_perks_to_player"), params, player);
    }
}*/

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync_perks_to_player"))
    {
        if (!isClient()) return;
        u16 me_id = params.read_u16();
        u8 size = params.read_u8();

        CPlayer@ me = getPlayerByNetworkId(me_id);
        if (!me.isMyPlayer()) return;

        for (u8 i = 0; i < size; i++)
        {
            u16 id = params.read_u16();
            string perk = params.read_string();
            
            CPlayer@ p = getPlayerByNetworkId(id);
            if (p is null) continue;
            
            addPerk(p, perks.find(perk));
        }
    }
}