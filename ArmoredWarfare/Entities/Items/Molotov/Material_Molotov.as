#include "ParticleSparks.as";
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("explosive");
	this.maxQuantity = 1;

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action3);
	}
	this.Tag("change team on pickup");
	this.Tag("collideswithglass");
	this.Tag("weapon");

	this.set_u32("activate_delay", 0);
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return true;
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	this.set_u32("activate_delay", getGameTime()+2);
}

void onTick(CBlob@ this)
{
	if (isClient()) // a try to fix clientsideonly activation
	{
		if (this.hasTag("activated"))
		{
			this.Untag("activated");
		}
	}
	if (this.isAttached() && !this.hasTag("activated"))
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (ap !is null && ap.isKeyJustPressed(key_action3) && ap.getOccupied() !is null && ap.getOccupied().isMyPlayer() && !ap.getOccupied().isAttached())
			{
			//if (!this.hasTag("no_pin")) Sound::Play("/Pinpull.ogg", this.getPosition(), 0.8f, 1.0f);
			CBitStream params;
			this.SendCommand(this.getCommandID("activate"), params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("activate"))
    {
		if (this.get_u32("activate_delay") > getGameTime()) return;

		if (isClient() && !this.hasTag("activated"))
		{
			this.getSprite().PlaySound("Lighter_Use", 1.00f, 0.90f + (XORRandom(100) * 0.30f));
			sparks(this.getPosition(), 1, 0.25f);
		}
		
        if(isServer() && !this.hasTag("dead"))
        {
    		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
            if (point !is null)
			{
				CBlob@ holder = point.getOccupied();
				if (holder !is null && this !is null && !this.hasTag("activated"))
				{
					if (holder.getPlayer() !is null)
					{
						AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");

						this.SetDamageOwnerPlayer(holder.getPlayer());

						bool has_camo = false;
						PerkStats@ stats;
						if (holder.getPlayer().get("PerkStats", @stats))
							has_camo = stats.ghillie;

						if (has_camo)
						{
							if (getMap() !is null && XORRandom(100) < stats.ignite_self_chance)
							{
								getMap().server_setFireWorldspace(holder.getPosition(), true);
							}
						}
					}
					CBlob@ blob = server_CreateBlob("molotov", this.getTeamNum(), this.getPosition());
					if (blob !is null)
					{
						this.Tag("dead");
						blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
						//blob.setVelocity(this.getVelocity());
					}
					holder.server_Pickup(blob);
					this.server_Die();
					
					CPlayer@ activator = holder.getPlayer();
					string activatorName = activator !is null ? (activator.getUsername() + " (team " + activator.getTeamNum() + ")") : "<unknown>";
					//printf(activatorName + " has activated " + this.getName());
				}
				else 
				{
					CBlob@ blob = server_CreateBlob("molotov", this.getTeamNum(), this.getPosition());
					this.server_Die();
				}
			}
        }

		this.Tag("activated");
		this.set_bool("active", true);
    }
}
