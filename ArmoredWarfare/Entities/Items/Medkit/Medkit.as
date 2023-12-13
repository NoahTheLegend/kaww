#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	//this.getShape().SetRotationsAllowed(false);
	this.set_u8("medamount", 4);
	this.Tag("trap");
	this.Tag("heal");

	this.addCommandID("usemed");
	this.Tag("change team on pickup");
}

void onInit(CSprite@ this)
{
	this.ScaleBy(0.75f, 0.75f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (!blob.hasTag("trap") && !blob.hasTag("flesh") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;
	if (caller.exists("next_med") && caller.get_u32("next_med") >= getGameTime()) return;

	bool stats_loaded = false;
    PerkStats@ stats = getPerkStats(caller, stats_loaded);

	if (stats_loaded && stats.id == Perks::bull)
	{
		return;
	}

	if (caller.getHealth() < caller.getInitialHealth()-0.1f)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		u8 med_amount = this.get_u8("medamount");
		CButton@ button = caller.CreateGenericButton(30, Vec2f(0, 0), this, this.getCommandID("usemed"), med_amount + " use" + (med_amount == 1 ? "" : "s") + "      ", params);
		button.enableRadius = 28.0f;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("usemed"))
	{
		u16 blob_id;
		if (!params.saferead_u16(blob_id)) return;

		CBlob@ blob = getBlobByNetworkID(blob_id);

		if (blob !is null)
		{
			if (blob.get_u32("next_med") >= getGameTime()) return;
			blob.set_u32("next_med", getGameTime()+15);
		}

		this.getSprite().PlaySound("Heart.ogg");

		if (isServer())
		{
			if (blob !is null)
			{
				CPlayer@ p = blob.getPlayer();
				bool stats_loaded = false;
				PerkStats@ stats;
				if (p !is null && p.get("PerkStats", @stats) && stats !is null)
					stats_loaded = true;

				//if (blob.getHealth() > oldHealth)
				{
					if (stats_loaded && blob.get_bool("has_aos"))
					{
						blob.TakeBlob("aceofspades", 1);
						blob.set_u32("aceofspades_timer", getGameTime()+stats.aos_healed_time);
					}
				}

				f32 heal_amount = 1.5f; // 1.0f is 50 HP
				if (stats_loaded)
				{
					heal_amount *= stats.regen;
				}
				blob.server_Heal(heal_amount);
				
				if (this.get_u8("medamount") <= 1) 
				{
					this.server_Die();
				}
				else
				{
					this.set_u8("medamount", this.get_u8("medamount") - 1);
					this.Sync("medamount", true);
				}
			}
		}
	}
}