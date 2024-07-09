const f32 max_colorblind = 1.0f;
const f32 max_ammo_autopickup = 600;

class ClientVars {
    f32 colorblind;
    u8 colorblind_type;
    u16 ammo_autopickup;

    bool body_rotation;
    bool head_rotation;

    ClientVars()
    {
        colorblind = 0.0f;
        colorblind_type = 0;
        ammo_autopickup = 100;
        
        body_rotation = true;
        head_rotation = true;
    }
};