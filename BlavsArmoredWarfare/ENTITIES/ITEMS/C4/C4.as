#include "WarfareGlobal.as"
#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.set_s8(penRatingString, 4);
	this.set_f32(projExplosionRadiusString, 52.0f+XORRandom(13));
	this.set_f32(projExplosionDamageString, 4.0f);

	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", true);
	this.Tag("collideswithglass");

	this.set_u16("exploding", 0);
	this.set_bool("explode", false);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action3);
	}
	this.set_u8("death_timer", 120);
	this.Tag("change team on pickup");

	this.Tag("medium weight");

	this.addCommandID("switch");

	CSprite@ sprite = this.getSprite();
	sprite.ScaleBy(0.75f, 0.75f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("trap")) return false;
	if (blob.hasTag("destructable"))
	{
		return true;
	}
	if (blob.hasTag("structure") && (!blob.hasTag("bunker") || blob.getName() == "sandbags" || blob.getTeamNum() == this.getTeamNum()))
	{
		return false;
	}
	if (blob.hasTag("flesh"))
	{
		return false;
	}
	return (!blob.hasTag("vehicle") && blob.isCollidable());
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return true;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.get_bool("explode");
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 52.0f+XORRandom(5));
	this.set_f32("map_damage_ratio", 0.15f);
	
	for (u8 i = 0; i < 5+XORRandom(2); i++)
	{
		WarfareExplode(this, this.get_f32(projExplosionRadiusString), this.get_f32(projExplosionDamageString));
	}
	
	if (isClient())
	{
		for (int i = 0; i < (v_fastrender ? 5 : 30); i++)
		{
			MakeParticle(this, Vec2f( XORRandom(60) - 30, XORRandom(60) - 30), getRandomVelocity(-angle, XORRandom(125) * 0.01f, 90));
		}
		
		this.Tag("exploded");
		if (!v_fastrender) this.getSprite().Gib();
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.exists("delay") && this.get_u32("delay") > getGameTime()) return;
 	if (caller is null) return;
	if (!caller.isMyPlayer()) return;
	if (this.getDistanceTo(caller) > 16.0f) return;
	if (this.isAttachedTo(caller) || !this.isAttached())
	{
		CBitStream params;
		CButton@ button = caller.CreateGenericButton(11, Vec2f(0, 0), this, this.getCommandID("switch"), "\n\n"+(this.get_bool("explode") ? "Deactivate" : "Activate")+" C-4", params);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	this.getShape().SetStatic(false);
	this.getShape().getConsts().mapCollisions = true;
    if (attached !is null) this.SetDamageOwnerPlayer(attached.getPlayer());
	this.server_setTeamNum(attached.getTeamNum());
}

void onTick(CBlob@ this)
{
	if (isServer() && this.get_bool("explode") && this.get_u16("exploding") > 90) // experimental
	{
		if (getGameTime()%15==0)
		{
			this.Sync("explode", true);
			this.Sync("exploding", true);
		}
	}
	if (this.getShape() is null) return;
	if (this.get_bool("explode") && this.get_u16("exploding") > 0)
	{
		if (getGameTime() % 30 == 0)
		{
			this.getSprite().PlaySound("C4Beep.ogg", 1.0f, 1.1f);
		}
		this.set_u16("exploding", this.get_u16("exploding") - 1);
		f32 angle = -this.get_f32("bomb angle");

		Vec2f pos = this.getPosition();

		if (this.get_u16("exploding") == 3)
		{
			DoExplosion(this);

			if (!v_fastrender)
			{
				for (int i = 0; i < 15; i++)
				{
					CParticle@ p = ParticleAnimated("BulletHitParticle1.png", pos + getRandomVelocity(-angle, XORRandom(30) * 1.0f, 360), Vec2f(0,0), XORRandom(360), 1.0f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
				}

				// glow
				this.SetLight(true);
				this.SetLightRadius(300.0f);
				this.SetLightColor(SColor(255, 255, 240, 210));
			}
		}
		else if (this.get_u16("exploding") < 2)
		{
			for (int i = 0; i < 3; i++)
			{
				MakeParticle(this, Vec2f( XORRandom(100) - 50, XORRandom(100) - 50), getRandomVelocity(-angle, XORRandom(125) * 0.01f, 90));
			}

			for (int i = 0; i < 14; i++)
			{
				{ CParticle@ p = ParticleAnimated("BulletChunkParticle.png", pos, getRandomVelocity(-angle, XORRandom(125) * 0.1f, 360), 0.0f, 0.55f + XORRandom(50)*0.01f, 22+XORRandom(3), 0.3f, true);
				if (p !is null) { p.lighting = true; }}
			}

			for (int i = 0; i < 3; i++)
			{
				ParticleAnimated("Smoke", pos, getRandomVelocity(0, XORRandom(10) * 0.12f, 360), 0.0f, 2.0f, 8+XORRandom(4), XORRandom(70) * -0.0003f, true);
			}
		}

		if (this.get_u16("exploding") == 1)
		{
			this.Untag("activated");
			this.server_Die();
		}
	}
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 25.0f);
	at.y -= 2.5f;
	ParticlePixel(at, vel, color, true, 119);
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "Explosion.png")
{
	if (!isClient()) return;
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
   	if (cmd == this.getCommandID("switch"))
	{
		if (this.get_bool("explode"))
		{
			if (isClient())
			{
				Sound::Play("C4Defuse.ogg", this.getPosition(), 0.75f, 1.075f);
			}

			

			if (isServer())
			{
				this.set_bool("active", false);
				this.set_bool("explode", false);
				this.set_u16("exploding", 0);
				this.Sync("active", true);
				this.Sync("explode", true);
				this.Sync("exploding", true);
			}
		}
		else
		{
			if (isClient())
			{
				Sound::Play("C4Plant.ogg", this.getPosition(), 0.75f, 1.075f);
			}
			this.set_u32("delay", getGameTime()+30);
			
			if (isServer())
			{
				this.set_bool("active", true);
				this.set_bool("explode", true);
				this.set_u16("exploding", 300);
				this.Sync("active", true);
				this.Sync("explode", true);
				this.Sync("exploding", true);
				this.server_DetachFromAll();
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	const f32 vellen = this.getOldVelocity().Length();
	const u8 hitter = this.get_u8("custom_hitter");

	if (isServer() && solid && vellen > 8.0f && this.get_bool("explode")) // avoid abuse while paratrooping
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("switch"), params);
	}

	if (!this.isAttached())
	{
		CMap@ map = getMap();
		if (map !is null)
		{
			Vec2f v = this.getOldVelocity();
			bool stop = false;
			for (u8 i = 0; i < 12; i++)
			{
				if (stop) break;
				for (u8 j = 0; j < 4; j++)
				{
					Vec2f offset = Vec2f(i, 0).RotateBy(-(this.getPosition()-this.getOldPosition()).Angle()).RotateBy(Maths::Min(0.0f, j*90.0f)); // j*90.0f - rot
					
					if (map.isTileSolid(map.getTile(this.getPosition()+offset)))
					{
						this.setPosition(this.getPosition()+offset-(offset*0.25f));
						this.getShape().SetStatic(true);
						this.getShape().getConsts().mapCollisions = false;
						stop = true;
						break;
					}
				}
			}
		}

		this.setVelocity(Vec2f(0,0));
	}
}

