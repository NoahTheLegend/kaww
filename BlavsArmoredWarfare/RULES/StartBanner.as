#define CLIENT_ONLY

Vec2f bannerStart = Vec2f_zero;
Vec2f bannerPos = Vec2f_zero;
Vec2f bannerDest = Vec2f_zero;
f32 frameTime = 0;
const f32 maxTime = 1.2f;

void onInit(CRules@ this)
{
    if (!GUI::isFontLoaded("AveriaSerif-Bold_32"))
    {
        string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
        GUI::LoadFont("AveriaSerif-Bold_32", AveriaSerif, 32, true);
    }

    onRestart(this);
}

void onRestart(CRules@ this)
{
    this.Untag("animateBanner");
    bannerPos = Vec2f_zero;
    bannerDest = Vec2f_zero;
    frameTime = 0;
}

void onTick(CRules@ this)
{
    if (getGameTime() < 370 && getMap().getMapName() != "KAWWTraining.png")
    {
        Driver@ driver = getDriver();
        if (driver !is null)
        {
            bannerDest = Vec2f(driver.getScreenWidth()/2, driver.getScreenHeight()/9);
            bannerStart = bannerDest;
            bannerStart.y = 0;
            bannerPos = bannerStart;

            this.Tag("animateBanner");
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
            DrawBanner(bannerPos);
        }
    }
}

void DrawBanner(Vec2f center)
{
    GUI::SetFont("AveriaSerif-Bold_32");

    string text = "";
    text = "Control all flags to win";
    
    GUI::DrawTextCentered(getTranslatedString(text), center, SColor(255, 148, 27, 27));
    
    //GUI::DrawIcon("TeamIcons.png", team, Vec2f(96, 96), center - Vec2f(96, 192) + offset, 1.0f, team);
}