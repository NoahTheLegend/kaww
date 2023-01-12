#include "ActorHUDCON.as";
#include "PlayerRankInfo.as";

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

	if (this.isAttachedToPoint("DRIVER"))
	{
		this.Tag("driver_vision");
		this.set_u32("dont_change_zoom", getGameTime()+1);
	}

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
	if (blob.getHealth() > 0)
	{
		Vec2f heartoffset = Vec2f(534, -16);
		Vec2f heartpos = origin + heartoffset;

		Vec2f dim = Vec2f(156, 26);
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
						blob.getSprite().PlaySound("/Heartbeat", 1.5f);
					}
					else if (getGameTime() % 60 == 0)
					{
						color.set(255, 255, 55, 22);
						blob.getSprite().PlaySound("/Heartbeat", 1.5f);
					}	
				}
				else
				{
					color.set(255, 82, 210*Maths::Min((blob.getHealth() / blob.getInitialHealth())*1.5, 1.0), 10);
				}

				SColor color_dark;
				color_dark.set(255, 117, 150*Maths::Clamp((blob.getHealth() / blob.getInitialHealth())*1.5, 0.2, 1.0), 44);

				GUI::DrawRectangle(Vec2f(heartpos.x - dim.x - 2, heartpos.y - 2), Vec2f(heartpos.x + dim.x + 2, heartpos.y + dim.y + 3));
				GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 2, heartpos.y + 2), Vec2f(heartpos.x + dim.x - 2, heartpos.y + dim.y - 2), SColor(0xff7f1140));

				if (blob.getHealth() >= 0.25)
				{
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 1, heartpos.y + 1), Vec2f(heartpos.x - dim.x + perc2 * 2.0f * dim.x - 1, heartpos.y + dim.y + 0), SColor(0xeeeeeeee));
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 2, heartpos.y + 2), Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 2, heartpos.y + dim.y - 2), color);
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 2, heartpos.y + 21), Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 2, heartpos.y + dim.y - 2), color_dark);
					GUI::DrawRectangle(Vec2f(heartpos.x - dim.x + 4, heartpos.y + 4), Vec2f(heartpos.x - dim.x + perc * 2.0f * dim.x - 4, heartpos.y + dim.y - 20), SColor(0xffffffff));
				}

				// plus sign
				GUI::DrawIcon("HealthIcon", 0, Vec2f(32, 32), Vec2f(heartpos.x - dim.x - 40, heartpos.y - 18), 1.0);

				// hp text
				GUI::SetFont("menu");
				GUI::DrawTextCentered(""+Maths::Ceil(blob.getHealth()*100), Vec2f(heartpos.x - dim.x - 13, heartpos.y + 12), SColor(0xffffffff));
			}
		}
	}
}

void renderEXPBar(CBlob@ blob, Vec2f origin)
{
	Vec2f offset = Vec2f(57, -640);
	Vec2f xppos = origin + offset;

	Vec2f dim = Vec2f(90, 8);

	float exp = 0;
	// load exp
	if (blob.getPlayer() !is null)
	{
		exp = getRules().get_u32(blob.getPlayer().getUsername() + "_exp");
	}
	

	int level = 1;
	string rank = RANKS[0];

    // Calculate the exp required to reach each level
    for (int i = 1; i <= RANKS.length; i++)
    {
        if (exp >= getExpToNextLevel(i - 0))
        {
            level = i + 1;
            rank = RANKS[Maths::Min(i, RANKS.length)];
        }
        else
        {
            // The current level has been reached
            break;
        }
    }
	
	float next_rank = getExpToNextLevel(level);

	float previousrankexp = getExpToMyLevel(level);
	
	float expratio = (exp-previousrankexp) / (next_rank-previousrankexp); //next_rank

	getRules().set_u32("Yeti5000707" + "_exp", 79);

	GUI::DrawRectangle(Vec2f(xppos.x - dim.x + 2, xppos.y + 2), Vec2f(xppos.x + dim.x - 2, xppos.y + dim.y - 2), SColor(0x505bff33)); // background pane

	GUI::DrawRectangle(Vec2f(xppos.x - dim.x + 1, xppos.y + 2), Vec2f(xppos.x - dim.x + expratio * 2.0f * dim.x - 1, xppos.y + dim.y - 2), SColor(0xff76ff33)); // fill color

	GUI::SetFont("menu");
	GUI::DrawText(""+exp+" / " + next_rank, Vec2f(xppos.x / 2 - 16, xppos.y + dim.y + 0), SColor(0xffffffff));
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

	if (blob !is null)
	{
		CPlayer@ player = blob.getPlayer();

		if (player !is null)
		{
			float exp = 0;
			// load exp
			if (blob.getPlayer() !is null)
			{
				exp = getRules().get_u32(blob.getPlayer().getUsername() + "_exp");
			}

			int level = 1;
			string rank = RANKS[0];

			if (exp > 0)
			{
				// Calculate the exp required to reach each level
				for (int i = 1; i <= RANKS.length; i++)
				{
					if (exp >= getExpToNextLevel(i - 0))
					{
						level = i + 1;
						rank = RANKS[Maths::Min(i, RANKS.length)];
						//print("rank: " + RANKS[i]+ "  - exp needed to reach: " + )
					}
					else
					{
						// The current level has been reached
						break;
					}
				}
			}

			GUI::DrawIcon("Ranks", level - 1, Vec2f(32, 32), Vec2f(16, -12), 1.0f, 0);

			// draw player username
			GUI::SetFont("menu");
			GUI::DrawText(rank + " | "+player.getCharacterName(), Vec2f(60, 10), SColor(0xffffffff));
		}
	}
	
	if (!blob.isMyPlayer()) return; // afaik otherwise all rectangles and images will stack over each other
	Vec2f dim = Vec2f(302, 64); // (402, 64)
	Vec2f ul(getHUDX() - dim.x / 2.0f, getHUDY() - dim.y + 12);
	Vec2f lr(ul.x + dim.x, ul.y + dim.y);
	u8 bar_width_in_slots = blob.get_u8("gui_HUD_slots_width");
	f32 width = bar_width_in_slots * 40.0f;

	renderBox(ul + Vec2f(dim.x + 46, 0), width*1.2, 1.0f); //width*1.9
	renderHPBar(blob, ul);

	// draw xp bar
	renderEXPBar(blob, ul - Vec2f(10,0));

	// draw class icon
	int icon_num = 0;
	if (blob.getName() == "revolver")
	{
		icon_num = 1;
	}
	else if (blob.getName() == "ranger")
	{
		icon_num = 2;
	}
	else if (blob.getName() == "shotgun")
	{
		icon_num = 3;
	}
	else if (blob.getName() == "sniper")
	{
		icon_num = 4;
	}
	else if (blob.getName() == "antitank")
	{
		icon_num = 5;
	}
	else if (blob.getName() == "mp5")
	{
		icon_num = 6;
	}

	GUI::DrawIcon("ClassIconSimple.png", icon_num, Vec2f(48, 48), Vec2f(icon_num == 0 ? -14 : 46, getScreenHeight()-166), 2);

	string ammo_amt = blob.get_u32("mag_bullets");
	string ammo_amt_max = blob.get_u32("mag_bullets_max");
	Vec2f pngsize = Vec2f(98, 159);
	

	if (icon_num != 0)
	{
		// display correct text
		if (ammo_amt != "" && ammo_amt.size() > 1)
		{	// CURRENT AMMO
			GUI::DrawIcon("FontNum.png", ammo_amt[0]+2, pngsize, Vec2f(-30.0f, getHUDY() - dim.y - 138.0f), 0.5f);
			GUI::DrawIcon("FontNum.png", ammo_amt[1]+2, pngsize, Vec2f(15.0f, getHUDY() - dim.y - 138.0f), 0.5f);
		}
		else if (ammo_amt.length() == 1)
		{
			GUI::DrawIcon("FontNum.png", ammo_amt[0]+2, pngsize, Vec2f(-7.0f, getHUDY() - dim.y - 138.0f), 0.5f);
		}
		
		GUI::DrawIcon("Separator.png", 0, Vec2f(400, 300), Vec2f(-110.0f, getHUDY() - dim.y - 153.0f), 0.45f);

		if (ammo_amt_max != "" && ammo_amt_max.size() > 1)
		{	// MAX AMMO
			GUI::DrawIcon("FontNum.png", ammo_amt_max[0]+2, pngsize, Vec2f(-14.0f, getHUDY() - dim.y - 26.0f), 0.35f);
			GUI::DrawIcon("FontNum.png", ammo_amt_max[1]+2, pngsize, Vec2f(18.0f, getHUDY() - dim.y - 26.0f), 0.35f);
		}
		else if (ammo_amt_max.length() == 1)
		{
			GUI::DrawIcon("FontNum.png", ammo_amt_max[0]+2, pngsize, Vec2f(-8.0f, getHUDY() - dim.y - 26.0f), 0.35f);
		}
	}

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