const string engineRPMString_Manager = "engine_RPM_M";
const float baseVolume = 1.0f; // 1.0 is smooth, 1.1 adds grime

const float idleRestingPitch = 300.0f;
const string isThisOnGroundString = "isThisOnGround";

void onInit(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();

    const bool type = this.get_bool("manager_Type");

    if (!this.exists("engine_high")) this.set_string("engine_high", "EngineRun_high.ogg");
    if (!this.exists("engine_mid")) this.set_string("engine_mid", "EngineRun_mid.ogg");
    if (!this.exists("engine_low")) this.set_string("engine_low", "EngineRun_low.ogg");

    sprite.SetEmitSound(type ? this.get_string("engine_mid") : this.get_string("engine_low"));

	sprite.SetEmitSoundSpeed(1.0f);
    sprite.SetEmitSoundVolume(0.1f);
	sprite.SetEmitSoundPaused(true);

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

    //print("a " + this.get_bool(isThisOnGroundString));

    if (!type)
    {
        if (rpm < 5000) // switch to idle
        {
            sprite.SetEmitSound(this.get_string("engine_low"));

            f32 pitchMod = this.get_f32("custom_pitch");
            if (this.get_bool("engine_stuck")) pitchMod = 0.65f;
            if (pitchMod < 0.01f) pitchMod = 0.01f;

            sprite.SetEmitSoundSpeed(
                Maths::Min(0.01f + Maths::Abs((idleRestingPitch - rpm) / 2000), 1.00f) * 1.0 * pitchMod);
        }
        else // high rpm
        {
            sprite.SetEmitSound(this.get_string("engine_high"));

            f32 pitchMod = this.get_f32("custom_pitch");
            if (!this.get_bool("isThisOnGround")) pitchMod *= 0.9f;
            if (pitchMod < 0.01f) pitchMod = 0.01f;

            sprite.SetEmitSoundSpeed(
                Maths::Min(0.01f + Maths::Abs((5500 - rpm) / 3000), 1.15f) * 1.0 * pitchMod);

            if(!this.get_bool(isThisOnGroundString))
            {
                sprite.SetEmitSoundSpeed(sprite.getEmitSoundSpeed() * 1.25f * pitchMod);
            }
        }        
    }
    else{ 
        // middle ground
        f32 pitchMod = this.get_f32("custom_pitch");
        if (!this.get_bool("isThisOnGround")) pitchMod *= 0.9f;
        if (pitchMod < 0.01f) pitchMod = 0.01f;

        sprite.SetEmitSoundSpeed(
            Maths::Min(0.01f + Maths::Abs((2000 - rpm) / 2000), 1.2f) * 1.0 * pitchMod);

        if(!this.get_bool(isThisOnGroundString))
        {
            sprite.SetEmitSoundSpeed( sprite.getEmitSoundSpeed() * 1.25f * pitchMod);
        }
    }
   
    if (rpm > 2000)
    {
        if (type) // MANAGER 1
        {
            if (rpm > 6000)
            {
                if (rpm > 8000)
                {
                    sprite.SetEmitSoundPaused(true);
                }
                else
                {
                    sprite.SetEmitSoundPaused(false);
                    sprite.SetEmitSoundVolume(Maths::Clamp(1 - Maths::Abs((6000 - rpm) / 2000), 0, baseVolume));
                    //print("med " + Maths::Clamp(1 - Maths::Abs((6000 - rpm) / 2000), 0, baseVolume));
                }
            }
            else
            {
                sprite.SetEmitSoundVolume(Maths::Clamp(Maths::Abs((2000 - rpm) / 1000), 0, baseVolume));
                //print("med " + Maths::Clamp(Maths::Abs((2000 - rpm) / 1000), 0, baseVolume));
            }
            
        }
        else // MANAGER 2
        {
            if (rpm < 6000)
            {
                sprite.SetEmitSoundVolume(Maths::Clamp(1.0f - Maths::Abs(2000 - rpm) / 2000, 0, baseVolume));
                //print("low " + Maths::Clamp(1.0f - Maths::Abs(2000 - rpm) / 2000, 0, baseVolume));
            }
            else {
                sprite.SetEmitSoundVolume(Maths::Clamp(Maths::Abs((6000 - rpm) / 1000), 0, baseVolume));
                //print("high " + Maths::Clamp(Maths::Abs((6000 - rpm) / 1000), 0, baseVolume));
            }
        }
    }
    else
    {
        const u32 low_rpm_fade = 800;
        if (rpm < low_rpm_fade)
        {
            sprite.SetEmitSoundVolume(1 - (low_rpm_fade - rpm)/low_rpm_fade);
        }
        else
        {
             // only idle
            sprite.SetEmitSoundVolume(type ? 0 : baseVolume);
        }
    }

   // print("rpm " + rpm);
}