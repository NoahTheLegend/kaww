void onInit(CBlob@ this)
{
	// glow
	this.SetLight(true);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 150, 240, 50));

	if (!this.exists("cash_amount"))
	{
		this.set_u8("cash_amount", 1);
	}

	this.server_SetTimeToDie(15);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("player"))
	{
		blob.getSprite().PlaySound("Pickup_cash.ogg", 0.6);

		CPlayer@ player = blob.getPlayer();

		if (player !is null)
		{
			player.server_setCoins(player.getCoins() + this.get_u8("cash_amount"));
		}

		this.server_Die();
	}
	return false;
}