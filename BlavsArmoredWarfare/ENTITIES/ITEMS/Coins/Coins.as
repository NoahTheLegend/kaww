const string current_player = "current_player";

void onInit(CBlob@ this)
{
	this.set_u16(current_player, 0);
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return (this.get_u16(current_player) == byBlob.getNetworkID());
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	CPlayer@ player = attached.getPlayer();
	if (player !is null)
	{
		player.server_setCoins(player.getCoins() + 10);
		this.server_Die();

		this.getSprite().PlaySound("/coinpick", 1.5f, 1.0f);
	}
}