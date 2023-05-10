
void onInit(CBlob@ this)
{
    this.set_u16("set_tickets", 0);
    string[] tickets = this.getName().split("_");
    this.getShape().SetGravityScale(0.0f);
}

void onTick(CBlob@ this)
{
    if (getGameTime()==180)
    {
        string[] tickets = this.getName().split("_");
        if (tickets.length > 1)
        {
            printf(tickets[1]);
            getRules().set_s16("teamLeftTickets", parseInt(tickets[1]));
            getRules().set_s16("teamRightTickets", parseInt(tickets[1]));
            if (isServer()) this.server_Die();
        }
    }
}