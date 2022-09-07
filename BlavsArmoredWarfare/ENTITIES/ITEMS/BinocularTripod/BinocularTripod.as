#include "Explosion.as";

// BinocularTripod.as

void onInit(CBlob@ this)
{
	this.Tag("vehicle");

 	this.Tag("medium weight");

 	if (this.getTeamNum() == 0)
	{
		this.SetFacingLeft(false);
	}
	else if (this.getTeamNum() == 1)
	{
		this.SetFacingLeft(true);
	}
}

// Blow up
void onDie(CBlob@ this)
{
	Explode(this, 32.0f, 0.5f);
}