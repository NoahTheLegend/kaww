const string engineRPMString_Manager = "engine_RPM_M";
const float baseVolume = 1.5f;
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

    sprite.SetEmitSoundPaused( false);

    if (!type)
    {
        if (this.get_f32(engineRPMString_Manager) < 6000)
        {
            sprite.SetEmitSound("EngineRun_low.ogg");
        }
        else
        {
            sprite.SetEmitSound("EngineRun_high.ogg");
        }

        sprite.SetEmitSoundSpeed(
            Maths::Min(0.01f + Maths::Abs(this.get_f32(engineRPMString_Manager) / 2000), 1.15f) * 1.0);
    }
    else{
        sprite.SetEmitSoundSpeed(
            Maths::Min(0.01f + Maths::Abs(this.get_f32(engineRPMString_Manager) / 6000), 1.3f) * 1.0);
    }
   

    if (this.get_f32(engineRPMString_Manager) > 2000)
    {
        //man 2
        if (type)
        {
            sprite.SetEmitSoundVolume(Maths::Abs(Maths::Min(2000 - this.get_f32(engineRPMString_Manager), 1000) / 2000));
        }
        else // 1
        {
            if (this.get_f32(engineRPMString_Manager) < 6000)
            {
                sprite.SetEmitSoundVolume(1.5f - Maths::Abs(Maths::Min(2000 - this.get_f32(engineRPMString_Manager), 1000) / 2000));
            }
            else{
                //print("c " + Maths::Abs(Maths::Min(6000 - this.get_f32(engineRPMString_Manager), 1000) / 1000));
                sprite.SetEmitSoundVolume(Maths::Abs(Maths::Min(6000 - this.get_f32(engineRPMString_Manager), 1000) / 2000));
                
            }
        }
    }
    else
    {
        // only idle
        sprite.SetEmitSoundVolume(type ? 0 : baseVolume);
        //sprite.SetEmitSoundVolume(baseVolume);
    }
    
}











//script by blav