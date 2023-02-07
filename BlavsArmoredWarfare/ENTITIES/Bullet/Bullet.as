#include "WarfareGlobal.as"
#include "Hitters.as";
#include "MakeDustParticle.as";
#include "CustomBlocks.as";

void onInit(CBlob@ this)
{
	if (!this.exists("bullet_damage_body")) { this.set_f32("bullet_damage_body", 0.15f); }
	if (!this.exists("bullet_damage_head")) { this.set_f32("bullet_damage_head", 0.4f); }

	this.Tag("projectile");
	this.Tag("bullet");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.ScaleBy(Vec2f(0.75f + (this.get_f32("bullet_damage_body")*0.5f), 1.0f));
	}

	this.SetMapEdgeFlags(u8(CBlob::map_collide_none | CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath));

	consts.net_threshold_multiplier = 10.0f;
}

void onTick(CBlob@ this)
{
	Vec2f v = (this.getVelocity() + this.getOldVelocity())/2;
	if (v.getLength() > 27.0)
	{
		this.getSprite().SetFrameIndex(2);
	}
	else if (v.getLength() > 19.0)
	{
		this.getSprite().SetFrameIndex(1);
	}
	else{
		this.getSprite().SetFrameIndex(0);
	}
	
	Vec2f pos = this.getPosition();
	CShape@ shape = this.getShape();
	Vec2f velocity = this.getVelocity();

	this.getSprite().SetVisible(this.getTickSinceCreated() >= XORRandom(2)+1);
	
	if (pos.x < 0.1f or pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

	f32 angle;
	angle = velocity.Angle();
	this.setAngleDegrees(-angle);

	if (shape.vellen > 0.0001f)
	{
		if (shape.vellen > 13.5f)
			shape.SetGravityScale(0.1f);
		else
			shape.SetGravityScale(Maths::Min(1.0f, 1.0f / (shape.vellen * 0.1f)));
	}

	if (this.isInWater())
	{
		this.setVelocity(velocity*0.94f);
	}
	else if (this.hasTag("rico"))
	{
		this.AddForce(Vec2f(0.0f, 0.5f));
	}
	else
	{
		this.AddForce(Vec2f(0.0f, 0.11f));
	}

	// collison with blobs
	HitInfo@[] infos;
	CMap@ map = this.getMap();
	if (isServer() && map.isTileSolid(map.getTile(this.getPosition()).type)) this.server_Die();
	if (map.getHitInfosFromArc(this.getPosition(), -angle, (this.getTickSinceCreated() > 4 ? 13 : (this.getTickSinceCreated() < 1 ? 70 : 35)), 27.0f, this, true, @infos))
	{
		for (uint i = 0; i < infos.length; i ++)
		{
			CBlob@ blob = infos[i].blob;
			Vec2f hit_position = infos[i].hitpos;

			if (blob !is null)
			{
				if (!doesCollideWithBlob(this, blob))
					continue;

				onHitBlob(this, hit_position, velocity, blob, Hitters::arrow);
				return;
			}
		}
	}

	// collison with map
	Vec2f end;
	if (this.getTickSinceCreated() > 0)
	{
		if (map.rayCastSolidNoBlobs(this.getPosition(), this.getPosition() + velocity, end))
		{
			onHitWorld(this, end);
		}
	}
	else
	{
		if (map.rayCastSolidNoBlobs(this.getPosition(), this.getPosition() + velocity, end))
		{
			onHitWorld(this, end);
		}
	}
}

void onHitWorld(CBlob@ this, Vec2f end)
{
	CMap@ map = getMap();
	this.setVelocity(this.getVelocity() * 0.8f);

	// chance to break a block. Will not touch "strong" tag for now.
	TileType tile = map.getTile(end).type;
	bool isStrong = this.hasTag("strong");
	if (isServer())
	{
		if (this.hasTag("shrapnel"))
		{
			if (tile == CMap::tile_wood)
			{
				map.server_DestroyTile(end, XORRandom(4)==0 ? 15.0f : 7.5f, this);
				this.server_Die();
			}
		}
		if (!isTileCompactedDirt(tile) && (((tile == CMap::tile_ground || isTileScrap(tile))
		&& XORRandom(100) <= 3) || (tile != CMap::tile_ground && tile <= 255 && XORRandom(100) < 10)))
		{
			if (map.getSectorAtPosition(end, "no build") is null)
			{
				map.server_DestroyTile(end, isStrong ? 1.5f : 0.65f, this);
			}
		}
	}

	if (XORRandom(100) < 25)
	{
		if (!this.hasTag("rico"))
		{
			this.Tag("rico");
			this.Tag("dead");

			if (!v_fastrender)
			{
				for (uint i = 0; i < 3+XORRandom(6); i ++)
				{
					Vec2f velr = this.getVelocity()/(XORRandom(5)+3.0f);
					velr += Vec2f(0.0f, -6.5f);
					velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

					ParticlePixel(end, velr, SColor(255, 255, 255, 0), true);
				}
			}

			Sound::Play("/BulletMetal" + XORRandom(4), this.getPosition(), 1.2f, 0.8f + XORRandom(40) * 0.01f);

			{ TileType tile = map.getTile(end + Vec2f(0, -1)).type;
			if (map.isTileSolid(tile)) this.AddForce(Vec2f(0.0f, 30.0f)); }

			{ TileType tile = map.getTile(end + Vec2f(0, 1)).type;
			if (map.isTileSolid(tile)) this.AddForce(Vec2f(0.0f, -30.0f)); }	

			{ TileType tile = map.getTile(end + Vec2f(-1, 0)).type;
			if (map.isTileSolid(tile)) this.AddForce(Vec2f(30.0f, 0.0f)); }

			{ TileType tile = map.getTile(end + Vec2f(1, 0)).type;
			if (map.isTileSolid(tile)) this.AddForce(Vec2f(-30.0f, 0.0f)); }

			this.server_SetTimeToDie(0.6);
		}

		return;
	}
	else
	{
		this.setVelocity(Vec2f_zero);

		ParticleAnimated("Smoke", end, Vec2f(0.0f, -0.1f), 0.0f, 1.0f, 5, XORRandom(70) * -0.00005f, true);

		Sound::Play("/BulletDirt" + XORRandom(3), this.getPosition(), 1.7f, 0.85f + XORRandom(25) * 0.01f);

		if (!v_fastrender)
		{
			CParticle@ p = ParticleAnimated("SparkParticle.png", this.getPosition(), Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(2), 0.0f, false);
			if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

			{ CParticle@ p = ParticleAnimated("BulletChunkParticle.png", end, Vec2f(0.5f - XORRandom(100)*0.01f,-0.5), XORRandom(360), 0.55f + XORRandom(50)*0.01f, 22+XORRandom(3), 0.2f, true);
			if (p !is null) { p.lighting = true; }}
		}

		u16 impact_angle = 33;

		//print("angle " + this.getAngleDegrees()); work on this

		{ TileType tile = map.getTile(end + Vec2f(0, -1)).type;
		if (map.isTileSolid(tile)) impact_angle = 180;}

		{ TileType tile = map.getTile(end + Vec2f(0, 1)).type;
		if (map.isTileSolid(tile)) impact_angle = 0;}

		{ TileType tile = map.getTile(end + Vec2f(-1, 0)).type;
		if (map.isTileSolid(tile)) impact_angle = 90;}

		{ TileType tile = map.getTile(end + Vec2f(1, 0)).type;
		if (map.isTileSolid(tile)) impact_angle = 270;}

		if (XORRandom(2) == 0 && !v_fastrender)
		{
			{ CParticle@ p = ParticleAnimated("BulletHitParticle1.png", end + Vec2f(0.0f, 1.0f), Vec2f(0,0), impact_angle, 0.55f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
			if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }}
		}

		this.server_Die();
	}
}

void onHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, CBlob@ blob, u8 customData)
{
	CSprite@ sprite = this.getSprite();
	f32 dmg = this.get_f32("bullet_damage_body");

	s8 finalRating = getFinalRating(this, blob.get_s8(armorRatingString), this.get_s8(penRatingString), blob.get_bool(hardShelledString), blob, hit_position);
	//print("rating: "+finalRating);

	const bool can_pierce = finalRating < 2;

	if (blob !is null)
	{
		if (blob.hasTag("vehicle"))
		{
			if (isServer()) this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), this.hasTag("strong") ? 0.75f : 0.25f, Hitters::builder);
		}
		else{
			// play sound
			if (blob.hasTag("flesh"))
			{
				if (isClient() && XORRandom(100) < 60)
				{
					sprite.PlaySound("Splat.ogg");
				}
			}
			else if (v_fastrender)
			{
				CParticle@ p = ParticleAnimated("SparkParticle.png", hit_position, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(5), 0.0f, false);
				if (p !is null)
				{
					p.diesoncollide = true;
					p.fastcollision = true;
					p.lighting = false;
					p.Z = 200.0f;
				}
			}
		}


		if (isServer() && this.getTeamNum() != blob.getTeamNum() && (blob.getName() == "wooden_platform" || blob.hasTag("door")))
		{
			if (blob.getName() != "stone_door")
			{
				// destroy doors. Will not touch "strong" tag for now.
				this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), this.hasTag("strong") ? 1.25f : 0.15f, Hitters::builder);
				this.server_Die();
			}
		}

		if (blob.hasTag("vehicle") && !this.hasTag("rico"))
		{
			this.Tag("dead");

			if (isClient() && XORRandom(101) < (can_pierce ? 20 : 35))
			{
				Vec2f velr = this.getVelocity()/(XORRandom(4)+2.5f);
				velr += Vec2f(0.0f, -3.0f);
				velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

				ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
			}

			if (!can_pierce)
			{
				this.Tag("rico");
				Sound::Play("/BulletRico" + (XORRandom(4) + 4), this.getPosition(), 1.4f, 0.85f + XORRandom(45) * 0.01f);
				this.setVelocity(this.getVelocity() * 1.05f);
				this.AddForce(Vec2f(3.5f-XORRandom(7), 5.0f-XORRandom(10)));

				if (!v_fastrender)
				{
					CParticle@ p = ParticleAnimated("PingParticle.png", hit_position, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(5), 0.0f, false);
					if (p !is null)
					{
						p.diesoncollide = true;
						p.fastcollision = true;
						p.lighting = false;
						p.Z = 200.0f;
					}
				}
			}
			else
			{ 
				Vec2f pos = this.getPosition() + Vec2f(this.getOldVelocity().x * 0.65f, 0.0f);
				pos += Vec2f(0.0f, this.getOldVelocity().y * 0.65f);

				if (!v_fastrender)
				{
					CParticle@ p = ParticleAnimated("PingParticle.png", pos, Vec2f(0,0), XORRandom(360), 0.75f + XORRandom(4) * 0.10f, 3, 0.0f, false);
					if (p !is null)
					{
						p.diesoncollide = true;
						p.fastcollision = true;
						p.lighting = false;
						p.Z = 200.0f;
					}
				}

				sprite.PlaySound("/BulletPene" + XORRandom(3), 0.9f, 0.8f + XORRandom(50) * 0.01f);
				
				if (isServer() && XORRandom(100)<50)
				{
					this.server_Die();
				}
				else
				{
					this.server_SetTimeToDie(0.5f);
				}
			}
		}
		
		if (blob.hasTag("flesh") && hit_position.y < blob.getPosition().y - 3.2f)
		{
			dmg = this.get_f32("bullet_damage_head");

			// hit helmet
			if (blob.get_string("equipment_head") == "helmet")
			{
				dmg *= 0.45;

				if (XORRandom(100) < 25)
				{
					this.Tag("rico");

					Sound::Play("/BulletRico" + XORRandom(4), this.getPosition(), 1.2f, 0.7f + XORRandom(60) * 0.01f);

					Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
					velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

					ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
					this.server_SetTimeToDie(0.35);

					dmg = 0;
				}
			}
		}

		if (!this.hasTag("strong"))
		{
			int creationTicks = this.getTickSinceCreated();
			if (creationTicks > 20) // less dmg offscreen
			{
				dmg *= 0.75f;
			}
			else if  (creationTicks > 14)
			{
				dmg *= 0.5f;
			}
		}

		if (!blob.hasTag("weakprop"))
		{
			this.server_Die();
		}
		else
		{
			this.setVelocity(velocity * 0.96f);
		}

		if (blob.hasTag("flesh"))
		{
			if (blob.getPlayer() !is null)
			{
				// player is using bloodthirsty
				if (getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Bloodthirsty")
				{
					dmg *= 1.20f; // take extra damage
				}
			}
		}

		if (dmg > 0.0f && !this.hasTag("rico"))
		{
			this.server_Hit(blob, hit_position, velocity, dmg, Hitters::arrow, false);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//if (isServer())
	{
		if (blob.hasTag("always bullet collide"))
		{
			if (blob.getTeamNum() != this.getTeamNum()) return false;
			return true;
		}

		if (blob.getTeamNum() == this.getTeamNum() && blob.hasTag("friendly_bullet_pass"))
		{
			return false;
		}

		if (this.getTickSinceCreated() < 2 && (blob.hasTag("vehicle") || blob.getName() == "sandbags"))
		{
			return false;
		}
	}

	if (blob.hasTag("vehicle"))
	{
		if (blob.getTeamNum() == this.getTeamNum())
		{
			this.IgnoreCollisionWhileOverlapped(blob, 10);
			if (blob.hasTag("apc") || blob.hasTag("turret")) return (XORRandom(100) > 70);
			else if (blob.hasTag("tank")) return (XORRandom(100) > 50);
			else if (blob.hasTag("gun")) return false;
			else return true;
		}
		else
		{
			onHitBlob(this, this.getPosition()+this.getVelocity(), this.getVelocity(), blob, Hitters::arrow);
			return false;
		}
	}
	
	//if (isServer())
	{
		if ((blob.hasTag("respawn") && blob.getName() != "importantarmory") || blob.hasTag("invincible"))
		{
			return false;
		}

		if (blob.hasTag("turret") && blob.getTeamNum() != this.getTeamNum())
		{
			return true;
		}

		if (blob.hasTag("destructable_nosoak"))
		{
			this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), 0.5f, Hitters::builder);
			return false;
		}

		if (blob.isAttached() && !blob.hasTag("player"))
		{
			return false;
		}

		if ((this.getTickSinceCreated() > 1 || blob.getTeamNum() != this.getTeamNum()) && blob.isAttached() && !blob.hasTag("covered"))
		{
			if (blob.hasTag("collidewithbullets")) return XORRandom(2)==0;
			if (XORRandom(8) == 0)
			{
				return true;
			}
			AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("GUNNER");
			if (point !is null && point.getOccupied() !is null && (point.getOccupied().getName() == "heavygun" || point.getOccupied().getName() == "gun") && blob.getTeamNum() != this.getTeamNum())
				return true;
		}

		if (blob.getName() == "trap_block")
		{
			return blob.getShape().getConsts().collidable;
		}

		if (blob.hasTag("trap"))
		{
			return false;
		}

		if (blob.isAttached())
		{
			if (blob.hasTag("collidewithbullets")) return true;
			return false;
		}

		if (blob.hasTag("bunker") && blob.getTeamNum() != this.getTeamNum())
		{
			return true;
		}

		if (blob.hasTag("door") && blob.getShape().getConsts().collidable)
		{
			return true;
		}

		if (blob.getName() == "wooden_platform" && blob.isCollidable())
		{
			f32 velx = this.getOldVelocity().x;
			f32 vely = this.getOldVelocity().y;
			f32 deg = blob.getAngleDegrees();

			if ((deg < 45.0f || deg > 315.0f) && vely > 0.0f) //up		
			{
				return true;
			}
			if ((deg > 45.0f && deg < 135.0f) && velx < 0.0f) //right
			{
				return true;
			}
			if ((deg > 135.0f && deg < 225.0f) && vely < 0.0f) //down
			{
				return true;
			}
			if ((deg > 225.0f && deg < 315.0f) && velx > 0.0f) //left
			{
				return true;
			}

			//printf("deg "+deg);
			//printf("velx "+velx);
			//printf("vely "+vely);

			return false;
		}

		if (blob.hasTag("destructable"))
		{
			return true;
		}

		if (blob.getShape().isStatic()) // this is annoying
		{
			return false;
		}

		if (this.getTeamNum() == blob.getTeamNum() && blob.hasTag("flesh"))
		{
			return false;
		}

		if (blob.hasTag("projectile") || this.hasTag("rico"))
		{
			return false;
		}

		if (blob.hasTag("blocks bullet"))
		{
			return true;
		}

		bool check = this.getTeamNum() != blob.getTeamNum();
		if (!check)
		{
			CShape@ shape = blob.getShape();
			check = (shape.isStatic() && !shape.getConsts().platform);
		}

		if (check)
		{
			if (blob.hasTag("dead"))
			{
				return false;
			}
			else
			{
				return true;
			}
		}
	}

	return true;
}

void BulletHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	Sound::Play("/BulletDirt" + XORRandom(3), this.getPosition(), 1.4f, 0.85f + XORRandom(25) * 0.01f);

	this.server_Die();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0.0f; //no cut arrows
}
/*
void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (this !is hitBlob)
	{
		const f32 scale = 0.5f;

		Vec2f vel = velocity;
		const f32 speed = vel.Normalize();
		if (speed > 6.5f)
		{
			f32 force = 0.07f * Maths::Sqrt(hitBlob.getMass() + 1) * scale;
		}
	}
}