#include "ComputerCommon.as"
#include "OrdnanceCommon.as"

void onInit(CBlob@ this)
{
	this.set_u16(targetNetIDString, 0);
	this.set_f32(targetingProgressString, 0.0f); // out of 1.0f

	this.Tag("medium weight");
	this.Tag("trap"); // so bullets pass
	this.Tag("hidesgunonhold"); // is it's own weapon

	this.addCommandID(launchOrdnanceIDString);
	this.addCommandID(launcherDeathIDString);
	this.addCommandID(launcherUpdateStateIDString);
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	return !inventoryBlob.hasTag("flesh") && !this.hasTag("dead");
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null)
	{ return; }
	
    if (cmd == this.getCommandID(launcherDeathIDString)) // launcher is tagged dead
    {
		this.Tag("dead");
		if (isServer()) this.server_SetTimeToDie(10);
	}
	else if (cmd == this.getCommandID(launcherUpdateStateIDString)) // launcher state update
    {
		s8 launcherState = 0;
		float launcherAngle = 0;

		if (!params.saferead_s8(launcherState)) return;
		if (!params.saferead_f32(launcherAngle)) return;
		
		if (isClient()) this.set_s8("launcher_frame", launcherState);
		this.set_f32("launcher_angle", launcherAngle);
	}
}