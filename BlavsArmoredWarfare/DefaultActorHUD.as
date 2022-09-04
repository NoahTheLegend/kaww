#include "ActorHUDCON.as";

const int slotsSize = 6;

void renderBox(Vec2f farside, f32 width, f32 scale)
{
	GUI::DrawIcon("Entities/Common/GUI/BaseGUI.png", 2, Vec2f(16, 32), farside + Vec2f(-460, 0), scale * 17.1);
}

const string linadj_hp = "linear adjustment";

void onInit(CBlob@ this)
{
	this.set_f32(linadj_hp, this.getHealth());
}

void onTick(CBlob@ this)
{
	const f32 initialHealth = this.getInitialHealth();

	// match to real hp
	if ((this.get_f32(linadj_hp) != this.getHealth()))
	{
		if (this.get_f32(linadj_hp) < this.getHealth())
		{
			this.set_f32(linadj_hp, this.get_f32(linadj_hp) + 0.02);
		}
		else if (this.get_f32(linadj_hp)-0.02 > this.getHealth())
		{
			this.set_f32(linadj_hp, this.get_f32(linadj_hp) - 0.02);
		}
	}
}

void renderHPBar(CBlob@ blob, Vec2f origin)
{
	int segmentWidth = 32;

	int HPs = 0;

	f32 thisHP = blob.getHealth();

	if (thisHP > 0)
	{
		Vec2f heartoffset = Vec2f(148, 5);
		Vec2f heartpos = origin + Vec2f((segmentWidth*0.5) * HPs, 0) + heartoffset;

		Vec2f dim = Vec2f(126, 24);
		const f32 initialHealth = blob.getInitialHealth();
		if (initialHealth > 0.0f)
		{
			const f32 perc  = blob.getHealth() / initialHealth;
			const f32 perc2 = blob.get_f32(linadj_hp) / initialHealth;

			if (perc >= 0.0f)
			{
				SColor color;

				if (blob.getHealth() <= blob.getInitialHealth() / 3.5f && getGameTime() % 30 == 0)
				{
					if (blob.getHealth() <= blob.getInitialHealth() / 4.5f)
					{
						color.set(255, 255, 55, 22);
						blob.getSprite().PlaySound("/Heartbeat", 1.45f);
					}
					else if (getGameTime() % 60 == 0)
					{
						color.set(255, 255, 55, 22);
						blob.getSprite().PlaySound("/Heartbeat", 1.45f);
					}	
				}
				else
				{
					color.set(255, 117, 220, 44);
				}

				GUI::DrawRectangle(Vec2f(heartpos.x - dim.x - 2, heartpos.y - 2), Vec2f(heartpos.x + dim.x + 2, heartpos.y + dim.y + 2));
				GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 2, heartpos.y + 2), Vec2f(heartpos.x + dim.x - 2, heartpos.y + dim.y - 2), SColor(0xff7f1140));

				if (blob.getHealth() >= 0.25)
				{
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 1, heartpos.y + 1), Vec2f(heartpos.x - dim.x + perc2 * 2.0f * dim.x - 1, heartpos.y + dim.y + 0), SColor(0xeeeeeeee));
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 2, heartpos.y + 2), Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 2, heartpos.y + dim.y - 2), color);
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 2, heartpos.y + 21), Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 2, heartpos.y + dim.y - 2), SColor(0xff2a760a));
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 4, heartpos.y + 4), Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 4, heartpos.y + dim.y - 16), SColor(0xffffffff));

					if (perc != 1) {GUI::DrawIcon("Taper.png", Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 34, heartpos.y + 1), 0.5f);}
				}
			}
		}
	}
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
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer()) return; // afaik otherwise all rectangles and images will stack over each other
	Vec2f dim = Vec2f(302, 64); // (402, 64)
	Vec2f ul(getHUDX() - dim.x / 2.0f, getHUDY() - dim.y + 12);
	Vec2f lr(ul.x + dim.x, ul.y + dim.y);
	u8 bar_width_in_slots = blob.get_u8("gui_HUD_slots_width");
	f32 width = bar_width_in_slots * 40.0f;

	renderBox(ul + Vec2f(dim.x + 46, 0), width*1.2, 1.0f); //width*1.9
	renderHPBar(blob, ul);

	string ammo_amt = blob.get_u32("mag_bullets");
	string ammo_amt_max = blob.get_u32("mag_bullets_max");
	Vec2f pngsize = Vec2f(98, 159);

	// display correct text
	if (ammo_amt != "" && ammo_amt.size() > 1)
	{	// CURRENT AMMO
		GUI::DrawIcon("FontNum.png", ammo_amt[0]+2, pngsize, Vec2f(-30.0f, getHUDY() - dim.y - 58.0f), 0.5f);
		GUI::DrawIcon("FontNum.png", ammo_amt[1]+2, pngsize, Vec2f(14.0f, getHUDY() - dim.y - 58.0f), 0.5f);
	}
	else if (ammo_amt.length() == 1)
	{
		GUI::DrawIcon("FontNum.png", ammo_amt[0]+2, pngsize, Vec2f(-10.0f, getHUDY() - dim.y - 58.0f), 0.5f);
	}
	
	/*
	if (ammo_amt_max != "" && ammo_amt_max.size() > 1)
	{	// MAX AMMO
		GUI::DrawIcon("FontNum.png", ammo_amt_max[0]+2, pngsize, Vec2f(-14.0f, getHUDY() - dim.y - 11.0f), 0.3f);
		GUI::DrawIcon("FontNum.png", ammo_amt_max[1]+2, pngsize, Vec2f(16.0f, getHUDY() - dim.y - 11.0f), 0.3f);
	}
	else if (ammo_amt_max.length() == 1)
	{
		GUI::DrawIcon("FontNum.png", ammo_amt_max[0]+2, pngsize, Vec2f(-10.0f, getHUDY() - dim.y - 8.0f), 0.3f);
	}

	//GUI::DrawIcon("Separator.png", 0, Vec2f(400, 300), Vec2f(-136.0f, getHUDY() - dim.y - 153.0f), 0.5f);
	*/

	// combining images would reduce lag
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
}