//implements 2 default vote types (kick and next map) and menus for them

#include "VoteCommon.as"

bool g_haveStartedVote = false;
s32 g_lastVoteCounter = 0;
string g_lastUsernameVoted = "";
const float required_minutes = 0; //time you have to wait after joining w/o skip_votewait.

s32 g_lastNextmapCounter = 10;
s32 g_lastExtendtimeCounter = 5;
const float required_minutes_nextmap = 10; //global nextmap vote cooldown
const float required_minutes_extendtime = 5;

const s32 VoteKickTime = 30; //minutes (30min default)

//kicking related globals and enums
enum kick_reason
{
	kick_reason_griefer = 0,
	kick_reason_hacker,
	kick_reason_teamkiller,
	kick_reason_spammer,
	kick_reason_non_participation,
	kick_reason_count,
};
string[] kick_reason_string = { "Griefer", "Hacker", "Teamkiller", "Chat Spam", "Non-Participation" };

string g_kick_reason = kick_reason_string[kick_reason_griefer]; //default

//kick bots
enum kickbots_reason
{
	kickbots_reason_remove = 0
};
string[] kickbots_reason_string = { "Remove bots" };


//next map related globals and enums
enum nextmap_reason
{
	nextmap_reason_ruined = 0,
	nextmap_reason_stalemate,
	nextmap_reason_bugged,
	nextmap_reason_count,
};

string[] nextmap_reason_string = { "Map Ruined", "Stalemate", "Game Bugged" };

enum extendtime_time
{
	extendtime_time_5 = 0,
	extendtime_time_10,
	extendtime_time_15,
	extendtime_time_count,
};


string[] extendtime_reason_string = { "Extend game time by 5 minutes", "Extend game time by 10 minutes", "Extend game time by 15 minutes" };

//votekick and vote nextmap

const string votekick_id = "vote: kick";
const string votekickbots_id = "vote: kick bots";
const string votenextmap_id = "vote: nextmap";
const string votesurrender_id = "vote: surrender";
const string votescramble_id = "vote: scramble";
const string voteextendtime_id = "vote: extend time";


//set up the ids
void onInit(CRules@ this)
{
	this.addCommandID(votekick_id);
	this.addCommandID(votekickbots_id);
	this.addCommandID(votenextmap_id);
	this.addCommandID(votesurrender_id);
	this.addCommandID(votescramble_id);
	this.addCommandID(voteextendtime_id);
}


void onRestart(CRules@ this)
{
	g_lastNextmapCounter = 60 * getTicksASecond() * required_minutes_nextmap;
}

void onTick(CRules@ this)
{
	if (g_lastVoteCounter < 60 * getTicksASecond()*required_minutes)
	{
		g_lastVoteCounter++;
	}

	if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap)
	{
		g_lastNextmapCounter++;
	}

	if (g_lastExtendtimeCounter < 60 * getTicksASecond()*required_minutes_extendtime)
	{
		g_lastExtendtimeCounter++;
	}
}

//VOTE KICK --------------------------------------------------------------------
//votekick functors

class VoteKickFunctor : VoteFunctor
{
	VoteKickFunctor() {} //dont use this
	VoteKickFunctor(CPlayer@ _kickplayer)
	{
		@kickplayer = _kickplayer;
	}

	CPlayer@ kickplayer;

	void Pass(bool outcome)
	{
		if (kickplayer !is null && outcome)
		{
			client_AddToChat(
				getTranslatedString("Votekick passed! {USER} will be kicked out.")
					.replace("{USER}", kickplayer.getUsername()),
				vote_message_colour()
			);

			if (getNet().isServer())
			{
				getSecurity().ban(kickplayer, VoteKickTime, "Voted off"); //30 minutes ban
			}
		}
	}
};

class VoteKickCheckFunctor : VoteCheckFunctor
{
	VoteKickCheckFunctor() {}//dont use this
	VoteKickCheckFunctor(CPlayer@ _kickplayer, string _reason)
	{
		@kickplayer = _kickplayer;
		reason = _reason;
	}

	CPlayer@ kickplayer;
	string reason;

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		if (!getSecurity().checkAccess_Feature(player, "mark_player")) return false;

		if (reason.find(kick_reason_string[kick_reason_griefer]) != -1 || //reason contains "Griefer"
				reason.find(kick_reason_string[kick_reason_teamkiller]) != -1 || //or TKer
				reason.find(kick_reason_string[kick_reason_non_participation]) != -1) //or AFK
		{
			return (player.getTeamNum() == kickplayer.getTeamNum() || //must be same team
					kickplayer.getTeamNum() == getRules().getSpectatorTeamNum() || //or they're spectator
					getSecurity().checkAccess_Feature(player, "mark_any_team"));   //or has mark_any_team
		}

		return true; //spammer, hacker (custom?)
	}
};

class VoteKickLeaveFunctor : VotePlayerLeaveFunctor
{
	VoteKickLeaveFunctor() {} //dont use this
	VoteKickLeaveFunctor(CPlayer@ _kickplayer)
	{
		@kickplayer = _kickplayer;
	}

	CPlayer@ kickplayer;

	//avoid dangling reference to player
	void PlayerLeft(VoteObject@ vote, CPlayer@ player)
	{
		if (player is kickplayer)
		{
			client_AddToChat(
				getTranslatedString("{USER} left early, acting as if they were kicked.")
					.replace("{USER}", player.getUsername()),
				vote_message_colour()
			);
			if (getNet().isServer())
			{
				getSecurity().ban(player, VoteKickTime, "Ran from vote");
			}

			CancelVote(vote);
		}
	}
};

//setting up a votekick object
VoteObject@ Create_Votekick(CPlayer@ player, CPlayer@ byplayer, string reason)
{
	VoteObject vote;

	@vote.onvotepassed = VoteKickFunctor(player);
	@vote.canvote = VoteKickCheckFunctor(player, reason);
	@vote.playerleave = VoteKickLeaveFunctor(player);

	vote.title = "Kick {USER}?";
	vote.reason = reason;
	vote.byuser = byplayer.getUsername();
	vote.user_to_kick = player.getUsername();
	vote.forcePassFeature = "ban";
	vote.cancel_on_restart = false;

	CalculateVoteThresholds(vote);

	return vote;
}

//VOTE KICK BOTS --------------------------------------------------------------------

class VoteKickBotsFunctor : VoteFunctor
{
	VoteKickBotsFunctor() {} //dont use this

	void Pass(bool outcome)
	{
		if (outcome)
		{
			client_AddToChat(
				getTranslatedString("Votekick passed! Kicking bots..."),
				vote_message_colour()
			);

			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p !is null && p.isBot()) KickPlayer(p);
			}
		}
	}
};

class VoteKickBotsCheckFunctor : VoteCheckFunctor
{
	VoteKickBotsCheckFunctor() {}//dont use this
	VoteKickBotsCheckFunctor(string _reason)
	{
		reason = _reason;
	}

	string reason;

	bool PlayerCanVote(CPlayer@ player)
	{
		return true;
	}
};

VoteObject@ Create_Votekickbots(CPlayer@ byplayer, string reason)
{
	VoteObject vote;

	@vote.onvotepassed = VoteKickBotsFunctor();
	@vote.canvote = VoteKickBotsCheckFunctor(reason);

	vote.title = "Kick bots?";
	vote.reason = reason;
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "ban";
	vote.cancel_on_restart = true;

	CalculateVoteThresholds(vote);

	return vote;
}

//VOTE NEXT MAP ----------------------------------------------------------------
//nextmap functors

class VoteNextmapFunctor : VoteFunctor
{
	string playername;
	u8 MapType = 0;

	VoteNextmapFunctor() {} //dont use this
	VoteNextmapFunctor(CPlayer@ player, u8 type)
	{
		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (charname != username &&
		        charname != player.getClantag() + username &&
		        charname != player.getClantag() + " " + username)
		{
			playername = charname + " (" + player.getUsername() + ")";
		}
		else
		{
			playername = charname;
		}

		MapType = type;
	}

	void Pass(bool outcome)
	{
		if (outcome)
		{
			if (isServer())
			{
				printf(""+maptype);
				switch (MapType)
				{
					case 0:
					{
						string[]@ ClassicMaps;
						getRules().get("maptypes-classic", @ClassicMaps);

						LoadMap(ClassicMaps[XORRandom(ClassicMaps.length)]);
					}
					break;

					case 1:
					{
						string[]@ LargeMaps;
						getRules().get("maptypes-large", @LargeMaps);

						LoadMap(LargeMaps[XORRandom(LargeMaps.length)]);
					}
					break;

					case 2:
					{
						string[]@ AverageMaps;
						getRules().get("maptypes-average", @AverageMaps);

						LoadMap(AverageMaps[XORRandom(AverageMaps.length)]);
					}
					break;

					case 3:
					{
						string[]@ FlagMaps;
						getRules().get("maptypes-flag", @FlagMaps);

						LoadMap(FlagMaps[XORRandom(FlagMaps.length)]);
					}
					break;

					case 4:
					{
						string[]@ TruckMaps;
						getRules().get("maptypes-truck", @TruckMaps);

						LoadMap(TruckMaps[XORRandom(TruckMaps.length)]);
					}
					break;

					case 5:
					{
						string[]@ TdmMaps;
						getRules().get("maptypes-tdm", @TdmMaps);

						LoadMap(TdmMaps[XORRandom(TdmMaps.length)]);
					}
					break;

					// If the maptype is invalid or set to default, 
					// load next map like before
					default:
						LoadNextMap();
					break;
				}
			}
		}
		else
		{
			client_AddToChat(playername + " needs to take a spoonful of cement! Play on!", vote_message_colour());
		}
	}
};

class VoteNextmapCheckFunctor : VoteCheckFunctor
{
	VoteNextmapCheckFunctor() {}

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		return getSecurity().checkAccess_Feature(player, "map_vote");
	}
};

//setting up a vote next map object
VoteObject@ Create_VoteNextmap(CPlayer@ byplayer, string reason, u8 maptype)
{
	VoteObject vote;

	@vote.onvotepassed = VoteNextmapFunctor(byplayer, maptype);
	@vote.canvote = VoteNextmapCheckFunctor();

	vote.title = "Load new map";
	vote.maptype = TypeToString[maptype % 6];
	vote.reason = reason;
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "nextmap";
	vote.required_percent = 0.7f;

	CalculateVoteThresholds(vote);

	return vote;
}

//VOTE SURRENDER ----------------------------------------------------------------
//surrender functors

class VoteSurrenderFunctor : VoteFunctor
{
	VoteSurrenderFunctor() {} //dont use this
	VoteSurrenderFunctor(CPlayer@ player)
	{
		team = player.getTeamNum();

		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (
			charname != username &&
			charname != player.getClantag() + username &&
			charname != player.getClantag() + " " + username
		) {
			playername = charname + " (" + player.getUsername() + ")";
		}
		else
		{
			playername = charname;
		}
	}

	string playername;
	s32 team;
	void Pass(bool outcome)
	{
		if (outcome)
		{
			if (getNet().isServer())
			{
				CRules@ rules = getRules();
				s32 teamWonNum = (team + 1) % rules.getTeamsCount();
				CTeam@ teamLost = rules.getTeam(team);
				CTeam@ teamWon = rules.getTeam(teamWonNum);

				rules.SetTeamWon(teamWonNum);
				rules.SetCurrentState(GAME_OVER);

				rules.SetGlobalMessage("{LOSING_TEAM} Surrendered! {WINNING_TEAM} wins the Game!");
				rules.AddGlobalMessageReplacement("LOSING_TEAM", teamLost.getName());
				rules.AddGlobalMessageReplacement("WINNING_TEAM", teamWon.getName());
			}
		}
		else
		{
			client_AddToChat(getTranslatedString("{USER} needs to take a spoonful of cement! Play on!").replace("{USER}", playername), vote_message_colour());
		}
	}
};

class VoteSurrenderCheckFunctor : VoteCheckFunctor
{
	VoteSurrenderCheckFunctor() {}//dont use this
	VoteSurrenderCheckFunctor(s32 _team)
	{
		team = _team;
	}

	s32 team;

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		//todo: seclevs? how would they look?

		return player.getTeamNum() == team;
	}
};

//VOTE EXTEND TIME ----------------------------------------------------------------
//extendtime functors

class VoteExtendTimeFunctor : VoteFunctor
{
	VoteExtendTimeFunctor() {} //dont use this
	VoteExtendTimeFunctor(CPlayer@ player)
	{
		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (
			charname != username &&
			charname != player.getClantag() + username &&
			charname != player.getClantag() + " " + username
		) {
			playername = charname + " (" + player.getUsername() + ")";
		}
		else
		{
			playername = charname;
		}
	}

	string playername;
	void Pass(bool outcome)
	{
		if (outcome)
		{
			CRules@ rules = getRules();
			
			rules.set_u32("game_end_time", rules.get_u32("game_end_time")+(10*30*60));
			rules.set_u32("warn_extended_time", getGameTime()+300);
			rules.set_bool("show_warn_extended_time", true);
		}
		else
		{
			client_AddToChat(getTranslatedString("Vote for extending time failed!"), vote_message_colour());
		}
	}
};

class VoteExtendTimeCheckFunctor : VoteCheckFunctor
{
	VoteExtendTimeCheckFunctor() {}//dont use this
	VoteExtendTimeCheckFunctor(s32 _team)
	{
		team = _team;
	}

	s32 team;

	bool PlayerCanVote(CPlayer@ player)
	{
		//if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		//todo: seclevs? how would they look?

		return true;
	}
};

VoteObject@ Create_VoteExtendTime(CPlayer@ byplayer)
{
	VoteObject vote;

	@vote.onvotepassed = VoteExtendTimeFunctor(byplayer);

	vote.title = "Extend remaining match time for 10 minutes?";
	vote.reason = "";
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "surrender"; // leave it so
	vote.cancel_on_restart = true;

	CalculateVoteThresholds(vote);

	return vote;
}

//setting up a vote surrender object
VoteObject@ Create_VoteSurrender(CPlayer@ byplayer)
{
	VoteObject vote;

	@vote.onvotepassed = VoteSurrenderFunctor(byplayer);
	@vote.canvote = VoteSurrenderCheckFunctor(byplayer.getTeamNum());

	vote.title = "Surrender to the enemy?";
	vote.reason = "";
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "surrender";
	vote.cancel_on_restart = true;

	CalculateVoteThresholds(vote);

	return vote;
}

//VOTE SCRAMBLE ----------------------------------------------------------------
//scramble functors

class VoteScrambleFunctor : VoteFunctor
{
	VoteScrambleFunctor() {} //dont use this
	VoteScrambleFunctor(CPlayer@ player)
	{
		string charname = player.getCharacterName();
		string username = player.getUsername();
		//name differs?
		if (
			charname != username &&
			charname != player.getClantag() + username &&
			charname != player.getClantag() + " " + username
		) {
			playername = charname + " (" + player.getUsername() + ")";
		}
		else
		{
			playername = charname;
		}
	}

	string playername;
	void Pass(bool outcome)
	{
		if (outcome)
		{
			if (getNet().isServer())
			{
				LoadMap(getMap().getMapName());
			}
		}
		else
		{
			client_AddToChat(
				getTranslatedString("{USER} needs to take a spoonful of cement! Play on!")
					.replace("{USER}", playername),
				vote_message_colour()
			);
		}
	}
};

class VoteScrambleCheckFunctor : VoteCheckFunctor
{
	VoteScrambleCheckFunctor() {}

	bool PlayerCanVote(CPlayer@ player)
	{
		if (!VoteCheckFunctor::PlayerCanVote(player)) return false;

		return player.getTeamNum() != getRules().getSpectatorTeamNum();
	}
};

//setting up a vote next map object
VoteObject@ Create_VoteScramble(CPlayer@ byplayer)
{
	VoteObject vote;

	@vote.onvotepassed = VoteScrambleFunctor(byplayer);
	@vote.canvote = VoteScrambleCheckFunctor();

	vote.title = "Scramble the teams?";
	vote.reason = "";
	vote.byuser = byplayer.getUsername();
	vote.forcePassFeature = "scramble";
	vote.cancel_on_restart = true;

	CalculateVoteThresholds(vote);

	return vote;
}

//create menus for kick and nextmap

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	//get our player first - if there isn't one, move on
	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CRules@ rules = getRules();

	if (Rules_AlreadyHasVote(rules))
	{
		Menu::addContextItem(menu, getTranslatedString("(Vote already in progress)"), "DefaultVotes.as", "void CloseMenu()");
		Menu::addSeparator(menu);

		return;

	}

	//and advance context menu when clicked
	CContextMenu@ votemenu = Menu::addContextMenu(menu, getTranslatedString("Start a Vote"));
	Menu::addSeparator(menu);

	//vote options menu

	CContextMenu@ kickmenu = Menu::addContextMenu(votemenu, getTranslatedString("Kick"));
	CContextMenu@ mapmenu = Menu::addContextMenu(votemenu, getTranslatedString("Next Map"));
	CContextMenu@ extendtimemenu = Menu::addContextMenu(votemenu, getTranslatedString("Add Match Time"));
	CContextMenu@ surrendermenu = Menu::addContextMenu(votemenu, getTranslatedString("Surrender"));
	CContextMenu@ scramblemenu = Menu::addContextMenu(votemenu, getTranslatedString("Scramble"));
	CContextMenu@ kickbotsmenu = Menu::addContextMenu(votemenu, getTranslatedString("Kick Bots"));
	Menu::addSeparator(votemenu); //before the back button

	bool can_skip_wait = getSecurity().checkAccess_Feature(me, "skip_votewait");

	bool duplicatePlayer = isDuplicatePlayer(me);

	//kick menu
	if (getSecurity().checkAccess_Feature(me, "mark_player"))
	{
		if (duplicatePlayer)
		{
			Menu::addInfoBox(
				kickmenu,
				getTranslatedString("Can't Start Vote"),
				getTranslatedString(
					"Voting to kick a player\n" +
					"is not allowed when playing\n" +
					"with a duplicate instance of KAG.\n\n" +
					"Try rejoining the server\n" +
					"if this was unintentional."
				)
			);
		}
		else if (g_lastVoteCounter < 60 * getTicksASecond()*required_minutes
				&& (!can_skip_wait || g_haveStartedVote))
		{
			string cantstart_info = getTranslatedString(
				"Voting requires a {REQUIRED_MIN} min wait\n" +
				"after each started vote to\n" +
				"prevent spamming/abuse.\n"
			).replace("{REQUIRED_MIN}", "" + required_minutes);

			Menu::addInfoBox(kickmenu, getTranslatedString("Can't Start Vote"), cantstart_info);
		}
		else
		{
			string votekick_info = getTranslatedString(
				"Vote to kick a player on your team\nout of the game.\n\n" +
				"- use responsibly\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select a reason from the\n     list (default is griefing).\n" +
				"- select a name from the list.\n" +
				"- everyone votes.\n"
			);
			Menu::addInfoBox(kickmenu, getTranslatedString("Vote Kick"), votekick_info);

			Menu::addSeparator(kickmenu);

			//reasons
			for (uint i = 0 ; i < kick_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				Menu::addContextItemWithParams(kickmenu, getTranslatedString(kick_reason_string[i]), "DefaultVotes.as", "Callback_KickReason", params);
			}

			Menu::addSeparator(kickmenu);

			//write all players on our team
			bool added = false;
			for (int i = 0; i < getPlayersCount(); ++i)
			{
				CPlayer@ player = getPlayer(i);

				//if(player is me) continue; //don't display ourself for kicking
				//commented out for max lols

				int player_team = player.getTeamNum();
				if ((player_team == me.getTeamNum() || player_team == this.getSpectatorTeamNum()
						|| getSecurity().checkAccess_Feature(me, "mark_any_team"))
						&& (!getSecurity().checkAccess_Feature(player, "kick_immunity")))
				{
					string descriptor = player.getCharacterName();

					if (player.getUsername() != player.getCharacterName())
						descriptor += " (" + player.getUsername() + ")";

					if(g_lastUsernameVoted == player.getUsername())
					{
						string title = getTranslatedString(
							"Cannot kick {USER}"
						).replace("{USER}", descriptor);
						string info = getTranslatedString(
							"You started a vote for\nthis person last time.\n\nSomeone else must start the vote."
						);
						//no-abuse box
						Menu::addInfoBox(
							kickmenu,
							title,
							info
						);
					}
					else
					{
						string kick = getTranslatedString("Kick {USER}").replace("{USER}", descriptor);
						string kicking = getTranslatedString("Kicking {USER}").replace("{USER}", descriptor);
						string info = getTranslatedString( "Make sure you're voting to kick\nthe person you meant.\n" );

						CContextMenu@ usermenu = Menu::addContextMenu(kickmenu, kick);
						Menu::addInfoBox(usermenu, kicking, info);
						Menu::addSeparator(usermenu);

						CBitStream params;
						params.write_u16(player.getNetworkID());

						Menu::addContextItemWithParams(
							usermenu, getTranslatedString("Yes, I'm sure"),
							"DefaultVotes.as", "Callback_Kick",
							params
						);
						added = true;

						Menu::addSeparator(usermenu);
					}
				}
			}

			if (!added)
			{
				Menu::addContextItem(
					kickmenu, getTranslatedString("(No-one available)"),
					"DefaultVotes.as", "void CloseMenu()"
				);
			}
		}
	}
	else
	{
		Menu::addInfoBox(
			kickmenu,
			getTranslatedString("Can't vote"),
			getTranslatedString(
				"You are now allowed to votekick\n" +
				"players on this server\n"
			)
		);
	}
	Menu::addSeparator(kickmenu);

	//nextmap menu
	if (getSecurity().checkAccess_Feature(me, "map_vote"))
	{
		if (duplicatePlayer)
		{
			Menu::addInfoBox(
				mapmenu,
				getTranslatedString("Can't Start Vote"),
				getTranslatedString(
					"Voting for next map\n" +
					"is not allowed when playing\n" +
					"with a duplicate instance of KAG.\n\n" +
					"Try rejoining the server\n" +
					"if this was unintentional."
				)
			);
		}
		else if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap
				&& (!can_skip_wait || g_haveStartedVote))
		{
			string cantstart_info = getTranslatedString(
				"Voting for next map\n" +
				"requires a {NEXTMAP_MINS} min wait\n" +
				"after each started vote\n" +
				"to prevent spamming.\n"
			).replace("{NEXTMAP_MINS}", "" + required_minutes_nextmap);
			Menu::addInfoBox( mapmenu, getTranslatedString("Can't Start Vote"), cantstart_info);
		}
		else
		{
			CContextMenu@ classic_map_menu = Menu::addContextMenu(mapmenu, "Classic Map");
			CContextMenu@ large_map_menu = Menu::addContextMenu(mapmenu, "Large Map");
			CContextMenu@ average_map_menu = Menu::addContextMenu(mapmenu, "Small Map");
			CContextMenu@ flag_map_menu = Menu::addContextMenu(mapmenu,  "Flags Map");
			CContextMenu@ truck_map_menu = Menu::addContextMenu(mapmenu,  "Trucks Map");
			CContextMenu@ tdm_map_menu = Menu::addContextMenu(mapmenu,  "TDM Map");

			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				params.write_u8(1);
				Menu::addContextItemWithParams(classic_map_menu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}

			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				params.write_u8(2);
				Menu::addContextItemWithParams(large_map_menu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}

			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				params.write_u8(3);
				Menu::addContextItemWithParams(average_map_menu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}

			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				params.write_u8(4);
				Menu::addContextItemWithParams(flag_map_menu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}

			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				params.write_u8(5);
				Menu::addContextItemWithParams(truck_map_menu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}

			for (uint i = 0 ; i < nextmap_reason_count; ++i)
			{
				CBitStream params;
				params.write_u8(i);
				params.write_u8(6);
				Menu::addContextItemWithParams(tdm_map_menu, nextmap_reason_string[i], "DefaultVotes.as", "Callback_NextMap", params);
			}
		}
	}
	else
	{
		Menu::addInfoBox(
			mapmenu,
			getTranslatedString("Can't vote"),
			getTranslatedString(
				"You are not allowed to vote\n" +
				"to change the map on this server\n"
			)
		);
	}
	Menu::addSeparator(mapmenu);

	//extendtime menu
	if (duplicatePlayer)
	{
		Menu::addInfoBox(
			extendtimemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for additional time\n" +
				"is not allowed when playing\n" +
				"with a duplicate instance of KAG.\n\n" +
				"Try rejoining the server\n" +
				"if this was unintentional."
		)
		);
	}
	else if (g_lastExtendtimeCounter < 60 * getTicksASecond()*required_minutes_extendtime
			 && (!can_skip_wait || g_haveStartedVote))
	{
		string cantstart_info = getTranslatedString(
			"Voting for additional match time\n" +
			"requires a {NEXTMAP_MINS} min wait\n" +
			"after each started vote\n" +
			"to prevent spamming.\n\n"
		).replace("{NEXTMAP_MINS}", "" + required_minutes_extendtime);
		Menu::addInfoBox(extendtimemenu, getTranslatedString("Can't Start Vote"), cantstart_info);
	}
	else
	{
		Menu::addInfoBox(
			extendtimemenu,
			getTranslatedString("Vote for extra match time"),
			getTranslatedString(
				"Vote for additional 10 minutes for match time."
			)
		);

		Menu::addSeparator(extendtimemenu);
		CBitStream params;
		Menu::addContextItemWithParams(
			extendtimemenu,
			getTranslatedString("Add extra 10 minutes to match time?"),
			"DefaultVotes.as", "Callback_ExtendTime",
			params
		);
	}
	Menu::addSeparator(extendtimemenu);

	//surrender menu
	//(shares nextmap counter to prevent nextmap/surrender spam)
	if (duplicatePlayer)
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for surrender\n" +
				"is not allowed when playing\n" +
				"with a duplicate instance of KAG.\n\n" +
				"Try rejoining the server\n" +
				"if this was unintentional."
		)
		);
	}
	else if (me.getTeamNum() == rules.getSpectatorTeamNum())
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for surrender\n" +
				"is not available as a spectator\n"
			)
		);
	}
	else if (!this.isMatchRunning() && !can_skip_wait)
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for surrender\n" +
				"is not allowed before the game starts.\n"
			)
		);
	}
	else if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap
			 && (!can_skip_wait || g_haveStartedVote))
	{
		string cantstart_info = getTranslatedString(
			"Voting for surrender\n" +
			"requires a {NEXTMAP_MINS} min wait\n" +
			"after each started vote\n" +
			"to prevent spamming.\n"
		).replace("{NEXTMAP_MINS}", "" + required_minutes_nextmap);
		Menu::addInfoBox(surrendermenu, getTranslatedString("Can't Start Vote"), cantstart_info);
	}
	else
	{
		Menu::addInfoBox(
			surrendermenu,
			getTranslatedString("Vote Surrender"),
			getTranslatedString(
				"Vote to end the game\nin favour of the enemy team.\n\n" +
				"- report any abuse of this feature.\n" +
				"\nTo Use:\n\n" +
				"- select surrender if you're sure.\n" +
				"- everyone votes.\n"
			)
		);

		Menu::addSeparator(surrendermenu);
		CBitStream params;
		Menu::addContextItemWithParams(
			surrendermenu,
			getTranslatedString("We Surrender! (I'm sure)"),
			"DefaultVotes.as", "Callback_Surrender",
			params
		);
	}
	Menu::addSeparator(surrendermenu);

	if (duplicatePlayer)
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for team scramble\n" +
				"is not allowed when playing\n" +
				"with a duplicate instance of KAG.\n\n" +
				"Try rejoining the server\n" +
				"if this was unintentional."
			)
		);
	}
	else if (me.getTeamNum() == rules.getSpectatorTeamNum())
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for team scramble\n" +
				"is not available as a spectator\n"
			)
		);
	}
	else if (!this.isWarmup() && !can_skip_wait)
	{
		Menu::addInfoBox(
			scramblemenu,
			getTranslatedString("Can't Start Vote"),
			getTranslatedString(
				"Voting for team scramble\n" +
				"is not allowed after the game starts.\n"
			)
		);
	}
	else if (g_lastNextmapCounter < 60 * getTicksASecond()*required_minutes_nextmap
			 && (!can_skip_wait || g_haveStartedVote))
	{
		string cantstart_info = getTranslatedString(
			"Voting for team scramble\n" +
			"requires a {NEXTMAP_MINS} min wait\n" +
			"after each started vote\n" +
			"to prevent spamming.\n"
		).replace("{NEXTMAP_MINS}", "" + required_minutes_nextmap);
		Menu::addInfoBox(scramblemenu, getTranslatedString("Can't Start Vote"), cantstart_info);
	}
	Menu::addSeparator(scramblemenu);

	//kick bots menu
	if (getSecurity().checkAccess_Feature(me, "mark_player"))
	{
		if (duplicatePlayer)
		{
			Menu::addInfoBox(
				kickbotsmenu,
				getTranslatedString("Can't Start Vote"),
				getTranslatedString(
					"Voting to kick bots\n" +
					"is not allowed when playing\n" +
					"with a duplicate instance of KAG.\n\n" +
					"Try rejoining the server\n" +
					"if this was unintentional."
				)
			);
		}
		else if (g_lastVoteCounter < 60 * getTicksASecond()*required_minutes
				&& (!can_skip_wait || g_haveStartedVote))
		{
			string cantstart_info = getTranslatedString(
				"Voting requires a {REQUIRED_MIN} min wait\n" +
				"after each started vote to\n" +
				"prevent spamming/abuse.\n"
			).replace("{REQUIRED_MIN}", "" + required_minutes);

			Menu::addInfoBox(kickbotsmenu, getTranslatedString("Can't Start Vote"), cantstart_info);
		}
		else
		{
			string votekickbots_info = getTranslatedString(
				"Vote to kick bots\nout of the game.\n"
			);
			Menu::addInfoBox(kickbotsmenu, getTranslatedString("Vote Kick Bots"), votekickbots_info);

			Menu::addSeparator(kickbotsmenu);

			CBitStream params;
			Menu::addContextItemWithParams(
				kickbotsmenu, getTranslatedString("Yes, I'm sure"),
				"DefaultVotes.as", "Callback_KickBots",
				params
			);
			Menu::addSeparator(kickbotsmenu);
		}
	}
	else
	{
		Menu::addInfoBox(
			kickbotsmenu,
			getTranslatedString("Can't vote"),
			getTranslatedString(
				"You are now allowed to votekick\n" +
				"bots on this server\n"
			)
		);
	}
	Menu::addSeparator(kickbotsmenu);
}

void CloseMenu()
{
	Menu::CloseAllMenus();
}

void onPlayerStartedVote()
{
	g_lastVoteCounter = 0;
	g_lastNextmapCounter = 0;
	g_lastExtendtimeCounter = 0;
	g_haveStartedVote = true;
}

void Callback_KickReason(CBitStream@ params)
{
	u8 id; if (!params.saferead_u8(id)) return;

	if (id < kick_reason_count)
	{
		g_kick_reason = kick_reason_string[id];
	}
}

void Callback_Kick(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	u16 id;
	if (!params.saferead_u16(id)) return;

	CPlayer@ other_player = getPlayerByNetworkId(id);
	if (other_player is null) return;

	if (getSecurity().checkAccess_Feature(other_player, "kick_immunity"))
		return;

	//monitor to prevent abuse
	g_lastUsernameVoted = other_player.getUsername();

	CBitStream params2;

	params2.write_u16(other_player.getNetworkID());
	params2.write_u16(me.getNetworkID());
	params2.write_string(g_kick_reason);

	getRules().SendCommand(getRules().getCommandID(votekick_id), params2);
	onPlayerStartedVote();
}

void Callback_KickBots(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;
	params2.write_u16(me.getNetworkID());
	params2.write_string("Remove bots");

	getRules().SendCommand(getRules().getCommandID(votekickbots_id), params2);
	onPlayerStartedVote();
}

void Callback_NextMap(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	u8 id;
	if (!params.saferead_u8(id)) return;

	u8 type;
	if (!params.saferead_u8(type)) return;

	string reason = "";
	if (id < nextmap_reason_count)
	{
		reason = nextmap_reason_string[id];
	}

	CBitStream params2;

	params2.write_u16(me.getNetworkID());
	params2.write_string(reason);
	params2.write_u8(type);

	getRules().SendCommand(getRules().getCommandID(votenextmap_id), params2);
	onPlayerStartedVote();
}

void Callback_Surrender(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;

	params2.write_u16(me.getNetworkID());

	getRules().SendCommand(getRules().getCommandID(votesurrender_id), params2);
	onPlayerStartedVote();
}

void Callback_Scramble(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;

	params2.write_u16(me.getNetworkID());

	getRules().SendCommand(getRules().getCommandID(votescramble_id), params2);
	onPlayerStartedVote();
}

void Callback_ExtendTime(CBitStream@ params)
{
	CloseMenu(); //definitely close the menu

	CPlayer@ me = getLocalPlayer();
	if (me is null) return;

	CBitStream params2;

	params2.write_u16(me.getNetworkID());

	getRules().SendCommand(getRules().getCommandID(voteextendtime_id), params2);
	onPlayerStartedVote();
}

//actually setting up the votes
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (Rules_AlreadyHasVote(this))
		return;

	if (cmd == this.getCommandID(votekick_id))
	{
		u16 playerid, byplayerid;
		string reason;

		if (!params.saferead_u16(playerid)) return;
		if (!params.saferead_u16(byplayerid)) return;
		if (!params.saferead_string(reason)) return;

		CPlayer@ player = getPlayerByNetworkId(playerid);
		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (player !is null && byplayer !is null)
			Rules_SetVote(this, Create_Votekick(player, byplayer, reason));
	}
	else if (cmd == this.getCommandID(votekickbots_id))
	{
		u16 byplayerid;
		string reason;

		if (!params.saferead_u16(byplayerid)) return;
		if (!params.saferead_string(reason)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_Votekickbots(byplayer, reason));
	}
	else if (cmd == this.getCommandID(votenextmap_id))
	{
		u16 byplayerid;
		string reason;
		u8 maptype;

		if (!params.saferead_u16(byplayerid)) return;
		if (!params.saferead_string(reason)) return;
		if (!params.saferead_u8(maptype)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_VoteNextmap(byplayer, reason, maptype));

		g_lastNextmapCounter = 0;
	}
	else if (cmd == this.getCommandID(votesurrender_id))
	{
		u16 byplayerid;

		if (!params.saferead_u16(byplayerid)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_VoteSurrender(byplayer));

		g_lastNextmapCounter = 0;
	}
	else if (cmd == this.getCommandID(votescramble_id))
	{
		u16 byplayerid;

		if (!params.saferead_u16(byplayerid)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_VoteScramble(byplayer));

		g_lastNextmapCounter = 0;
	}
	else if (cmd == this.getCommandID(voteextendtime_id))
	{
		u16 byplayerid;

		if (!params.saferead_u16(byplayerid)) return;

		CPlayer@ byplayer = getPlayerByNetworkId(byplayerid);

		if (byplayer !is null)
			Rules_SetVote(this, Create_VoteExtendTime(byplayer));
		g_lastExtendtimeCounter = 0;
	}
}

const string[] TypeToString = {
	"Random",
	"Classic",
	"Large",
	"Average",
	"CTF",
	"DTT",
	"TDM"
};