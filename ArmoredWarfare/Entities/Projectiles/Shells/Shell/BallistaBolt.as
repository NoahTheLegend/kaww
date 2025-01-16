#include "WarfareGlobal.as"
#include "Hitters.as";
#include "HittersAW.as";
#include "ShieldCommon.as";
#include "LimitedAttacks.as";
#include "Explosion.as";
#include "CustomBlocks.as";

const f32 MEDIUM_SPEED = 5.0f;
const f32 linger_time = 2.0f;

void onInit(CBlob@ this)
{
	this.Tag("projectile");

	this.set_u8("blocks_pierced", 0);
	this.set_bool("map_damage_raycast", true);

	// Set impact damage modifier
	f32 impact_damage_mod = this.exists("scale_impact_damage") && this.get_f32("scale_impact_damage") > 0.05f 
							? this.get_f32("scale_impact_damage") 
							: 1.0f;

	// Set impact radius
	f32 impact_radius = this.exists("impact_radius") && this.get_f32("impact_radius") > 0.05f 
						? this.get_f32("impact_radius") 
						: -1.0f;

	// Set projectile properties
	this.set_f32(projDamageString, 1.0f * impact_damage_mod);
	this.set_f32(projExplosionRadiusString, impact_radius != -1 ? impact_radius : 20.0f);
	this.set_f32(projExplosionDamageString, 15.0f * impact_damage_mod);

	bool he_shell = isHEProjectile(this);
	bool apc = isAPCProjectile(this);
	if (he_shell) this.set_f32(projExplosionRadiusString, 42.0f);
	if (apc) this.set_f32("tile_damage", 0.1f);

	// Configure shape properties
	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 2.0f;

	LimitedAttack_setup(this);

	// Initialize offsets array
	u32[] offsets;
	this.set("offsets", offsets);

	// Configure sprite properties
	CSprite@ sprite = this.getSprite();
	sprite.SetFrame(0);
	sprite.getConsts().accurateLighting = true;
	sprite.SetFacingLeft(!sprite.isFacingLeft());

	#ifdef STAGING
	sprite.setRenderStyle(RenderStyle::additive);
	#endif

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
	this.server_SetTimeToDie(apc ? 3 : 30);
}

void onTick(CBlob@ this)
{
	//this.setPosition(Vec2f(this.getPosition().x, this.getOldPosition().y)); // useful for debugging

	CMap@ map = getMap();
	Vec2f velocity = this.getVelocity();

	f32 angle = 0;
	angle = velocity.Angle();

	// lingering
	if (this.hasTag("idle"))
	{
		this.setVelocity(Vec2f_zero);
		this.getSprite().SetVisible(false);
		this.getShape().SetStatic(true);

		if (this.getTimeToDie() <= 1.0f)
		{
			ResetPlayer(this);
		}

		return;
	}
	
	if (map !is null)
	{
		if (this.getPosition().y + this.getVelocity().y >= map.tilemapheight * 8
			&& this.getPlayer() !is null)
		{
			ResetPlayer(this);
		}
	}

	// fly straight some time
	if (this.getTickSinceCreated() <= 7) this.setVelocity(this.getOldVelocity());

	if (isClient() && !v_fastrender)
	{
		Vec2f pos = this.getPosition();

		for (u8 i = 0; i < 3; i++)
		{
			CParticle@ trail = ParticlePixelUnlimited(pos+Vec2f(XORRandom(12)-6,
				XORRandom(4)-2)-this.getVelocity(), this.getVelocity()/2, SColor(255,255,175+XORRandom(75),0), false);
			if (trail !is null)
			{
				trail.deadeffect = -1;
				trail.collides = false;
				trail.fastcollision = true;
				trail.setRenderStyle(RenderStyle::additive);
				trail.gravity = Vec2f_zero;
				trail.damping = 0.9f + XORRandom(51)*0.001f;
				trail.timeout = 5+XORRandom(6);
			}
		}

		if (this.hasTag("rpg")) // smoke trail
		{
			if (this.getTickSinceCreated() > 0)
			{
				CParticle@ p = ParticleAnimated("LargeSmoke", pos - this.getVelocity(), this.getVelocity() * -0.1f, 180 + -this.getVelocity().Angle()-90 + XORRandom(11)-10, 0.4f + XORRandom(40) * 0.01f, 3 + XORRandom(21) * 0.1f, XORRandom(70) * -0.00005f, true);
				if (p !is null)
				{
					p.collides = false;
					p.fastcollision = true;
					p.growth = -0.01f;
					p.damping = 0.85f;
					p.frame = 5;
					p.Z = 550.0f;
				}
			}
			else
			{
				for (u8 i = 0; i < 10; i++)
				{
					if (XORRandom(4) == 0) continue;

					f32 rangle = XORRandom(51)-25;
					CParticle@ p = ParticleAnimated("DustSmallDark.png",
						pos - this.getVelocity() - Vec2f(-4,0).RotateBy(this.getAngleDegrees()),
							-this.getVelocity().RotateBy(rangle) * 0.33f,
								this.getVelocity().Angle() + rangle,
									0.5f + XORRandom(51) * 0.01f, 4 + XORRandom(3), 0, false);
					if (p !is null)
					{
						p.damping = 0.5f;
						p.collides = false;
						p.fastcollision = true;
						p.growth = -0.025f;
						p.frame = 3;
						p.Z = 550.0f;
					}
				}
			}

			if (this.getTickSinceCreated() < 5)
			{
				CParticle@ p1 = ParticleAnimated("DustSmallDark.png", pos - this.getVelocity(), -this.getVelocity()*XORRandom(4)*0.005f, this.getVelocity().Angle(), 1.0f, 5 + XORRandom(2), 0, false);
				if (p1 !is null)
				{
					p1.collides = false;
					p1.fastcollision = true;
					p1.growth = -0.01f;
					p1.scale = 0.75f + (XORRandom(11)-5) * 0.1f;
					p1.deadeffect = -1;
					p1.Z = 550.0f;
				}
			}
		}
	}

	Pierce(this, velocity, angle); // pierce tiles

	if (this.getTickSinceCreated() == 0) this.set_Vec2f("from_pos", this.getPosition());
	this.setAngleDegrees(-angle + 180.0f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.hasTag("idle")) return false;
	CBlob@ carrier = blob.getCarriedBlob();

	if ((blob.hasTag("turret") || blob.hasTag("sandbags"))
		&& blob.getTeamNum() != this.getTeamNum())
	{
		return true;
	}

	if (blob.hasTag("passable") && !this.hasTag("rpg"))
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

	if ((blob.hasTag("vehicle") && this.getTeamNum() == blob.getTeamNum()))
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
	if (this.hasTag("idle")) return;
	CMap@ map = this.getMap();

	const f32 speed = velocity.getLength();
	const f32 damage = this.get_f32(projDamageString);

	Vec2f direction = velocity;
	direction.Normalize();

	Vec2f position = this.getPosition();
	Vec2f tip_position = position + direction * 13.0f;
	Vec2f middle_position = position + direction * 6.0f;
	Vec2f tail_position = position - direction * 8.0f;

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
				this.Tag("weaken");
				DoExplosion(this, this.getVelocity());

				this.Tag("dead");
				SetDeath(this);
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

void ResetPlayer(CBlob@ this)
{
	if (isServer() && this.get_u16("ownerblob_id") != 0)
	{
		CPlayer@ ply = getPlayerByNetworkId(this.get_u16("ownerplayer_id"));
		CBlob@ blob = getBlobByNetworkID(this.get_u16("ownerblob_id"));
		if (blob !is null && ply !is null && !blob.hasTag("dead"))
		{
			blob.Untag("camera_offset");
			blob.server_SetPlayer(ply);
		}

		this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	if (isServer() && !this.hasTag("idle") && this.hasTag("artillery"))
	{
		CBlob@ b = server_CreateBlob("cheapfuckparticles_explosion", this.getTeamNum(), this.getPosition());
	}
}

bool DoExplosion(CBlob@ this, Vec2f velocity)
{
	if (this.hasTag("idle")) return false;
	if (this.hasTag("dead")) return true;

	float projExplosionRadius = this.get_f32(projExplosionRadiusString);
	if (this.hasTag("weaken")) projExplosionRadius *= 0.5f;

	float projExplosionDamage = this.get_f32(projExplosionDamageString);
	f32 length = this.get_f32("linear_length");

	//printf(""+projExplosionRadius);
	//printf(""+length);

	WarfareExplode(this, projExplosionRadius*1.35, projExplosionDamage);
	LinearExplosion(this, velocity, length, projExplosionRadius, 2+Maths::Floor(length/6), 0.01f, Hitters::fall); // only for damaging map
	
	if (this.hasTag("rpg"))
	{
		if (!this.hasTag("artillery"))
			this.getSprite().PlaySound("/RpgExplosion", 1.1, 0.9f + XORRandom(20) * 0.01f);
	}
	else // smaller shell
	{
		this.getSprite().PlayRandomSound("/MediumShellExplosion.ogg", 1.0, 0.9f + XORRandom(20) * 0.01f);
	}

	Vec2f pos = this.getPosition();
	bool is_artillery = isArtilleryProjectile(this);

	if (is_artillery && this.isMyPlayer())
	{
		CRules@ rules = getRules();
		if (rules !is null)
		{
			Vec2f[]@ artillery_explosions;
			if (rules.get("artillery_explosions", @artillery_explosions))
			{
				artillery_explosions.push_back(this.getPosition());
				rules.Tag("artillery_exploded");
			}

			CBitStream params;
			params.write_Vec2f(pos);
			rules.SendCommand(rules.getCommandID("add_artillery_explosion"), params);
		}
	}

	if (isClient() && !is_artillery && !isAPCProjectile(this)) // hacked particles cast with createblob, dont play it twice
	{
		for (int i = 0; i < 8; i++)
		{
			CParticle@ p = ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(16) - 8, XORRandom(12) - 6), getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + Vec2f(0.0f, -0.8f), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 3 + XORRandom(4), XORRandom(45) * -0.00005f, true);
			if (p !is null) p.Z = 550.0f;
		}
		for (int i = 0; i < 4; i++)
		{
			CParticle@ p = ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(20) * 0.005f, 360), float(XORRandom(360)), 0.75f + XORRandom(40) * 0.01f, 5 + XORRandom(6), XORRandom(30) * -0.0001f, true);
			if (p !is null) p.Z = 550.0f;
		}

		for (int i = 0; i < (v_fastrender ? 4 + XORRandom (4) : 8 + XORRandom(7)); i++)
		{
			makeGibParticle("GenericGibs", pos - Vec2f(0, 2), this.getOldVelocity()/5 + getRandomVelocity((pos + Vec2f(XORRandom(24) - 12, 0.0f)).getAngle(), 1.0f + XORRandom(4), 360.0f) + Vec2f(0.0f, -5.0f),
	                2, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
		}
	}

	Boom(this);

	this.Tag("dead");
	SetDeath(this);

	if (!v_fastrender) this.getSprite().Gib();

	return true;
}

bool isHEProjectile(CBlob@ this)
{
	return this.hasTag("HE_shell");
}

bool isArtilleryProjectile(CBlob@ this)
{
	return this.hasTag("artillery");
}

bool isAPCProjectile(CBlob@ this)
{
	return this.hasTag("small_bolt");
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

void SetDeath(CBlob@ this)
{
	if (this.getPlayer() !is null)
	{
		if (!this.hasTag("idle"))
		{
			this.Tag("idle");

			this.server_SetTimeToDie(linger_time + 1);
		}
	}
	else this.server_Die();
}

void BallistaHitMap(CBlob@ this, const u32 offset, Vec2f hit_position, Vec2f velocity, const f32 damage, u8 customData)
{
	if (this.hasTag("idle")) return;

	if (!this.hasTag("soundplayed") && !isAPCProjectile(this))
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

		SetDeath(this);
		this.getSprite().Gib();
	}
	
	else if (!map.isTileGroundStuff(type) && !isAPCProjectile(this))
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

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("idle")) return 0;
	
	if (this.getPlayer() !is null && customData == 11) return 0;
	return damage;
}

void Boom(CBlob@ this)
{
	if (isAPCProjectile(this)) return;
	
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