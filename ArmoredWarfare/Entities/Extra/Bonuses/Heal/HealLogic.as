const u8 time_despawn_sec = 22;

void onInit(CBlob@ this)
{
	// glow
	this.SetLight(true);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 240, 25, 25));

	// despawn
	this.server_SetTimeToDie(time_despawn_sec);
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();

	if (b.getTickSinceCreated() > 30 * time_despawn_sec-6) {
		if (b.getTickSinceCreated() > 30 * time_despawn_sec-3) 	this.SetVisible(getGameTime() % 5 < 3);
		else 									this.SetVisible(getGameTime() % 8 < 4);
	}

	this.SetOffset(Vec2f(0, Maths::Sin((getGameTime() + b.getNetworkID()) / 6.0f) * 3.0f - 5.0f));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("player"))
	{
		blob.getSprite().PlaySound("Heart.ogg", 1.3);

		if (blob.getHealth() < blob.getInitialHealth()/3.5)
		{
			blob.getSprite().PlaySound("Pickup_heart.ogg", 0.9);
		}

		CPlayer@ p = blob.getPlayer();

		blob.server_Heal(5.0f);

		this.server_Die();
	}
	return false;
}