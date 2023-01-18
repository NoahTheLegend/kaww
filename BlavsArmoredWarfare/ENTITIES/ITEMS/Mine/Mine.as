// Mine.as

#include "Hitters.as";
#include "Explosion.as";

const u8 MINE_PRIMING_TIME = 105;

const string MINE_STATE = "mine_state";
const string MINE_TIMER = "mine_timer";
const string MINE_PRIMING = "mine_priming";
const string MINE_PRIMED = "mine_primed";

enum State
{
	NONE = 0,
	PRIMED
};

void onInit(CBlob@ this)
{
	this.set_f32("explosive_radius", 42.0f);
	this.set_f32("explosive_damage", 3.0f);
	this.set_f32("map_damage_radius", 32.0f);
	this.set_f32("map_damage_ratio", 0.5f);
	this.set_bool("map_damage_raycast", true);
	this.set_string("custom_explosion_sound", "MineExplosion.ogg");
	this.set_u8("custom_hitter", Hitters::mine);

	this.Tag("trap");
	this.getSprite().SetRelativeZ(-0.1f); //background

	this.Tag("ignore fall");
	this.Tag("ignore_saw");
	this.Tag(MINE_PRIMING);

	if (this.exists(MINE_STATE))
	{
		if (getNet().isClient())
		{
			CSprite@ sprite = this.getSprite();

			if (this.get_u8(MINE_STATE) == PRIMED)
			{
				sprite.SetFrameIndex(1);
			}
			else
			{
				sprite.SetFrameIndex(0);
			}
		}
	}
	else
	{
		this.set_u8(MINE_STATE, NONE);
	}

	this.set_u8(MINE_TIMER, 0);
	this.addCommandID(MINE_PRIMED);

	this.getCurrentScript().tickIfTag = MINE_PRIMING;
}

void onTick(CBlob@ this)
{
	if (getNet().isServer())
	{
		//tick down
		if (this.getVelocity().LengthSquared() < 1.0f && !this.isAttached())
		{
			u8 timer = this.get_u8(MINE_TIMER);
			timer++;
			this.set_u8(MINE_TIMER, timer);

			if (timer >= MINE_PRIMING_TIME)
			{
				this.Untag(MINE_PRIMING);
				this.SendCommand(this.getCommandID(MINE_PRIMED));
			}
		}
		//reset if bumped/moved
		else if (this.hasTag(MINE_PRIMING))
		{
			this.set_u8(MINE_TIMER, 0);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(MINE_PRIMED))
	{
		if (this.isAttached()) return;

		if (this.isInInventory()) return;

		if (this.get_u8(MINE_STATE) == PRIMED) return;

		this.set_u8(MINE_STATE, PRIMED);
		this.getShape().checkCollisionsAgain = true;

		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetFrameIndex(1);
			sprite.PlaySound("MineArmed.ogg");
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	this.Untag(MINE_PRIMING);

	if (this.get_u8(MINE_STATE) == PRIMED)
	{
		this.set_u8(MINE_STATE, NONE);
		this.getSprite().SetFrameIndex(0);
	}

	if (this.getDamageOwnerPlayer() is null || this.getTeamNum() != attached.getTeamNum())
	{
		CPlayer@ player = attached.getPlayer();
		if (player !is null)
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.Untag(MINE_PRIMING);

	if (this.get_u8(MINE_STATE) == PRIMED)
	{
		this.set_u8(MINE_STATE, NONE);
		this.getSprite().SetFrameIndex(0);
	}

	if (this.getDamageOwnerPlayer() is null || this.getTeamNum() != inventoryBlob.getTeamNum())
	{
		CPlayer@ player = inventoryBlob.getPlayer();
		if (player !is null)
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (getNet().isServer())
	{
		this.Tag(MINE_PRIMING);
		this.set_u8(MINE_TIMER, 0);
	}
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (getNet().isServer() && !this.isAttached())
	{
		this.Tag(MINE_PRIMING);
		this.set_u8(MINE_TIMER, 0);
	}
}

bool explodeOnCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() != blob.getTeamNum() &&
	(blob.hasTag("flesh") || blob.hasTag("vehicle"));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (getNet().isServer() && blob !is null)
	{
		if (this.get_u8(MINE_STATE) == PRIMED && explodeOnCollideWithBlob(this, blob))
		{
			this.Tag("exploding");
			this.Sync("exploding", true);

			this.server_SetHealth(-1.0f);
			this.server_Die();

			if (isClient())
			{
				Vec2f pos = this.getPosition();
				CMap@ map = getMap();

				ParticleAnimated("BoomParticle", pos, Vec2f(0.0f, -0.1f), 0.0f, 1.0f, 3, XORRandom(70) * -0.00005f, true);
				
				for (int i = 0; i < 12; i++)
				{
					ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(32) - 16, XORRandom(24) - 12), getRandomVelocity(0.0f, XORRandom(35) * 0.01f, 360) + Vec2f(0.0f, -0.16f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 5 + XORRandom(10), XORRandom(70) * -0.00005f, true);
				}

				for (int i = 0; i < 5; i++)
				{
					ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(32) - 16, XORRandom(24) - 12), getRandomVelocity(0.0f, XORRandom(35) * 0.01f, 360) + Vec2f(0.0f, -0.16f), float(XORRandom(360)), 0.9f + XORRandom(100) * 0.01f, 16 + XORRandom(10), XORRandom(70) * -0.00005f, true);
				}

				for (int i = 0; i < (15 + XORRandom(15)); i++)
				{
					makeGibParticle("GenericGibs", this.getPosition(), getRandomVelocity((this.getPosition() + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
			                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (getNet().isServer() && this.hasTag("exploding"))
	{
		const Vec2f POSITION = this.getPosition();

		CBlob@[] blobs;
		getMap().getBlobsInRadius(POSITION, this.getRadius() + 16, @blobs);
		for(u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ target = blobs[i];
			if (target.hasTag("flesh") &&
			(target.getTeamNum() != this.getTeamNum() || target.getPlayer() is this.getDamageOwnerPlayer()))
			{
				this.server_Hit(target, POSITION, Vec2f_zero, 3.0f, Hitters::mine_special, true);
			}

			if (target.hasTag("vehicle") &&
			(target.getTeamNum() != this.getTeamNum() || target.getPlayer() is this.getDamageOwnerPlayer()))
			{
				this.server_Hit(target, POSITION, Vec2f_zero, 10.0f, Hitters::mine_special, true);
				target.AddForce(Vec2f(0, -1500.0f));
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() == blob.getTeamNum() || this.get_u8(MINE_STATE) != PRIMED;;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return customData == Hitters::builder ? this.getInitialHealth() / 2 : damage * 0.5;
}
