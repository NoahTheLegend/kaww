// Bush logic

#include "canGrow.as";

void onInit(CBlob@ this)
{

	//this.Tag("scenary");
}

//sprite

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	u16 netID = blob.getNetworkID();
	this.animation.frame = (netID % this.animation.getFramesCount());
	this.SetFacingLeft(((netID % 13) % 2) == 0);
	//this.getCurrentScript().runFlags |= Script::remove_after_this;	// wont be sent on network
	this.SetZ(10.0f);
}