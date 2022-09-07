//This file was replaced to handle loading gamemode.cfg better. Unfortunately, the required scripts to do this don't exist.
//At the moment this file only runs example_gamemoe.cfg if the gamemode name is "Testing" and otherwise functions normally.

// default startup functions for autostart scripts

void RunServer()
{
    //Numan - Need to check through every gamemode.cfg file. As it was not possible at the time of this message, certain things were commented out.
	if (getNet().CreateServer())
	{
        string gamemode_path = "Rules/" + sv_gamemode + "/gamemode.cfg";

        /*ConfigFile cfg = ConfigFile();
        if (!cfg.loadFile(gamemode_path))
        {
            error("failure to load gamemode.cfg");
        }
        else
        {
            string cfg_gamemode = cfg.read_string("gamemode_name");

            if(cfg_gamemode == sv_gamemode)//Is this the gamemode that is set.
            {
                LoadRules(gamemode_path);//Load the gamemode.
            }
        }*/
        
        //Temp
        if(sv_gamemode == "Testing")
        {
            LoadRules("example_gamemode.cfg");
        }
        else
        {
            LoadRules(gamemode_path);
        }
        if (sv_mapcycle.size() > 0)
		{
			LoadMapCycle(sv_mapcycle);
		}
		else
		{
			LoadMapCycle("Rules/" + sv_gamemode + "/mapcycle.cfg");
		}

		LoadNextMap();
	}
}

void ConnectLocalhost()
{
	getNet().Connect("localhost", sv_port);
}

void RunLocalhost()
{
	RunServer();
	ConnectLocalhost();
}

void LoadDefaultMenuMusic()
{
	if (s_menumusic)
	{
		CMixer@ mixer = getMixer();
		if (mixer !is null)
		{
			mixer.ResetMixer();
			mixer.AddTrack("Sounds/Music/world_intro.ogg", 0);
			mixer.PlayRandom(0);
		}
	}
}
