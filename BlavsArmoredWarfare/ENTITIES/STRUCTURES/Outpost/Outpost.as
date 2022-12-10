// Vehicle Workshop

#include "GenericButtonCommon.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"

const u16 MIN_RESPAWNS = 5;
const u8 ADD_RESPAWN_PER_PLAYERS = 2;
const u8 respawn_immunity_time = 30 * 1.5;

void onInit(CBlob@ this)
{
	this.Tag("respawn");
	this.Tag("builder always hit");
	this.Tag("vehicle"); // required for minimap

	this.SetLight(true);
	this.SetLightRadius(86.0f);
	this.SetLightColor(SColor(255, 255, 240, 155));

	this.set_u16("max_respawns", MIN_RESPAWNS+(getPlayerCount()/ADD_RESPAWN_PER_PLAYERS));
	//printf(""+this.get_u16("max_respawns"));

	this.set_u8("custom respawn immunity", respawn_immunity_time); 

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ flag = sprite.addSpriteLayer("camp layer", "Outpost.png", 32, 32);
	if (flag !is null)
	{
		flag.addAnimation("default", 5, true);
		int[] frames = { 9, 10, 11 };
		flag.animation.AddFrames(frames);
		flag.SetRelativeZ(0.8f);
		flag.SetOffset(Vec2f(8.0f, -4.0f));
		flag.SetAnimation("default");
	}

	//this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	//this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 7, Vec2f(16, 16));
	//this.SetMinimapRenderAlways(true);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this) && canSeeButtons(this, forBlob));
}
