#include "ActorHUDCON.as";
#include "InfantryCommon.as";

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
			// gun reload cursor, fully relative. Change `icons_total` to the amount of icons on PNG
			InfantryInfo@ infantry;
			if (!blob.get("infantryInfo", @infantry)) return;

			if (blob.get_bool("isReloading"))
			{
				CPlayer@ p = blob.getPlayer();
				if (p is null) return;

				f32 mod = 1.0f;
				if (getRules().get_string(p.getUsername() + "_perk") == "Sharp Shooter")
				{
					mod = 1.5f;
				}
				else if (getRules().get_string(p.getUsername() + "_perk") == "Bull")
				{
					mod = 0.70f;
				}
				f32 end = blob.get_u32("reset_reloadtime");
				f32 reloadtime = infantry.reload_time;
				f32 diff = (end-getGameTime());
				f32 perc = (diff/(reloadtime*mod));

				u8 icons_total = 8;
				u8 icon = Maths::Clamp(icons_total/mod-(Maths::Ceil(icons_total*perc)), 0, icons_total);

				getHUD().SetCursorImage("GunReload.png", Vec2f(32, 32));
				getHUD().SetCursorFrame(icon);
				getHUD().SetCursorOffset(Vec2f(-38, -38)); // -38 is perfect alignment but messes up esc cursor

				blob.set_u32("wasReloading", getGameTime()+2);
			}
			else
			{
				getHUD().SetCursorImage("GunCursor.png", Vec2f(32, 32));

				if (getGameTime() < blob.get_u32("wasReloading")) getHUD().SetCursorFrame(1); // remove annoying flickering

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