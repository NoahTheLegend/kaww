const f32 max_colorblind = 1.0f;

class ClientVars {
    f32 colorblind;
    u8 colorblind_type;

    ClientVars()
    {
        colorblind = 0.0f;
        colorblind_type = 0;
    }
};