const f32 max_colorblind = 1.0f;

class ClientVars {
    f32 colorblind;
    u8 colorblind_type;

    bool body_rotation;
    bool head_rotation;

    ClientVars()
    {
        colorblind = 0.0f;
        colorblind_type = 0;
        
        body_rotation = true;
        head_rotation = true;
    }
};