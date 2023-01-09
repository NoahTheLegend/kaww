// Music Engine

// by blav

#define CLIENT_ONLY

enum GameMusicTags
{
	world_ambient_start,

	world_ambient,
	world_ambient_underground,
	world_ambient_mountain,
	world_ambient_night,

	world_ambient_end,

	world_intro,
	world_tension,
	world_domination,
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

	mixer.AddTrack("Sounds/Music/ambient_forest.ogg", world_ambient);
	mixer.AddTrack("Sounds/Music/ambient_mountain.ogg", world_ambient_mountain);
	mixer.AddTrack("Sounds/Music/ambient_cavern.ogg", world_ambient_underground);
	mixer.AddTrack("Sounds/Music/ambient_night.ogg", world_ambient_night);

	// world_intro Intro: randomly selected to play at new match start
	// world_tension Tension: plays when team first caps middle point | or maybe when both teams have 0 tickets remaining
	// world_domination Domination: when one team controls all points for the first time
	// world_ambient
	// world_battle

	mixer.AddTrack("Music1.ogg", world_intro);
	mixer.AddTrack("Music1.ogg", world_battle);

	mixer.AddTrack("Music2.ogg", world_battle);

	mixer.AddTrack("Music3.ogg", world_intro);

	mixer.AddTrack("Music4.ogg", world_intro);

	mixer.AddTrack("Music5.ogg", world_battle);

	mixer.AddTrack("Music6.ogg", world_battle);


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

	mixer.AddTrack("Kaww_18_theme.ogg", world_intro);
	mixer.AddTrack("Kaww_18_theme.ogg", world_battle);


	mixer.AddTrack("Kaww_timesup_theme.ogg", world_timer);
}

uint timer = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	timer++;
	if (mixer is null)
		return;

	CRules @rules = getRules();
	u32 gameEndTime = rules.get_u32("game_end_time");
	/*
	CBlob @blob = getLocalPlayerBlob();
	if (blob is null)
	{
		mixer.FadeOutAll(0.0f, 3.0f);
		return;
	}

	CMap@ map = blob.getMap();
	if (map is null)
		return;

	Vec2f pos = blob.getPosition();*/
	/*
	//calc ambience
	if (timer % 30 == 0)
	{
		bool isNight = map.getDayTime() < 0.09f;
		bool isUnderground = map.rayCastSolid(pos, Vec2f(pos.x, pos.y - 60.0f));
		if (isUnderground)
		{
			changeAmbience(mixer, world_ambient_underground, 4.0f, 4.0f);
		}
		else if (pos.y < map.tilemapheight * map.tilesize * 0.2f) // top one fifth of map is windy
		{
			changeAmbience(mixer, world_ambient_mountain, 4.0f, 4.0f);
		}
		else if (isNight)
		{
			changeAmbience(mixer, world_ambient_night, 4.0f, 4.0f);
		}
		else
		{
			changeAmbience(mixer, world_ambient, 4.0f, 4.0f);
		}
	}*/
	//print("g : " + mixer.getPlayingTag(world_intro));
	if ((gameEndTime - getGameTime())/30 == 70) // fade out all current music
	{
		mixer.FadeOutAll(0.0f, 7.0f);
	}
	else if ((gameEndTime - getGameTime())/30 == 60) // play ending music
	{
		mixer.FadeInRandom(world_timer , 0.0f);
	}
	else if (getGameTime() == 120 && mixer.getPlayingCount() < 1 ) // intro theme
	{
		mixer.FadeInRandom(world_intro , 5.0f);
		
	}
	else if (rules.isMatchRunning()) // chance for random battle music every 20000 ticks
	{
		if (mixer.getPlayingCount() < 1 && getGameTime() % 20000 == 0 && XORRandom(4) != 0)
		{
			mixer.FadeInRandom(world_battle , 5.0f);
		}
	}
	else
	{
		if (mixer.getPlayingCount() >= 0)
		{
			mixer.FadeOutAll(0.0f, 1.0f);
		}
	}
}

// handle fadeouts / fadeins dynamically
void changeAmbience(CMixer@ mixer, int nextTrack, f32 fadeoutTime = 0.0f, f32 fadeinTime = 0.0f)
{
	if (!mixer.isPlaying(nextTrack))
	{
		for (u32 i = world_ambient_start + 1; i < world_ambient_end; i++)
			mixer.FadeOut(i, fadeoutTime);
	}

	mixer.FadeInRandom(nextTrack, fadeinTime);
}
