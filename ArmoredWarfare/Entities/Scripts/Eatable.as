#include "EatCommon.as";
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	if (!this.exists("eat sound"))
	{
		this.set_string("eat sound", "/Eat.ogg");
	}

	this.addCommandID(heal_id);

	this.Tag("pushedByDoor");
	this.Tag("trap");
	this.Tag("heal");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(heal_id))
	{
		this.getSprite().PlaySound(this.get_string("eat sound"));

		if (getNet().isServer())
		{
			u16 blob_id;
			if (!params.saferead_u16(blob_id)) return;

			CBlob@ theBlob = getBlobByNetworkID(blob_id);
			if (theBlob !is null)
			{
				if (this.getName() != "heart")
				{
					CPlayer@ p = theBlob.getPlayer();
					bool stats_loaded = false;
					PerkStats@ stats;
					if (p !is null && p.get("PerkStats", @stats) && stats !is null)
						stats_loaded = true;

					if (stats_loaded && theBlob.get_bool("has_aos"))
					{
						theBlob.TakeBlob("aceofspades", 1);
						theBlob.set_u32("aceofspades_timer", getGameTime()+stats.aos_healed_time);
					}
				}

				u8 heal_amount;
				if (!params.saferead_u8(heal_amount)) return;

				bool is_burger = false;
				if (heal_amount == 255) is_burger = true;
				f32 extra = theBlob.get_u32("regen") > getGameTime() ? float(theBlob.get_u32("regen"))-float(getGameTime()) : 0;

				if (is_burger)
				{
					theBlob.set_u32("regen", extra + getGameTime()+150);
					theBlob.set_u8("step_max_temp", 8);
					theBlob.set_f32("regen_amount", 0.5f);
				}
				else
				{
					theBlob.set_u32("regen", extra + getGameTime()+90);
					theBlob.set_u8("step_max_temp", 4);
					theBlob.set_f32("regen_amount", 0.125f);
				}

				CBitStream params;
				params.write_u32(theBlob.get_u32("regen"));
				theBlob.SendCommand(theBlob.getCommandID("sync_regen"), params);

				theBlob.Sync("heal amount", true);
			}

			this.server_Die();
		}
	}
}

bool canHeal(CBlob@ this, CBlob@ blob)
{
	if (blob.getPlayer() is null) return true;

	return true;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.get_u32("regen") > getGameTime() || blob.isAttached())
	{
		return;
	}
	if (!canHeal(this, blob))
	{
		return;
	}

	if (getNet().isServer() && !blob.hasTag("dead"))
	{
		Heal(blob, this);
	}
}


void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this is null || attached is null) {return;}

	if (isServer() && canHeal(this, attached) && attached.get_u32("regen") <= getGameTime())
	{
		Heal(attached, this);
	}

	CPlayer@ p = attached.getPlayer();
	if (p is null){return;}

	this.set_u16("healer", p.getNetworkID());
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (this is null || detached is null) {return;}

	if (isServer() && canHeal(this, detached) && detached.get_u32("regen") <= getGameTime())
	{
		Heal(detached, this);
	}

	CPlayer@ p = detached.getPlayer();
	if (p is null){return;}

	this.set_u16("healer", p.getNetworkID());
}