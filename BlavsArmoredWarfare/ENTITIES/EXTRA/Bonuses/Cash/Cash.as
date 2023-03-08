const u8 time_despawn_sec = 60;

void onInit(CSprite@ this) {
	this.SetRelativeZ(600.0f);
}
void onTick(CSprite@ this) {
	CBlob@ b = this.getBlob();

	if (b.getTickSinceCreated() > 30 * time_despawn_sec-6) {
		if (b.getTickSinceCreated() > 30 * time_despawn_sec-3) 	this.SetVisible(getGameTime() % 5 < 3);
		else 									this.SetVisible(getGameTime() % 8 < 4);
	}

	this.SetOffset(Vec2f(0, Maths::Sin((getGameTime() + b.getNetworkID()) / 6.0f) * 3.0f - 5.0f));
}

void onInit(CBlob@ this) {

	// glow
	this.SetLight(true);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 150, 240, 50));

	// despawn
	this.server_SetTimeToDie(time_despawn_sec);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ b) {
	if (b.hasTag("player"))
	{
		b.getSprite().PlaySound("Pickup_cash.ogg", 1.1);

		CPlayer@ p = b.getPlayer();

		if (p !is null) {
			p.server_setCoins(p.getCoins() + this.get_u8("cash_amount"));
		}

		this.server_Die();
	}
	return false;
}