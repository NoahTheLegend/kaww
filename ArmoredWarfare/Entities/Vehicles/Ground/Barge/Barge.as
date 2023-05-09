#include "VehicleCommon.as"
#include "GenericButtonCommon.as"
#include "Hitters.as";

// Boat logic

void onInit(CBlob@ this)
{
	this.Tag("engine_can_get_stuck");
	this.Tag("boat");
	this.Tag("vehicle");
	this.Tag("no_upper_collision");

	this.SetFacingLeft(this.getTeamNum()==1);

	AddIconToken("$store_inventory$", "InteractionIcons.png", Vec2f(32, 32), 28);

	Vehicle_Setup(this,
	              5000.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, -2.5f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_SetupWaterSound(this, v, "EngineRun_mid.ogg",  // movement sound
	                        1.0f, // movement sound volume modifier   0.0f = no manipulation
	                        1.33f // movement sound pitch modifier     0.0f = no manipulation
	                       );

	this.getShape().SetOffset(Vec2f(this.getTeamNum()==0?-3:3, 9));
	this.getShape().getConsts().transports = true;
	this.getSprite().SetZ(50);

	f32 corellate = 0;
	if (this.getTeamNum() == 1) corellate = 8;

	Vec2f[] backbackShape;
	backbackShape.push_back(Vec2f(4.0f, -2.0f));
	backbackShape.push_back(Vec2f(6.0f , -2.0f));
	backbackShape.push_back(Vec2f(6.0f , 8.0f));
	backbackShape.push_back(Vec2f(4.0f, 8.0f));
	this.getShape().AddShape(backbackShape);

	Vec2f[] backShape;
	backShape.push_back(Vec2f(25.0f, -6.0f));
	backShape.push_back(Vec2f(27.0f, -6.0f));
	backShape.push_back(Vec2f(27.0f, 10.0f));
	backShape.push_back(Vec2f(25.0f, 10.0f));
	this.getShape().AddShape(backShape);

	Vec2f[] frontShape;
	frontShape.push_back(Vec2f(108.0f, 0.0f));
	frontShape.push_back(Vec2f(120.0f, 16.0f));
	frontShape.push_back(Vec2f(108.0f, 16.0f));
	frontShape.push_back(Vec2f(108.0f, 16.0f));
	this.getShape().AddShape(frontShape);

	getMap().server_AddMovingSector(Vec2f(-60.0f, 0.0f), Vec2f(-48.0f, 16.0f), "ladder", this.getNetworkID());
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onTick(CBlob@ this)
{
	HitInfo@[] subjects;
	if (getMap().getHitInfosFromRay(this.getPosition()-Vec2f(this.getRadius()*0.95f, 0), 0, this.getRadius()*1.75f, this, @subjects))
	{
		for (u16 i = 0; i < subjects.length; i++)
		{
			HitInfo@ subj = subjects[i];
			if (subj is null || subj.blob is null) continue;
			if (subj.blob.hasTag("player") && doesCollideWithBlob(this, subj.blob))
			{
				subj.blob.AddForce(this.getVelocity()*subj.blob.getMass()/10);
			}
		}
	}

	if (isServer() && getGameTime()%60 == 0)
	{
		if (this.isOnGround() && !this.isInWater())
		{
			this.server_Hit(this, this.getPosition(), this.getOldVelocity(), 5.0f, Hitters::builder);
		}
	}
	const int time = this.getTickSinceCreated();
	if (this.hasAttached() || time < 30) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);
	}
	if (this.isInWater())
	{
		this.getShape().SetRotationsAllowed(false);
		this.setAngleDegrees(0);
	}
	else this.getShape().SetRotationsAllowed(true);


	if (getMap() !is null)
	{
		u8 w = 0;
		for (u8 i = 0; i < 8; i++)
		{
			if (getMap().isInWater(this.getPosition()+Vec2f(0,8)-Vec2f(0, 1+i)))
			{
				w++;
			}
		}
		this.setVelocity(Vec2f(this.getVelocity().x, this.getVelocity().y - 0.1f*w));
	}

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];

			if (ap.getOccupied() !is null)
			{
				const bool left = ap.isKeyPressed(key_left);
				const bool right = ap.isKeyPressed(key_right);

				if (ap.name == "ROWER")
				{
					// manage oar sprite animation
					CSpriteLayer@ oar = this.getSprite().getSpriteLayer("oar " + i);

					bool splash = false;

					if (oar !is null)
					{
						Animation@ anim = oar.getAnimation("default");

						if (anim !is null)
						{
							anim.loop = (left || right);
							anim.backward = ((!this.isFacingLeft() && right) || (this.isFacingLeft() && left));

							ap.getOccupied().SetFacingLeft(!this.isFacingLeft());

							if (oar.isFrameIndex(2))
								splash = true;
						}
						//make splashes when rowing
						if (this.isInWater() && (left || right) && splash)
						{
							Vec2f pos = oar.getWorldTranslation();
							Vec2f vel = this.getVelocity();
							for (int particle_step = 0; particle_step < 3; ++particle_step)
							{
								Splash(pos, vel, particle_step);
							}
						}
					}

				}
				else if (ap.name == "SAIL")
				{
					// manage oar sprite animation
					CSpriteLayer@ sail = this.getSprite().getSpriteLayer("sail " + i);

					if (sail !is null)
					{
						Animation@ anim = sail.getAnimation("default");

						if (anim !is null)
						{
							anim.loop = (left || right);
							anim.backward = ((!this.isFacingLeft() && right) || (this.isFacingLeft() && left));

							ap.getOccupied().SetFacingLeft(this.isFacingLeft());
						}
					}
				}

				// always play sound when rowing
				if (this.isInWater() && (left || right))
				{
					this.getSprite().SetEmitSoundPaused(false);
				}
			}
		}
		if (this.isInWater() && this.getShape().vellen > 2.0f)
		{
			Vec2f pos = this.getPosition();
			f32 side = this.isFacingLeft() ? this.getWidth() : -this.getWidth();
			side *= 0.45f;
			pos.x += side;
			pos.y += 20.0f;
			Splash(pos, this.getVelocity(), XORRandom(3));
		}
	}
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("boat")) return false;
	if (blob.hasTag("player") && blob.getTeamNum() == this.getTeamNum() && blob.getPosition().y > this.getPosition().y+16.0f) return false;
	return blob.hasTag("vehicle") || Vehicle_doesCollideWithBlob_boat(this, blob);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

void Splash(Vec2f pos, Vec2f vel, int randomnum)
{
	Vec2f randomVel = getRandomVelocity(90, 0.5f , 40);
	CParticle@ p = ParticleAnimated("Splash.png", pos,
	                                Vec2f(-vel.x, -0.4f) + randomVel, 0.0f, Maths::Max(1.0f, 0.5f * (1.0f + Maths::Abs(vel.x))),
	                                2 + randomnum,
	                                0.1f, false);
	if (p !is null)
	{
		p.rotates = true;
		p.rotation.y = ((XORRandom(333) > 150) ? -1.0f : 1.0f);
		p.Z = 100;
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::explosion || customData == Hitters::keg)
	{
		return damage *= 0.5f;
	}
	return damage;
}
