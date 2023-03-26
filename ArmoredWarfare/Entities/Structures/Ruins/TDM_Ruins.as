// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "RespawnCommandCommon.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.CreateRespawnPoint("ruins", Vec2f(0.0f, 16.0f));
	//TDM classes
	addPlayerClass(this, "Crewman", "$crewman_class_icon$", "crewman", "Crewman for a vehicle.");
	addPlayerClass(this, "Ranger", "$ranger_class_icon$", "ranger", "Uses an Ak47.");
	addPlayerClass(this, "Sniper", "$sniper_class_icon$", "sniper", "Uses a long range sniper.");
	addPlayerClass(this, "RPG", "$rpg_class_icon$", "rpg", "Uses an RPG-7.");
	addPlayerClass(this, "Mechanic", "$mechanic_class_icon$", "mechanic", "Builds, digs.");
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.addCommandID("class menu");
	this.Tag("ignore_arrow");

	this.Tag("change class drop inventory");

	this.getSprite().SetZ(-50.0f);   // push to background
}

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	u16 netID = blob.getNetworkID();
	this.SetFacingLeft(((netID % 13) % 2) == 0);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
		{
			BuildRespawnMenuFor(this, caller);
		}
	}
	else
	{
		onRespawnCommand(this, cmd, params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (canChangeClass(this, caller))
	{
		if (isInRadius(this, caller))
		{
			BuildRespawnMenuFor(this, caller);
		}
		else
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			caller.CreateGenericButton("$change_class$", Vec2f(0, 6), this, this.getCommandID("class menu"), getTranslatedString("Change class"), params);
		}
	}

	// warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (this.getPosition() - caller.getPosition()).Length() < this.getRadius();
}
