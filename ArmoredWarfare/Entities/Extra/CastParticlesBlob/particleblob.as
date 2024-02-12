
// god forgive me
void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
    if (shape !is null)
    {
        shape.getConsts().mapCollisions = false;
        shape.SetStatic(true);
    }
}

void onTick(CBlob@ this)
{
    if (!isServer()) return;
    if (this.getTickSinceCreated() >= 1) this.server_Die();
}