#define CLIENT_ONLY

#include "ClientVars.as";
#include "ClientConfig.as";
#include "Utilities.as";

const u16 savetime_fadeout = 10;
const u16 savetime_delay = 60;
u16 savetime = 0;

void onInit(CRules@ this)
{
    // init
    ClientVars setvars();
	this.set("ClientVars", @setvars);

    ClientVars@ vars;
    if (this.get("ClientVars", @vars))
    {
        LoadConfig(this, vars);
        SetupUI(this);

        ConfigMenu@ menu;
        if (this.get("ConfigMenu", @menu))
        {
            WriteConfig(this, menu);
        }
    }
}

void onRestart(CRules@ this)
{
    if (isServer() && getLocalPlayer() !is null) // localhost fix
        onInit(this);
}

void LoadConfig(CRules@ this, ClientVars@ vars) // load cfg from cache
{
    ConfigFile cfg = ConfigFile();

	if (!cfg.loadFile("../Cache/AW/clientconfig.cfg"))
	{
        error("Client config or vars could not load");

		cfg.add_f32("colorblind", 0);
	}
    else if (vars !is null)
    {
        vars.colorblind = cfg.read_f32("colorblind");
    }
}

void SetupUI(CRules@ this) // add options here
{
    Vec2f menu_pos = Vec2f(17.5f,70);
    Vec2f menu_dim = Vec2f(400, 400);
    ConfigMenu setmenu(menu_pos, menu_dim);
    
    // keep order with saving vars
    ClientVars@ vars = getVars();
    if (vars !is null)
    {
        Vec2f section_pos = menu_pos;
        Section special("Special", section_pos, Vec2f(menu_dim.x/2, menu_pos.y + 150));

        // slider increases every build up from initializing, pls fix 

        Option colorblind("Color blindness", section_pos+special.padding+Vec2f(0,35), true, false);
        colorblind.setSliderPos(vars.colorblind);
        colorblind.slider.mode = 2;
        string[] descriptions = {"None", "Protanopia", "Deuteranopia", "Tritanopia", "Protanomaly", "Deuteranomaly", "Tritanomaly"};
        colorblind.slider.setSnap(descriptions.size());
        colorblind.slider.descriptions = descriptions;
        special.addOption(colorblind);

        setmenu.addSection(special);
    }
    else error("Could not setup config UI, clientvars do not exist");

	this.set("ConfigMenu", @setmenu);
}

void WriteConfig(CRules@ this, ConfigMenu@ menu) // save config
{
    if (menu is null)
    {
        error("Could not save vars, menu is null");
        return;
    }

    ClientVars@ vars;
    if (this.get("ClientVars", @vars))
    {
        //camera
        //====================================================
        if (menu.sections.size() != 0)
        {
            if (menu.sections[0].options.size() != 0)
            {
                // section 0
                Option colorblind       = menu.sections[0].options[0];
                vars.colorblind         = colorblind.slider.scrolled;
                vars.colorblind_type    = Maths::Round(colorblind.slider.snap_points * colorblind.slider.scrolled);
            }

            //====================================================
            ConfigFile cfg = ConfigFile();
	        if (cfg.loadFile("../Cache/AW/clientconfig.cfg"))
	        {
                // write config
                //====================================================
                cfg.add_f32("colorblind", vars.colorblind);
                //====================================================
                // save config
	        	cfg.saveFile("AW/clientconfig.cfg");

                savetime = savetime_fadeout + savetime_delay;
	        }
            else
            {
                error("Could not load config to save vars code 1");
                error("Loading default preset");
                //====================================================
                cfg.add_f32("colorblind", vars.colorblind);
                //====================================================
		        cfg.saveFile("AW/clientconfig.cfg");
            }
        }
        else error("Could not load config to save vars code 2");
    }

    this.Untag("update_clientvars");
}

void onRender(CRules@ this) // renderer for class, saves config if class throws update tag
{
    bool need_update = this.hasTag("update_clientvars");
        
    ConfigMenu@ menu;
    if (this.get("ConfigMenu", @menu))
    {
        menu.render();

        GUI::SetFont("menu");
        if (savetime > 0)
        {
            GUI::DrawText("Saved!", menu.pos+Vec2f(menu.target_dim.x + 6, 7),
                SColor(185 * Maths::Min(1.0f, f32(savetime)/savetime_fadeout), 25, 255, 50));
            savetime--;
        }
    }
}

void onTick(CRules@ this)
{
    bool need_update = this.hasTag("update_clientvars");
    
    ConfigMenu@ menu;
    if (this.get("ConfigMenu", @menu))
    {
        if (need_update)
        {
            ClientVars@ vars;
            if (this.get("ClientVars", @vars))
            {
                LoadConfig(this, vars);
            }

            WriteConfig(this, menu);
        }
    }
}