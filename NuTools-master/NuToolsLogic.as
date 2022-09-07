//This file handles misc logic and rendering related things in this mod. This file should go before all other files that interact with functions in this mod
//TODO, swap the sending command system from CRules to a single NuTools blob. The command will only send to the blob and cause less max commands issues and be more performant hopfully. Use a method to send a command.
//TODO, figure out what I meant by this ^

#include "NuMenuCommon.as";
#include "NuTextCommon.as";
#include "NuHub.as";
#include "NuToolsRendering.as";

bool init;
NuHub@ hub;

void onInit( CRules@ rules )//First time start only.
{
    @hub = @LoadStuff(rules);
    
    if(isClient())
    {
        hub.SetupRendering();
    }

    NuLib::onInit(rules);

    onRestart(rules);
}

NuHub@ LoadStuff( CRules@ rules )//Every reload and restart
{
    //NuMenu::addMenuToList(buttonhere);//Add buttons like this
    NuHub@ _hub = NuHub();

    rules.set("NuHub", @_hub);
    
    print("NuHub Loaded");

    if(isClient())
    {
        NuRender::onInit(rules, _hub);

        NuMenu::onInit(rules, _hub);

        addFonts(rules, _hub);
    }
    

    if(sv_gamemode == "Testing")//Is the gamemode name Testing?
    {
        if(!init)//If first time init
        {
            print("=====NuButton.as attempt to add. This will only work if the NuButton mod is installed=====");
            rules.AddScript("NuButton.as");//Add the NuButton script to the gamemode.
            print("=====If an error is above, it is safe to ignore. It simply means the NuButton mod was not installed and is of no concern. Blame kag for not allowing the checking of the modlist=====");
        }//It's done like this to allow NuTools Testing gamemode with or without the NuButton mod installed
    } 

    init = true;

    return @_hub;
}

void onReload( CRules@ rules )
{
    LoadStuff(rules);
}

void onRestart( CRules@ rules)
{
    NuLib::onRestart(rules);
}

void onTick( CRules@ rules )
{
    if(getGameTime() == 30 && sv_gamemode == "Testing" && isServer())//If thirty ticks have passed since restarting and the gamemode is testing, and this is serverside.
    {
        CPlayer@ player = getPlayer(0);
        if(player != @null)
        {
            CBlob@ plob = Nu::RespawnPlayer(rules, player);//Respawn the player
            server_CreateBlob("saw", -1, plob.getPosition() + Vec2f(20.0f, 0));
        } 
    }
    NuRender::onTick(rules);

    NuMenu::MenuTick();//Run logic for the menus.
}

void onRender( CRules@ rules )
{
    if(!init) { return; }//Kag renders before onInit. Stop this.

    NuRender::onRender(rules);

    NuLib::onRender(rules);
}





void addFonts( CRules@ rules, NuHub@ hub)
{
    hub.addFont(MSDF, "Lato-Regular", "Lato-Regular.png", "Lato-Regular.cfg");//MSDF font
    hub.addFont(IrrFontTool, "Calibri-48-Bold", "Calibri-48-Bold.png");//Irr Font
}





void onCommand(CRules@ rules, u8 cmd, CBitStream@ params)
{
    NuLib::onCommand(rules, cmd, params);
}