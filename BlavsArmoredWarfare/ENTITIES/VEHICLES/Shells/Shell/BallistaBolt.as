#include "WarfareGlobal.as"
#include "Hitters.as";
#include "ShieldCommon.as";
#include "LimitedAttacks.as";
#include "Explosion.as";

const f32 MEDIUM_SPEED = 5.0f;

void onInit(CBlob@ this)
{
	this.Tag("projectile");

	f32 damage_mod = 1.0f;
	if (this.exists("damage_modifier") && this.get_f32("damage_modifier") > 0.05f) damage_mod = this.get_f32("damage_modifier");
	this.set_f32(projDamageString, 1.0f);
	this.set_f32(projExplosionRadiusString, 22.0f);
	this.set_f32(projExplosionDamageString, 15.0f*damage_mod);

	this.set_u8("blocks_pierced", 0);

	this.server_SetTimeToDie(12);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

	LimitedAttack_setup(this);

	u32[] offsets;
	this.set("offsets", offsets);
	// Offsets of the tiles that have been hit.

	CSprite@ sprite = this.getSprite();
	sprite.SetFrame(0);
	sprite.getConsts().accurateLighting = true;
	sprite.SetFacingLeft(!sprite.isFacingLeft());

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
}

void onTick(CBlob@ this)
{
	f32 angle = 0;

	if (this.getTickSinceCreated() <= 4) // make it fly straight some time before falling
	{
		this.setVelocity(this.getOldVelocity());
	}

	if (isClient())
	{
		const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius()*0.12f, 360);
		CParticle@ p = ParticleAnimated("YellowParticle.png", pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(3), 0.0f, false);
		if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

		if (XORRandom(2) == 0)
		{
			ParticleAnimated("LargeSmoke", this.getPosition(), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, 90), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 3 + XORRandom(2), XORRandom(70) * -0.00005f, true);
		}
	}

	Vec2f velocity = this.getVelocity();
	angle = velocity.Angle();

	Pierce(this, velocity, angle);

	if (this.getTickSinceCreated() == 0) // return 0,0 onInit()
	{
		this.set_Vec2f("from_pos", this.getPosition());
		//printf("x: "+this.get_Vec2f("from_pos").x+" y: "+this.get_Vec2f("from_pos").y);
	}

	this.setAngleDegrees(-angle + 180.0f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CBlob@ carrier = blob.getCarriedBlob();

	if (blob.hasTag("structure") || blob.getName() == "log" || blob.hasTag("trap"))
	{
		return false;
	}

	if (blob.hasTag("flesh") && this.getTickSinceCreated() <= 1)
	{
		return false;
	}

	if ((blob.hasTag("bunker") || blob.hasTag("turret") || blob.hasTag("door")) && this.getTeamNum() == blob.getTeamNum())
	{
		return false;
	}
	
	if (blob.hasTag("vehicle") && this.getTeamNum() == blob.getTeamNum())
	{
		return false;
	}

	if (blob.hasTag("projectile"))
	{
		return false;
	}

	if (carrier !is null)
		if (carrier.hasTag("player")
		        && (this.getTeamNum() == carrier.getTeamNum() || blob.hasTag("temp blob")))
			return false;

	return (this.getTeamNum() != blob.getTeamNum() || blob.getShape().isStatic())
	       && blob.isCollidable();
}

void Pierce(CBlob@ this, Vec2f velocity, const f32 angle)
{
	CMap@ map = this.getMap();

	const f32 speed = velocity.getLength();
	const f32 damage = this.get_f32(projDamageString);

	Vec2f direction = velocity;
	direction.Normalize();

	Vec2f position = this.getPosition();
	Vec2f tip_position = position + direction * 13.0f;
	Vec2f middle_position = position + direction * 6.0f;
	Vec2f tail_position = position - direction * 12.0f;

	Vec2f[] positions =
	{
		position,
		tip_position,
		middle_position,
		tail_position
	};

	for (uint i = 0; i < positions.length; i ++)
	{
		Vec2f temp_position = positions[i];
		TileType type = map.getTile(temp_position).type;

		if (map.isTileSolid(type))
		{
			u32[]@ offsets;
			this.get("offsets", @offsets);
			const u32 offset = map.getTileOffset(temp_position);

			if (offsets.find(offset) != -1)
				continue;

			BallistaHitMap(this, offset, temp_position, velocity, damage, Hitters::ballista);
			this.server_HitMap(temp_position, velocity, damage, Hitters::ballista);
		}
	}

	HitInfo@[] infos;

	if (speed > 0.1f && map.getHitInfosFromArc(tail_position, -angle, 10, (tip_position - tail_position).getLength(), this, true, @infos))
	{
		for (uint i = 0; i < infos.length; i ++)
		{
			CBlob@ blob = infos[i].blob;
			Vec2f hit_position = infos[i].hitpos;

			if (blob !is null)
			{

				if (blob.getShape().getConsts().platform && !CollidesWithPlatform(this, blob, velocity))
					continue;

				if (!doesCollideWithBlob(this, blob) || LimitedAttack_has_hit_actor(this, blob))
					continue;

				BallistaHitBlob(this, hit_position, velocity, damage, blob, Hitters::ballista);
				LimitedAttack_add_actor(this, blob);
			}
		}
	}
}

bool DoExplosion(CBlob@ this, Vec2f velocity)
{
	if (this.hasTag("dead")) return true;

	float projExplosionRadius = this.get_f32(projExplosionRadiusString);
	float projExplosionDamage = this.get_f32(projExplosionDamageString);
	f32 length = this.get_f32("linear_length");
	//printf(""+projExplosionRadius);
	//printf(""+length);
	WarfareExplode(this, projExplosionRadius*1.35, projExplosionDamage);
	LinearExplosion(this, velocity, projExplosionRadius, length, 2+Maths::Floor(length/6), 0.01f, Hitters::fall);//only for damaging map
	
	this.getSprite().PlaySound("/ShellExplosion");

	Vec2f pos = this.getPosition();

	if (isClient())
	{
		for (int i = 0; i < 8; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(16) - 8, XORRandom(12) - 6), getRandomVelocity(0.0f, XORRandom(35) * 0.005f, 360) + Vec2f(0.0f, -0.8f), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 3 + XORRandom(4), XORRandom(45) * -0.00005f, true);
		}
		for (int i = 0; i < 4; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(15) * 0.005f, 360), float(XORRandom(360)), 0.75f + XORRandom(40) * 0.01f, 5 + XORRandom(6), XORRandom(30) * -0.0001f, true);
		}

		for (int i = 0; i < (15 + XORRandom(15)); i++)
		{
			makeGibParticle("GenericGibs", pos, getRandomVelocity((pos + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
		}
	}

	this.Tag("dead");
	this.server_Die();
	this.getSprite().Gib();

	return true;
}

void BallistaHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, f32 damage, CBlob@ blob, u8 customData)
{
	this.server_Hit(blob, hit_position, Vec2f(0,0), damage, Hitters::ballista, true); 
	
	for (int i = 0; i < (10 + XORRandom(5)); i++)
		{
			Vec2f velr = (velocity/6) + getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
	velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

	ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
	}

	if (DoExplosion(this, velocity)) return;
	if (!blob.getShape().isStatic()) return;

	this.setVelocity(velocity * 0.7f);
}

void BallistaHitMap(CBlob@ this, const u32 offset, Vec2f hit_position, Vec2f velocity, const f32 damage, u8 customData)
{
	if (DoExplosion(this, velocity)) return;

	CMap@ map = getMap();
	TileType type = map.getTile(offset).type;
	const f32 angle = velocity.Angle();

	if (type == CMap::tile_bedrock)
	{
		this.Tag("dead");
		this.server_Die();
		this.getSprite().Gib();
	}
	else if (!map.isTileGroundStuff(type))
	{
		if (map.getSectorAtPosition(hit_position, "no build") is null)
			map.server_DestroyTile(hit_position, 1.0f, this);

		u8 blocks_pierced = this.get_u8("blocks_pierced");
		const f32 speed = velocity.getLength();

		this.setVelocity(velocity * 0.5f);
		this.push("offsets", offset);

		if (speed > 10.0f && map.isTileWood(type))
		{
			this.set_u8("blocks_pierced", blocks_pierced + 1);
		}
	}
}

bool CollidesWithPlatform(CBlob@ this, CBlob@ blob, Vec2f velocity)
{
	f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}