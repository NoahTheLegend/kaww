#include "WarfareGlobal.as"
#include "Hitters.as";
#include "Explosion.as";
// const u32 fuel_timer_max = 30 * 600;
const f32 SPEED_MAX = 62.5;
const Vec2f gun_offset = Vec2f(-30, 8.5);

const u32 shootDelay = 1; // Ticks
const f32 projDamage = 0.75f;

//ICONS
//AddIconToken("$bf109$", "Bf109.png", Vec2f(40, 32), 0);

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

string[] smokes = 
{
	"LargeSmoke.png",
	"SmallSmoke1.png",
	"SmallSmoke2.png"
};

void onInit(CBlob@ this)
{
	// causes command no found errors (added manually)
	this.addCommandID("load_ammo");
	this.addCommandID("swap_ammo");
	this.addCommandID("putin_mag");
	this.addCommandID("fire");
	this.addCommandID("flip_over");
	this.addCommandID("getin_mag");
	this.addCommandID("vehicle getout");
	this.addCommandID("recount ammo");
	this.addCommandID("sync_last_fired");
	this.addCommandID("sync_ammo");
	this.addCommandID("reload");

	this.set_f32("velocity", 0.0f);
	
	this.set_bool("map_damage_raycast", true);
	this.Tag("map_damage_dirt");
	this.addCommandID("shoot bullet");
	
	this.Tag("vehicle");
	this.Tag("aerial");
	this.Tag("wooden");
	this.Tag("pass_bullet");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("Aircraft_Loop.ogg");
	sprite.SetEmitSoundSpeed(0.0f);
	sprite.SetEmitSoundPaused(false);

	this.getShape().SetRotationsAllowed(true);
	this.set_Vec2f("direction", Vec2f(0, 0));
}

void onInit(CSprite@ this)
{
	this.RemoveSpriteLayer("tracer");
	CSpriteLayer@ tracer = this.addSpriteLayer("tracer", "GatlingGun_Tracer.png", 32, 1, this.getBlob().getTeamNum(), 0);

	if (tracer !is null)
	{
		Animation@ anim = tracer.addAnimation("default", 0, false);
		anim.AddFrame(0);
		
		tracer.SetOffset(gun_offset);
		tracer.SetRelativeZ(-1.0f);
		tracer.SetVisible(false);
		tracer.setRenderStyle(RenderStyle::additive);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot bullet"))
	{
		this.set_u32("next_shoot", getGameTime()+shootDelay);
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;

		if (getNet().isServer() && !this.hasTag("no_more_proj"))
		{
			CBlob@ proj = CreateProj(this, arrowPos, arrowVel);
			if (proj !is null)
			{
				proj.server_SetTimeToDie(3.0);
				proj.Tag("plane_bullet");
			}

			CInventory@ inv = this.getInventory();
			if (inv !is null)
			{
				for (u8 i = 0; i < inv.getItemsCount(); i++)
				{
					if (inv.getItem(i) is null || inv.getItem(i).getName() != "mat_7mmround") continue;
					if (XORRandom(5) != 0) continue;
					inv.getItem(i).server_SetQuantity(inv.getItem(0).getQuantity()-1);
					break;
				}
			}
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.hasTag("falling"))
	{
		if (isServer() && this.isOnGround()) this.server_Die();
		this.setAngleDegrees(this.getAngleDegrees() + (Maths::Sin(getGameTime() / 5.0f) * 8.5f));
	}
	if (getGameTime() >= this.get_u32("next_shoot"))
	{
		this.Untag("no_more_shooting");
		this.Untag("no_more_proj");
	}
	AttachmentPoint@ ap_pilot = this.getAttachments().getAttachmentPointByName("PILOT");
	if (this.hasAttached() && ap_pilot !is null)
	{
		CBlob@ pilot = ap_pilot.getOccupied();
		
		if (pilot !is null)
		{
			Vec2f dir = pilot.getPosition() - pilot.getAimPos();
			const f32 len = dir.Length();
			dir.Normalize();
			dir.RotateBy(this.isFacingLeft() ? 30 : -30); // make it fly directly to cursor, works weird vertically
			dir = Vec2f_lerp(this.get_Vec2f("direction"), dir, 0.1f);

			// this.SetFacingLeft(dir.x > 0);
			this.SetFacingLeft(this.getVelocity().x < -0.1f);
			// const f32 ang = this.isFacingLeft() ? 0 : 180;
			// this.setAngleDegrees(ang - dir.Angle());
		
			bool pressed_w = ap_pilot.isKeyPressed(key_up);
			bool pressed_s = ap_pilot.isKeyPressed(key_down);
			bool pressed_lm = ap_pilot.isKeyPressed(key_action1);

			//if (this.getTickSinceCreated() == 5*30)
			//{
			//	this.Tag('falling');
			//	this.set_u32("falling_time", getGameTime());
			//}
			if (this.hasTag("falling"))
			{
				Vec2f old_pos = this.getOldPosition();
				Vec2f pos = this.getPosition();
				dir.RotateBy(this.isFacingLeft() ? -1.0f * (getGameTime()-this.get_u32("falling_time")) * 2 : 2 * (getGameTime()-this.get_u32("falling_time")));
			}
			
			
			if (!this.hasTag("no_more_shooting") && pilot.isMyPlayer() && pressed_lm && this.get_u32("next_shoot") < getGameTime())
			{
				bool can_attack = false;
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					for (u8 i = 0; i < inv.getItemsCount(); i++)
					{
						if (inv.getItem(i) is null || inv.getItem(i).getName() != "mat_7mmround") continue;
						can_attack = true;
						break;
					}
				}
				if (can_attack)
				{
					if (!this.hasTag("no_more_shooting")) this.getSprite().PlaySound("AssaultFire.ogg", 1.25f, 0.95f + XORRandom(15) * 0.01f);
					ShootBullet(this, (this.getPosition() - Vec2f(0,1)), this.getPosition()+Vec2f(this.isFacingLeft() ? -32.0f : 32.0f, 0).RotateBy(this.getAngleDegrees() + (this.isFacingLeft() ? -2.5f : 2.5f)), 17.59f * 1.75f);
					this.Tag("no_more_shooting");
				}
			}
			
			// bool pressed_s = ap_pilot.isKeyPressed(key_down);
		
			if (pressed_w) 
			{
				this.set_f32("velocity", Maths::Min(SPEED_MAX, this.get_f32("velocity") + 2.5f));
			}
			
			if (pressed_s) 
			{
				this.set_f32("velocity", Maths::Min(SPEED_MAX, this.get_f32("velocity") - 0.50f));
			}
			
			this.set_Vec2f("direction", dir);
		}		
	}
	else
	{
		this.set_f32("velocity", Maths::Max(0, this.get_f32("velocity") - 1.00f));
	}

	if (this.hasTag("falling") || this.getHealth() <= this.getInitialHealth() * 0.33f)
	{
		u8 rand = 5;
		if (this.hasTag("falling")) rand = 1;
		if (XORRandom(rand) == 0)
		{
			const Vec2f pos = this.getPosition() + getRandomVelocity(0, this.getRadius()*0.4f, 360);
			CParticle@ p = ParticleAnimated("BlackParticle.png", pos, Vec2f(0,0), -0.5f, 1.0f, 5.0f, 0.0f, false);
			if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

			Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

			ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);

			if (isClient())
			{
				Vec2f pos = this.getPosition();
				CMap@ map = getMap();
				
				ParticleAnimated("LargeSmoke", pos + Vec2f(XORRandom(60) - 30, XORRandom(48) - 24), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, 90), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 7 + XORRandom(8), XORRandom(70) * -0.00005f, true);
			}
		}

		if (this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(vel * 0.98);
		}
	}

	const f32 hmod = 1.0f;
	const f32 v = this.get_f32("velocity");
	Vec2f d = this.get_Vec2f("direction");
	// Vec2f grav = Vec2f(0, 1) * 4 * (SPEED_MAX - v);
	
	this.AddForce(-d * v * hmod);

	if (this.getVelocity().Length() > 1.50f && v > 0.25f) this.setAngleDegrees((this.isFacingLeft() ? 180 : 0) - this.getVelocity().Angle());
	else this.setAngleDegrees(0);
	
	if (getNet().isClient())
	{
		this.getSprite().SetEmitSoundSpeed(0.5f + (this.get_f32("velocity") / SPEED_MAX * 0.4f) * (this.getVelocity().Length() * 0.15f));
		
		if (hmod < 0.7 && u32(getGameTime() % 20 * hmod) == 0) ParticleAnimated(CFileMatcher(smokes[XORRandom(smokes.length)]).getFirst(), this.getPosition(), Vec2f(0, 0), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 3 + XORRandom(4), XORRandom(100) * -0.001f, true);
	}
	if (this.hasTag("falling"))
	{
		this.setAngleDegrees(this.getAngleDegrees() + (Maths::Sin(getGameTime() / 5.0f) * 6.0f));
	}
}

void ShootBullet(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed)
{
	Vec2f arrowVel = (aimpos - arrowPos);
	arrowVel.Normalize();
	arrowVel *= arrowspeed;
	CBitStream params;
	params.write_Vec2f(arrowPos);
	params.write_Vec2f(arrowVel);

	this.SendCommand(this.getCommandID("shoot bullet"), params);
}

CBlob@ CreateProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	if (!this.hasTag("no_more_proj"))
	{
		CBlob@ proj = server_CreateBlobNoInit("bulletheavy");
		if (proj !is null)
		{
			proj.SetDamageOwnerPlayer(this.getPlayer());
			proj.Init();

			proj.set_s8(penRatingString, 2);

			proj.set_f32("bullet_damage_body", projDamage);
			proj.set_f32("bullet_damage_head", projDamage*1.5f);
			proj.IgnoreCollisionWhileOverlapped(this);
			proj.server_setTeamNum(this.getTeamNum());
			arrowVel.RotateBy(this.isFacingLeft() ? -2.5 : 2.5);
			proj.setVelocity(arrowVel.RotateBy(0.125f*(XORRandom(36)-17.5f)));

			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PILOT");
			if (ap !is null && ap.getOccupied() !is null && ap.getOccupied().getPlayer() !is null) //getting player is necessary in case when player leaves
			{
				proj.SetDamageOwnerPlayer(ap.getOccupied().getPlayer());
			}
			
			proj.getShape().setDrag(proj.getShape().getDrag() * 0.3f);
			proj.setPosition(arrowPos + Vec2f((this.isFacingLeft() ? -16.0f : 16.0f), 8.0f).RotateBy(this.getAngleDegrees()));
		}
		this.Tag("no_more_proj");
		return proj;
	}
	else
		return null;
}

void Shoot(CBlob@ this)
{
	if (getGameTime() < this.get_u32("fireDelay")) return;

	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	if (inv.getItemsCount() > 0)
	{
		for (u8 i = 0; i < inv.getItemsCount(); i++)
		{
			if (inv.getItem(i) !is null && inv.getItem(i).getName() == "mat_7mmround")
			{
				CBlob@ ammo = inv.getItem(i);
				if (ammo.getQuantity() > 0 && isServer())
				{
					ammo.server_SetQuantity(ammo.getQuantity() - 1);
					break;
				}
				if (ammo.getQuantity() == 0 && isServer())
				{
					ammo.server_Die();
					break;
				}
			}
			else return;
		}
	}
	else
	{
		AttachmentPoint@ ap_pilot = this.getAttachments().getAttachmentPointByName("PILOT");
		if (ap_pilot !is null)
		{
			CBlob@ pilot = ap_pilot.getOccupied();
			if (pilot.isMyPlayer())
			{
				if (getGameTime() % 30 == 0) Sound::Play("NoAmmo");
			}
		}
		return;
	}

	f32 sign = (this.isFacingLeft() ? -1 : 1);
	f32 angleOffset = (10 * sign);
	f32 angle = this.getAngleDegrees() + ((XORRandom(200) - 100) / 100.0f) + angleOffset;
		
	Vec2f dir = Vec2f(sign, 0.0f).RotateBy(angle);
	
	Vec2f offset = gun_offset;
	offset.x *= -sign;
	
	Vec2f startPos = this.getPosition() + offset.RotateBy(angle);
	Vec2f endPos = startPos + dir * 500;
	Vec2f hitPos;
	
	bool flip = this.isFacingLeft();		
	HitInfo@[] hitInfos;
	
	bool mapHit = getMap().rayCastSolid(startPos, endPos, hitPos);
	f32 length = (hitPos - startPos).Length();
	
	bool blobHit = getMap().getHitInfosFromRay(startPos, angle + (flip ? 180.0f : 0.0f), length, this, @hitInfos);
		
	if (getNet().isClient())
	{
		DrawLine(this.getSprite(), startPos, length / 32, angleOffset, this.isFacingLeft());
		this.getSprite().PlaySound("AssaultFire.ogg", 1.00f, 1.00f);
		
		// Vec2f mousePos = getControls().getMouseScreenPos();
		// getControls().setMousePosition(Vec2f(mousePos.x, mousePos.y - 10));
	}
	
	if (getNet().isServer())
	{
		if (blobHit)
		{
			f32 falloff = 1;
			for (u32 i = 0; i < hitInfos.length; i++)
			{
				if (hitInfos[i].blob !is null)
				{	
					CBlob@ blob = hitInfos[i].blob;
					
					if ((blob.isCollidable() || blob.hasTag("flesh")) && blob.getTeamNum() != this.getTeamNum())
					{
						// print("Hit " + blob.getName() + " for " + damage * falloff);
						this.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), projDamage * Maths::Max(0.1, falloff), Hitters::arrow);
						falloff = falloff * 0.5f;			
					}
				}
			}
		}
		
		if (mapHit)
		{
			CMap@ map = getMap();
			TileType tile =	map.getTile(hitPos).type;
			
			if (!map.isTileBedrock(tile) && tile != CMap::tile_ground_d0 && tile != CMap::tile_stone_d0)
			{
				map.server_DestroyTile(hitPos, 0.125f);
			}
		}
	}
	
	this.set_u32("fireDelay", getGameTime() + shootDelay);
}

void DrawLine(CSprite@ this, Vec2f startPos, f32 length, f32 angle, bool flip)
{
	CSpriteLayer@ tracer = this.getSpriteLayer("tracer");
	
	tracer.SetVisible(true);
	
	tracer.ResetTransform();
	tracer.ScaleBy(Vec2f(length, 1.0f));
	tracer.TranslateBy(Vec2f(length * 16.0f, 0.0f));
	tracer.RotateBy(angle + (flip ? 180 : 0), Vec2f());
}

void onTick(CSprite@ this)
{
	if ((this.getBlob().get_u32("fireDelay") - (shootDelay - 1)) < getGameTime()) this.getSpriteLayer("tracer").SetVisible(false);
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PILOT");
	if (point is null) return true;
		
	CBlob@ holder = point.getOccupied();
	if (holder is null) return true;
	else return false;
}

bool canBePutInInventory(CBlob@ inventoryBlob)
{
	return false;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (blob.getName() == "bf109" || blob.getName() == "bomberplane") return false;
	if (blob.hasTag("bullet")) return true;
	if (!blob.isCollidable() || blob.isAttached()){
		return false;
	} // no colliding against people inside vehicles
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer() && solid && this.hasTag("falling"))
		this.server_Die();
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 random = XORRandom(40);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = -this.get_f32("bomb angle");
	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (30.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.50f);
	
	Explode(this, 30.0f + random, 64.0f);
	
	for (int i = 0; i < 10 * modifier; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		dir.x *= 2;
		dir.Normalize();
		
		LinearExplosion(this, dir, 16.0f + XORRandom(16) + (modifier * 8), 16 + XORRandom(24), 3, 2.00f, Hitters::explosion);
	}
	
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	
	for (int i = 0; i < 35; i++)
	{
		MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(-angle, XORRandom(220) * 0.01f, 90), particles[XORRandom(particles.length)]);
	}
	
	this.Tag("exploded");
	this.getSprite().Gib();
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!getNet().isClient()) return;

	ParticleAnimated(CFileMatcher(filename).getFirst(), this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

void onAttach(CBlob@ this,CBlob@ attached,AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("bomber")) return;

	attached.Tag("invincible");
	attached.Tag("invincibilityByVehicle");
	attached.Tag("increase_max_zoom");
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("invincible");
	detached.Untag("invincibilityByVehicle");
	detached.Untag("increase_max_zoom");
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	AttachmentPoint@ ap_pilot = this.getAttachments().getAttachmentPointByName("PILOT");
	
	if (ap_pilot !is null)
	{
		return ap_pilot.getOccupied() == null;
	}
	else return true;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("ignore damage")) return 0;
	if (damage >= this.getHealth())
	{
		this.Tag("ignore damage");
		this.Tag("falling");
		this.Tag("invincible");
		if (isServer())
		{
			this.server_SetTimeToDie(30);
			this.server_SetHealth(this.getInitialHealth());
		}
		this.set_u32("falling_time", getGameTime());
		return 0;
	}
	else if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 0.75f;
	}
	else if (hitterBlob.hasTag("bullet"))
	{
		if (hitterBlob.hasTag("plane_bullet")) return damage * 0.25f;
		return damage * (hitterBlob.hasTag("strong") ? 0.85f : 0.65f);
	}
	return damage;
}