#include "Hitters.as"
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("medium weight");
	this.Tag("trap");
	this.Tag("weapon");
	this.getSprite().SetRelativeZ(1.0f); //background
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() == blob.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is null && hitterBlob.getTeamNum() != this.getTeamNum() && hitterBlob.hasTag("player"))
	{
		if (hitterBlob.getPlayer() !is null && hasPerk(hitterBlob.getPlayer(), Perks::fieldengineer))
		{
			damage *= 2.0f;
		}
	}
	if (customData == Hitters::fall)
	{
		return damage * 0.25f;
	}
	if (hitterBlob.getName() == "c4")
	{
		return damage * 2;
	}
	if (customData == Hitters::explosion)
	{
		return damage * 0.75f;
	}
	return customData == Hitters::builder ? damage*4 : damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("vehicle") && blob.getTeamNum() < 7 && this.getTeamNum() != blob.getTeamNum())
	{
		return true;
	}

	return false;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point !is null)
	{
		CBlob@ blob = point.getOccupied();
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (getNet().isServer() && blob !is null && this.getVelocity().x >= -1.0f && this.getVelocity().x <= 1.0f)
	{
		if (blob.hasTag("vehicle") && blob.getTeamNum() < 7 && this.getTeamNum() != blob.getTeamNum())
		{
			this.server_Hit(blob, blob.getPosition(), Vec2f_zero, 65.0f, Hitters::explosion);

			if (blob.isOnMap())
			{
				Vec2f vel = blob.getVelocity();
				blob.setVelocity(vel * 0.00f);
			}

			this.server_SetHealth(-1.0f);
			this.server_Die();
		}
	}
}