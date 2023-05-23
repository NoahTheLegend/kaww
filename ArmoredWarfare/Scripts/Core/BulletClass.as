
//  BulletClass.as - Vamist


#include "BulletCase.as";
#include "BulletParticle.as";
#include "Hitters.as";
#include "HittersAW.as";
#include "CustomBlocks.as";
#include "WarfareGlobal.as";

const SColor trueWhite = SColor(255,255,255,255);
Driver@ PDriver = getDriver();
const int ScreenX = getDriver().getScreenWidth();
const int ScreenY = getDriver().getScreenWidth();

class BulletObj
{
	u16 hoomanShooterID;
	u16 LastHitBlobID;

	BulletFade@ Fade;

	s8 CurrentType;
	s32 CurrentHitter;

	Vec2f TrueVelocity;
	Vec2f CurrentPos;
	Vec2f BulletGrav;
	Vec2f RenderPos;
	Vec2f OldPos;
	Vec2f LastPos;
	Vec2f Gravity;
	Vec2f KB;
	f32 StartingAimPos;
	f32 lastDelta;
	f32 DamageBody;
	f32 DamageHead;
	s8 CurrentPen;
	f32 MaxAngleRicochet;
	bool HadRico;
	u32 CreateTime;

	u8 TeamNum;
	u8 Speed;

	s8 TimeLeft;

	bool FacingLeft;
	
	BulletObj(u16 humanBlobID, f32 angle, Vec2f pos, s8 type, f32 damage_body,
		f32 damage_head, s8 penetration, u32 creation_time, s32 hitter, u8 time, u8 speedo)
	{
		LastHitBlobID = 0;
		CBlob@ human = getBlobByNetworkID(humanBlobID);

		CurrentType = type;
		CurrentPos = pos;
		FacingLeft = human !is null ? human.isFacingLeft() : true;
		BulletGrav = human !is null ? human.get_Vec2f("grav") : Vec2f_zero;
		DamageBody = damage_body;
		DamageHead = damage_head;
		CurrentPen = penetration;
		TeamNum  = human !is null ? human.getTeamNum() : 8;
		TimeLeft = time;
		KB       = Vec2f(0,0);
		Speed    = speedo;
		hoomanShooterID = humanBlobID;
		StartingAimPos = angle;
		OldPos     = CurrentPos;
		LastPos    = CurrentPos;
		RenderPos  = CurrentPos;
		MaxAngleRicochet = 25;
		HadRico = false;
		CreateTime = creation_time;
		CurrentHitter = hitter;
		

		lastDelta = 0;
		//@Fade = BulletGrouped.addFade(CurrentPos);
	}

	void SetStartAimPos(Vec2f aimPos, bool isFacingLeft)
	{
		Vec2f aimvector = aimPos - CurrentPos;
		StartingAimPos = isFacingLeft ? -aimvector.Angle()+180.0f : -aimvector.Angle();
	}

	Vec2f GetIntersectionPoint(Vec2f start1, Vec2f end1, Vec2f start2, Vec2f end2)
	{
	    f32 x1 = start1.x;
	    f32 y1 = start1.y;
	    f32 x2 = end1.x;
	    f32 y2 = end1.y;
	    f32 x3 = start2.x;
	    f32 y3 = start2.y;
	    f32 x4 = end2.x;
	    f32 y4 = end2.y;

	    f32 det = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

	    if (det == 0)
	    {
	        // Отрезки параллельны или совпадают, вернуть точку по умолчанию
	        return Vec2f(0, 0);
	    }
	    else
	    {
	        Vec2f intersectionPoint;
	        intersectionPoint.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / det;
	        intersectionPoint.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / det;

	        return intersectionPoint;
	    }
	}

	bool doesCollideWithBlob(CBlob@ blob, CBlob@ hoomanBlob)
	{
		CBlob@ LastHitBlob = getBlobByNetworkID(LastHitBlobID);
		Random _rand_r(getGameTime());
		const bool is_young = getGameTime() - CreateTime <= 1;
		const bool same_team = TeamNum == blob.getTeamNum();

		if (LastHitBlob is blob)
		{
			TimeLeft = 0;
			return false;
		}

		if (blob.hasTag("always bullet collide"))
		{
			if (blob.hasTag("trap")) return true;
			else if (!same_team) return false;
			return true;
		}

		if (blob.hasTag("respawn") || blob.hasTag("invincible") || blob.hasTag("dead") || blob.hasTag("projectile") || blob.hasTag("trap") || blob.hasTag("material")) {
			return false;
	    }

		if (blob.hasTag("bulletpassable"))
		{
			if (isServer())
			{
				hoomanBlob.server_Hit(blob, OldPos, blob.getVelocity(), 0.1f+DamageBody/2, Hitters::builder);
			}
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

		if (blob.hasTag("vehicle"))
		{
			if (same_team)
			{
				if (blob.hasTag("apc") || blob.hasTag("turret")) return (_rand_r.NextRanged(100) > 70);
				else if (blob.hasTag("tank")) return (_rand_r.NextRanged(100) > 50);
				else if (blob.hasTag("machinegun")) return false;
				else return true;
			}
			else
			{
				if (blob.hasTag("machinegun")) return (_rand_r.NextRanged(100) < 33);
				return true;
			}
		}

		if (blob.hasTag("turret") && !same_team)
			return true;

		if (blob.hasTag("destructable_nosoak"))
		{
			hoomanBlob.server_Hit(blob, CurrentPos, blob.getVelocity(), 0.5f, Hitters::builder);
			return false;
		}

		if ((!is_young || !same_team) && blob.isAttached() && !blob.hasTag("covered"))
		{
			if (blob.hasTag("collidewithbullets")) return _rand_r.NextRanged(2)==0;
			if (_rand_r.NextRanged(4) == 0 || blob.hasTag("player"))
				return true;

			AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("GUNNER");
			if (point !is null && point.getOccupied() !is null && (point.getOccupied().hasTag("machinegun")) && !same_team)
				return false;
		}

		if (blob.isAttached() && !blob.hasTag("player"))
			return false;

		if (blob.getName() == "trap_block")
			return shape.getConsts().collidable;

		if (blob.isAttached()) return blob.hasTag("collidewithbullets");

		if (blob.hasTag("bunker") && !same_team) return true;

		if (blob.getName() == "wooden_platform") // get blocked by directional platforms
		{
			Vec2f thisVel = TrueVelocity;
			float thisVelAngle = thisVel.getAngleDegrees();
			float blobAngle = blob.getAngleDegrees()-90.0f;

			float angleDiff = (-thisVelAngle+360.0f) - blobAngle;
			angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;

			return Maths::Abs(angleDiff) > 100.0f;
		}

		// old bullet is stopped by sandbags
		if (!is_young && blob.getName() == "sandbags") return true;

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

	bool onFakeTick(CMap@ map)
	{
		CBlob@ hoomanShooter = getBlobByNetworkID(hoomanShooterID);
		Random _rand_r(getGameTime());

		//Time to live check
		TimeLeft--;

		if (TimeLeft <= 0)
		{
			return true;
		}

		// Angle update
		OldPos = CurrentPos;
		Gravity -= BulletGrav;
		f32 angle = FacingLeft ? StartingAimPos+180 : StartingAimPos;
		Vec2f dir = Vec2f((FacingLeft ? -1 : 1), 0.0f).RotateBy(angle);
		CurrentPos = ((dir * Speed) - (Gravity * Speed)) + CurrentPos;
		TrueVelocity = CurrentPos - OldPos;

		bool endBullet = false;
		bool breakLoop = false;
		HitInfo@[] list;
		if (map.getHitInfosFromRay(OldPos, -(CurrentPos - OldPos).Angle(), (OldPos - CurrentPos).Length(), hoomanShooter, @list))
		{
			for (int a = 0; a < list.length(); a++)
			{
				breakLoop = false;

				HitInfo@ hit = list[a];
				Vec2f hitpos = hit.hitpos;
				CBlob@ blob = @hit.blob;
				TileType tile = map.getTile(hitpos).type;

				if (blob !is null && !doesCollideWithBlob(blob, hoomanShooter))
				{
					continue;
				}

				if (blob !is null)
				{
					f32 dmg = DamageBody;
					s8 finalRating = getFinalRatingBullet(CurrentHitter, blob.get_s8(armorRatingString), CurrentHitter == HittersAW::bullet?1:2, blob.get_bool(hardShelledString), blob, hitpos);
					const bool can_pierce = finalRating < 2;

					CSprite@ sprite = blob.getSprite();
					if (sprite is null) return false;

					int BlobTeamNum = blob.getTeamNum();
					string BlobName = blob.getName();

					if (blob.hasTag("vehicle"))
					{
						if (isServer())
						{
							if (hoomanShooter !is null) hoomanShooter.server_Hit(blob, OldPos, Vec2f(0,0.35f), CurrentType == 1 ? 0.75f : CurrentType == -1 ? 0.1f : 0.25f, Hitters::builder);
							else blob.server_Hit(blob, OldPos, Vec2f(0,0.35f), CurrentType == 1 ? 0.75f : CurrentType == -1 ? 0.1f : 0.25f, Hitters::builder);
						}
					}
					else
					{
						// play sound
						if (blob.hasTag("flesh"))
						{
							if (hoomanShooter !is null && !blob.hasTag("dead") && hoomanShooter.getDamageOwnerPlayer() !is null)
							{
								CPlayer@ p = hoomanShooter.getDamageOwnerPlayer();

								if (getRules().get_string(p.getUsername() + "_perk") == "Bloodthirsty")
								{
									CBlob@ pblob = p.getBlob();
									if (pblob !is null)
									{
										f32 mod = 0.35f+_rand_r.NextRanged(6)*0.01f;
										f32 amount = DamageBody * mod;
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
							CParticle@ p = ParticleAnimated("SparkParticle.png", hitpos, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(5), 0.0f, false);
							if (p !is null) {
								p.diesoncollide = true;
								p.fastcollision = true;
								p.lighting = false;
								p.Z = 200.0f;
							}
						}
					}

					if (TeamNum != BlobTeamNum && (BlobName == "wooden_platform" || blob.hasTag("door")))
					{
						if (isServer()) 
						{
							f32 door_dmg = BlobName != "stone_door" ? CurrentType == 1 ? 1.0f : 0.1f : 0.01f;
							if (hoomanShooter !is null) hoomanShooter.server_Hit(blob, CurrentPos, blob.getOldVelocity(), door_dmg, Hitters::builder);
							else blob.server_Hit(blob, CurrentPos, blob.getOldVelocity(), door_dmg, Hitters::builder);
						}
						endBullet = true;
					}

					if (blob.hasTag("vehicle") && !HadRico)
					{
						if (isClient() && _rand_r.NextRanged(101) < (can_pierce ? 20 : 35))
						{
							Vec2f velr = TrueVelocity/(XORRandom(4)+2.5f);
							velr += Vec2f(0.0f, -3.0f);
							velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

							ParticlePixel(CurrentPos, velr, SColor(255, 255, 255, 0), true);
						}
						if (isServer() && _rand_r.NextRanged(101) < (can_pierce ? 20 : 35))
						{
							// skip seed's value i guess?
						}

						if (!can_pierce)
						{
							HadRico = true;
							if (isClient())
							{
								Sound::Play("/BulletRico" + (XORRandom(4) + 4), CurrentPos, 1.4f, 0.85f + XORRandom(45) * 0.01f);

								if (!v_fastrender)
								{
									CParticle@ p = ParticleAnimated("PingParticle.png", hitpos, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(5), 0.0f, false);
									if (p !is null) {
										p.diesoncollide = true;
										p.fastcollision = true;
										p.lighting = false;
										p.Z = 200.0f;
									}
								}
							}
						}
						else
						{ 
							if (!v_fastrender)
							{
								CParticle@ p = ParticleAnimated("PingParticle.png", OldPos+TrueVelocity, Vec2f(0,0), XORRandom(360), 0.75f + XORRandom(4) * 0.10f, 3, 0.0f, false);
								if (p !is null) {
									p.diesoncollide = true;
									p.fastcollision = true;
									p.lighting = false;
									p.Z = 200.0f;
								}
							}

							sprite.PlaySound("/BulletPene" + XORRandom(3), 0.9f, 0.8f + XORRandom(50) * 0.01f);

							TimeLeft = 15;
						}
					}

					if (blob.hasTag("flesh") && hitpos.y < blob.getPosition().y - 3.2f)
					{
						if (!blob.hasTag("nohead")) dmg = DamageHead;

						// hit helmet
						if (blob.get_string("equipment_head") == "helmet")
						{
							dmg *= 0.5;

							if (_rand_r.NextRanged(100) < 25)
							{
								HadRico = true;

								Sound::Play("/BulletRico" + XORRandom(4), CurrentPos, 1.2f, 0.7f + XORRandom(60) * 0.01f);

								Vec2f velr = getRandomVelocity(!FacingLeft ? 70 : 110, 4.3f, 40.0f);
								velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

								ParticlePixel(CurrentPos, velr, SColor(255, 255, 255, 0), true);
								TimeLeft = 10;

								dmg = 0;
							}
						}
					}

					if (blob.hasTag("nolegs")) dmg = DamageHead;

					if (CurrentType < 1 && (hoomanShooter is null || hoomanShooter.getName() != "sniper")) {
						// do less dmg offscreen
						int creationTicks = getGameTime()-CreateTime;
						if (creationTicks > 20) 		dmg *= 0.75f;
						else if  (creationTicks > 14) 	dmg *= 0.5f;
					}

					if (!blob.hasTag("weakprop"))
					{
						endBullet = true;
						//break;
					}

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

					if (dmg > 0.0f)
					{
						if (hoomanShooter !is null) hoomanShooter.server_Hit(blob, OldPos, Vec2f(0,0.35f), dmg, CurrentHitter, false);
						else blob.server_Hit(blob, OldPos, Vec2f(0,0.35f), dmg, CurrentHitter, false);
						LastHitBlobID = blob.getNetworkID();
					}

					TimeLeft = 0;
					return true;
				}
				else
				{
					if (isClient())
					{
						const Vec2f xNew = PDriver.getScreenPosFromWorldPos(CurrentPos);
						if(!(xNew.x > 0 && xNew.x < ScreenX)) // Is our main position still on screen?
						{
							TimeLeft = 0;
							return true;
						}
					}

					bool stop = true;
					bool try_rico = true;
					bool do_hit_map = true;

					if (map.isTileWood(tile) && _rand_r.NextRanged(2)==0)
					{ // hit wood
						map.server_DestroyTile(hitpos, 0.1f);
					}
					else if (!isTileCompactedDirt(tile) && (((tile == CMap::tile_ground || isTileScrap(tile)) 
					&& _rand_r.NextRanged(100) <= 1) || (!map.isTileGround(tile) && tile <= 255 && _rand_r.NextRanged(100) < 3)))
					{ // hit resistant tile
						if (map.getSectorAtPosition(hitpos, "no build") is null)
						{
							map.server_DestroyTile(hitpos, CurrentType == 1 ? 1.5f : 0.65f);
						}
					}

					if(isTileCompactedDirt(tile) || map.isTileGround(tile))
					{
						try_rico = false;
					}

					// ricochet - https://www.youtube.com/watch?v=MOuMZWarmxg
					if (try_rico)
					{
						bool has_rico = false;
						// change the direction, if the angle is small
						u16 raw_angle = 0;

						f32 x = (hitpos.x%8.0f)-4.0f; // check if the hitpos is left\right\down\top from -4.0 to 4.0
						f32 y = (hitpos.y%8.0f)-4.0f;
						Vec2f side = Vec2f(x,y);

						// in this case it may pass the walls, so check if it hits the corner
						f32 threshold = 2.0f;
						if ((y <= -threshold && x <= -threshold) || (y <= -threshold && x >= threshold)
							|| (y >= threshold && x >= threshold) || (y >= threshold && x <= -threshold))
								try_rico = false;

						//printf(""+side);
								
						if (try_rico)
						{
							f32 angle_diff = 0;
							f32 current_angle = angle+270;

							// the angle is a bit weird if !FacingLeft, so we have to evaluate sides
							if (!FacingLeft)
								current_angle -= 180;
							if (current_angle <= -180) 
								current_angle = 360 + current_angle;

							f32 saved_angle = current_angle;
							current_angle += 45;

							current_angle = Maths::Min(4, Maths::Round(current_angle / 90));
							if (current_angle == 1 || current_angle == 3)
							{
								hitpos.x = Maths::Round(hitpos.x / 8) * 8;
							}
							else
							{
								hitpos.y = Maths::Round(hitpos.y / 8) * 8;
							}

							//printf("y "+y+" angle "+saved_angle+" "+current_angle);

							bool right_floor = false; // hack

							if (y > 3.0f && (current_angle == 1 || current_angle == 4)) // ceiling
							{
								bool e = current_angle == 1;
								f32 mod = e ? 1 : -1;

								if ((saved_angle > 90 - MaxAngleRicochet && saved_angle < 90)
									|| (saved_angle < 270 + MaxAngleRicochet && saved_angle > 270)) 
								{
									angle_diff = (e ? 90 : 270) - saved_angle;
									angle = -angle;

									OldPos = CurrentPos;
									dir = Vec2f((FacingLeft ? -1 : 1), 0.0f).RotateBy(angle);
									CurrentPos = ((dir * Speed) - (Gravity * Speed)) + hitpos;
									SetStartAimPos(CurrentPos+(dir*mod), FacingLeft);
									TrueVelocity = CurrentPos - OldPos;
									has_rico = true;
								}
							}
							else if (y < -3.0f && (current_angle == 2 || current_angle == 3)) // floor
							{
								bool e = current_angle == 2;
								f32 mod = e ? 1 : -1;

								if ((saved_angle < 90 + MaxAngleRicochet && saved_angle > 90)
									|| (saved_angle > 270 - MaxAngleRicochet && saved_angle < 270))
								{
									angle_diff = (e ? 90 + MaxAngleRicochet : 270) - saved_angle;
									angle = -angle;
									if (e) right_floor = true; // hack

									OldPos = CurrentPos;
									dir = Vec2f((FacingLeft ? -1 : 1), 0.0f).RotateBy(angle);
									CurrentPos = ((dir * Speed) - (Gravity * Speed)) + hitpos;
									SetStartAimPos(CurrentPos+(dir*mod), FacingLeft);
									TrueVelocity = CurrentPos - OldPos;
									has_rico = true;
								}
							}
							if (x < -3.0f && (current_angle == 1 || current_angle == 2)) // right wall
							{
								if ((saved_angle < MaxAngleRicochet && saved_angle > 0)
									|| (saved_angle < 180 && saved_angle > 180 - MaxAngleRicochet))
								{
									angle_diff = (current_angle == 1 ? MaxAngleRicochet : 180 - MaxAngleRicochet) - saved_angle;
									angle = -angle;

									OldPos = CurrentPos;
									dir = Vec2f((FacingLeft ? 1 : -1), 0.0f).RotateBy(angle);
									CurrentPos = ((dir * Speed) - (Gravity * Speed)) + hitpos;
									SetStartAimPos(CurrentPos+dir, FacingLeft);
									TrueVelocity = CurrentPos - OldPos;
									has_rico = true;
								}
							}
							else if (x > 3.0f && (current_angle == 3 || current_angle == 4)) // left wall
							{
								if ((saved_angle < 180 + MaxAngleRicochet && saved_angle > 180)
									|| (saved_angle < 360 && saved_angle > 360 - MaxAngleRicochet))
								{
									angle_diff = (current_angle == 3 ? 180 + MaxAngleRicochet : 360 - MaxAngleRicochet) - saved_angle;
									angle = -angle;

									OldPos = CurrentPos;
									dir = Vec2f((FacingLeft ? 1 : -1), 0.0f).RotateBy(angle);
									CurrentPos = ((dir * Speed) - (Gravity * Speed)) + hitpos;
									SetStartAimPos(CurrentPos-dir, FacingLeft);
									TrueVelocity = CurrentPos - OldPos;
									has_rico = true;
								}
							}
							
							if (has_rico && _rand_r.NextRanged(100) < 100-angle_diff*(right_floor ? 2 : 4))
							{
								HadRico = true;
								if (!v_fastrender)
								{
									for (uint i = 0; i < 3+XORRandom(6); i++) {
										Vec2f velr = TrueVelocity/(XORRandom(5)+3.0f);
										velr += Vec2f(0.0f, -6.5f);
										velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

										ParticlePixel(hitpos, velr, SColor(255, 255, 255, 0), true);
									}
								}
								Sound::Play("/BulletMetal" + XORRandom(4), CurrentPos, 1.2f, 0.8f + XORRandom(40) * 0.01f);

								TimeLeft /= 2;

								stop = false;
								do_hit_map = false;
							}
						}
					}
					
					// hit map
					if (do_hit_map)
					{
						ParticleAnimated("Smoke", hitpos, Vec2f(0.0f, -0.1f), 0.0f, 1.0f, 5, XORRandom(70) * -0.00005f, true);

						Sound::Play("/BulletDirt" + XORRandom(3), CurrentPos, 1.7f, 0.85f + XORRandom(25) * 0.01f);

						if (!v_fastrender)
						{
							CParticle@ p = ParticleAnimated("SparkParticle.png", OldPos, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(2), 0.0f, false);
							if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

							{ CParticle@ p = ParticleAnimated("BulletChunkParticle.png", hitpos, Vec2f(0.5f - XORRandom(100)*0.01f,-0.5), XORRandom(360), 0.55f + XORRandom(50)*0.01f, 22+XORRandom(3), 0.2f, true);
							if (p !is null) { p.lighting = true; }}
						}

						u16 impact_angle = 0;

						// ??? this is probably not working and heavy, remove\rewrite later
						{ TileType tile = map.getTile(hitpos + Vec2f(0, -1)).type;
						if (map.isTileSolid(tile)) impact_angle = 180;}

						{ TileType tile = map.getTile(hitpos + Vec2f(0, 1)).type;
						if (map.isTileSolid(tile)) impact_angle = 0;}

						{ TileType tile = map.getTile(hitpos + Vec2f(-1, 0)).type;
						if (map.isTileSolid(tile)) impact_angle = 90;}

						{ TileType tile = map.getTile(hitpos + Vec2f(1, 0)).type;
						if (map.isTileSolid(tile)) impact_angle = 270;}

						if (XORRandom(2) == 0 && !v_fastrender)
						{
							CParticle@ p = ParticleAnimated("BulletHitParticle1.png", hitpos + Vec2f(0.0f, 1.0f), Vec2f(0,0), impact_angle, 0.55f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
							if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }
						}
					}

					if (stop)
					{
						CurrentPos = hitpos;
						endBullet = true;
						ParticleBullet(CurrentPos, TrueVelocity);
					}
				}
			}
		}

		if (endBullet == true)
		{
			TimeLeft = 0;
		}
		return false;
	}

	void JoinQueue() // Every bullet gets forced to join the queue in onRenders, so we use this to calc to position
	{   
		// Are we on the screen?
		const Vec2f xLast = PDriver.getScreenPosFromWorldPos(LastPos);
		const Vec2f xNew  = PDriver.getScreenPosFromWorldPos(CurrentPos);
		if(!(xNew.x > 0 && xNew.x < ScreenX)) // Is our main position still on screen?
		{
			if(!(xLast.x > 0 && xLast.x < ScreenX)) // Was our last position on screen?
			{
				return; // No, lets not stay here then
			}
		}

		// Lerp
		Vec2f newPos = Vec2f_lerp(LastPos, CurrentPos, FRAME_TIME);
		LastPos = newPos;

		f32 angle = Vec2f(CurrentPos.x-newPos.x, CurrentPos.y-newPos.y).getAngleDegrees();//Sets the angle

		// y increases length, x increases width
		Vec2f scale = Vec2f(2.0f, 2.5f);
		if (CurrentType == -1)
			scale = Vec2f(1.75f, 1.25f);
		else if (CurrentType == 1)
			scale = Vec2f(2.0f, 5.0f+XORRandom(11)*0.1f);

		Vec2f TopLeft  = Vec2f(newPos.x -0.7*scale.x, newPos.y-3*scale.y);
		Vec2f TopRight = Vec2f(newPos.x -0.7*scale.x, newPos.y+3*scale.y);
		Vec2f BotLeft  = Vec2f(newPos.x +0.7*scale.x, newPos.y-3*scale.y);
		Vec2f BotRight = Vec2f(newPos.x +0.7*scale.x, newPos.y+3*scale.y);

		angle = -((angle % 360) + 90);

		BotLeft.RotateBy( angle,newPos);
		BotRight.RotateBy(angle,newPos);
		TopLeft.RotateBy( angle,newPos);
		TopRight.RotateBy(angle,newPos);   

		/*if(FacingLeft)
		{
			Fade.JoinQueue(TopLeft,TopRight);
		}
		else
		{
			//Fade.JoinQueue(newPos,BotRight);
		}*/


		v_r_bullet.push_back(Vertex(TopLeft.x,  TopLeft.y,      0, 0, 0,   trueWhite)); // top left
		v_r_bullet.push_back(Vertex(TopRight.x, TopRight.y,     0, 1, 0,   trueWhite)); // top right
		v_r_bullet.push_back(Vertex(BotRight.x, BotRight.y,     0, 1, 1, trueWhite));   // bot right
		v_r_bullet.push_back(Vertex(BotLeft.x,  BotLeft.y,      0, 0, 1, trueWhite));   // bot left
	}

}

class BulletHolder
{
	BulletObj[] bullets;
	BulletFade[] fade;
	PrettyParticle@[] PParticles;
	BulletHolder(){}

	void FakeOnTick(CRules@ this)
	{
		CMap@ map = getMap();
		for (int a = 0; a < bullets.length(); a++)
		{
			BulletObj@ bullet = bullets[a];
			if (bullet.onFakeTick(map))
			{
				bullets.erase(a);
				a--;
			}
		}
		//print(bullets.length() + '');
		 
		for (int a = 0; a < PParticles.length(); a++)
		{
			if (PParticles[a].ttl == 0)
			{
				PParticles.erase(a);
				a--;
				continue;
			}
			PParticles[a].FakeTick();
		}
	}

	BulletFade addFade(Vec2f spawnPos)
	{   
		BulletFade@ fadeToAdd = BulletFade(spawnPos);
		fade.push_back(fadeToAdd);
		return fadeToAdd; 
	}

	void addNewParticle(CParticle@ p,const u8 type)
	{
		PParticles.push_back(PrettyParticle(p,type));
	}
	
	void FillArray()
	{
		for (int a = 0; a < bullets.length(); a++)
		{
			bullets[a].JoinQueue();
		}
	}

	void AddNewObj(BulletObj@ this)
	{
		CMap@ map = getMap();
		this.onFakeTick(map);
		bullets.push_back(this);
	}
	
	void Clean()
	{
		bullets.clear();
	}

	int ArrayCount()
	{
		return bullets.length();
	}
}

const bool CollidesWithPlatform(CBlob@ blob, const Vec2f velocity) // Stolen from rock.as
{
	const f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	const float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}

