//default actor hud
// a bar with hearts in the bottom left, bottom right free for actor specific stuff

#include "ActorHUDStartPos.as";

void renderBackBar(Vec2f origin, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 64; step += 64.0f * scale)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(step * scale, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(64, 32), origin + Vec2f(width - 128 * scale, 0), scale);
}

void renderFrontStone(Vec2f farside, f32 width, f32 scale)
{
	for (f32 step = 0.0f; step < width / scale - 16.0f * scale * 2; step += 16.0f * scale * 2)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-step * scale - 32 * scale, 0), scale);
	}

	if (width > 16)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-width, 0), scale);
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), farside + Vec2f(-width - 32 * scale, 0), scale);
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), farside, scale);
}

void renderHPBar(CBlob@ blob, Vec2f origin)
{
	string heartFile = "GUI/HeartNBubble.png";
	int segmentWidth = 32;
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 0, Vec2f(16, 32), origin + Vec2f(-segmentWidth, 0));
	int HPs = 0;

	for (f32 step = 0.0f; step < blob.getInitialHealth(); step += 0.5f)
	{
		GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 1, Vec2f(16, 32), origin + Vec2f(segmentWidth * HPs, 0));
		f32 thisHP = blob.getHealth() - step;

		if (thisHP > 0)
		{
			Vec2f heartoffset = (Vec2f(2, 10) * 2);
			Vec2f heartpos = origin + Vec2f(segmentWidth * HPs, 0) + heartoffset;

			if (thisHP <= 0.125f)
			{
				GUI::DrawIcon(heartFile, 4, Vec2f(12, 12), heartpos);
			}
			else if (thisHP <= 0.25f)
			{
				GUI::DrawIcon(heartFile, 3, Vec2f(12, 12), heartpos);
			}
			else if (thisHP <= 0.375f)
			{
				GUI::DrawIcon(heartFile, 2, Vec2f(12, 12), heartpos);
			}
			else
			{
				GUI::DrawIcon(heartFile, 1, Vec2f(12, 12), heartpos);
			}
		}

		HPs++;
	}

	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 3, Vec2f(16, 32), origin + Vec2f(32 * HPs, 0));
}

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	if (!GUI::isFontLoaded("AveriaSerif-Bold_32"))
    {
        string AveriaSerif = CFileMatcher("AveriaSerif-Regular.ttf").getFirst();
        GUI::LoadFont("AveriaSerif-Regular_32", AveriaSerif, 32, true);
    }
}

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f dim = Vec2f(402, 64);
	Vec2f ul(getHUDX() - dim.x / 2.0f, getHUDY() - dim.y + 12);
	Vec2f lr(ul.x + dim.x, ul.y + dim.y);
	renderBackBar(ul, dim.x, 1.0f);
	u8 bar_width_in_slots = blob.get_u8("gui_HUD_slots_width");
	f32 width = bar_width_in_slots * 40.0f;
	renderFrontStone(ul + Vec2f(dim.x + 40, 0), width, 1.0f);
	renderHPBar(blob, ul);
	//GUI::DrawIcon("Vignette.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));

	if (blob.getHealth() <= blob.getInitialHealth() / 1.5f)
	{
		GUI::DrawIcon("BloodOverlay.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}
	if (blob.getHealth() <= blob.getInitialHealth() / 2.25f)
	{
		GUI::DrawIcon("BloodOverlay.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}
	if (blob.getHealth() <= blob.getInitialHealth() / 3.5f)
	{
		GUI::DrawIcon("BloodOverlay.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}

	GUI::SetFont("AveriaSerif-Regular_32");

	GUI::DrawText("Perk:", ul+Vec2f(468.0f, 37.0f), SColor(255, 180, 180, 180));

	if (blob.getPlayer() is null)
	{
		return;
	}

	if (blob.getPlayer().hasTag("Kevlar"))
	{
		GUI::DrawText("Kevlar", ul+Vec2f(494.0f, 37.0f), SColor(255, 50, 110, 20));
	}
	else if (blob.getPlayer().hasTag("Conditioning"))
	{
		GUI::DrawText("Conditioning", ul+Vec2f(494.0f, 37.0f), SColor(255, 200, 200, 220));
	}
	else if (blob.getPlayer().hasTag("Blood Thirst"))
	{
		GUI::DrawText("Blood Thirst", ul+Vec2f(494.0f, 37.0f), SColor(255, 180, 50, 50));
	}
	else if (blob.getPlayer().hasTag("Commando"))
	{
		GUI::DrawText("Commando", ul+Vec2f(494.0f, 37.0f), SColor(255, 255, 200, 75));
	}
	else if (blob.getPlayer().hasTag("Sharpshooter"))
	{
		GUI::DrawText("Sharpshooter", ul+Vec2f(494.0f, 37.0f), SColor(255, 255, 40, 40));
	}
	else
	{
		GUI::DrawText("None", ul+Vec2f(494.0f, 37.0f), SColor(255, 130, 130, 130));
	}	
}