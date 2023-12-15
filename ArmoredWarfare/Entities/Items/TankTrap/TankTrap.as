#include "Hitters.as"
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("medium weight");
	this.Tag("trap");
	this.Tag("always vehicle collide");
	this.Tag("no_upper_collision"); // for RunOverPeople.as
	this.Tag("weapon");
	this.getSprite().SetRelativeZ(1.0f); //background
	this.getShape().SetRotationsAllowed(true);
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() == blob.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is null)
	{
		if (hitterBlob.getTeamNum() != this.getTeamNum() && hitterBlob.hasTag("player"))
		{
			bool stats_loaded = false;
    		PerkStats@ stats = getPerkStats(hitterBlob, stats_loaded);

			if (stats_loaded && stats.id == Perks::fieldengineer)
			{
				damage *= 2.0f;
			}
		}
		else if (isClient() && hitterBlob is this)
		{
			this.getSprite().PlaySound("dig_stone", Maths::Min(1.25f, Maths::Max(0.5f, damage)));
			makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                	2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
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
	this.SetMass(this.isOnGround()?2500:250);
	if (this.isAttached())
	{
		return false;
	}
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
	if (blob !is null)
	{
		if (blob.hasTag("vehicle") && blob.getTeamNum() < 7 && this.getTeamNum() != blob.getTeamNum())
		{
			if (isServer())
			{
				f32 massmod = blob.getMass() > 4000 ? 200.0f : 1.0f;
				f32 vehdmg = 1.0f + blob.getShape().vellen;
				if (blob.getPosition().y < this.getPosition().y-8) vehdmg *= 3;
				this.server_Hit(blob, blob.getPosition(), Vec2f_zero, vehdmg, vehdmg <= 10.0f ? Hitters::sword : Hitters::builder);
				this.server_Hit(this, this.getPosition(), Vec2f_zero, blob.getShape().vellen * massmod * 0.025f, Hitters::builder);
			
				blob.setVelocity(Vec2f(0, blob.getVelocity().y));
			}
			blob.set_f32("engine_RPM", Maths::Lerp(blob.get_f32("engine_RPM"), 2000, 0.1f));
		}
	}
}