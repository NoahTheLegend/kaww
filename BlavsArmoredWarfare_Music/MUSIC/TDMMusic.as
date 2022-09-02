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
	//world_calm,
	//world_battle_2,
	//world_outro,
	//world_quick_out,
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

	// Intro: randomly selected to play at new match start
	// Tension: plays when team first caps middle point
	// Domination: when one team controls all points for the first time
	// Ambient: plays randomly but respects buffers, usually not music
	/* 
	mixer.AddTrack("Music6.ogg", world_battle);
	mixer.AddTrack("Music7.ogg", world_battle);
	mixer.AddTrack("Music8.ogg", world_battle);
	mixer.AddTrack("Music9.ogg", world_battle);
	mixer.AddTrack("Empty.ogg", world_battle);
	mixer.AddTrack("Empty.ogg", world_battle);

	mixer.AddTrack("Music1.ogg", world_intro);
	mixer.AddTrack("Music2.ogg", world_intro);
	mixer.AddTrack("Music3.ogg", world_intro);
	mixer.AddTrack("Music4.ogg", world_intro);
	mixer.AddTrack("Music5.ogg", world_intro);
	mixer.AddTrack("Music10.ogg", world_intro);
	mixer.AddTrack("Music11.ogg", world_intro);
	*/

	mixer.AddTrack("Kaww_01_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_02_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_03_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_04_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_05_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_06_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_07_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_08_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_09_theme.ogg", world_intro);

	mixer.AddTrack("Kaww_11_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_12_theme.ogg", world_intro);

	mixer.AddTrack("Kaww_10_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_13_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_14_theme.ogg", world_intro);
	


	mixer.AddTrack("Kaww_10_theme.ogg", world_battle);
	mixer.AddTrack("Kaww_13_theme.ogg", world_battle);
	mixer.AddTrack("Kaww_14_theme.ogg", world_battle);


}

//uint timer = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	if (rules.isWarmup())
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_intro , 0.0f);
		}
	}
	else if (rules.isMatchRunning()) //battle music
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_battle , 0.0f);
		}
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}
