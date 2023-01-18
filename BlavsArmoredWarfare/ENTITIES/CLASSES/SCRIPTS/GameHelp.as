// Modified Shiprekt script by GingerBeard

#define CLIENT_ONLY
#include "ActorHUDStartPos.as";

bool showHelp = false;
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
    CPlayer@ player = getLocalPlayer();
    if (player !is null && getRules() !is null && getRules().get_u32(player.getUsername() + "_exp") < 25) showHelp = true;
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

	Vec2f tlBox = Vec2f(sMid - imageSize.x - boxMargin, Maths::Max(10.0f, sCenter - imageSize.y - infoSize.y/2 - controlsSize.y/2 - boxMargin));
	Vec2f brBox = Vec2f(sMid + imageSize.x + boxMargin, sCenter + imageSize.y + infoSize.y/2 + controlsSize.y/2);
	
	//draw box
	GUI::DrawButtonPressed(tlBox, brBox);
	
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
		+ "  * Ranks & Progression: Win, kill enemies or mine ore to unlock classes and perks!\n    Ranks and experience are bound to player and saved permanently\n"
		+ "  * New perks: A set of perks with game-changing features - 'pay' something to get stronger abilities\n"
		+ "  * Bots: Greatly written AI to fill server with small players count\n"
        + "  * New blocks: Effective against explosions and shells - a good and fair option for defensive gameplay\n"
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

    {
        GUI::SetFont("normal");

        Vec2f spawnInfo = Vec2f(325,147.5f);
        Vec2f marketInfo = Vec2f(500,147.5f);
        Vec2f armoryInfo = Vec2f(716,147.5f);
        //Vec2f digMatsInfo = Vec2f(330,225);
        Vec2f builderInfo = Vec2f(285,222.5f);
        Vec2f revolverInfo = Vec2f(365,250);
        Vec2f rangerInfo = Vec2f(435,250);
        Vec2f shotgunInfo = Vec2f(507.5f,250);
        Vec2f sniperInfo = Vec2f(575,250);
        Vec2f medicInfo = Vec2f(650,250);
        Vec2f rpgInfo = Vec2f(734,250);
        Vec2f craftInfo = Vec2f(325,375);
        Vec2f passengerInfo = Vec2f(430,385);
        Vec2f gunnerInfo = Vec2f(500,350);
        Vec2f mechanicInfo = Vec2f(560,385);
        Vec2f flagInfo = Vec2f(700,385);

        GUI::DrawTextCentered("Your spawn point\nSwitch class or\nperks here", tlBox+spawnInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Shop to buy\nsupplies or ammo\nYou gain money\nwith time", tlBox+marketInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("A truck with\nextended variety\nof supplies (requires scrap)", tlBox+armoryInfo, SColor(255, 240,240,240));
        //GUI::DrawTextCentered("Dig materials and\nresupply forges", tlBox+digMatsInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Produce scrap as builder.\nSupply your team and\nbuild defensives", tlBox+builderInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Basic fighter\nA good tank\ncrewmember", tlBox+revolverInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Strong fighter\nGood fire rate", tlBox+rangerInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Short-range\nfighter, has\na shovel", tlBox+shotgunInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Long-range\nfighter, very\naccurate", tlBox+sniperInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Medic\nHas a small\namount of HP", tlBox+medicInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("A tank cannon\nwith legs, requires\nrockets as ammo", tlBox+rpgInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Craft vehicles with scrap", tlBox+craftInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Passenger seat", tlBox+passengerInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Tank cannoneer\nShells are affected by gravity", tlBox+gunnerInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Tank driver\nIs responsible for it\nDon't lose it", tlBox+mechanicInfo, SColor(255, 240,240,240));
        GUI::DrawTextCentered("Some gamemodes require\nteams to capture flags\nfor winning. In case of a tie\nthe team with bigger amount of\nflags wins the game!", tlBox+flagInfo, SColor(255, 240,240,240));
    }
	
	GUI::SetFont("menu");
	
	//hud icons
	Vec2f tl = getActorHUDStartPosition(null, 6);
}