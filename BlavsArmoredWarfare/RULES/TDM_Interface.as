#include "TDM_Structs.as";

/*
void onTick( CRules@ this )
{
    //see the logic script for this
}
*/

void onInit(CRules@ this)
{
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

	CBitStream serialised_team_hud;
	this.get_CBitStream("tdm_serialised_team_hud", serialised_team_hud);

	if (serialised_team_hud.getBytesUsed() > 10)
	{
		serialised_team_hud.Reset();
		u16 check;

		if (serialised_team_hud.saferead_u16(check) && check == 0x5afe)
		{
			const string gui_image_fname = "Rules/TDM/TDMGui.png";

			while (!serialised_team_hud.isBufferEnd())
			{
				TDM_HUD hud(serialised_team_hud);
				Vec2f topLeft = Vec2f(500, 8 + 64 * hud.team_num);

				/*
				FlagsInfo flags_info;
    			if (flags_info !is null)
    			{
    			    flags_info.renderFlagIcons(Vec2f(16, 140));
    			}*/

				int team_player_count = 0;
				int team_dead_count = 0;
				int step = 0;
				Vec2f startIcons = Vec2f(64, 8);
				Vec2f startSkulls = Vec2f(160, 8);
				string player_char = "";
				int size = int(hud.unit_pattern.size());

				while (step < size)
				{
					player_char = hud.unit_pattern.substr(step, 1);
					step++;

					if (player_char == " ") { continue; }

					if (player_char != "s")
					{
						int player_frame = 1;

						if (player_char == "a")
						{
							player_frame = 2;
						}

						GUI::DrawIcon(gui_image_fname, 12 + player_frame, Vec2f(16, 16), topLeft + startIcons + Vec2f(team_player_count * 8, 0) , 1.0f, hud.team_num);
						team_player_count++;
					}
					else
					{
						GUI::DrawIcon(gui_image_fname, 12 , Vec2f(16, 16), topLeft + startSkulls + Vec2f(team_dead_count * 16, 0) , 1.0f, hud.team_num);
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
				if ((p.getTeamNum() == 0 && this.get_s16("blueTickets") == 0)
				|| (p.getTeamNum() == 1 && this.get_s16("redTickets") == 0))
				{
					GUI::DrawText(getTranslatedString("Your team ran out of respawns! Please, be patient and wait till game ends.") , Vec2f(getScreenWidth() / 2 - 265, getScreenHeight() / 4 + Maths::Sin(getGameTime() / 3.0f) * 5.0f), SColor(255, 255, 255, 55));
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
