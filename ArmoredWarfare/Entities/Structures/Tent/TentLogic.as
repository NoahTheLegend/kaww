#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-150.0f);

	this.Tag("respawn");
	this.Tag("ignore_arrow");

	// minimap
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1)
	{
		InitClasses(this);
		CBlob@[] tents;
		getBlobsByName("tent", tents);
		for (u8 i = 0; i < tents.length; i++)
		{
			CBlob@ t = tents[i];
			if (t is null || t.getTeamNum() != this.getTeamNum()) continue;
			if (t.getDistanceTo(this) > 16.0f) return;
			if (t.getNetworkID() > this.getNetworkID()) this.server_Die();
		}
	}
	if (enable_quickswap)
	{
		//quick switch class
		CBlob@ blob = getLocalPlayerBlob();
		if (blob !is null && blob.isMyPlayer())
		{
			if (
				canChangeClass(this, blob) && blob.getTeamNum() == this.getTeamNum() && //can change class
				blob.isKeyJustReleased(key_use) && //just released e
				isTap(blob, 4) && //tapped e
				blob.getTickSinceCreated() > 1 //prevents infinite loop of swapping class
			) {
				CycleClass(this, blob);
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	// button for runner
	// create menu for class change & perk change
	if (caller.getTeamNum() == this.getTeamNum())
	{
		caller.CreateGenericButton("$change_class$", Vec2f(0, 0), this, buildSpawnMenu, getTranslatedString("Swap Class"));
		caller.CreateGenericButton("$change_perk$", Vec2f(0, -10), this, buildPerkMenu, getTranslatedString("Switch Perk"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}
