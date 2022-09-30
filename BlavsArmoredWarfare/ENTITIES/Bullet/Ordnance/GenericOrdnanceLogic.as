// generic ordinance logic

#include "WarfareGlobal.as"
#include "OrdnanceCommon.as"
#include "ComputerCommon.as"

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(15);
	this.set_s8(navigationPhaseString, 0);

	this.set_bool(firstTickString, true);
	this.set_bool(clientFirstTickString, true);

	this.getSprite().SetFrame(0);

	this.addCommandID( targetUpdateCommandID );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null)
	{ return; }
	
    if (cmd == this.getCommandID(targetUpdateCommandID)) // updates target for all clients
    {
		u16 newTargetNetID;
		bool resetTimer;
		
		if (!params.saferead_u16(newTargetNetID) || !params.saferead_bool(resetTimer)) return;

		this.set_u16(targetNetIDString, newTargetNetID);
		if (resetTimer) this.set_u32(hasTargetTicksString, 0);
	}
}