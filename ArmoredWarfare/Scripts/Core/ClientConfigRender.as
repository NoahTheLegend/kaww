#define CLIENT_ONLY

#include "ClientVars.as";
#include "ClientConfig.as";
#include "Utilities.as";

const u16 savetime_fadeout = 10;
const u16 savetime_delay = 60;
u16 savetime = 0;

void onInit(CRules@ this)
{
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
        cfg.add_u16("ammo_autopickup", 100);
        cfg.add_bool("head_rotation", true);
        cfg.add_bool("body_rotation", true);
        cfg.add_bool("reset ping cursor", true);
	}
    else if (vars !is null)
    {
        vars.colorblind = cfg.read_f32("colorblind", 0);
        vars.ammo_autopickup = cfg.read_u16("ammo_autopickup", 100);
        vars.head_rotation = cfg.read_bool("head_rotation", true);
        vars.body_rotation = cfg.read_bool("body_rotation", true);
        vars.reset_ping_cursor = cfg.read_bool("reset ping cursor", true);
    }
}

const int step_mod_ammo = 50;

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
        const f32 section_offset = 50;
        const f32 option_offset = 30;

        ///////////////////////////////////////////////////////////////////////////////////////////////

        Section special("     Special", section_pos, Vec2f(menu_dim.x/2, menu_dim.y/2));

        Option colorblind("Color blindness", special.pos+special.padding+Vec2f(0,option_offset + special.padding.y), true, false);
        colorblind.setSliderPos(vars.colorblind);
        colorblind.slider.mode = 2;
        string[] descriptions = {"None", "Protanopia", "Deuteranopia", "Tritanopia", "Protanomaly", "Deuteranomaly", "Tritanomaly"};
        colorblind.slider.setSnap(descriptions.size());
        colorblind.slider.descriptions = descriptions;
        special.addOption(colorblind);

        Option ammo_autopickup("Ammo autopickup", colorblind.pos + Vec2f(0, option_offset * 2), true, false);
        ammo_autopickup.setSliderPos(f32(vars.ammo_autopickup / max_ammo_autopickup));
        ammo_autopickup.slider.setSnap(max_ammo_autopickup/step_mod_ammo+1); // +1 so 0 is also an option
        ammo_autopickup.slider.description_step_mod = step_mod_ammo;
        ammo_autopickup.slider.mode = 1;
        special.addOption(ammo_autopickup);

        setmenu.addSection(special);

        ///////////////////////////////////////////////////////////////////////////////////////////////

        Section preference("Preference", Vec2f(menu_pos.x, ammo_autopickup.pos.y)+Vec2f(0,section_offset), Vec2f(menu_dim.x/2, menu_dim.y/2));

        Option head_rotation("Head rotation", preference.pos+preference.padding+Vec2f(0,option_offset + preference.padding.y), false, true);
        head_rotation.check.state = vars.head_rotation;
        preference.addOption(head_rotation);

        Option body_rotation("Body rotation", head_rotation.pos+Vec2f(0,option_offset), false, true);
        body_rotation.check.state = vars.body_rotation;
        preference.addOption(body_rotation);  

        Option reset_ping_cursor("Reset cursor upon png", body_rotation.pos+Vec2f(0,option_offset), false, true);
        reset_ping_cursor.check.state = vars.reset_ping_cursor;
        preference.addOption(reset_ping_cursor);

        setmenu.addSection(preference);

        ///////////////////////////////////////////////////////////////////////////////////////////////
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
                vars.colorblind_type    = Maths::Clamp(Maths::Round(colorblind.slider.snap_points * colorblind.slider.scrolled), 0, 6);

                Option ammo_autopickup  = menu.sections[0].options[1];
                f32 ammo_rounder        = max_ammo_autopickup / step_mod_ammo;
                vars.ammo_autopickup    = Maths::Ceil(ammo_autopickup.slider.scrolled * ammo_rounder) / ammo_rounder * max_ammo_autopickup;
            }

            if (menu.sections[1].options.size() != 0)
            {
                // section 1
                Option head_rotation    = menu.sections[1].options[0];
                vars.head_rotation      = head_rotation.check.state;
                
                Option body_rotation    = menu.sections[1].options[1];
                vars.body_rotation      = body_rotation.check.state;

                Option reset_ping_cursor = menu.sections[1].options[2];
                vars.reset_ping_cursor = reset_ping_cursor.check.state;
            }

            //====================================================
            ConfigFile cfg = ConfigFile();
	        if (cfg.loadFile("../Cache/AW/clientconfig.cfg"))
	        {
                // write config
                //====================================================
                cfg.add_f32("colorblind", vars.colorblind);
                cfg.add_u16("ammo_autopickup", vars.ammo_autopickup);
                cfg.add_bool("head_rotation", vars.head_rotation);
                cfg.add_bool("body_rotation", vars.body_rotation);
                cfg.add_bool("reset ping cursor", vars.reset_ping_cursor);
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
                cfg.add_f32("colorblind", 0);
                cfg.add_u16("ammo_autopickup", 100);
                cfg.add_bool("head_rotation", true);
                cfg.add_bool("body_rotation", true);
                cfg.add_bool("reset ping cursor", true);
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
    if (!u_showtutorial) return;
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

uint timer = 0;
void onTick(CRules@ this)
{
    timer++;
    bool need_update = this.hasTag("update_clientvars") || timer == 30;
    
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

            if (getLocalPlayer() !is null && getGameTime() != 0)
            {
                CBitStream params;
                params.write_u16(getLocalPlayer().getNetworkID());
                params.write_u32(vars.ammo_autopickup);
                this.SendCommand(this.getCommandID("sync_clientconfig"), params);
            }
        }
    }
}