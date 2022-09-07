//Set gamemode to "Testing" for this to activate.

#include "NuMenuCommon.as";
#include "NuTextCommon.as";

void onInit( CRules@ this )
{
    if(!isClient())
    {
        return;
    }
    
    init = true;

    NuHub@ hub;
    if(!getHub(@hub)) { return; }

    print("Text AAAA Creation");

    array<NuText@> screaming();
}

void onReload( CRules@ this )
{
    onInit(this);
}

//TODO, remove those that get too far away from the end of the map.

void onTick( CRules@ this )
{
    if(getGameTime() % 1 == 0)
    {
        CPlayer@ player = getLocalPlayer();
        if(player != null)
        {
            CControls@ controls = getControls();
            if(controls.isKeyPressed(KEY_LCONTROL) && controls.isKeyPressed(KEY_KEY_E))
            {
                CBlob@ blob = player.getBlob();
                if(blob != null)
                {
                    u8 rnd = XORRandom(50);
                    
                    NuText@ txt;
                    if(rnd < 45)
                    {
                        @txt = @NuText("Lato-Regular", "A");
                    }
                    else if(rnd < 49)
                    {
                        @txt = @NuText("Lato-Regular", "AA\nAA");
                    }
                    else if(rnd == 48)
                    {
                        @txt = @NuText("Lato-Regular", "Applesauce!");
                    }
                    else
                    {
                        @txt = @NuText("Lato-Regular", "B");
                    }
                    
                    if(rnd > 0)
                    {
                        txt.setScale(Vec2f(0.25f, 0.25f));
                    }
                    else
                    {
                        txt.setScale(Vec2f(0.5f, 0.5f));
                    }

                    screaming.push_back(@txt);
                
                    //screaming_direction.push_back(RandomDirection());    
                    screaming_direction.push_back(getRandomVelocity(0, 12.0f, 360));

                    screaming_pos.push_back(controls.getMouseWorldPos() - txt.string_size_total / 2);
                
                    screaming_angle_vel.push_back(XORRandom(50));
                }
            }
        }
    }

    CMap@ map = getMap();
    Vec2f map_size = Vec2f(map.tilemapwidth * map.tilesize, map.tilemapheight * map.tilesize);

    for(u16 i = 0; i < screaming.size(); i++)
    {
        screaming[i].setColor(SColor(255, 255, 0, 0));

        screaming[i].setAngle(screaming[i].getAngle() + screaming_angle_vel[i]);

        screaming_pos[i] += screaming_direction[i];


        bool point_of_no_return = false;
        if(screaming_pos[i].x > map_size.x)//Greater than map width
        {
            point_of_no_return = true;
        }
        else if(screaming_pos[i].y > map_size.y)//Greater than map height
        {
            point_of_no_return = true;
        }
        else if(screaming_pos[i].x + screaming[i].string_size_total.x < 0)//Less than map width
        {
            point_of_no_return = true;
        }
        else if(screaming_pos[i].y + screaming[i].string_size_total.y < 0)//Less than map height
        {
            point_of_no_return = true;
        }

        if(point_of_no_return)//Kill this text
        {
            screaming.removeAt(i);
            screaming_pos.removeAt(i);
            screaming_direction.removeAt(i);
            i--;
        }
    }
}

array<NuText@> screaming;
array<Vec2f> screaming_pos;
array<Vec2f> screaming_direction;
array<float> screaming_angle_vel;


bool init;

void onRender(CRules@ this)
{
    if(!init){ return; }//If the init has not yet happened.
    for(u16 i = 0; i < screaming.size(); i++)
    {
        screaming[i].Render(screaming_pos[i]);
    }
}



Vec2f RandomDirection()
{
    u8 rnd = XORRandom(7);

    if(rnd == 0){
        return Vec2f(-1, 0);
    }
    else if(rnd == 1){
        return Vec2f(1, 0);
    }
    else if(rnd == 2){
        return Vec2f(0, 1);
    }
    else if(rnd == 3){
        return Vec2f(0, -1);
    }
    else if(rnd == 4){
        return Vec2f(1, 1);
    }
    else if(rnd == 5){
        return Vec2f(-1, -1);
    }
    else
    {
        return Vec2f(0,0);
    }

}