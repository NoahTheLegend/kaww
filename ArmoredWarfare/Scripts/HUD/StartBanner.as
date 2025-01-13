#include "GamemodeCheck.as";

#define CLIENT_ONLY

Vec2f bannerStart = Vec2f_zero;
Vec2f bannerPos = Vec2f_zero;
Vec2f bannerDest = Vec2f_zero;
f32 frameTime = 0;
const f32 maxTime = 1.2f;

void onInit(CRules@ this)
{
    if (!GUI::isFontLoaded("score-big"))
    {
        string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
        GUI::LoadFont("score-big", AveriaSerif, 32, true);
    }

    onRestart(this);
}

void onRestart(CRules@ this)
{
    this.Untag("animateBanner");

    this.set_s8("flagcount", -1);
    this.set_string("bannertext", ".");

    bannerPos = Vec2f_zero;
    bannerDest = Vec2f_zero;
    frameTime = 0;
}

void onTick(CRules@ this)
{
    if (getGameTime() < 370 && getGameTime() > 0)
    {
        CBlob@[] tents;
        getBlobsByName("tent", @tents);

        bool ctf = isCTF();
        bool dtt = isDTT();
        bool ptb = isPTB();
        u8 ptb_defenders = defendersTeamPTB();

        u8 local_team = 255;
        if (getLocalPlayer() !is null)
        {
            local_team = getLocalPlayer().getTeamNum();
        }

        Driver@ driver = getDriver();
        if (driver !is null)
        {
            bannerDest = Vec2f(driver.getScreenWidth()/2, driver.getScreenHeight()/9);
            bannerStart = bannerDest;
            bannerStart.y = 0;
            bannerPos = bannerStart;

            this.Tag("animateBanner");
        }

        if (this.get_string("map_name") == "Abacus")
        {
            this.set_string("bannertext", "Zombie Mode");
        }
        else {
            if (tents.length == 0 && dtt)
            {
                // break the truck
                this.set_string("bannertext", "Destroy the enemy truck!");
            }
            else if (ctf)
            {
                CBlob@[] flags;
                getBlobsByTag("pointflag", @flags);

                // capture the flag
                this.set_string("bannertext", (flags.size() <= 2 ? "Capture all the flags to win!" : "         Collect enough control points to win!"));
                bannerDest += Vec2f(0, 100);
            }
            else if (ptb)
            {
                // plant the bomb
                this.set_string("bannertext", local_team == ptb_defenders ? "Don't let enemies to explode the cores!" : "Plant a C-4 at enemy cores!");
            }
            else
            {
                // showdown
                this.set_string("bannertext", "Kill the enemy team until they run out of respawns!");
            }
        }

    }
    else
    {
    	this.Untag("animateBanner");
    }
}

void onRender(CRules@ this)
{
    if (this.hasTag("animateBanner"))
    {
        Driver@ driver = getDriver();
        if (driver !is null)
        {
            if (bannerPos != bannerDest)
            {
                frameTime = Maths::Min(frameTime + (getRenderDeltaTime() / maxTime), 1);

                bannerPos = Vec2f_lerp(bannerStart, bannerDest, frameTime);
            }
            DrawBanner(bannerPos, this);
        }
    }
}

void DrawBanner(Vec2f center, CRules@ this)
{
    GUI::SetFont("score-big");

    string text = "";
    text = this.get_string("bannertext");
    
    GUI::DrawTextCentered(getTranslatedString(text), center, SColor(255, 255, 255, 255));

    
    
    //GUI::DrawIcon("TeamIcons.png", team, Vec2f(96, 96), center - Vec2f(96, 192) + offset, 1.0f, team);
}