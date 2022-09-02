SColor color_blue(255, 30, 30, 250);
SColor color_red(255, 250, 30, 30);

u16 blue_team_kills = 0;
u16 red_team_kills = 0;

void onPlayerDie( CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData )
{
    if (isServer())
    {
        if (attacker != null)
        {
        	if (attacker.getTeamNum() == victim.getTeamNum())
        	{
        		// Give point to other team
        		if (attacker.getTeamNum() == 0)
	            {
	                red_team_kills++;
	                this.set_u16("red_kills", red_team_kills);
	                this.Sync("red_kills", true);
	            }
	            else if (attacker.getTeamNum() == 1)
	            {
	                blue_team_kills++;
	                this.set_u16("blue_kills", blue_team_kills);
	                this.Sync("blue_kills", true);
	            }

        		return;
        	}

            if (attacker.getTeamNum() == 0)
            {
                blue_team_kills++;
                this.set_u16("blue_kills", blue_team_kills);
                this.Sync("blue_kills", true);
            }
            else if (attacker.getTeamNum() == 1)
            {
                red_team_kills++;
                this.set_u16("red_kills", red_team_kills);
                this.Sync("red_kills", true);
            }
        }
    }
}

void onRestart(CRules@ this)
{
    blue_team_kills = 0;
    this.set_u16("blue_kills", blue_team_kills);
    red_team_kills = 0;
    this.set_u16("red_kills", red_team_kills);
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
    if (isServer())
    {
        this.SyncToPlayer("blue_kills", player);
        this.SyncToPlayer("red_kills", player);
    }
}

void onRender(CRules@ this)
{
	if (getMap().getMapName() == "KAWWTraining.png")
    {
    	GUI::SetFont("menu");
   	 GUI::DrawTextCentered( "Bootcamp", Vec2f(getScreenWidth()/2,16), color_white );

        return;
    }

    GUI::SetFont("menu");
    GUI::DrawTextCentered( "KILLS:", Vec2f(getScreenWidth()/2,16), color_white );

    GUI::DrawText( ""+this.get_u16("blue_kills"), Vec2f(-25 + getScreenWidth()/2, 30), color_blue );
    GUI::DrawText( ""+this.get_u16("red_kills"), Vec2f(15 + getScreenWidth()/2, 30), color_red );
}