#include "ScoreboardCommon.as";
#include "Accolades.as";
#include "ColoredNameToggleCommon.as";
#include "PlayerRankInfo.as";
#include "AllHashCodes.as";

CPlayer@ hoveredPlayer;
Vec2f hoveredPos;

int hovered_accolade = -1;
int hovered_rank = -1;
bool mouseWasPressed1 = false;
bool disable_line = false;

float scoreboardMargin = 52.0f;
float scrollOffset = 0.0f;
float scrollSpeed = 5.0f;
float maxMenuWidth = 600;
float screenMidX = getScreenWidth()/2;

bool mouseWasPressed2 = false;

const string[] descriptions = {
	"A chance to receive extra ore (+20%, +2)",
	"Shorter respawn time, longer spawn protection (-1s, +1.5s)",
	"Faster constructing, less constraining building (+20%, -50% lock radius)",
	"Cheaper and stronger molotovs (-25%-33%, more liquid)",
	"Faster vehicle capture, faster C-4 activation, better grenades (+50%, -2.5s, +10% radius)",
	"A chance to receive more coins in an income (33%, +1)",
	"Increased damage resist for infantry, mines activate faster (+12.5%, -2s)"
};

//returns the bottom
float drawScoreboard(CPlayer@ localplayer, CPlayer@[] players, Vec2f topleft, CTeam@ team, Vec2f emblem, int teamnum)
{
	if (players.size() <= 0 || team is null)
		return topleft.y;

	CRules@ rules = getRules();
	Vec2f orig = topleft; //save for later

	f32 lineheight = 18;
	f32 padheight = 7;
	f32 stepheight = lineheight + padheight;
	Vec2f bottomright(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + (players.length + 5.5) * stepheight);
	GUI::DrawPane(topleft, bottomright, team.color);

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();

	//offset border
	topleft.x += stepheight;
	bottomright.x -= stepheight;
	topleft.y += stepheight;

	GUI::SetFont("menu");

	//draw team info
	GUI::DrawText(team.getName(), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	Vec2f dim;
	if (rules.get_bool("enable_powers"))
	{
		GUI::GetTextDimensions(team.getName(), dim);
		GUI::DrawIcon("FractionIcons.png", teamnum, Vec2f(64,64), Vec2f(topleft.x + 20 + dim.x, topleft.y - 10), 0.5f, teamnum);
		
		if (mousePos.x >= topleft.x && mousePos.y >= topleft.y
			&& mousePos.x <= bottomright.x && mousePos.y <= bottomright.y)
		{
			GUI::DrawText(descriptions[teamnum], Vec2f(topleft.x + 100 + dim.x, topleft.y), SColor(0xffffffff));
		}
	}
	GUI::DrawText(getTranslatedString("Players: {PLAYERCOUNT}").replace("{PLAYERCOUNT}", "" + players.length), Vec2f(bottomright.x - 92, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 1.5;

	const int accolades_start = 700;

	//draw player table header
	GUI::DrawText(getTranslatedString("Player"), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Username"), Vec2f(bottomright.x - 470, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Ping"), Vec2f(bottomright.x - 330, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Kills"), Vec2f(bottomright.x - 260, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Deaths"), Vec2f(bottomright.x - 190, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Assists"), Vec2f(bottomright.x - 120, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("KDR"), Vec2f(bottomright.x - 50, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Accolades"), Vec2f(bottomright.x - accolades_start, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Rank"), Vec2f(bottomright.x - accolades_start - 92, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Perk"), Vec2f(bottomright.x - accolades_start - 140, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 0.5f;

	//draw players
	for (u32 i = 0; i < players.length; i++)
	{
		CPlayer@ p = players[i];

		topleft.y += stepheight;
		bottomright.y = topleft.y + lineheight;

		bool playerHover = mousePos.y > topleft.y && mousePos.y < topleft.y + 15;

		if (playerHover)
		{
			if (controls.mousePressed1)
			{
				setSpectatePlayer(p.getUsername());
			}

			if (controls.mousePressed2 && !mouseWasPressed2)
			{
				// reason for this is because this is called multiple per click (since its onRender, and clicking is updated per tick)
				// we don't want to spam anybody using a clipboard history program
				if (getFromClipboard() != p.getUsername())
				{
					CopyToClipboard(p.getUsername());
					rules.set_u16("client_copy_time", getGameTime());
					rules.set_string("client_copy_name", p.getUsername());
					rules.set_Vec2f("client_copy_pos", mousePos + Vec2f(0, -10));
				}
			}
		}

		Vec2f lineoffset = Vec2f(0, -2);

		u32 underlinecolor = 0xff404040;
		u32 playercolour = (p.getBlob() is null || p.getBlob().hasTag("dead")) ? 0xff505050 : 0xff808080;
		if (playerHover)
		{
			playercolour = 0xffcccccc;
			@hoveredPlayer = p;
			hoveredPos = topleft;
			hoveredPos.x = bottomright.x - 150;
		}

		if (!disable_line)
		{
			GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, SColor(underlinecolor));
			GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, SColor(playercolour));
		}

		string tex = "";
		u16 frame = 0;
		Vec2f framesize;
		if (p.isMyPlayer())
		{
			tex = "ClassIcons.png";
			frame = 7;
			framesize.Set(16, 16);
		}
		else
		{
			tex = "ClassIcons.png";
            if (p.getBlob() !is null)
            {
				int blobHash = p.getBlob().getName().getHash();
				switch (blobHash)
				{
					case _revolver:
					{
						frame = 0;
						break;
					}
					case _ranger:
					{
						frame = 1;
						break;
					}
					case _rpg:
					{
						frame = 2;
						break;
					}
					case _shotgun:
					{
						frame = 3;
						break;
					}
					case _sniper:
					{
						frame = 4;
						break;
					}
					case _mp5:
					{
						frame = 5;
						break;
					}
					case _mechanic:
					{
						frame = 6;
						break;
					}
					case _shielder:
					{
						frame = 8;
						break;
					}
					case _firebringer:
					{
						frame = 9;
						break;
					}
					case _lmg:
					{
						frame = 10;
						break;
					}
				}
            }
			framesize.Set(16, 16);
		}
		if (tex != "")
		{
			GUI::DrawIcon(tex, frame, framesize, topleft, 0.5f, p.getTeamNum());
		}

		string username = p.getUsername();

		string playername = p.getCharacterName();
		string clantag = p.getClantag();

		if(getSecurity().isPlayerNameHidden(p) && getLocalPlayer() !is p)
		{
			if(isAdmin(getLocalPlayer()))
			{
				playername = username + "(hidden: " + clantag + " " + playername + ")";
				clantag = "";

			}
			else
			{
				playername = username;
				clantag = "";
			}
		}

		//head icon

		//TODO: consider maybe the skull emoji for dead players?
		int headIndex = 0;
		string headTexture = "";
		int teamIndex = p.getTeamNum();

		CBlob@ b = p.getBlob();
		if (b !is null)
		{
			headIndex = b.get_s32("head index");
			headTexture = b.get_string("head texture");
			teamIndex = b.get_s32("head team");
		}

		if (headTexture != "")
		{
			GUI::DrawIcon(headTexture, headIndex, Vec2f(16, 16), topleft + Vec2f(22, -12), 1.0f, teamIndex);
		}

		//have to calc this from ticks
		s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f);

		//how much room to leave for names and clantags
		float name_buffer = 57.0f;
		Vec2f clantag_actualsize(0, 0);

		//render the player + stats
		SColor namecolour = getNameColour(p);
		SColor usernamecolour = p.isMod() ? SColor(255, 255, 65, 65) : SColor(255, 215, 225, 35);

		//right align clantag
		if (clantag != "")
		{
			GUI::GetTextDimensions(clantag, clantag_actualsize);
			GUI::DrawText(clantag, topleft + Vec2f(name_buffer, 0), SColor(0xff888888));
			//draw name alongside
			GUI::DrawText(playername, topleft + Vec2f(name_buffer + clantag_actualsize.x + 8, 0), namecolour);
		}
		else
		{
			//draw name alone
			GUI::DrawText(playername, topleft + Vec2f(name_buffer, 0), namecolour);
		}
	
		float exp = 0;
		// load exp
		if (p !is null)
		{
			exp = getRules().get_u32(p.getUsername() + "_exp");
		}

		//draw rank level
		int level = 1;
		string rank = RANKS[0];

		// Calculate the exp required to reach each level
		for (int i = 1; i <= RANKS.length; i++)
		{
			int expToNextLevel = getExpToNextLevel(level);
			if (exp >= expToNextLevel)
			{
				level = i + 1;
				rank = RANKS[Maths::Min(i, RANKS.length-1)];
			}
			else
			{
				// The current level has been reached
				break;
			}
		}

		{
			//draw rank level
			int level = 1;
			string rank = RANKS[0];

			// Calculate the exp required to reach each level
			for (int i = 1; i <= RANKS.length; i++)
			{
				int expToNextLevel = getExpToNextLevel(level);
				if (exp >= expToNextLevel)
				{
					level = i + 1;
					rank = RANKS[Maths::Min(i, RANKS.length-1)];
				}
				else
				{
					// The current level has been reached
					break;
				}
			}

			float x = bottomright.x - accolades_start - 80;
			float extra = 8;
			GUI::DrawIcon("Ranks", level - 1, Vec2f(32, 32), Vec2f(x, topleft.y-12), 0.5f, 0);

			if (playerHover && mousePos.x > x - extra && mousePos.x < x + 16 + extra)
			{
				hovered_rank = level - 1;
			}
		}

		{
			//draw perk
			u8 icon = 0;
			string perk = (getRules().get_string(username + "_perk")).substr(0,2);
			
			if (perk == "Ca") icon = 6;
			else if (perk == "Sh") icon = 1;
			else if (perk == "Bl") icon = 3;
			else if (perk == "Op") icon = 5;
			else if (perk == "Lu") icon = 4;
			else if (perk == "We") icon = 2;
			else if (perk == "De") icon = 7;
			else if (perk == "Pa") icon = 9;
			else if (perk == "Bu") icon = 10;
			else if (perk == "Fi") icon = 11;

			float x = bottomright.x - accolades_start - 140;
			float extra = 8;
			GUI::DrawIcon("PerkIcon", icon, Vec2f(36, 36), Vec2f(x, topleft.y-12), 0.5f, 0);
		}

		//render player accolades
		Accolades@ acc = getPlayerAccolades(username);
		if (acc !is null)
		{
			if (acc.patreonMember)
			{
				//draw patreon accolades
				float x = bottomright.x - accolades_start-40;
				float extra = 32;
				GUI::DrawIcon("BadgesPatreon", 0, Vec2f(16, 16), Vec2f(x, topleft.y-2), 0.5f, 0);
				
				if (playerHover && mousePos.x > x-8 && mousePos.x < x + 24)
				{
					disable_line = true;
					GUI::DrawPane(mousePos+Vec2f(extra, extra-8), mousePos + Vec2f(192,55), SColor(0xffffffff));
					GUI::DrawText("Patreon supporter", mousePos + Vec2f(44,32), SColor(0xffffffff));
				}
				else disable_line = false;
			}
			else if (acc.spriterMember)
			{
				float x = bottomright.x - accolades_start-40;
				float extra = 32;
				GUI::DrawIcon("BadgesSpriter", 0, Vec2f(16, 16), Vec2f(x, topleft.y-2), 0.5f, 0);
				
				if (playerHover && mousePos.x > x-8 && mousePos.x < x + 24)
				{
					disable_line = true;
					GUI::DrawPane(mousePos+Vec2f(extra, extra-8), mousePos + Vec2f(398,55), SColor(0xffffffff));
					GUI::DrawText("In gratitude for significant spriting contribution.", mousePos + Vec2f(44,32), SColor(0xffffffff));
				}
				else disable_line = false;
			}

			//(remove crazy amount of duplicate code)
			int[] badges_encode = {
				//count,                icon,  show_text, group

				//misc accolades
				(acc.community_contributor ?
					1 : 0),             4,     0,         0,
				(acc.github_contributor ?
					1 : 0),             5,     0,         0,
				(acc.map_contributor ?
					1 : 0),             6,     0,         0,
				(acc.moderation_contributor && (
						//always show accolade of others if local player is special
						(p !is localplayer && isSpecial(localplayer)) ||
						//always show accolade for ex-admins
						!isSpecial(p) ||
						//show accolade only if colored name is visible
						coloredNameEnabled(getRules(), p)
					) ?
					1 : 0),             7,     0,         0,
				(p.getOldGold() ?
					1 : 0),             8,     0,         0,

				//tourney badges
				acc.gold,               0,     1,         1,
				acc.silver,             1,     1,         1,
				acc.bronze,             2,     1,         1,
				acc.participation,      3,     1,         1,

				//(final dummy)
				0, 0, 0, 0,
			};
			//encoding per-group
			int[] group_encode = {
				//singles
				accolades_start,                 24,
				//medals
				accolades_start - (24 * 5 + 12), 38,
			};

			for(int bi = 0; bi < badges_encode.length; bi += 4)
			{
				int amount    = badges_encode[bi+0];
				int icon      = badges_encode[bi+1];
				int show_text = badges_encode[bi+2];
				int group     = badges_encode[bi+3];

				int group_idx = group * 2;

				if(
					//non-awarded
					amount <= 0
					//erroneous
					|| group_idx < 0
					|| group_idx >= group_encode.length
				) continue;

				int group_x = group_encode[group_idx];
				int group_step = group_encode[group_idx+1];

				float x = bottomright.x - group_x;

				GUI::DrawIcon("AccoladeBadges", icon, Vec2f(16, 16), Vec2f(x, topleft.y), 0.5f, p.getTeamNum());
				if (show_text > 0)
				{
					string label_text = "" + amount;
					int label_center_offset = label_text.size() < 2 ? 4 : 0;
					GUI::DrawText(
						label_text,
						Vec2f(x + 15 + label_center_offset, topleft.y),
						SColor(0xffffffff)
					);
				}

				if (playerHover && mousePos.x > x && mousePos.x < x + 16)
				{
					hovered_accolade = icon;
				}

				//handle repositioning
				group_encode[group_idx] -= group_step;

			}
		}


		GUI::DrawText("" + username, Vec2f(bottomright.x - 470, topleft.y), usernamecolour);
		GUI::DrawText("" + ping_in_ms, Vec2f(bottomright.x - 330, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getKills(), Vec2f(bottomright.x - 260, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getDeaths(), Vec2f(bottomright.x - 190, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + p.getAssists(), Vec2f(bottomright.x - 120, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + formatFloat(getKDR(p), "", 0, 2), Vec2f(bottomright.x - 50, topleft.y), SColor(0xffffffff));
	}

	// username copied text, goes at bottom to overlay above everything else
	uint durationLeft = rules.get_u16("client_copy_time");

	if ((durationLeft + 64) > getGameTime())
	{
		durationLeft = getGameTime() - durationLeft;
		DrawFancyCopiedText(rules.get_string("client_copy_name"), rules.get_Vec2f("client_copy_pos"), durationLeft);
	}

	return topleft.y;

}

void onRenderScoreboard(CRules@ this)
{
	//sort players by exp (rank)
	CPlayer@[] teamleftplayers;
	CPlayer@[] teamrightplayers;
	CPlayer@[] spectators;
	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);

		float exp = 0;
		exp = this.get_u32(p.getUsername() + "_exp");

		bool inserted = false;
		if (p.getTeamNum() == this.getSpectatorTeamNum())
		{
			spectators.push_back(p);
			continue;
		}

		int teamNum = p.getTeamNum();
		if (teamNum == this.get_u8("teamleft")) //blue team
		{
			for (u32 j = 0; j < teamleftplayers.length; j++)
			{
				if (this.get_u32(teamleftplayers[j].getUsername() + "_exp") < exp)
				{
					teamleftplayers.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				teamleftplayers.push_back(p);
		}
		else if (teamNum == this.get_u8("teamright"))
		{
			for (u32 j = 0; j < teamrightplayers.length; j++)
			{
				if (this.get_u32(teamrightplayers[j].getUsername() + "_exp") < exp)
				{
					teamrightplayers.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				teamrightplayers.push_back(p);
		}
	}

	//draw board

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
		return;
	int localTeam = localPlayer.getTeamNum();

	@hoveredPlayer = null;

	Vec2f topleft(Maths::Max( 100, screenMidX-maxMenuWidth), 150);
	drawServerInfo(40);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//(reset)
	hovered_accolade = -1;
	hovered_rank = -1;

	//draw the scoreboards
	
	if (localTeam == this.get_u8("teamleft") || localTeam == getRules().getSpectatorTeamNum())
		topleft.y = drawScoreboard(localPlayer, teamleftplayers, topleft, this.getTeam(this.get_u8("teamleft")), Vec2f(0, 0), this.get_u8("teamleft"));
	else
		topleft.y = drawScoreboard(localPlayer, teamrightplayers, topleft, this.getTeam(this.get_u8("teamright")), Vec2f(32, 0), this.get_u8("teamright"));

	topleft.y += 52;

	if (localTeam == this.get_u8("teamright"))
		topleft.y = drawScoreboard(localPlayer, teamleftplayers, topleft, this.getTeam(this.get_u8("teamleft")), Vec2f(0, 0), this.get_u8("teamleft"));
	else
		topleft.y = drawScoreboard(localPlayer, teamrightplayers, topleft, this.getTeam(this.get_u8("teamright")), Vec2f(32, 0), this.get_u8("teamright"));

	topleft.y += 52;

	if (spectators.length > 0)
	{
		//draw spectators
		f32 stepheight = 16;
		Vec2f bottomright(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + stepheight * 2);
		f32 specy = topleft.y + stepheight * 0.5;
		GUI::DrawPane(topleft, bottomright, SColor(0xffc0c0c0));

		Vec2f textdim;
		string s = getTranslatedString("Spectators:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(topleft.x + 5, specy), SColor(0xffaaaaaa));

		f32 specx = topleft.x + textdim.x + 15;
		for (u32 i = 0; i < spectators.length; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < bottomright.x - 100)
			{
				string name = p.getCharacterName();
				if (i != spectators.length - 1)
					name += ",";
				GUI::GetTextDimensions(name, textdim);
				SColor namecolour = getNameColour(p);
				GUI::DrawText(name, Vec2f(specx, specy), namecolour);
				specx += textdim.x + 10;
			}
			else
			{
				GUI::DrawText(getTranslatedString("and more ..."), Vec2f(specx, specy), SColor(0xffaaaaaa));
				break;
			}
		}

		topleft.y += 52;
	}

	float scoreboardHeight = topleft.y + scrollOffset;
	float screenHeight = getScreenHeight();
	CControls@ controls = getControls();

	if(scoreboardHeight > screenHeight) {
		Vec2f mousePos = controls.getMouseScreenPos();

		float fullOffset = (scoreboardHeight + scoreboardMargin) - screenHeight;

		if(scrollOffset < fullOffset && mousePos.y > screenHeight*0.83f) {
			scrollOffset += scrollSpeed;
		}
		else if(scrollOffset > 0.0f && mousePos.y < screenHeight*0.16f) {
			scrollOffset -= scrollSpeed;
		}

		scrollOffset = Maths::Clamp(scrollOffset, 0.0f, fullOffset);
	}

	drawPlayerCard(hoveredPlayer, hoveredPos);

	drawHoverExplanation(hovered_accolade, hovered_rank, Vec2f(getScreenWidth() * 0.5, topleft.y));

	mouseWasPressed2 = controls.mousePressed2; 

	makeWebsiteLink(Vec2f(getScreenWidth()/2+500, 100.0f-scrollOffset), "Discord ", "https://discord.gg/55yueJWy7g");
	makeWebsiteLink(Vec2f(getScreenWidth()/2+420, 100.0f-scrollOffset), "Github ", "https://github.com/NoahTheLegend/kaww");
	makeWebsiteLink(Vec2f(getScreenWidth()/2+330, 100.0f-scrollOffset), "Patreon ", "https://www.patreon.com/armoredwarfare");
	//makeWebsiteLink(Vec2f(getScreenWidth()/2+198, 100.0f-scrollOffset), "Important Poll ", "https://docs.google.com/forms/d/e/1FAIpQLSdYi7ZN7R0Yl5142gTtKjcw8PhboYzDo9MACr_9vvJCAm0RMw/viewform");

	mouseWasPressed1 = controls.mousePressed1;
}

void drawHoverExplanation(int hovered_accolade, int hovered_rank, Vec2f centre_top)
{
	if( //(invalid/"unset" hover)
		(hovered_accolade < 0
		 || hovered_accolade >= accolade_description.length) &&
		(hovered_rank < 0
		 || hovered_rank >= RANKS.length)
	) {
		return;
	}

	string desc = getTranslatedString(
		(hovered_accolade >= 0) ? accolade_description[hovered_accolade] : RANKS[hovered_rank]
	);

	Vec2f size(0, 0);
	GUI::GetTextDimensions(desc, size);

	CControls@ controls = getControls();
	Vec2f tl = controls.getMouseScreenPos() + Vec2f(30,30); //centre_top - Vec2f(size.x / 2, 0);
	Vec2f br = tl + size;

	//margin
	Vec2f expand(8, 8);
	tl -= expand;
	br += expand;

	GUI::DrawPane(tl, br + Vec2f(4,0), SColor(0xffffffff));
	GUI::DrawText(desc, tl + expand, SColor(0xffffffff));
}

void onTick(CRules@ this)
{
	//if(isServer() && this.getCurrentState() == GAME)
	//{
		//this.add_u32("match_time", 1);
		//this.Sync("match_time", true);
	//}
	this.set_u32("match_time", getGameTime());
}

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	if(isServer())
	{
		this.set_u32("match_time", 0);
		this.Sync("match_time", true);
		getMapName(this);
	}
}

void getMapName(CRules@ this)
{
	CMap@ map = getMap();
	if(map !is null)
	{
		string[] name = map.getMapName().split('/');	 //Official server maps seem to show up as
		string mapName = name[name.length() - 1];		 //``Maps/CTF/MapNameHere.png`` while using this instead of just the .png
		mapName = getFilenameWithoutExtension(mapName);  // Remove extension from the filename if it exists

		this.set_string("map_name", mapName);
		this.Sync("map_name",true);
	}
}

void DrawFancyCopiedText(string username, Vec2f mousePos, uint duration)
{
	string text = "Username copied: " + username;
	Vec2f pos = mousePos - Vec2f(0, duration);
	int col = (255 - duration * 3);

	GUI::DrawTextCentered(text, pos, SColor((255 - duration * 4), col, col, col));
}

void makeWebsiteLink(Vec2f pos, const string&in text, const string&in website)
{
	Vec2f dim;
	GUI::GetTextDimensions(text, dim);

	const f32 width = dim.x + 20;
	const f32 height = 40;
	const Vec2f tl = Vec2f(getScreenWidth() - 10 - width - pos.x, pos.y);
	const Vec2f br = Vec2f(getScreenWidth() - 10 - pos.x, tl.y + height);

	CControls@ controls = getControls();
	const Vec2f mousePos = controls.getMouseScreenPos();

	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		GUI::DrawButton(tl, br);

		if (controls.mousePressed1 && !mouseWasPressed1)
		{
			Sound::Play("option");
			OpenWebsite(website);
		}
	}
	else
	{
		GUI::DrawPane(tl, br, 0xffcfcfcf);
	}

	GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
}