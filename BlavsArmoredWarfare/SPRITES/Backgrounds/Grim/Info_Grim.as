#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", 2);

	if (isClient())
	{
		//SetScreenFlash(255, 255, 255, 255);
	
		CMap@ map = this.getMap();
		
		map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
		map.CreateSkyGradient("Sprites/skygradient.png"); // override sky color with gradient
		getRules().set_bool("allowclouds", true);
		getRules().set_u8("brightmod", 0);
				
		map.AddBackground("Backgrounds/BackgroundTrees.png", Vec2f(0.0f,  -35.0f), Vec2f(0.4f, 0.4f), color_white);
		map.AddBackground("Backgrounds/City.png", Vec2f(0.0f, -38.0f), Vec2f(0.2f, 0.2f), color_white);
		map.AddBackground("Backgrounds/Forest.png", Vec2f(0.0f, -120.0f), Vec2f(0.35f, 0.35f), color_white);

		SetScreenFlash(255,   0,   0,   0,   3.0);

		setTextureSprite(this,TreeTexture,"Grim_Trees.png");
		setTextureSprite(this,BushTexture,"Grim_Bushes.png");
		swapBlobTextures();	
	}
}