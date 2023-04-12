
// dumb way for fixing engine bug, when the blob is permanently invisible on your screen in case
// if it is created far away offscreen or passed the edge when its position doesnt render
// anymore, creates particles on die

// TODO do logic here after some ensuring tests

void onInit(CBlob@ this)
{
    this.getShape().SetGravityScale(0.0f);
}

void onTick(CBlob@ this)
{
    if (!isServer()) return;

    if (this.getTickSinceCreated() >= 1)
    {
        this.server_Die();
    }
}