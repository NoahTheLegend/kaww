#include "Hitters.as";
#include "ParticleSparks.as";
#include "Knocked.as";
#include "UtilityChecks.as";

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next attack", 0);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}
	
	CSprite@ sprite = this.getSprite();
	if (sprite !is null) sprite.getConsts().accurateLighting = false;
	// this.getSprite().addAnimation("honk", 0, false);

	this.set_bool("holding", false);
	
	if (isServer()) this.server_setTeamNum(XORRandom(8));
}

void onTick(CBlob@ this)
{	
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if(point is null){return;}
		CBlob@ holder = point.getOccupied();
		
		if (holder is null){return;}

		if (getKnocked(holder) <= 0)
		{
			if (holder.isKeyPressed(key_action2) || point.isKeyPressed(key_action2))
			{
				if (isClient())
				{
					if (!this.get_bool("holding")) 
					{
						this.getSprite().PlaySound("Lighter_Use", 1.00f, 0.90f + (XORRandom(100) * 0.30f));
						sparks(this.getPosition(), 1, 0.25f);
					}
				}

				this.set_bool("holding", true);

				if (isServer())
				{
					holder.SetLight(true);
					holder.SetLightRadius(32.00f);
					holder.SetLightColor(SColor(255, 255, 155, 40));
				}
			}
			else 
			{
				this.set_bool("holding", false);
				holder.SetLight(false);
			}

			if (holder.isKeyPressed(key_action1) || point.isKeyPressed(key_action1))
			{
				if (this.get_u32("next attack") > getGameTime()) return;
				Vec2f pos = holder.getAimPos();
			
				if (isClient())
				{
					this.getSprite().PlaySound("Lighter_Use", 1.00f, 0.90f + (XORRandom(100) * 0.30f));
					sparks(this.getPosition(), 1, 0.25f);
				}
				
				if (isServer())
				{
					if ((pos - this.getPosition()).getLength() < 32)
					{
						getMap().rayCastSolidNoBlobs(this.getPosition(), pos, pos);
						CBlob@ blob = getMap().getBlobAtPosition(pos);
						
						getMap().server_setFireWorldspace(pos, true);
					}
				}
				
				this.set_u32("next attack", getGameTime() + 20);
			}
		}
	}
}