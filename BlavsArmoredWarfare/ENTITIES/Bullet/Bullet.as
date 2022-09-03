#include "Hitters.as";
#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	if (!this.exists("bullet_damage_body")) { this.set_f32("bullet_damage_body", 0.125f); }
	if (!this.exists("bullet_damage_head")) { this.set_f32("bullet_damage_head", 0.5f); }

	this.Tag("projectile");

	// glow
	this.SetLight(true);
	this.SetLightRadius(30.0f);
	this.SetLightColor(SColor(255, 255, 240, 210));

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;	

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	consts.net_threshold_multiplier = 1.0f;
}

void onTick(CBlob@ this)
{
	CShape@ shape = this.getShape();
	Vec2f velocity = this.getVelocity();

	this.getSprite().SetVisible(this.getTickSinceCreated() >= XORRandom(2)+1);

	Vec2f pos = this.getPosition();
	if (pos.x < 0.1f || pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
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
		this.AddForce(Vec2f(0.0f, 0.1f)); //0.20
	}
	
	// collison with blobs
	HitInfo@[] infos;
	CMap@ map = this.getMap();
	if (isServer() && map.isTileSolid(map.getTile(this.getPosition()).type)) this.server_Die();
	if (map.getHitInfosFromArc(this.getPosition(), -angle, 12, 24.0f, this, true, @infos))
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
	if (map.rayCastSolidNoBlobs(this.getPosition(), this.getPosition() + velocity, end))
	{
		onHitWorld(this, end);
	}
}

void onHitWorld(CBlob@ this, Vec2f end)
{
	CMap@ map = getMap();
	this.setVelocity(this.getVelocity() * 0.8f);

	if (XORRandom(100) < 25) //28
	{
		if (!this.hasTag("rico"))
		{
			this.Tag("rico");
			this.Tag("dead");

			for (uint i = 0; i < 3+XORRandom(6); i ++)
			{
				Vec2f velr = this.getVelocity()/(XORRandom(5)+3.0f);
				velr += Vec2f(0.0f, -6.5f);
				velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

				ParticlePixel(end, velr, SColor(255, 255, 255, 0), true);
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
			//this.setPosition(end);
		}

		return;
	}
	else
	{
		//this.setPosition(end);
		this.setVelocity(Vec2f_zero);

		ParticleAnimated("Smoke", end, Vec2f(0.0f, -0.1f), 0.0f, 1.0f, 5, XORRandom(70) * -0.00005f, true);

		Sound::Play("/BulletDirt" + XORRandom(3), this.getPosition(), 1.6f, 0.85f + XORRandom(25) * 0.01f);

		CParticle@ p = ParticleAnimated("SparkParticle.png", this.getPosition(), Vec2f(0,0),  0.0f, 1.0f, 2+XORRandom(2), 0.0f, false);
		if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

		{ CParticle@ p = ParticleAnimated("BulletChunkParticle.png", end, Vec2f(0.5f - XORRandom(100)*0.01f,-0.5), 0.0f, 0.55f + XORRandom(50)*0.01f, 22+XORRandom(3), 0.2f, true);
		if (p !is null) { p.lighting = true; }}

		u16 impact_angle = 33;

		//print("angle " + this.getAngleDegrees()); work on this

		bool isStrong = this.hasTag("strong") && map.isTileWood(map.getTile(this.getPosition()).type);

		{ TileType tile = map.getTile(end + Vec2f(0, -1)).type;
		if (map.isTileSolid(tile)) impact_angle = 180;}

		{ TileType tile = map.getTile(end + Vec2f(0, 1)).type;
		if (map.isTileSolid(tile)) impact_angle = 0;}

		{ TileType tile = map.getTile(end + Vec2f(-1, 0)).type;
		if (map.isTileSolid(tile)) impact_angle = 90;}

		{ TileType tile = map.getTile(end + Vec2f(1, 0)).type;
		if (map.isTileSolid(tile)) impact_angle = 270;}

		if (XORRandom(2) == 0)
		{
			{ CParticle@ p = ParticleAnimated("BulletHitParticle1.png", end + Vec2f(0.0f, 1.0f), Vec2f(0,0), impact_angle, 0.55f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
			if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }}
		}

		// chance to break a block
		
		if (XORRandom(100) < Maths::Min((isStrong ? 100 : 40) * this.get_f32("bullet_damage_head"), (isStrong ? 100 : 30)))
		{
			if (map.getSectorAtPosition(this.getPosition(), "no build") is null && !map.isTileCastle(map.getTile(this.getPosition()).type))
			{
				map.server_DestroyTile(this.getPosition(), isStrong ? 1.5f : 0.25f, this);
			}
		}

		this.server_Die();
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	//if (!isServer() || !solid) return;
	//this.server_Die();
}

void onHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, CBlob@ blob, u8 customData)
{
	f32 dmg = 0.0f;
		
	if (blob.getTeamNum() != this.getTeamNum())
	{
		dmg = this.get_f32("bullet_damage_body");
	}

	if (blob !is null)
	{
		// play sound
		if (blob.hasTag("flesh"))
		{
			if (isClient() && XORRandom(100) < 60)
			{
				this.getSprite().PlaySound("Splat.ogg");
			}
		}

		/*
		CPlayer@ player = this.getDamageOwnerPlayer();

		if (player.getBlob() !is null)
		{
			if (player.hasTag("Hollow"))
			{
				dmg *= 1.5;
			}
		}*/
	}

	if (isServer() && this.getTeamNum() != blob.getTeamNum() && (blob.getName() == "wooden_platform" || blob.hasTag("door")))
	{
		if (blob.getName() != "stone_door")
		{
			this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), this.hasTag("strong") ? 1.0f : 0.25f, Hitters::builder);
			this.server_Die();
		}
	}

	CParticle@ p = ParticleAnimated("SparkParticle.png", hit_position, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), 0.0f, false);
	if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

	if (blob.hasTag("vehicle") && !blob.hasTag("takesdmgfrombullet") && !this.hasTag("rico"))
	{
		this.Tag("rico");
		this.Tag("dead");

		if (blob.getName() == "uh1")
		{
			this.getSprite().PlaySound("/BulletPene" + XORRandom(3), 0.9f, 0.8f + XORRandom(50) * 0.01f);
			this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), 0.15f, Hitters::arrow);
		}

		if (XORRandom(101) < (blob.hasTag("takesdmgfrombullets") ? 20 : 35))
		{
			Vec2f velr = this.getVelocity()/(XORRandom(4)+2.5f);
			velr += Vec2f(0.0f, -3.0f);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

			ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
		}

		if (XORRandom(101) < (blob.hasTag("takesdmgfrombullets") ? 10 : 45))
		{
			Sound::Play("/BulletRico" + (XORRandom(4) + 4), this.getPosition(), 1.4f, 0.85f + XORRandom(45) * 0.01f);
			this.setVelocity(this.getVelocity() * 1.05f);
			this.AddForce(Vec2f(3.5f-XORRandom(7), 5.0f-XORRandom(10)));
		}
		else
		{ 
			Vec2f pos = this.getPosition() + Vec2f(this.getOldVelocity().x * 0.65f, 0.0f);
			pos += Vec2f(0.0f, this.getOldVelocity().y * 0.65f);

			CParticle@ p = ParticleAnimated("PingParticle.png", pos, Vec2f(0,0),  0.0f, 0.75f + XORRandom(4) * 0.10f, 2, 0.0f, false);
			if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }

			if (blob.hasTag("takesdmgfrombullets"))
			{
				this.getSprite().PlaySound("/BulletPene" + XORRandom(3), 0.9f, 0.8f + XORRandom(50) * 0.01f);
				this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), 0.5f, Hitters::arrow);
			}
			else
			{
				this.getSprite().PlaySound("/BulletRico" + XORRandom(4), 0.8f, 0.7f + XORRandom(60) * 0.01f);
			}
			
			this.server_Die();
		}

		this.server_SetTimeToDie(0.4);
	}
	
	if (hit_position.y < blob.getPosition().y - 3.2f)
	{
		dmg = this.get_f32("bullet_damage_head");

		// hit helmet
		if (blob.get_string("equipment_head") == "helmet" || blob.get_string("equipment_head") == "goldenhelmet")
		{
			dmg*=0.6;

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
	else
	{
		dmg = this.get_f32("bullet_damage_body");
	}

	

	if (!blob.hasTag("weakprop"))
	{
		dmg *= 2.0f;

		this.server_Die();
	}
	else
	{
		this.setVelocity(velocity * 0.96f);
	}

	if (dmg > 0.0f && !this.hasTag("rico"))
	{
		this.server_Hit(blob, hit_position, velocity, dmg, Hitters::arrow);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("respawn") || blob.hasTag("invincible"))
	{
		return false;
	}

	if (this.getTickSinceCreated() > 1 && blob.isAttached())
	{
		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("GUNNER");
		if (point !is null && point.getOccupied() !is null && (point.getOccupied().getName() == "heavygun" || point.getOccupied().getName() == "gun"))
			return true;
	}
	
	if (blob.hasTag("trap"))
	{
		return false;
	}
	
	if (blob.isAttached() && !blob.hasTag("turret"))
	{
		return false;
	}

	if (blob.hasTag("vehicle") && blob.hasTag("takesdmgfrombullet") && blob.getTeamNum() == this.getTeamNum())
	{
		return false;
	}

	if (blob.hasTag("blocks bullet"))
	{
		return true;
	}

	if (blob.hasTag("bunker") && blob.getTeamNum() != this.getTeamNum())
	{
		return true;
	}

	if (blob.hasTag("door") && blob.getShape().getConsts().collidable)
	{
		return true;
	}

	if (blob.getName() == "wooden_platform")
	{
		//printf("enter");
		f32 velx = this.getVelocity().x;
		f32 vely = this.getVelocity().y;
		f32 deg = blob.getAngleDegrees();

		if ((deg < 45.0f || deg > 315.0f) && vely > 0.0f) //up		
		{
			blob.Tag("takesdmgfrombullet");
			return true;
		}
		else if (deg > 45.0f && deg < 135.0f && velx < 0.0f) //right
		{
			blob.Tag("takesdmgfrombullet");
			return true;
		}
		else if (deg > 135.0f && deg < 225.0f && vely < 0.0f) //down
		{
			blob.Tag("takesdmgfrombullet");
			return true;
		}
		else if (deg > 225.0f && deg < 315.0f && velx > 0.0f) //left
		{
			blob.Tag("takesdmgfrombullet");
			return true;
		}

		//printf("deg "+deg);
		//printf("velx "+velx);
		//printf("vely "+vely);

		return false;
	}

	if (this.getTickSinceCreated() < 2 && (blob.hasTag("vehicle") || blob.getName() == "sandbags"))
	{
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

	return true;
}

void BulletHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	Sound::Play("/BulletDirt" + XORRandom(3), this.getPosition(), 1.4f, 0.85f + XORRandom(25) * 0.01f);

	this.server_Die();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::sword)
	{
		return 0.0f; //no cut arrows
	}

	return damage;
}

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

			//hitBlob.AddForce(velocity * force);
		}
	}
}