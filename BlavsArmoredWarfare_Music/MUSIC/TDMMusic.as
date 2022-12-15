// Music Engine

// by blav

#define CLIENT_ONLY

enum GameMusicTags
{
	world_intro,
	world_tension,
	world_domination,
	world_ambient,
	world_battle,
	world_timer,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_gamemusic && s_musicvolume > 0.0f)
	{
		if (!this.get_bool("initialized game"))
		{
			AddGameMusic(this, mixer);
		}

		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();

	// world_intro Intro: randomly selected to play at new match start
	// world_tension Tension: plays when team first caps middle point | or maybe when both teams have 0 tickets remaining
	// world_domination Domination: when one team controls all points for the first time
	// world_ambient Ambient: plays randomly but respects buffers, usually not music
	// world_battle

	mixer.AddTrack("Music1.ogg", world_intro);
	mixer.AddTrack("Music1.ogg", world_battle);

	mixer.AddTrack("Music2.ogg", world_battle);

	mixer.AddTrack("Music3.ogg", world_intro);

	mixer.AddTrack("Music4.ogg", world_intro);

	mixer.AddTrack("Music5.ogg", world_battle);

	mixer.AddTrack("Music6.ogg", world_battle);

	//mixer.AddTrack("Music7.ogg", world_battle); not good

	mixer.AddTrack("Music8.ogg", world_battle);

	mixer.AddTrack("Music9.ogg", world_intro);

	mixer.AddTrack("Music10.ogg", world_intro);

	mixer.AddTrack("Music11.ogg", world_intro);

	mixer.AddTrack("Kaww_01_theme.ogg", world_intro);
	
	mixer.AddTrack("Kaww_02_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_03_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_04_theme.ogg", world_intro);

	mixer.AddTrack("Kaww_05_theme.ogg", world_battle); // mysterious

	mixer.AddTrack("Kaww_06_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_07_theme.ogg", world_battle);
	mixer.AddTrack("Kaww_07_theme.ogg", world_tension); // intense

	mixer.AddTrack("Kaww_08_theme.ogg", world_intro);

	mixer.AddTrack("Kaww_09_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_09_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_10_theme.ogg", world_battle);
	mixer.AddTrack("Kaww_10_theme.ogg", world_tension); // intense

	mixer.AddTrack("Kaww_11_theme.ogg", world_intro);

	mixer.AddTrack("Kaww_12_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_12_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_13_theme.ogg", world_battle);
	mixer.AddTrack("Kaww_13_theme.ogg", world_tension); // intense

	mixer.AddTrack("Kaww_14_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_15_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_15_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_16_theme.ogg", world_battle);

	mixer.AddTrack("Kaww_17_theme.ogg", world_intro);


	mixer.AddTrack("Kaww_timesup_theme.ogg", world_timer);
}

//uint timer = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();
	u32 gameEndTime = rules.get_u32("game_end_time");

	if ((gameEndTime - getGameTime())/30 == 70)
	{
		mixer.FadeOutAll(0.0f, 7.0f);
	}
	else if ((gameEndTime - getGameTime())/30 == 60)
	{
		mixer.FadeInRandom(world_timer , 0.0f);
	}
	else if (rules.isWarmup())
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_intro , 0.0f);
		}
	}
	else if (rules.isMatchRunning()) //chance for battle music every 22000 ticks (every 12 m)
	{
		if (mixer.getPlayingCount() == 0 && getGameTime() % 22000 == 0 && XORRandom(4) != 0)
		{
			mixer.FadeInRandom(world_battle , 0.0f);
		}
		
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}
