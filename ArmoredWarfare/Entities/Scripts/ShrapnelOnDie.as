
void onDie(CBlob@ this)
{
    if (isServer())
    {
        if (this.get_string("shrapnel_iftag") != "" && !this.hasTag(this.get_string("shrapnel_iftag")))
            return;
        //common
        u8 count = 10; 
        f32 time_to_die = 10.0f;
        f32 vel = 10.0f;
        f32 vel_random = 0.0f;
        Vec2f offset = Vec2f(0,0);
        if (this.exists("shrapnel_count")) count = this.get_u8("shrapnel_count");   
        if (this.exists("shrapnel_timetodie")) time_to_die = this.get_f32("shrapnel_timetodie");
        if (this.exists("shrapnel_vel")) vel = this.get_f32("shrapnel_vel");
        if (this.exists("shrapnel_vel_random")) vel_random = this.get_f32("shrapnel_vel_random");
        if (this.exists("shrapnel_offset")) offset = this.get_Vec2f("shrapnel_offset");

        //angle
        bool random = false; // if true, each's piece angle is separated evenly and random angle_deviation is added
        f32 angle_deviation = 0.0f;
        f32 angle_max = 45;
        
        if (this.exists("shrapnel_random")) random = this.get_bool("shrapnel_random");
        if (this.exists("shrapnel_angle_deviation")) angle_deviation = this.get_f32("shrapnel_angle_deviation");
        if (this.exists("shrapnel_angle_max")) angle_max = this.get_f32("shrapnel_angle_max");
        
        for (u8 i = 0; i <= count * this.getQuantity(); i++)
        {
            Vec2f dir = Vec2f(0, -1); //center dir, angle max is +-(angle_max/2) from that point
            if (this.exists("shrapnel_dir")) dir = this.get_Vec2f("shrapnel_dir");

            Vec2f current_dir = Vec2f(0,0);
            if (random)
            {
                current_dir = dir;
                current_dir.RotateBy(XORRandom(angle_max) - (angle_max*0.5f));
            }
            else
            {
                //printf(""+(-angle_max/2 + angle_max/count*i));
                //printf(""+current_dir.x+" "+current_dir.y);

                current_dir = dir;
                current_dir.RotateBy(-angle_max/2 + angle_max/count*i);
                current_dir.RotateBy(XORRandom(angle_deviation) - (angle_deviation/2));
            }

            CBlob@ shrapnel = server_CreateBlob("shrapnel", this.getTeamNum(), this.getPosition()+Vec2f(offset.x, offset.y*this.getVelocity().Length()));
            if (shrapnel !is null)
            {
                shrapnel.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
                shrapnel.setVelocity(Vec2f(this.getVelocity().x/4, 0) + current_dir*(vel+(XORRandom(vel_random*10)*0.1f)));
                shrapnel.server_SetTimeToDie(time_to_die);
            }
        }
    }
}