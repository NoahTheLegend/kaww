#include "Hitters.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next repair", 0);

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

		if (this.get_u32("next repair") > getGameTime())
		{
			if (this.get_u32("next repair") - getGameTime() > 6)
			{
				float mul = (7 - (this.get_u32("next repair") - getGameTime() -44))*2;

				this.getSprite().ResetTransform();
				this.getSprite().SetOffset(Vec2f(((holder.isFacingLeft() ? -1 : 1) * (this.getPosition().x - holder.getAimPos().x))/mul, (-1*(this.getPosition().y - holder.getAimPos().y))/mul));

				this.getSprite().RotateBy((holder.isFacingLeft() ? 9 : -9)*(this.get_u32("next repair") - getGameTime()), Vec2f());
			}
			else 
			{
				this.getSprite().SetOffset(Vec2f());
				this.getSprite().ResetTransform();
			}
			
			return;
		}
		
		if (getKnocked(holder) <= 0)
		{		
			if (point.isKeyJustPressed(key_action1))
			{
				u8 team = holder.getTeamNum();
				
				HitInfo@[] hitInfos;
				if (getMap().getHitInfosFromArc(this.getPosition(), -(holder.getAimPos() - this.getPosition()).Angle(), 60, 16, this, @hitInfos))
				{
					for (uint i = 0; i < hitInfos.length; i++)
					{
						CBlob@ blob = hitInfos[i].blob;
						if (blob !is null && blob.hasTag("vehicle"))
						{
							if (isServer())
							{
								holder.server_Hit(this, this.getPosition(), Vec2f(), 0.2f, Hitters::fall, true);
							}

							float repair_amount = 0.5f;

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
				            }
				            else //Repair amount would go above the inital health (max health). 
				            {
				                blob.server_SetHealth(blob.getInitialHealth());//Set health to the inital health (max health)
				            }
						}
					}
				}

				// Woosh
				if (isClient())
				{
					this.getSprite().PlaySound("throw.ogg", 1.5f, 1.0f);
				}

				this.set_u32("next repair", getGameTime() + 40);
			}
		}
	}
}