//tree making logs on death script

#include "MakeSeed.as"

void onDie(CBlob@ this)
{
	if (!getNet().isServer()) return; //SERVER ONLY
	if (!this.hasTag("was_hit") && this.hasTag("tree")) return;

	Vec2f pos = this.getPosition();

	if (getGameTime() > 30)
		server_MakeSeed(pos, this.getName());
}