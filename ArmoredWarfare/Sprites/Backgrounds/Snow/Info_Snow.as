#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", MapType::snow);

	if (isClient())
	{
		CMap@ map = this.getMap();
		map.CreateTileMap(0, 0, 8.0f, "Snow_World.png");
		map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
		map.CreateSkyGradient("Sprites/skygradient.png"); // override sky color with gradient
		getRules().set_bool("allowclouds", true);
		getRules().set_u8("brightmod", 50);

		map.AddBackground("Backgrounds/Snow_BackgroundPlains.png", Vec2f(0.0f, -38.0f), Vec2f(0.2f, 0.2f), color_white);
		map.AddBackground("Backgrounds/Snow_BackgroundTrees.png", Vec2f(0.0f,  -35.0f), Vec2f(0.4f, 0.4f), color_white);
	}
}