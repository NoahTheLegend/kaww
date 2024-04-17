#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("has mount");
	this.Tag("blocks bullet");
}