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
	if (g_videorecording) return;
	
	CBlob@ blob = this.getBlob();

	// set cursor
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
		getHUD().SetCursorOffset(Vec2f(-6, -6)); // -6 is perfect alignment but messes up esc cursor
	}
	else
	{
		if (blob.getName() != "mechanic") // is not a builder
		{
			getHUD().SetCursorImage("GunCursor.png", Vec2f(32, 32));
			getHUD().SetCursorOffset(Vec2f(-38, -38)); // -38 is perfect alignment but messes up esc cursor

			CControls@ controls = blob.getControls();
			if (controls !is null)
			{
				CInventory@ inv = blob.getInventory();
				
				if (inv !is null && (
					blob.getName() != "rpg" && inv.getItem("ammo") is null) || // is any normal class
					blob.getName() == "rpg" && inv.getItem("mat_heatwarhead") is null) // is rpg
				{
					GUI::SetFont("menu");
					GUI::DrawTextCentered("No Ammo", controls.getInterpMouseScreenPos() + Vec2f(-2,35), controls.isKeyPressed(KEY_KEY_R) ? SColor(0xfff20101) : SColor(0xffffffff));
				}
			}
		}
		else{

			getHUD().SetCursorImage("Entities/Characters/Builder/BuilderCursor.png");
			getHUD().SetCursorOffset(Vec2f(0, -0));
		}
	}

	CPlayer@ player = blob.getPlayer();

	// draw coins
	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD(blob, coins, Vec2f(195, getHUDY()-120), slotsSize - 1);
}