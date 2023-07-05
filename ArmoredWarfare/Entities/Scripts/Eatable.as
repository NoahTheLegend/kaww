#include "EatCommon.as";

void onInit(CBlob@ this)
{
	if (!this.exists("eat sound"))
	{
		this.set_string("eat sound", "/Eat.ogg");
	}

	this.addCommandID(heal_id);

	this.Tag("pushedByDoor");
	this.Tag("trap");
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
				//if (theBlob.getHealth() > oldHealth)
				{
					if (theBlob.hasBlob("aceofspades", 1))
					{
						theBlob.TakeBlob("aceofspades", 1);
						theBlob.set_u32("aceofspades_timer", getGameTime()+180);
					}
				}

				u8 heal_amount;
				if (!params.saferead_u8(heal_amount)) return;

				bool is_burger = false;
				if (heal_amount == 255) is_burger = true;
				f32 extra = theBlob.get_u32("regen") > getGameTime() ? float(theBlob.get_u32("regen"))-float(getGameTime()) : 0;

				if (is_burger)
				{
					theBlob.set_u32("regen", extra + getGameTime()+120);
					theBlob.set_u8("step_max_temp", 6);
					theBlob.set_f32("regen_amount", 0.5f);
				}
				else
				{
					theBlob.set_u32("regen", extra + getGameTime()+90);
					theBlob.set_u8("step_max_temp", 4);
					theBlob.set_f32("regen_amount", 0.125f);
				}

				/*
				f32 res = 1.5f;
				if (theBlob.getPlayer() !is null && getRules().get_string(theBlob.getPlayer().getUsername() + "_perk") == "Bloodthirsty")
				{
					if (heal_amount != 255) heal_amount /= 2;
					res /= 2;
				}

				if (heal_amount == 255)
				{
					res = (theBlob.getInitialHealth()-theBlob.getHealth())*res;
					theBlob.add_f32("heal amount", theBlob.getInitialHealth() - theBlob.getHealth());
					res <= 0.5f*(res/1.5f) ? theBlob.server_SetHealth(theBlob.getInitialHealth()) :  theBlob.server_Heal(Maths::Max(res, 0.25f));
					if (theBlob.getHealth() > theBlob.getInitialHealth()) theBlob.server_SetHealth(theBlob.getInitialHealth());
				}
				else
				{
					f32 oldHealth = theBlob.getHealth();
					theBlob.server_Heal(f32(heal_amount) * 0.25f);
					theBlob.add_f32("heal amount", theBlob.getHealth() - oldHealth);
				}
				*/

				//give coins for healing teammate
				if (this.exists("healer"))
				{
					CPlayer@ player = theBlob.getPlayer();
					u16 healerID = this.get_u16("healer");
					CPlayer@ healer = getPlayerByNetworkId(healerID);
					if (player !is null && healer !is null)
					{
						bool healerHealed = healer is player;
						bool sameTeam = healer.getTeamNum() == player.getTeamNum();
						if (!healerHealed && sameTeam)
						{
							int coins = 2;
							if (getRules().get_string(healer.getUsername() + "_perk") == "Wealthy")
							{
								coins *= 2;
							}
							healer.server_setCoins(healer.getCoins() + coins);
						}
					}
				}

				theBlob.Sync("heal amount", true);
			}

			this.server_Die();
		}
	}
}

bool canHeal(CBlob@ this, CBlob@ blob)
{
	if (blob.getPlayer() is null) return true;
	if (getRules() !is null && getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Bloodthirsty")
		return false;

	return true;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.get_u32("regen") > getGameTime())
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
