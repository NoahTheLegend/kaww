
void onInit(CBlob@ this)
{
    this.Tag("crane_mount");
    this.addCommandID("sync");

    this.Tag("builder always hit");
    this.Tag("builder urgent hit");
    this.Tag("trap");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync"))
    {
        bool active = params.read_bool();
        bool attached = params.read_bool();

        CShape@ shape = this.getShape();

        if (active) this.Tag("active");
        else this.Untag("active");

        if (attached)
        {
            this.Tag("attached");

            shape.getConsts().mapCollisions = false;
            if (!this.hasTag("rotary_joint")) shape.SetGravityScale(0);
            shape.getConsts().net_threshold_multiplier = 0.5f;
        }
        else
        {
            this.Untag("attached");

            shape.getConsts().mapCollisions = true;
            if (!this.hasTag("rotary_joint")) shape.SetGravityScale(1.0f);
            shape.getConsts().net_threshold_multiplier = 1.0f;
        }
    }
}

void Sync(CBlob@ this)
{
    if (!isServer()) return;

    CBitStream params;
    params.write_bool(this.hasTag("active"));
    params.write_bool(this.hasTag("attached"));
    this.SendCommand(this.getCommandID("sync"), params);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ ap)
{
    if (attached !is null && attached.getPlayer() is null)
        this.getSprite().SetRelativeZ(-50.0f);
    this.Untag("active");
    
    if (isServer()) Sync(this);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ ap)
{
    if (detached !is null && detached.getPlayer() is null)
        this.getSprite().SetRelativeZ(0.0f);
    this.Untag("active");

    if (isServer()) Sync(this);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !this.hasTag("attached") && (!blob.hasTag("trap") && !blob.hasTag("flesh") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("attached");
}
