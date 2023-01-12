f32 getHUDX()
{
	return getScreenWidth() / 5;
}

f32 getHUDY()
{
	return getScreenHeight();
}

// compatibility - prefer to use getHUDX() and getHUDY() as you are rendering, because resolution may dynamically change (from asu's staging build onwards)
const f32 HUD_X = getHUDX();
const f32 HUD_Y = getHUDY();

Vec2f getActorHUDStartPosition(CBlob@ blob, const u8 bar_width_in_slots)
{
	f32 width = bar_width_in_slots * 40.0f;
	return Vec2f(getHUDX() + 180 + 50 + 8 - width, getHUDY() - 40);
}

void DrawCoinsOnHUD(CBlob@ this, const int coins, Vec2f tl, const int slot)
{
	if (coins > 0)
	{
		//GUI::DrawIcon("CashIcon.png", tl + Vec2f(slot * 180, 10), 0.25f);
		GUI::SetFont("menu");
		GUI::DrawText("$" + coins + ".0", tl + Vec2f(slot * 180 , 0), color_white);
	}
} 