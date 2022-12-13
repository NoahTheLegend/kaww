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
		{
			getHUD().SetCursorImage("GunCursor.png", Vec2f(32, 32));
			getHUD().SetCursorOffset(Vec2f(-32, -32));
		}
		{
			//getHUD().SetCursorImage("Entities/Characters/Builder/BuilderCursor.png");
		}
	}

	CPlayer@ player = blob.getPlayer();

	// draw coins
	const int coins = player !is null ? player.getCoins() : 0;
	DrawCoinsOnHUD(blob, coins, getActorHUDStartPosition(blob, slotsSize+14), slotsSize - 2);
}