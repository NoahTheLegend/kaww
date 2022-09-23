#include "WarfareGlobal.as"
#include "Explosion.as";

const string GRENADE_STATE = "grenade_state";
const string GRENADE_TIMER = "grenade_timer";
const string GRENADE_PRIMING = "grenade_priming";
const string GRENADE_PRIMED = "grenade_primed";

enum State
{
    NONE = 0,
    PRIMED
};

void onInit(CBlob@ this)
{
	this.set_s8(penRatingString, 4);
	this.set_f32(projExplosionRadiusString, 64.0f);
	this.set_f32(projExplosionDamageString, 5.0f);

	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", true);
	
	this.Tag("projectile");
	this.Tag("collideswithglass");

	this.set_u8("exploding_2", 0);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action3);
	}
	this.set_u8("death_timer", 120);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("destructable"))
	{
		return true;
	}
	if (blob.hasTag("structure") || blob.hasTag("bunker"))
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
	return !this.hasTag("activated");
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 17.0f);
	this.set_f32("map_damage_ratio", 0.01f);
	
	WarfareExplode(this, this.get_f32(projExplosionRadiusString), this.get_f32(projExplosionDamageString));
	
	//if (isClient())
	{
		for (int i = 0; i < 30; i++)
		{
			MakeParticle(this, Vec2f( XORRandom(60) - 30, XORRandom(60) - 30), getRandomVelocity(-angle, XORRandom(125) * 0.01f, 90));
		}
		
		this.Tag("exploded");
		this.getSprite().Gib();
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
    this.Untag(GRENADE_PRIMING);

    if(this.get_u8(GRENADE_STATE) == PRIMED)
    {
        this.set_u8(GRENADE_STATE, NONE);
        this.getSprite().SetFrameIndex(0);
    }

    if(this.getDamageOwnerPlayer() is null || this.getTeamNum() != attached.getTeamNum())
    {
        CPlayer@ player = attached.getPlayer();
        if(player !is null)
        {
            this.SetDamageOwnerPlayer(player);
        }
    }
}

void onTick(CBlob@ this)
{
	if (isClient()) // a try to fix clientsideonly activation
	{
		if (this.hasTag("activated") && this.get_u8("exploding_2") == 0)
		{
			this.Untag("activated");
		}
	}
	if (this.get_bool("sync_tag") && !this.hasTag("activated")) this.Tag("activated");
	if (this.isAttached() && !this.hasTag("activated"))
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (ap !is null && ap.isKeyJustPressed(key_action3))
		{
			if (!this.hasTag("no_pin")) 
			{
				Sound::Play("/Pinpull.ogg", this.getPosition(), 0.8f, 1.0f);
			}
			CBitStream params;
			this.SendCommand(this.getCommandID("activate"), params);
		}
	}
	if (this.get_u8("exploding_2") > 0)
	{
		this.set_u8("exploding_2", this.get_u8("exploding_2") - 1);
		f32 angle = -this.get_f32("bomb angle");

		Vec2f pos = this.getPosition();

		if (this.get_u8("exploding_2") == 3)
		{
			DoExplosion(this);

			for (int i = 0; i < 15; i++)
			{
				CParticle@ p = ParticleAnimated("BulletHitParticle1.png", pos + getRandomVelocity(-angle, XORRandom(30) * 1.0f, 360), Vec2f(0,0), XORRandom(360), 1.0f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
			}

			// glow
			this.SetLight(true);
			this.SetLightRadius(300.0f);
			this.SetLightColor(SColor(255, 255, 240, 210));
		}
		else if (this.get_u8("exploding_2") < 3)
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

		if (this.get_u8("exploding_2") == 1)
		{
			this.server_Die();
		}
	}
}

void onTick(CSprite@ this)
{
	if (this.getBlob().hasTag("activated") && XORRandom(100) < 35)
	{
		sparks(this.getBlob().getPosition(), this.getBlob().getAngleDegrees(), 3.5f + (XORRandom(10) / 5.0f), SColor(255, 255, 230, 0));
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
    if (cmd == this.getCommandID("activate"))
    {
		this.Tag("no_pin");
        if (isServer())
        {
    		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
            if (point is null){return;}
    		CBlob@ holder = point.getOccupied();

            if (holder !is null && this !is null)
            {
                this.Tag("activated");
				this.set_bool("sync_tag", true);
				this.Sync("sync_tag", true);
                this.set_u8("exploding_2", 110);
                this.Sync("exploding_2", true);
            }
        }
    }
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid)
	{
		return;
	}

	const f32 vellen = this.getOldVelocity().Length();
	const u8 hitter = this.get_u8("custom_hitter");
	if (vellen > 1.7f)
	{
		Sound::Play("/BombBounce.ogg", this.getPosition(), Maths::Min(vellen / 9.0f, 1.0f), 1.2f);
	}
}

