#include "Hitters.as";
#include "MaterialCommon.as";

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	this.set_f32("anim_time", 0);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1);
	}

	this.set_u8("repairs", 0);
	this.Tag("take a1");
}

const u8 max_repairs = 10;
const u8 repair_rate = 9;
const u8 anim_max_speed = 10;
const u8 anim_min_speed = 2;

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ holder = point.getOccupied();

	if (holder is null || holder.getName() != "mechanic") return;
	holder.isKeyPressed(key_action1) ? this.Tag("active") : this.Untag("active");

	bool active = this.hasTag("active");
	bool attached = this.hasTag("attached");
	bool timing = (getGameTime()+this.getNetworkID())%repair_rate==0;

	CSprite@ sprite = this.getSprite();

	if (isClient() && sprite !is null)
	{
		sprite.SetRelativeZ(attached ? -55.0f : 0.0f);
		f32 t = this.get_f32("anim_time");

		if (active)
		{
			t = Maths::Lerp(t, anim_max_speed, 0.1f);
			if (getGameTime()%4 == 0) sprite.PlaySound("welder_loop.ogg", 0.5f, 0.95f+XORRandom(11)*0.01f);
		}
		else
		{
			t = Maths::Lerp(t, 0, 0.025f);
		}

		this.set_f32("anim_time", t);

		if (sprite.animation !is null)
		{
			sprite.animation.time = Maths::Floor(t) == 0 ? 0 : anim_min_speed + anim_max_speed - t;
		}
	}

	if (active && timing)
	{
		u8 team = this.getTeamNum();
		
		CBlob@[] repair;
		getMap().getBlobsInRadius(holder.getAimPos(), this.getRadius() * 1, @repair);

		for (u16 i = 0; i < repair.size(); i++)
		{
			CBlob@ blob = repair[i];
			if (blob !is null)
			{
				if (blob.getDistanceTo(this) > 32.0f || getMap().rayCastSolidNoBlobs(holder.getAimPos(), blob.getPosition())) continue;

				if (blob.getHealth() < blob.getInitialHealth()
				&& (blob.hasTag("vehicle") || blob.hasTag("bunker")
					|| blob.hasTag("structure") || blob.hasTag("door") || blob.hasTag("repairable")))
				{
					if (blob.hasTag("respawn") || blob.hasTag("never_repair")) continue; // dont repair outposts
					if (team == blob.getTeamNum() || blob.getTeamNum() >= 7)
					{
						if (blob.get_u32("no_heal") > getGameTime())
						{
							if (blob.get_u32("heal_delayed") < getGameTime()) blob.Tag("request heal delay icon");
							else if (blob.get_u32("heal_delayed") - getGameTime() < 45)
								blob.set_u32("heal_delayed", Maths::Min(blob.get_u32("no_heal"), getGameTime() + 45));
							continue; 
						}

						this.add_u8("repairs", 1);

						if (this.get_u8("repairs") >= max_repairs)
						{
							if (holder.hasBlob("mat_scrap", 1))
							{
								this.set_u8("repairs", 0);

								if (isServer())
								{
									holder.TakeBlob("mat_scrap", 1);
									this.Sync("repairs", true);
								}
							}
							else break;
						}

						float repair_amount = 0.5f;

						if (blob.hasTag("bunker"))
						{
							repair_amount *= 4;
						}
						else if (blob.hasTag("structure"))
						{
							repair_amount *= 20;
						}
						else if (blob.hasTag("machinegun"))
						{
							repair_amount *= 7.5f;
						}
						else if (blob.hasTag("vehicle"))
						{
							repair_amount *= 2;
						}
						else if (blob.hasTag("door"))
						{
							repair_amount *= blob.getInitialHealth()/5;
						}

						if (isClient() && sprite !is null)
						{
							Vec2f offset = Vec2f(-7,1).RotateBy(this.getAngleDegrees());
							if (this.isFacingLeft()) offset.x *= -1;
							ParticleAnimated("LargeSmokeGray", this.getPosition() - offset, Vec2f(XORRandom(11)*0.01f, 0).RotateBy(XORRandom(360)), 0, 0.25f + XORRandom(31) * 0.01f, 2 + XORRandom(3), -0.0031f, true);
							sprite.PlaySound("welder_use.ogg", 1.0f, 0.75f+XORRandom(16)*0.01f);

							for (u8 i = 0; i < 10+XORRandom(10); i++)
							{
								sparks(this.getPosition()-Vec2f(4,4)+Vec2f(XORRandom(8),XORRandom(8)) - offset, XORRandom(360), 1.0f+XORRandom(51)*0.01f, SColor(255, 255, 255, XORRandom(125)));
							}
						}
						if (isServer())
						{
							if (blob.getHealth() + repair_amount <= blob.getInitialHealth())
			            	{
								blob.server_SetHealth(blob.getHealth() + repair_amount);
								break;
			            	}
			            	else
			            	{
			            	    blob.server_SetHealth(blob.getInitialHealth());
								break;
			            	}
						}
			    	}
			    }
			}
		}
	}
	
	if (isServer() && attached) this.setAngleDegrees(this.get_f32("angle"));
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 25.0f);
	at.y -= 2.5f;
	ParticlePixel(at, vel, color, true, 15+XORRandom(30));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !this.hasTag("attached") && (!blob.hasTag("trap") && !blob.hasTag("flesh") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}