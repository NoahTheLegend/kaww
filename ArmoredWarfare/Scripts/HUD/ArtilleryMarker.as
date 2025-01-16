class GenericArtilleryExplosion {
	Vec2f pos;
	u32 time;
    u16 owner_pid;
    f32 scale;

    GenericArtilleryExplosion()
    {
        pos = Vec2f_zero;
        time = 0;
        owner_pid = 0;
        scale = 1.0f;
    }

	GenericArtilleryExplosion(Vec2f _pos, u32 _time, f32 _scale = 1.0f, u16 _owner_pid = 0)
    {
        pos = _pos;
        time = _time;
        owner_pid = _owner_pid;
        scale = _scale;
    }
}