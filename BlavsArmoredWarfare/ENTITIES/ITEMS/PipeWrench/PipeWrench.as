#include "Hitters.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next repair", 0);
	this.Tag("trap");

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}
}

void UpdateAngle(CBlob@ this)
{
	AttachmentPoint@ point=this.getAttachments().getAttachmentPointByName("PICKUP");
	if(point is null) return;

	CBlob@ holder=point.getOccupied();
	if(holder is null) return;

	if (holder.isAttached()) return;

	Vec2f aimpos=holder.getAimPos();
	Vec2f pos=holder.getPosition();

	Vec2f aim_vec =(pos - aimpos);
	aim_vec.Normalize();

	f32 mouseAngle=aim_vec.getAngleDegrees();
	if(!holder.isFacingLeft()) mouseAngle += 180;

	this.setAngleDegrees(-mouseAngle);

	point.offset.x=0 +(aim_vec.x*2*(holder.isFacingLeft() ? 1.0f : -1.0f));
	point.offset.y=-(aim_vec.y);
}

void onTick(CBlob@ this)
{	
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		UpdateAngle(this);
		
		if (holder is null) return;
		if (holder.isAttached()) return;

		CSprite@ sprite = this.getSprite();
		if (sprite !is null && this.get_u32("next repair") > getGameTime())
		{
			f32 l = this.isFacingLeft() ? -1.0f : 1.0f;
			if (this.get_u32("next repair") == getGameTime() + 19)
				sprite.RotateBy(24.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 18)
				sprite.RotateBy(24.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 17)
				sprite.RotateBy(16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 14)  //bruh what is this like actually
				sprite.RotateBy(-16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 11)
				sprite.RotateBy(16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 8)
				sprite.RotateBy(-16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 7)
				sprite.RotateBy(-24.0f*l, Vec2f(0, 2));
			else if (this.get_u32("next repair") == getGameTime() + 6)
			{
				sprite.RotateBy(-24.0f*l, Vec2f(0, 2));
				sprite.ResetTransform();
			}
			
			return;
		}
		u32 repair_cd = 30;
		if (getKnocked(holder) <= 0)
		{		
			if (point.isKeyPressed(key_action1))
			{
				u8 team = holder.getTeamNum();
				
				HitInfo@[] hitInfos;
				if (getMap().getHitInfosFromArc(this.getPosition(), -(holder.getAimPos() - this.getPosition()).Angle(), 60, 16, this, @hitInfos))
				{
					for (uint i = 0; i < hitInfos.length; i++)
					{
						CBlob@ blob = hitInfos[i].blob;
						if (blob !is null)
						{
							if (blob.hasTag("vehicle") || blob.hasTag("bunker") || blob.hasTag("structure") || blob.hasTag("door"))
							{
								if (blob.hasTag("respawn") || blob.hasTag("never_repair")) continue; // dont repair outposts
								if (team == blob.getTeamNum() || blob.getTeamNum() >= 2)
								{
									if (isServer())
									{
										holder.server_Hit(this, this.getPosition(), Vec2f(), 0.2f, Hitters::fall, true);
									}

									float repair_amount = 0.35f;
									if (holder.getPlayer() !is null)
									{
										if (getRules().get_string(holder.getPlayer().getUsername() + "_perk") == "Operator")
										{
											repair_cd = 18;
										}
									}
									if (blob.hasTag("bunker"))
									{
										repair_amount *= 4;
									}
									else if (blob.hasTag("structure"))
									{
										repair_amount *= 20;
									}
									else if (blob.getName() == "heavygun")
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

									if (blob.getHealth() + repair_amount <= blob.getInitialHealth())
						            {
						                blob.server_SetHealth(blob.getHealth() + repair_amount);//Add the repair amount.

						               	if (isClient())
										{
											this.getSprite().PlaySound("Repair.ogg", 2.0f, 1.0f);
										}

						            	const Vec2f pos = blob.getPosition() + getRandomVelocity(0, blob.getRadius()*0.3f, 360);
										CParticle@ p = ParticleAnimated("SparkParticle.png", pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), 0.0f, false);
										if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

										Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
										velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

										ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);
										break;
						            }
						            else //Repair amount would go above the inital health (max health). 
						            {
						                blob.server_SetHealth(blob.getInitialHealth());//Set health to the inital health (max health)
						            }
					        	}
					        }

						}
					}
				}

				// Woosh
				if (isClient())
				{
					this.getSprite().PlaySound("throw.ogg", 1.5f, 1.0f);
				}

				this.set_u32("next repair", getGameTime() + repair_cd);
			}
		}
	}
}