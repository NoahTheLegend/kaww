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
	this.addCommandID(launcherSetDeathIDString);
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
	
    if (cmd == this.getCommandID(launcherSetDeathIDString)) // launcher is tagged dead
    {
		bool setDead = true;

		if (!params.saferead_bool(setDead)) return;
		
		if (setDead)
		{
			this.Tag("dead");
		}
		else
		{
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
			if (point is null) return;

			CBlob@ ownerBlob = point.getOccupied();
			if (ownerBlob is null) return;

			CInventory@ inv = ownerBlob.getInventory();
			if (inv is null || inv.getItem("mat_heatwarhead") is null) return;
			inv.server_RemoveItems("mat_heatwarhead", 1);

			this.Untag("dead");
		}
		
		//if (isServer()) this.server_SetTimeToDie(10);
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