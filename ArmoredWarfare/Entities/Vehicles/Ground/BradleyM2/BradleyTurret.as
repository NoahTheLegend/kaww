#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("release traps");

	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("apc");
	this.Tag("blocks bullet");
}