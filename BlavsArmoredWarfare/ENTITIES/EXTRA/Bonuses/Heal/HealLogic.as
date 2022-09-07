void onInit(CBlob@ this)
{
	// glow
	this.SetLight(true);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 240, 25, 25));

	this.server_SetTimeToDie(15);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("player"))
	{
		blob.getSprite().PlaySound("Heart.ogg", 0.35);

		if (blob.getHealth() < blob.getInitialHealth()/3.5)
		{
			blob.getSprite().PlaySound("Pickup_heart.ogg", 0.5);
		}

		CPlayer@ player = blob.getPlayer();

		blob.server_Heal(5.0f);

		this.server_Die();
	}
	return false;
}