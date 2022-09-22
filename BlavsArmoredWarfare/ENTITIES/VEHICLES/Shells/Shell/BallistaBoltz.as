#include "Hitters.as";
#include "ShieldCommon.as";
#include "LimitedAttacks.as";
#include "Explosionx.as";

const f32 MEDIUM_SPEED = 5.0f;

void onInit(CBlob@ this)
{
	this.set_u8("blocks_pierced", 0);
	this.set_bool("static", false);

	this.server_SetTimeToDie(11);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

	LimitedAttack_setup(this);

	u32[] offsets;
	this.set("offsets", offsets);
	// Offsets of the tiles that have been hit.

	this.Tag("projectile");
	this.getSprite().SetFrame(0);
	//this.getSprite().setRenderStyle(RenderStyle::additive);
	this.getSprite().getConsts().accurateLighting = true;
	this.getSprite().SetFacingLeft(!this.getSprite().isFacingLeft());

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

}

void onTick(CBlob@ this)
{
	f32 angle = 0;

	if (isClient())
	{
		const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius()*0.12f, 360);
		CParticle@ p = ParticleAnimated("YellowParticle.png", pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(3), 0.0f, false);
		if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

		if (XORRandom(2) == 0)
		{
			CMap@ map = getMap();
		
			ParticleAnimated("LargeSmoke", this.getPosition(), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, 90), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 3 + XORRandom(2), XORRandom(70) * -0.00005f, true);
		}
	}

	if (!this.get_bool("static"))
	{
		Vec2f velocity = this.getVelocity();
		angle = velocity.Angle();

		Pierce(this, velocity, angle);

		/*
		if (!this.hasTag("bomb"))
		{
			this.set_bool("map_damage_raycast", false);
			this.set_f32("map_damage_radius", 44.0f);

			this.Tag("bomb");
			this.getSprite().SetFrame(1);
		}
		*/
	}
	else
	{
		angle = Maths::get360DegreesFrom256(this.get_u8("angle"));

		this.setVelocity(Vec2f_zero);
		this.setPosition(Vec2f(this.get_f32("lock_x"), this.get_f32("lock_y")));
		this.getShape().SetStatic(true);
		this.doTickScripts = false;
	}

	this.setAngleDegrees(-angle + 180.0f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CBlob@ carrier = blob.getCarriedBlob();

	if (blob.hasTag("structure"))
	{
		return false;
	}

	if ((blob.hasTag("bunker") || blob.hasTag("door")) && this.getTeamNum() == blob.getTeamNum())
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
	const f32 damage = speed > MEDIUM_SPEED ? 4.0f : 3.5f;

	Vec2f direction = velocity;
	direction.Normalize();

	Vec2f position = this.getPosition();
	Vec2f tip_position = position + direction * 12.0f;
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

				//this.server_Hit(blob, hit_position, velocity, damage, Hitters::ballista, true);
				BallistaHitBlob(this, hit_position, velocity, damage, blob, Hitters::ballista);
				LimitedAttack_add_actor(this, blob);

			}
		}
	}
}

bool DoExplosion(CBlob@ this, Vec2f velocity)
{
	if (this.hasTag("dead"))
		return true;

	f32 mod = 1.0f;

	Explode(this, 20.0f*mod, 12.0f*(mod/2));
	LinearExplosion(this, velocity, 22.0f, 10.0f*mod, 9, 5.0f*mod, Hitters::fall);
	
	this.getSprite().PlaySound("/ShellExplosion");

	if (isClient())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();

		ParticleAnimated("BoomParticle", pos, Vec2f(0.0f, -0.1f), 0.0f, 1.0f, 3, XORRandom(70) * -0.00005f, true);
		
		for (int i = 0; i < 9; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(16) - 8, XORRandom(12) - 6), getRandomVelocity(0.0f, XORRandom(35) * 0.005f, 360) + Vec2f(0.0f, -0.8f), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 3 + XORRandom(4), XORRandom(45) * -0.00005f, true);
		}

		for (int i = 0; i < (15 + XORRandom(15)); i++)
		{
			makeGibParticle("GenericGibs", this.getPosition(), getRandomVelocity((this.getPosition() + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
		}
	}

	this.Tag("dead");
	this.server_Die();
	this.getSprite().Gib();

	return true;
}

void BallistaHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, const f32 damage, CBlob@ blob, u8 customData)
{
	
	if (DoExplosion(this, velocity)
	        || this.get_bool("static"))
		return;

	if (!blob.getShape().isStatic())
		return;



	if (blob.getHealth() > 0.0f)
	{

		const f32 angle = velocity.Angle();

		SetStatic(this, angle);

	}
	else this.setVelocity(velocity * 0.7f);
}

void BallistaHitMap(CBlob@ this, const u32 offset, Vec2f hit_position, Vec2f velocity, const f32 damage, u8 customData)
{

	if (DoExplosion(this, velocity)
	        || this.get_bool("static"))
		return;

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

		if (speed > 10.0f
		        && map.isTileWood(type))
			this.set_u8("blocks_pierced", blocks_pierced + 1);
		else SetStatic(this, angle);

	}
	else if (map.isTileSolid(type))
		SetStatic(this, angle);

}

void SetStatic(CBlob@ this, const f32 angle)
{
	Vec2f position = this.getPosition();

	this.set_u8("angle", Maths::get256DegreesFrom360(angle));
	this.set_bool("static", true);
	this.set_f32("lock_x", position.x);
	this.set_f32("lock_y", position.y);

	this.Sync("static", true);
	this.Sync("lock_x", true);
	this.Sync("lock_y", true);

	this.setVelocity(Vec2f_zero);
	this.setPosition(position);
	this.getShape().SetStatic(true);

	this.getCurrentScript().runFlags |= Script::remove_after_this;

	this.server_Die();
}

bool CollidesWithPlatform(CBlob@ this, CBlob@ blob, Vec2f velocity)
{
	f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}