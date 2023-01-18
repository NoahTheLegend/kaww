// Modified Shiprekt script by GingerBeard

#define CLIENT_ONLY
#include "ActorHUDStartPos.as";

bool showHelp = true;
bool justJoined = true;
bool mouseWasPressed1 = false;

const f32 boxMargin = 100.0f;
const SColor tipsColor = SColor(255, 255, 255, 255);
//key names
const string party_key = getControls().getActionKeyKeyName(AK_PARTY);
const string inv_key = getControls().getActionKeyKeyName(AK_INVENTORY);
const string pick_key = getControls().getActionKeyKeyName(AK_PICKUP);
const string taunts_key = getControls().getActionKeyKeyName(AK_TAUNTS);
const string use_key = getControls().getActionKeyKeyName(AK_USE);
const string action1_key = getControls().getActionKeyKeyName(AK_ACTION1);
const string action2_key = getControls().getActionKeyKeyName(AK_ACTION2);
const string action3_key = getControls().getActionKeyKeyName(AK_ACTION3);
const string map_key = getControls().getActionKeyKeyName(AK_MAP);
const string zoomIn_key = getControls().getActionKeyKeyName(AK_ZOOMIN);
const string zoomOut_key = getControls().getActionKeyKeyName(AK_ZOOMOUT);
		
void onInit(CRules@ this)
{
	CFileImage@ image = CFileImage("GameHelp.png");
	const Vec2f imageSize = Vec2f(image.getWidth(), image.getHeight());
	AddIconToken("$HELP$", "GameHelp.png", imageSize, 0);
}

void onTick(CRules@ this)
{
	CControls@ controls = getControls();
	if (controls.isKeyJustPressed(KEY_F1))
	{
		showHelp = !showHelp;
		u_showtutorial = showHelp;
		justJoined = false;
	}
}

//a work in progress
void onRender(CRules@ this)
{
	if (!showHelp) return;
	
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;
	
	const f32 sMid = getScreenWidth()/2;
	const f32 sCenter = getScreenHeight()/2;
	const u32 gameTime = getGameTime();

	Vec2f imageSize;
	GUI::GetIconDimensions("$HELP$", imageSize);

    if (imageSize.x == 0 || imageSize.y == 0)
    {
        if (getGameTime()%30==0)
        {
            printf("Image dimension is zero!");
        }
        return;
    } 

	const string infoTitle = "Tutorial";
	const string textInfo = "---Test---";
	
	//Controls
	const string controlsTitle = "---Controls---";
	const string controlsInfo = "--Controls2---";
	
	GUI::SetFont("menu");
	
	Vec2f infoSize;
	GUI::GetTextDimensions(infoTitle + textInfo, infoSize);
	Vec2f controlsSize;
	GUI::GetTextDimensions(controlsTitle + controlsInfo, controlsSize);

	const Vec2f tlBox = Vec2f(sMid - imageSize.x - boxMargin, Maths::Max(10.0f, sCenter - imageSize.y - infoSize.y/2 - controlsSize.y/2 - boxMargin));
	const Vec2f brBox = Vec2f(sMid + imageSize.x + boxMargin, sCenter + imageSize.y + infoSize.y/2 + controlsSize.y/2);
	
	//draw box
	GUI::DrawButtonPressed(tlBox, brBox);
	
	if (justJoined)
	{
		//welcome text
		const string intro = "\nWelcome to Armored Warfare!"; //last editor
		
		Vec2f introSize;
		GUI::GetTextDimensions(intro, introSize);
		GUI::SetFont("AveriaSerif-Bold_32");
		GUI::DrawTextCentered(intro, Vec2f(sMid, tlBox.y + 15), tipsColor);
        GUI::SetFont("menu");
        GUI::DrawTextCentered("Mod is developed with big effort by Blav (Yeti5000707) and salty Snek (NoahTheLegend)", Vec2f(sMid, tlBox.y + 60), SColor(255, 255,255,0));
        GUI::DrawTextCentered("You may thank us or donate if you wish. https://discord.gg/55yueJWy7g", Vec2f(sMid, tlBox.y + 75), SColor(255, 255,255,0));
        GUI::DrawTextCentered("Special thanks to contributors: Nevrotik, Skemonde, PURPLExeno, Goldy, GoldenGuy (hoster), petey5 and ThinkAbout!", Vec2f(sMid, tlBox.y + 92.5f), SColor(255, 255,255,0));
    } 

	{
		const string shiprektVersion = "Armored Warfare 2.0\n";
		const string lastChangesInfo = "\nChanges:\n\n"
		+ "  * Ranks & Progression: Win, kill enemies or mine ore to open classes and perks!\n    Ranks and experience are bound to player and saved permanently\n"
		+ "  * New perks: A set of perks with game-changing features - 'pay' something to get stronger abilities\n"
		+ "  * Bots: Greatly written AI to fill server with small players count\n"
        + "  * New blocks: Effective against explosions and shells - a good fair option for defensive gameplay\n"
        + "  * Most of bugs fixed: Common, rare and single-happening bugs are gone\n"
        + "  * New maps: enjoy a few new unique maps for TDM and default modes\n"
        + "  * Other: Small and different improvements, including QOL and balance\n";
		
		GUI::SetFont("menu");
		Vec2f lastChangesSize;
		GUI::GetTextDimensions(lastChangesInfo, lastChangesSize);
	
		const Vec2f tlBoxJustJoined = Vec2f(sMid - imageSize.x - boxMargin, Maths::Max(10.0f, sCenter - imageSize.y - lastChangesSize.y/2));
		
		GUI::DrawText(shiprektVersion, Vec2f(sMid - imageSize.x, tlBoxJustJoined.y + 2*imageSize.y), tipsColor);
		
		GUI::SetFont("menu");
		GUI::DrawText(lastChangesInfo, Vec2f(sMid - imageSize.x, tlBoxJustJoined.y + 2*imageSize.y + boxMargin), tipsColor);
		
		//image
		GUI::DrawIconByName("$HELP$", Vec2f(sMid - imageSize.x, tlBox.y + boxMargin + 10));
	}
	
	GUI::SetFont("menu");
	
	//hud icons
	Vec2f tl = getActorHUDStartPosition(null, 6);
}