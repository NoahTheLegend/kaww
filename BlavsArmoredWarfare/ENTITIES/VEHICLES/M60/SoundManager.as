const string engineRPMString_Manager = "engine_RPM_M";
const float baseVolume = 1.0f;
void onInit(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();

    const bool type = this.get_bool("manager_Type");

    sprite.SetEmitSound(type ? "EngineRun_mid.ogg" : "EngineRun_low.ogg");

	sprite.SetEmitSoundSpeed(1.0f);
    sprite.SetEmitSoundVolume(1.0f);
	sprite.SetEmitSoundPaused(false);

    this.getShape().SetGravityScale(0.0f);
}

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();

    const bool type = this.get_bool("manager_Type");
    const float rpm = this.get_f32(engineRPMString_Manager);

    if (rpm == 0)
    {
        sprite.SetEmitSoundPaused(true);
        return; //pause both
    }
    else{
        sprite.SetEmitSoundPaused(false);
    }

    if (!type)
    {
        if (rpm < 6000)
        {
            sprite.SetEmitSound("EngineRun_low.ogg");
        }
        else
        {
            sprite.SetEmitSound("EngineRun_high.ogg");
        }

        sprite.SetEmitSoundSpeed(
            Maths::Min(0.01f + Maths::Abs(rpm / 2000), 1.15f) * 1.0);
    }
    else{
        sprite.SetEmitSoundSpeed(
            Maths::Min(0.01f + Maths::Abs(rpm / 6000), 1.3f) * 1.0);
    }
   
    

    if (rpm > 2000)
    {
        if (type) // MANAGER 1
        {
            sprite.SetEmitSoundVolume(Maths::Clamp(Maths::Abs((2000 - rpm) / 1000), 0, baseVolume));
            print("mid " +Maths::Clamp(Maths::Abs((2000 - rpm) / 1000), 0, baseVolume));
        }
        else // MANAGER 2
        {
            if (rpm < 6000)
            {
                sprite.SetEmitSoundVolume(Maths::Clamp(1.0f - Maths::Abs(2000 - rpm) / 2000, 0, baseVolume));
                print("low " + Maths::Clamp(1.0f - Maths::Abs(2000 - rpm) / 2000, 0, baseVolume));
            }
            else {
                //print("c " + Maths::Abs(Maths::Min(6000 - rpm, 1000) / 1000));
                sprite.SetEmitSoundVolume(Maths::Clamp(Maths::Abs((6000 - rpm) / 1000), 0, baseVolume));
                print("high " + Maths::Clamp(Maths::Abs((6000 - rpm) / 1000), 0, baseVolume));
            }
        }
    }
    else
    {
        const u32 low_rpm_fade = 800;
        if (rpm < low_rpm_fade)
        {
            sprite.SetEmitSoundVolume(1 - (low_rpm_fade - rpm)/low_rpm_fade);
            //print("start " + (1 - (low_rpm_fade - rpm)/low_rpm_fade));
        }
        else
        {
             // only idle
            sprite.SetEmitSoundVolume(type ? 0 : baseVolume);
            //sprite.SetEmitSoundVolume(baseVolume);
        }
       
    }
    
}











//script by blav