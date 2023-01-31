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
	this.set_f32(projExplosionRadiusString, 80.0f);
	this.set_f32(projExplosionDamageString, 16.0f);

	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", true);
	this.Tag("collideswithglass");

	this.set_u16("follow_id", 0);

	this.set_u8("exploding_2", 0);
	this.Tag("grenade");

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action3);
	}
	this.set_u8("death_timer", 120);
	this.Tag("change team on pickup");

	if (this.getName() == "agrenade" || this.getName() == "sagrenade")
	{
		this.set_u8("exploding_2", 110);
	}

	// let it be not heavy, we'll see how OP it is
	//if (this.getName() == "sgrenade" || this.getName() == "sagrenade")
	//{
	//	this.Tag("medium weight");
	//}
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
	return !this.hasTag("activated");
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 40.0f);
	this.set_f32("map_damage_ratio", 0.5f);
	
	WarfareExplode(this, this.get_f32(projExplosionRadiusString), this.get_f32(projExplosionDamageString));
	
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

	this.getShape().SetStatic(false);
	this.set_Vec2f("follow_offset", Vec2f(0,0));
	this.set_u16("follow_id", 0);
	this.server_setTeamNum(attached.getTeamNum());
}

void onTick(CBlob@ this)
{
	if (this.isAttached() && (this.getName() == "grenade" || this.getName() == "sgrenade"))
	{
		if (this.isAttached() && !this.hasTag("activated"))
		{
			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
			if (ap !is null && ap.isKeyJustPressed(key_action3) && ap.getOccupied() !is null && ap.getOccupied().isMyPlayer())
			{
				if (ap.getOccupied().getPlayer() !is null)
				{
					if (getRules().get_string(ap.getOccupied().getPlayer().getUsername() + "_perk") == "Bull")
					{
						return;
					}
				}
				//if (!this.hasTag("no_pin")) Sound::Play("/Pinpull.ogg", this.getPosition(), 0.8f, 1.0f);
				CBitStream params;
				this.SendCommand(this.getCommandID("activate"), params);
			}
		}
	}
	else if (this.get_u8("exploding_2") > 0)
	{
		if (this.getName() == "sagrenade")
		{
			if (getBlobByNetworkID(this.get_u16("follow_id")) !is null && this.get_u16("follow_id") != 0)
			{
				CBlob@ follow = getBlobByNetworkID(this.get_u16("follow_id"));
				bool fl = (this.get_bool("follow_fl") && follow.isFacingLeft()) || (!this.get_bool("follow_fl") && !follow.isFacingLeft());
				this.setPosition(follow.getPosition()+(fl ? -this.get_Vec2f("follow_offset").RotateBy(follow.getAngleDegrees()) : this.get_Vec2f("follow_offset").RotateBy(follow.getAngleDegrees())));
			}
		}

		this.set_u8("exploding_2", this.get_u8("exploding_2") - 1);
		f32 angle = -this.get_f32("bomb angle");

		Vec2f pos = this.getPosition();

		if (this.get_u8("exploding_2") == 3)
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
			this.Untag("activated");
			this.server_Die();
		}
	}

	if ((this.getName() == "agrenade" || this.getName() == "sagrenade" ) && (!v_fastrender || XORRandom(3)==0))
	{
		sparks(this.getPosition(), this.getAngleDegrees(), 3.5f + (XORRandom(10) / 5.0f), SColor(255, 255, 230, 120));
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
		if (isClient() && !this.hasTag("activated"))
		{
			Sound::Play("/Pinpull.ogg", this.getPosition(), 0.8f, 1.0f);
		}

    	if (isServer())
    	{
			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
    	    if (point !is null)
			{
				string prop = (this.getName() == "grenade" ? "agrenade" : "sagrenade");
				CBlob@ holder = point.getOccupied();
				if (holder !is null && this !is null && !this.hasTag("activated"))
				{
					CBlob@ blob = server_CreateBlob(prop, this.getTeamNum(), this.getPosition());
					holder.server_Pickup(blob);
					this.server_Die();

					CPlayer@ activator = holder.getPlayer();
					string activatorName = activator !is null ? (activator.getUsername() + " (team " + activator.getTeamNum() + ")") : "<unknown>";
					//printf(activatorName + " has activated " + this.getName());
				}
				else 
				{
					CBlob@ blob = server_CreateBlob(prop, this.getTeamNum(), this.getPosition());
					this.server_Die();
				}
			}
    	}
		this.Tag("activated");
		this.set_bool("active", true);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid)
	{
		if (!this.getShape().isStatic() && this.get_u16("follow_id") == 0 && this.getName() == "sagrenade" && !this.isAttached())
		{
			if (blob.getTeamNum() != this.getTeamNum() && (blob.hasTag("vehicle") || blob.hasTag("player")))
			{
				this.getShape().setFriction(100.0f);
				this.set_Vec2f("follow_offset", blob.getPosition() - this.getPosition());
				this.set_u16("follow_id", blob.getNetworkID());
				this.set_bool("follow_fl", blob.isFacingLeft());
				this.setVelocity(Vec2f(0,0));
			}
		}
		return;
	}

	const f32 vellen = this.getOldVelocity().Length();
	const u8 hitter = this.get_u8("custom_hitter");
	if (vellen > 1.7f)
	{
		Sound::Play("/BombBounce.ogg", this.getPosition(), Maths::Min(vellen / 9.0f, 1.0f), 1.2f);
	}

	if ((this.getName() == "sgrenade" || this.getName() == "sagrenade") && !this.isAttached()) // sticky grenade sticks to blocks
	{
		CMap@ map = getMap();
		if (map !is null)
		{
			Vec2f v = this.getOldVelocity();
			//f32 rot = (v.y < 0.0f && Maths::Abs(v.y) > Maths::Abs(v.x) ? 90.0f : v.x > 0.1f ? 0.0f : v.x < -0.1f ? 180.0f : 0);
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
						stop = true;
						break;
					}
				}
			}
		}

		this.setVelocity(Vec2f(0,0));
	}
}

