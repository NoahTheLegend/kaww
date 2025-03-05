const string init_rot_string = "hand_rotations_allowed_by_intial";

void onInit(CBlob@ this)
{
    /*
    CShape@ shape = this.getShape();
    if (shape is null) return;

    this.set_bool(init_rot_string, shape.isRotationsAllowed());
    */
}
/*
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ ap)
{
    this.Tag("hand_rotation");
    this.set_f32("hand_angle", 0);

    this.setAngleDegrees(0);
    if (attached !is null && attached.hasScript("CheapFakeRolling.as"))
    {
        attached.getSprite().ResetTransform();
    }
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ ap)
{
    this.Untag("hand_rotation");

    CShape@ shape = this.getShape();
    if (shape is null) return;

    bool init_rot = this.get_bool(init_rot_string);
    shape.SetRotationsAllowed(init_rot);
    if (!init_rot)
    {
        this.setAngleDegrees(0);
    }
}
*/