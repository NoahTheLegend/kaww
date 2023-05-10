#include "TDM_Structs.as";

void onTick( CRules@ this )
{
    if (this.hasTag("restart_after_match"))
	{
		if (getGameTime() % 30 == 0 && getGameTime() <= 300)
		{
			u32 time = 300 - getGameTime();
			client_AddToChat("Server restarts in "+Maths::Ceil(time/30)+" second"+(time<2?"s":""), SColor(255, 255, 35, 35));
		}
	}
}

void onInit(CRules@ this)
{
	this.set_bool("show_warn_extended_time", false);
	CBitStream stream;
	stream.write_u16(0xDEAD);
	this.set_CBitStream("tdm_serialised_team_hud", stream);
}

shared class FlagsInfo {
    bool flagMatch = getBlobByName("pointflag") !is null;

    u8 getFlagsCount(u8 team, bool total)
    {
        CBlob@[] flags;
        getBlobsByName("pointflag", @flags);
        u8 cock = 0;
        for (u8 i = 0; i < flags.length; i++)
        {
            if (flags[i] is null) continue;
            if (flags[i].getTeamNum() != team) continue;
            cock++;
        }
        return cock;
    }

	bool done_sorting = false;

    void renderFlagIcons(Vec2f start_pos)
    {
        CBlob@[] flags;
        getBlobsByName("pointflag", @flags);

        for (u8 i = 0; i < flags.length; i++)
        {
        	CBlob@ flag = flags[i];
            if (flag is null) continue;
			
            u8 icon_idx;
            u8 team_num = flag.getTeamNum();
            u8 team_state = team_num; // team index | 255 neutral | 2 capping

            if (flag.get_s8("teamcapping") != -1
            && flag.get_s8("teamcapping") != team_num)
            {
                team_state = 2; // alert!!!
            }

			FlagIcon icon;
			if (icon !is null)
			{
				u8 bigger = 0;
				for (u8 j = 0; j < flags.length; j++) // set offset from left depending on x coordinate
				{
					if (flags[j] !is null)
					{
						if (flag.getPosition().x > flags[j].getPosition().x) bigger++;
					}
				}
				icon.xpos = 36.0f*bigger;
				icon.drawIcon(start_pos, team_state, team_num);
			}
        }
    }
};

shared class FlagIcon {
	f32 xpos;
	void drawIcon(Vec2f start_pos, u8 team_state, u8 team_num)
	{
		GUI::DrawIcon("CTFGui.png", 0, Vec2f(16,32), start_pos + Vec2f(xpos, 0), 1.0f, team_num);
    	if (team_state == 2)// && getGameTime() % 30 == 0) 
    	{
    		f32 wave = Maths::Sin(getGameTime() / 5.0f) * 5.0f - 25.0f;
    		GUI::DrawIcon("CTFGui.png", 1, Vec2f(16,32), start_pos + Vec2f(xpos + 2, 72 + wave), 1.0f, team_num);
    	}
	}
};

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	CPlayer@ p = getLocalPlayer();

	if (p is null || !p.isMyPlayer()) { return; }
	GUI::SetFont("menu");

	//if (this.get_bool("show_warn_extended_time") && this.get_u32("warn_extended_time") != 0 && this.get_u32("warn_extended_time") > getGameTime() && getGameTime() > 300)
	//{
	//	f32 wave = Maths::Sin(getGameTime() / 2.5f) * 2.5f - 12.5f;
	//	GUI::DrawTextCentered("Match time was extended by 10 minutes!", Vec2f(getDriver().getScreenWidth()/2, 220+wave), (getGameTime()/30)%2 == 0 ? SColor(255,255,255,55) : SColor(255,255,75,75));
	//}

	if (getBlobByName("importantarmory") !is null)
	{
		u8 teamleft = getRules().get_u8("teamleft");
		u8 teamright = getRules().get_u8("teamright");

		if (p.getTeamNum() == teamleft && this.get_u32("iarmory_warn"+teamleft) > getGameTime())
		{
			f32 wave = Maths::Sin(getGameTime() / 3.0f) * 5.0f - 25.0f;
			GUI::DrawTextCentered("Your truck is under attack!", Vec2f(getDriver().getScreenWidth()/2, 220+wave), SColor(255,255,255,0));
		}
		else if (p.getTeamNum() == teamright && this.get_u32("iarmory_warn"+teamright) > getGameTime())
		{
			f32 wave = Maths::Sin(getGameTime() / 3.0f) * 5.0f - 25.0f;
			GUI::DrawTextCentered("Your truck is under attack!", Vec2f(getDriver().getScreenWidth()/2, 220+wave), SColor(255,255,255,0));
		}

		
	}

	CBitStream serialised_team_hud;
	this.get_CBitStream("tdm_serialised_team_hud", serialised_team_hud);

	if (serialised_team_hud.getBytesUsed() > 10)
	{
		serialised_team_hud.Reset();
		u16 check;

		if (serialised_team_hud.saferead_u16(check) && check == 0x5afe)
		{
			while (!serialised_team_hud.isBufferEnd())
			{
				TDM_HUD hud(serialised_team_hud);
				Vec2f topLeft = Vec2f(-40, 64 + 48 * hud.team_num);

				/*
				FlagsInfo flags_info;
    			if (flags_info !is null)
    			{
    			    flags_info.renderFlagIcons(Vec2f(16, 140));
    			}*/

				int team_player_count = 0;
				int team_dead_count = 0;
				int step = 0;
				Vec2f startIcons = Vec2f(64, 60);
				Vec2f startSkulls = Vec2f(160, 60);
				string player_char = "";
				int size = int(hud.unit_pattern.size());

				while (step < size)
				{
					player_char = hud.unit_pattern.substr(step, 1);
					step++;

					if (player_char == " ") { continue; }

					if (player_char != "s")
					{
						GUI::DrawIcon("team_sheet", 0, Vec2f(16, 16), topLeft + startIcons + Vec2f(team_player_count * 8, 0) , 1.0f, hud.team_num);
						team_player_count++;
					}
					else
					{
						GUI::DrawIcon("DeathCountIcon.png", 0 , Vec2f(16, 16), topLeft + startSkulls + Vec2f(team_dead_count * 16, 0) , 1.0f, hud.team_num);
						team_dead_count++;
					}
				}

				if (hud.spawn_time != 255)
				{
					string time = "" + hud.spawn_time;
					GUI::DrawText(time, topLeft + Vec2f(196, 42), SColor(255, 255, 255, 255));
				}
			}
		}

		serialised_team_hud.Reset();
	}

	string propname = "tdm spawn time " + p.getUsername();
	if (p.getBlob() is null && this.exists(propname))
	{
		u8 spawn = this.get_u8(propname);

		string gamemode = this.get_string("bannertext");
		//GUI::DrawText(gamemode, Vec2f(15, getScreenHeight() / 6.25), SColor(255, 255, 255, 255));

		if (spawn != 255)
		{
			if (spawn == 254)
			{
				u8 teamleft = getRules().get_u8("teamleft");
				u8 teamright = getRules().get_u8("teamright");
				if ((p.getTeamNum() == teamleft && this.get_s16("teamLeftTickets") == 0)
				|| (p.getTeamNum() == teamright && this.get_s16("teamRightTickets") == 0))
				{
					GUI::DrawText(getTranslatedString("Your team ran out of respawns! Please, be patient and wait until game ends.") , Vec2f(getScreenWidth() / 2 - 265, getScreenHeight() / 4 + Maths::Sin(getGameTime() / 3.0f) * 5.0f), SColor(255, 255, 255, 55));
				}
				else
				{
					GUI::DrawText(getTranslatedString("In Queue to Respawn...") , Vec2f(getScreenWidth() / 2 - 70, getScreenHeight() / 3 + Maths::Sin(getGameTime() / 3.0f) * 5.0f), SColor(255, 255, 255, 55));
				}
			}
			else if (spawn == 253)
			{
				GUI::DrawText(getTranslatedString("No Respawning - Wait for the Game to End.") , Vec2f(getScreenWidth() / 2 - 180, getScreenHeight() / 3 + Maths::Sin(getGameTime() / 3.0f) * 5.0f), SColor(255, 255, 255, 55));
			}
			else
			{
				GUI::DrawText(getTranslatedString("Respawning in: {SEC}").replace("{SEC}", "" + spawn), Vec2f(getScreenWidth() / 2 - 70, getScreenHeight() / 3 + Maths::Sin(getGameTime() / 3.0f) * 5.0f), SColor(255, 255, 255, 55));
			}
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (isClient())
	{
		if (cmd == this.getCommandID("iarmorywarn"))
		{
			u8 team = params.read_u8();
			this.set_u32("iarmory_warn"+team, getGameTime()+150);
		}
	}
}