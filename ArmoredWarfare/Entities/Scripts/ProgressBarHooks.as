#include "ProgressBar.as"

void onTick(CBlob@ this)
{
	visualTimerTick(this);
}

void onRender(CSprite@ this)
{
	visualTimerRender(this);
}