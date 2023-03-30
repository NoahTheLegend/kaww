#include "WarfareGlobal.as"
#include "Hitters.as";
#include "MakeDustParticle.as";
#include "CustomBlocks.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.1f);

	if (isServer())
	{
		CPlayer@ p = this.getDamageOwnerPlayer();
		if (p !is null && p.getBlob() !is null)
		{
			p.Tag("created");
		}
	}
	
	if (!this.exists("bullet_damage_body")) { this.set_f32("bullet_damage_body", 0.15f); }
	if (!this.exists("bullet_damage_head")) { this.set_f32("bullet_damage_head", 0.4f); }

	CSprite@ sprite = this.getSprite();
	if (sprite !is null) {
		sprite.ResetTransform();

		f32 scale = 1.0f;
		this.hasTag("strong") ? scale = 1.33f : this.hasTag("shrapnel") ? scale = 0.66f : scale = 1.0f;

		sprite.ScaleBy(Vec2f(scale,1.0f));
		sprite.SetZ(550.0f);
	}

	this.Tag("projectile");
	this.Tag("bullet");

	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;

	this.SetMapEdgeFlags(u8(CBlob::map_collide_none | CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath));

	consts.net_threshold_multiplier = 10.0f;
}
	

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	if (map is null) return;

	CShape@ shape = this.getShape();
	if (shape is null) return;

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	float velDist = vel.getLength();
	Vec2f nextPos = pos + vel;

	// remove slow moving bullets
	if (shape.vellen > 0.0001f && shape.vellen < 13.5f) 					{ this.server_Die(); return; }
	// remove bullets on the edge of the map
	if (pos.x < 0.1f or pos.x > (map.tilemapwidth * map.tilesize) - 0.1f) 	{ this.server_Die(); return; }
	// 
	if (this.hasTag("dead"))												{ this.server_Die(); return; }

	int creationTicks = this.getTickSinceCreated();

	CSprite@ sprite = this.getSprite();
	sprite.SetVisible(creationTicks >= XORRandom(2)+1);

	Vec2f v = (vel + this.getOldVelocity())/2;
	if (v.getLength() > 27.0) 		sprite.SetFrameIndex(2);
	else if (v.getLength() > 19.0) 	sprite.SetFrameIndex(1);
	else 							sprite.SetFrameIndex(0);

	this.setAngleDegrees(-vel.Angle());

	if (this.isInWater()) 			this.setVelocity(vel * 0.95f);
	else if (this.hasTag("rico")) 	this.AddForce(Vec2f(0.0f, 0.5f));
	else 							this.AddForce(Vec2f(0.0f, 0.11f));

	Vec2f wallPos = Vec2f_zero;
	bool hitWall = map.rayCastSolidNoBlobs(pos, nextPos, wallPos); //if there's a wall, end the travel early
	if (hitWall)
	{
		nextPos = wallPos;
		Vec2f fixedTravel = nextPos - pos;
		velDist = fixedTravel.getLength();
	}

	HitInfo@[] hitInfos;
	bool hasHit = map.getHitInfosFromRay(pos, -vel.getAngleDegrees(), velDist*1.5f, this, @hitInfos);

	if (hasHit)
	{
		HitInfo@[] filteredHitInfos;

		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;

			if (b !is null && doesCollideWithBlob(this, b))
			{
				filteredHitInfos.push_back(hi);
			}
		}

		for (uint i = 0; i < filteredHitInfos.length; i++)
		{
			HitInfo@ hi = filteredHitInfos[i];
			pos = hi.hitpos;
			this.setPosition(pos);
			onHitBlob(this, pos, vel, hi.blob, Hitters::arrow);
			return;
		}
	}

	if (hitWall) // if there was no hit, but there is a wall, move bullet there and die
	{
		this.setPosition(nextPos);
		onHitWorld(this, nextPos);
	}

	// collison with map
	Vec2f end;
	if (map.rayCastSolidNoBlobs(pos, pos + vel, end)) onHitWorld(this, end);
}

void onHitWorld(CBlob@ this, Vec2f end)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	this.setVelocity(vel*0.8f);

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
		&& XORRandom(100) <= 1) || (tile != CMap::tile_ground && tile <= 255 && XORRandom(100) < 3)))
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
				for (uint i = 0; i < 3+XORRandom(6); i++) {
					Vec2f velr = vel/(XORRandom(5)+3.0f);
					velr += Vec2f(0.0f, -6.5f);
					velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

					ParticlePixel(end, velr, SColor(255, 255, 255, 0), true);
				}
			}

			Sound::Play("/BulletMetal" + XORRandom(4), pos, 1.2f, 0.8f + XORRandom(40) * 0.01f);

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

		Sound::Play("/BulletDirt" + XORRandom(3), pos, 1.7f, 0.85f + XORRandom(25) * 0.01f);

		if (!v_fastrender)
		{
			CParticle@ p = ParticleAnimated("SparkParticle.png", pos, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(2), 0.0f, false);
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
			CParticle@ p = ParticleAnimated("BulletHitParticle1.png", end + Vec2f(0.0f, 1.0f), Vec2f(0,0), impact_angle, 0.55f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
			if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }
		}

		this.server_Die();
	}
}

void onHitBlob(CBlob@ this, Vec2f hit_position, Vec2f velocity, CBlob@ blob, u8 customData)
{
	CSprite@ sprite = this.getSprite();
	f32 dmg = this.get_f32("bullet_damage_body");

	s8 finalRating = getFinalRating(this, blob.get_s8(armorRatingString), this.get_s8(penRatingString), blob.get_bool(hardShelledString), blob, hit_position);

	const bool can_pierce = finalRating < 2;

	if (blob !is null)
	{
		if (blob.hasTag("vehicle"))
		{
			if (isServer()) this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), this.hasTag("strong") ? 0.75f : 0.25f, Hitters::builder);
		}
		else {
			// play sound
			if (blob.hasTag("flesh"))
			{
				if (isServer() && !blob.hasTag("dead") && this.getDamageOwnerPlayer() !is null)
				{
					CPlayer@ p = this.getDamageOwnerPlayer();

					if (getRules().get_string(p.getUsername() + "_perk") == "Bloodthirsty")
					{
						CBlob@ pblob = p.getBlob();
						if (pblob !is null)
						{
							f32 mod = 0.25f+XORRandom(175)*0.001f;
							f32 amount = this.get_f32("bullet_damage_body") * mod;

							if (pblob.getHealth()+amount < pblob.getInitialHealth())
								pblob.server_Heal(amount);
							else pblob.server_SetHealth(pblob.getInitialHealth());
						}
					}
				}
				if (isClient() && XORRandom(100) < 60)
				{
					sprite.PlaySound("Splat.ogg");
				}
			}
			else if (v_fastrender)
			{
				CParticle@ p = ParticleAnimated("SparkParticle.png", hit_position, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(5), 0.0f, false);
				if (p !is null) {
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
					if (p !is null) {
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
					if (p !is null) {
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
			if (!blob.hasTag("nohead")) dmg = this.get_f32("bullet_damage_head");

			// hit helmet
			if (blob.get_string("equipment_head") == "helmet")
			{
				dmg *= 0.5;

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

		if (blob.hasTag("nolegs")) dmg = this.get_f32("bullet_damage_head");

		if (!this.hasTag("strong")) {
			// do less dmg offscreen
			int creationTicks = this.getTickSinceCreated();
			if (creationTicks > 20) 		dmg *= 0.75f;
			else if  (creationTicks > 14) 	dmg *= 0.5f;
		}

		if (!blob.hasTag("weakprop")) this.server_Die();
		else this.setVelocity(velocity * 0.96f);

		if (blob.hasTag("flesh"))
		{
			if (blob.getPlayer() !is null)
			{
				// player is using bloodthirsty
				if (getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Bloodthirsty")
				{
					dmg *= 1.1f; // take extra damage
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
	const bool is_young = this.getTickSinceCreated() <= 1;
	const bool same_team = blob.getTeamNum() == this.getTeamNum();

	if (blob.hasTag("always bullet collide"))
	{
		if (blob.hasTag("trap")) return true;
		if (!same_team) return false;
		return true;
	}

	if (blob.hasTag("respawn") || blob.hasTag("invincible") || blob.hasTag("dead") || blob.hasTag("projectile") || blob.hasTag("trap") || blob.hasTag("material") || this.hasTag("rico")) {
        return false;
    }

	CShape@ shape = blob.getShape();
	if (shape is null) return false;

	if (blob.hasTag("door") && shape.getConsts().collidable) return true; // blocked by closed doors

	if (blob.hasTag("missile") && !same_team) return true;

	if (same_team && blob.hasTag("friendly_bullet_pass")) return false;

	if (is_young && (blob.hasTag("vehicle") || blob.getName() == "sandbags")) return false;

	if (blob.hasTag("player") && blob.exists("mg_invincible") && blob.get_u32("mg_invincible") > getGameTime())
		return false;

	//if (blob.hasTag("player"))
	//{
	//	if (blob.hasTag("bushy") && this.getTickSinceCreated() > 10)
	//	{
	//		return false;
	//	}
	//}
		
	if (blob.hasTag("vehicle"))
	{
		if (same_team)
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

	if (blob.hasTag("turret") && !same_team)
		return true;
	
	if (blob.hasTag("destructable_nosoak"))
	{
		this.server_Hit(blob, blob.getPosition(), this.getOldVelocity(), 0.5f, Hitters::builder);
		return false;
	}
	
	if (blob.isAttached() && !blob.hasTag("player"))
		return false;

	if ((!is_young || !same_team) && blob.isAttached() && !blob.hasTag("covered"))
	{
		if (blob.hasTag("collidewithbullets")) return XORRandom(2)==0;
		if (XORRandom(8) == 0)
			return true;

		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("GUNNER");
		if (point !is null && point.getOccupied() !is null && (point.getOccupied().getName() == "heavygun" || point.getOccupied().getName() == "gun") && blob.getTeamNum() != this.getTeamNum())
			return true;
	}

	if (blob.getName() == "trap_block")
		return shape.getConsts().collidable;

	if (blob.isAttached()) return blob.hasTag("collidewithbullets");

	if (blob.hasTag("bunker") && !same_team) return true;

	if (blob.getName() == "wooden_platform") // get blocked by directional platforms
	{
		Vec2f thisVel = this.getVelocity();
		float thisVelAngle = thisVel.getAngleDegrees();
		float blobAngle = blob.getAngleDegrees()-90.0f;

		float angleDiff = (-thisVelAngle+360.0f) - blobAngle;
		angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;
		
		return Maths::Abs(angleDiff) > 100.0f;
	}

	// old bullet is stopped by sandbags
	if (!is_young && blob.getName() == "sandbags") return true;

	if (this.hasTag("rico")) return false; // do not hit vital targets if already bounced once

	if (blob.hasTag("destructable"))
		return true;

	if (shape.isStatic()) // trees, ladders, etc
		return false;
	
	if (!same_team && blob.hasTag("flesh")) // hit an enemy
		return true;

	if (blob.hasTag("blocks bullet"))
		return true;

	return false; // if all else fails, do not collide
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0.0f;
}