#include "DefaultGUI.as"
#include "DefaultLoaders.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"

void onInit(CRules@ this)
{
	LoadDefaultMapLoaders();
	LoadDefaultGUI();

	sv_gravity = 9.81f;//9.81
	particles_gravity.y = 1.25f;
	sv_visiblity_scale = 1.75f; // experimental change 1.25 > 1.5 // increased by .25 again
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	PrecacheTextures();

	//smooth shader
	Driver@ driver = getDriver();

	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", true);

	//reset var if you came from another gamemode that edits it
	SetGridMenusSize(24,2.0f,32);

	//also restart stuff
	onRestart(this);

	// for some reason you can not use same font source, otherwise first load is duplicated in all other fonts
	string font1 = CFileMatcher("KdamThmorPro-Regular.ttf").getFirst();
	GUI::LoadFont("score-big", font1, 26, true);

	string font2 = CFileMatcher("KdamThmorPro-Medium.ttf").getFirst();
	GUI::LoadFont("score-medium", font2, 18, true);

	string font3 = CFileMatcher("KdamThmorPro-Small.ttf").getFirst();
	GUI::LoadFont("score-small", font3, 14, true);

	string font4 = CFileMatcher("KdamThmorPro-Smaller.ttf").getFirst();
	GUI::LoadFont("score-smaller", font4, 12, true);

	string font5 = CFileMatcher("Editia.ttf").getFirst();
	GUI::LoadFont("title", font5, 20);

	string font6 = CFileMatcher("Editia-Small.ttf").getFirst();
	GUI::LoadFont("title-small", font6, 14);
}

bool need_sky_check = true;
void onRestart(CRules@ this)
{
	this.set_f32("immunity sec", Maths::Min(4+getPlayersCount()/5, 10));
	//map borders
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetBorderFadeWidth(36.0f);
		map.SetBorderColourTop(SColor(0x000000));
		map.SetBorderColourLeft(SColor(0xff000000));
		map.SetBorderColourRight(SColor(0xff000000));
		map.SetBorderColourBottom(SColor(0xff000000));

		//do it first tick so the map is definitely there
		//(it is on server, but not on client unfortunately)
		need_sky_check = true;
	}
}

void onTick(CRules@ this)
{
	//TODO: figure out a way to optimise so we don't need to keep running this hook
	if (need_sky_check)
	{
		need_sky_check = false;
		CMap@ map = getMap();
		//find out if there's any solid tiles in top row
		// if not - semitransparent sky
		// if yes - totally solid, looks buggy with "floating" tiles
		bool has_solid_tiles = false;
		for(int i = 0; i < map.tilemapwidth; i++) {
			if(map.isTileSolid(map.getTile(i))) {
				has_solid_tiles = true;
				break;
			}
		}
		map.SetBorderColourTop(SColor(has_solid_tiles ? 0xff000000 : 0x000000));
	}
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "dots", 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "off");
}