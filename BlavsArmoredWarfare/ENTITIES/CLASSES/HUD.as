#include "ActorHUDCON.as";

const int slotsSize = 6;

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	// set cursor
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
	}
	else
	{
		getHUD().SetCursorImage("GunCursor.png", Vec2f(32, 32));
		getHUD().SetCursorOffset(Vec2f(-32, -32));

		if (blob.getName() != "slave") // is not a builder
		{
			CControls@ controls = blob.getControls();
			if (controls !is null)
			{
				CInventory@ inv = blob.getInventory();
				
				if (inv !is null && (
					blob.getName() != "antitank" && inv.getItem("mat_7mmround") is null) || // is any normal class
					blob.getName() == "antitank" && inv.getItem("mat_heatwarhead") is null) // is antitank
				{
					GUI::SetFont("menu");
					GUI::DrawTextCentered("No Ammo", controls.getInterpMouseScreenPos() + Vec2f(4,41), controls.isKeyPressed(KEY_KEY_R) ? SColor(0xfff20101) : SColor(0xffffffff));
				}
			}
		}
	}

	CPlayer@ player = blob.getPlayer();

	// draw coins
	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD(blob, coins, getActorHUDStartPosition(blob, slotsSize+14), slotsSize - 2);
}