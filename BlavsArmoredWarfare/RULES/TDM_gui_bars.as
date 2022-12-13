#include "TeamColour.as";

SColor color_blue(255, 30, 30, 250);
SColor color_red(255, 250, 30, 30);

u16 blue_team_kills = 0;
u16 red_team_kills = 0;

void onRender(CRules@ this)
{
    GUI::SetFont("menu");

    GUI::DrawText( ""+this.get_u16("blue_kills"), Vec2f(245,70), getTeamColor(0) );
    GUI::DrawText( ""+this.get_u16("red_kills"), Vec2f(245,86), getTeamColor(1) );
}