#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", MapType::desert);

	if (isClient())
	{
		//SetScreenFlash(255, 255, 255, 255);
	
		CMap@ map = this.getMap();
		
		map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
		map.CreateSkyGradient("Sprites/skygradientdesert.png"); // override sky color with gradient
		getRules().set_bool("allowclouds", false);
		getRules().set_u8("brightmod", 100);

		map.AddBackground("Backgrounds/BackgroundDesertDetail.png", Vec2f(0.0f, -15.0f), Vec2f(0.055f, 0.5f), color_white);
		map.AddBackground("Backgrounds/BackgroundDesertRocky.png",  Vec2f(27.0f, -20.0f), Vec2f(0.12f, 0.5f), color_white);
		map.AddBackground("Backgrounds/BackgroundDesert.png",       Vec2f(5.0f, -8.0f), Vec2f(0.25f, 2.0f), color_white);
		map.AddBackground("Backgrounds/BackgroundDunes.png",        Vec2f(0.0f,  -7.0f), Vec2f(0.5f, 2.5f), color_white);
	}
}