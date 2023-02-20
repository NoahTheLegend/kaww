#include "WarfareGlobal.as"
#include "Hitters.as";
#include "ShieldCommon.as";
#include "LimitedAttacks.as";
#include "Explosion.as";
#include "CustomBlocks.as";

const f32 MEDIUM_SPEED = 5.0f;

void onInit(CBlob@ this)
{
	this.Tag("projectile");

	f32 damage_mod = 1.0f;
	if (this.exists("damage_modifier") && this.get_f32("damage_modifier") > 0.05f) damage_mod = this.get_f32("damage_modifier");
	this.set_f32(projDamageString, 1.0f);
	this.set_f32(projExplosionRadiusString, 20.0f);
	this.set_f32(projExplosionDamageString, 15.0f*damage_mod);

	if (this.hasTag("HE_shell"))
	{
		this.set_f32(projExplosionRadiusString, 42.0f);
	}

	this.set_u8("blocks_pierced", 0);
	this.set_bool("map_damage_raycast", true);

	this.server_SetTimeToDie(12);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 6.0f;

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
	//this.setPosition(Vec2f(this.getPosition().x, this.getOldPosition().y)); // useful for debugging
	f32 angle = 0;

	if (this.getTickSinceCreated() <= 6) // make it fly straight some time before falling
	{
		this.setVelocity(this.getOldVelocity());
	}

	if (isClient())
	{
		if (this.hasTag("rpg"))
		{
			ParticleAnimated("LargeSmoke", this.getPosition(), this.getVelocity() * -0.4f + getRandomVelocity(0.0f, XORRandom(80) * 0.01f, 90), float(XORRandom(360)), 0.4f + XORRandom(40) * 0.01f, 1, XORRandom(70) * -0.00005f, true);
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

	if (blob.hasTag("turret") && blob.getTeamNum() != this.getTeamNum())
	{
		return true;
	}

	if (blob.hasTag("passable"))
	{
		if (isServer()) this.server_Hit(blob, blob.getPosition(), Vec2f(0,0), 2.5f, Hitters::ballista, true); 
		return false;
	}

	if (blob.hasScript("IgnoreDamage.as"))
	{
		return false;
	}

	if (blob.hasTag("broken") || blob.hasTag("dead"))
	{
		return false;
	}

	if (blob.hasTag("structure") || blob.getName() == "log" || blob.hasTag("trap") || blob.hasTag("material"))
	{
		return false;
	}

	if (blob.hasTag("flesh") && this.getTickSinceCreated() <= 1)
	{
		return false;
	}

	if (blob.hasTag("bunker") && this.getTeamNum() == blob.getTeamNum())
	{
		return false;
	}
	
	if (blob.hasTag("door") && blob.getShape().getConsts().collidable)
	{
		return true;
	}

	if ((blob.hasTag("vehicle") && this.getTeamNum() == blob.getTeamNum()) || (blob.hasTag("aerial") && this.hasTag("artillery_shell")))
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

		if (map.isTileSolid(type) || type > 255)
		{
			u32[]@ offsets;
			this.get("offsets", @offsets);
			const u32 offset = map.getTileOffset(temp_position);

			if (offsets.find(offset) != -1)
				continue;

			if (!isTileCompactedDirt(type) && !isTileScrap(type))
			{
				BallistaHitMap(this, offset, temp_position, velocity, damage, Hitters::ballista);
				this.server_HitMap(temp_position, velocity, damage, Hitters::ballista);
			}
			else
			{
				{
					this.Tag("weaken");
					DoExplosion(this, this.getVelocity());
					this.Tag("dead");
					this.server_Die();
				}
			}
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
	if (this.hasTag("weaken")) projExplosionRadius *= 0.75f;
	float projExplosionDamage = this.get_f32(projExplosionDamageString);
	f32 length = this.get_f32("linear_length");
	//printf(""+projExplosionRadius);
	//printf(""+length);
	WarfareExplode(this, projExplosionRadius*1.35, projExplosionDamage);
	LinearExplosion(this, velocity, projExplosionRadius, length, 2+Maths::Floor(length/6), 0.01f, Hitters::fall); // only for damaging map
	
	if (this.hasTag("rpg"))
	{
		this.getSprite().PlaySound("/RpgExplosion", 1.1, 0.9f + XORRandom(20) * 0.01f);
	}
	else // smaller shell
	{ // why tf is this not working? sounds are not playing
		this.getSprite().PlayRandomSound("/MediumShellExplosion.ogg", 1.0, 0.9f + XORRandom(20) * 0.01f);
	}

	Vec2f pos = this.getPosition();

	if (isClient())
	{
		for (int i = 0; i < 8; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(16) - 8, XORRandom(12) - 6), getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + Vec2f(0.0f, -0.8f), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 3 + XORRandom(4), XORRandom(45) * -0.00005f, true);
		}
		for (int i = 0; i < 4; i++)
		{
			ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(20) * 0.005f, 360), float(XORRandom(360)), 0.75f + XORRandom(40) * 0.01f, 5 + XORRandom(6), XORRandom(30) * -0.0001f, true);
		}

		for (int i = 0; i < (20 + XORRandom(20)); i++)
		{
			makeGibParticle("GenericGibs", pos - Vec2f(0, 2), this.getOldVelocity()/5 + getRandomVelocity((pos + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
		}
	}

	Boom(this);

	this.Tag("dead");
	this.server_Die();
	if (!v_fastrender) this.getSprite().Gib();

	return true;
}

void BallistaHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, f32 damage, CBlob@ blob, u8 customData)
{
	this.server_Hit(blob, hit_position, Vec2f(0,0), damage, Hitters::ballista, true); 
	
	for (int i = 0; i < (10 + XORRandom(5)); i++)
		{
			Vec2f velr = (velocity/6) + getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
	velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

	if (!v_fastrender) ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
	}

	if (DoExplosion(this, velocity)) return;
	if (!blob.getShape().isStatic()) return;

	this.setVelocity(velocity * 0.7f);
}

void BallistaHitMap(CBlob@ this, const u32 offset, Vec2f hit_position, Vec2f velocity, const f32 damage, u8 customData)
{
	if (!this.hasTag("soundplayed"))
	{
		this.getSprite().PlayRandomSound("/ShellExplosion", 1.1, 0.9f + XORRandom(20) * 0.01f);
		this.Tag("soundplayed");
	}
	if (DoExplosion(this, velocity)) return;

	CMap@ map = getMap();
	TileType type = map.getTile(offset).type;
	const f32 angle = velocity.Angle();

	if (type == CMap::tile_bedrock || isTileCompactedDirt(type) || isTileScrap(type))
	{
		this.Tag("weaken");
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

void Boom(CBlob@ this)
{
	if (getNet().isClient()) {
		// screenshake effect when close to the explosion

		CBlob @blob = getLocalPlayerBlob();
		CPlayer @player = getLocalPlayer();
		Vec2f pos;

	    CCamera @camera = getCamera();
		if (camera !is null) {
			float mod = 0.9f;
			// If the player is a spectating, base their location off of their camera.	
			if (player !is null && player.getTeamNum() == getRules().getSpectatorTeamNum())
			{
				mod *= 0.6; // less shake
				pos = camera.getPosition();
			}
			else if (blob !is null)
			{
				pos = blob.getPosition();
			} 
			else 
			{
				return;
			}

			mod *= this.get_f32(projExplosionDamageString) / 10;

			

			pos -= this.getPosition();
			f32 dist = pos.Length();
			if (dist < 400) {
				ShakeScreen((250 - dist/2) * mod, 50, this.getPosition());
			}
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