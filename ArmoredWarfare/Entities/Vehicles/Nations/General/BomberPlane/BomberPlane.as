#include "VehicleCommon.as"
#include "WarfareGlobal.as"
#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";
#include "PerksCommon.as";

// const u32 fuel_timer_max = 30 * 600;
const f32 SPEED_MAX = 55.0;
const Vec2f gun_offset = Vec2f(-30, 8.5);
f32 windage = 0.5f;

const u32 shootDelay = 1; // Ticks
const f32 projDamage = 0.75f;

const u16 droptime = 15;
const u16 droptime_heavy = 150;

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
	this.Tag("plane");
	this.Tag("parachute_ondetach");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("Aircraft_Loop.ogg");
	sprite.SetEmitSoundSpeed(0.0f);
	sprite.SetEmitSoundPaused(false);

	this.getShape().SetRotationsAllowed(true);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.set_Vec2f("direction", Vec2f(0, 0));
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	if (oldHealth > this.getInitialHealth()/2 && this.getHealth() <= this.getInitialHealth()/2)
		sprite.SetAnimation("damaged");
	else if (oldHealth < this.getInitialHealth()/2 && this.getHealth() >= this.getInitialHealth()/2)
		sprite.SetAnimation("default");
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
	
}

void onTick(CBlob@ this)
{
	if (this.hasTag("falling"))
	{
		Vehicle_ensureFallingCollision(this);
		this.setAngleDegrees(this.getAngleDegrees() + (Maths::Sin(getGameTime() / 5.0f) * 8.5f));
	}
	if (getGameTime() >= this.get_u32("next_shoot"))
	{
		this.Untag("no_more_shooting");
		this.Untag("no_more_proj");
	}
	if (this.hasTag("aerial") && getGameTime()%10==0)
	{
		if (getMap() !is null)
		{
			if (this.getPosition().x <= 8.0f || this.getPosition().x >= (getMap().tilemapwidth*8)-8.0f) this.server_Hit(this, this.getPosition(), this.getVelocity(), 1.0f, Hitters::fall);
		}
	}
	AttachmentPoint@ ap_pilot = this.getAttachments().getAttachmentPointByName("PILOT");
	if (this.hasAttached() && ap_pilot !is null)
	{
		CBlob@ pilot = ap_pilot.getOccupied();
		
		if (pilot !is null)
		{
			if (pilot.isMyPlayer() && pilot.getControls() !is null)
			{
				if (pilot.getControls().isKeyJustPressed(KEY_LCONTROL))
				{
					this.add_u8("mode", 1);
					if (this.get_u8("mode") > 1) this.set_u8("mode", 0);
				}
			}

			f32 speed = this.get_f32("velocity");
			Vec2f dir = pilot.getPosition() - pilot.getAimPos();
			if (this.get_u32("take_control") > getGameTime())
			{
				dir = this.isFacingLeft() ? Vec2f(-8.0f,0) : Vec2f(8.0f,0);
			}
			const f32 len = dir.Length();
			dir.Normalize();
			dir.RotateBy(this.isFacingLeft() ? 32.5f : -32.5f); // make it fly directly to cursor, works weird vertically

			bool og = this.isOnGround();
			f32 ground_factor = og ? 4.0f : 1.0f;

			f32 mod = 0.1f * ground_factor;
			CPlayer@ p = pilot.getPlayer();
			PerkStats@ stats;
			if (p !is null && !this.hasTag("falling") && p.get("PerkStats", @stats))
			{
				mod *= 1.0f+stats.plane_velo;
			}

			f32 vellen = this.getShape().vellen;
			f32 vellen_factor = Maths::Max((vellen*6)/SPEED_MAX, mod);
			dir = Vec2f_lerp(this.get_Vec2f("direction"), dir, mod * vellen_factor);

			if (vellen < 4.0f)
			{
				dir.y = Maths::Lerp(dir.y, -0.0f, (1.0f-vellen/5.0f) / (4/ground_factor));
				if (!og) this.set_f32("velocity", this.get_f32("velocity")*0.95f);
			}

			this.SetFacingLeft(this.getVelocity().x < -0.01f);

			bool pressed_w = ap_pilot.isKeyPressed(key_up);
			bool pressed_s = ap_pilot.isKeyPressed(key_down);
			bool pressed_lm = ap_pilot.isKeyPressed(key_action1) && !this.isOnGround() && this.getVelocity().Length() > 4.0f;

			if (this.hasTag("falling"))
			{
				Vec2f old_pos = this.getOldPosition();
				Vec2f pos = this.getPosition();
				dir.RotateBy(this.isFacingLeft() ? -1.0f * (getGameTime()-this.get_u32("falling_time")) * 0.1f : 0.1f * (getGameTime()-this.get_u32("falling_time")));
			}
			
			// bool pressed_s = ap_pilot.isKeyPressed(key_down);
		
			if (pressed_w) 
			{
				this.set_f32("velocity", Maths::Min(SPEED_MAX, this.get_f32("velocity") + 2.25f));
			}
			else if (this.get_f32("velocity") > 0.0f)
			{
				this.set_f32("velocity", Maths::Min(SPEED_MAX, this.get_f32("velocity") - 0.50f));
			}
			else this.set_f32("velocity", 0);

			if (this.getVelocity().Length() <= 1.0f)
			{
				this.set_f32("velocity", Maths::Min(SPEED_MAX, this.get_f32("velocity") - 1.25f));
			}

			if (ap_pilot.isKeyPressed(key_action3) && !this.isOnGround() && this.getVelocity().Length() > 5.0f && this.get_u32("lastDropTime") < getGameTime()) 
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null) 
				{
					u32 itemCount = inv.getItemsCount();
					bool can_drop =  this.getAngleDegrees() > 335 || this.getAngleDegrees() < 45;

					if (isClient()) 
					{
						if (itemCount > 0 && can_drop)
						{ 
							this.getSprite().PlaySound("bridge_open", 1.0f, 1.0f);
						}
						else if (pilot.isMyPlayer())
						{
							Sound::Play("NoAmmo");
						}
					}

					CBlob@ item = inv.getItem(0);
					if (itemCount > 0 && can_drop) 
					{
						if (isServer()) 
						{
							u32 quantity = item.getQuantity();

							if (!item.hasTag("bomber ammo"))
							{ 
								CBlob@ b = server_CreateBlob("paracrate", this.getTeamNum(), this.getPosition()+Vec2f(0,8));
								if (b !is null)
								{
									b.Tag("no_expiration");
									for (u8 i = 0; i < inv.getItemsCount(); i++)
									{
										CBlob@ put = inv.getItem(i);
										if (put is null) continue;
										if (put.getName() == "mat_smallbomb") continue;
										
										this.server_PutOutInventory(put);
										b.server_PutInInventory(put);
										i--;
									}
								}
							}
							else
							{
								const f32 v = this.get_f32("velocity");
								Vec2f d = this.get_Vec2f("direction");
								CBlob@ dropped = server_CreateBlob(item.getName(), this.getTeamNum(), this.getPosition());
								dropped.server_SetQuantity(1);
								dropped.setVelocity(this.getVelocity()-Vec2f(0, this.getVelocity().y*0.4));
								dropped.AddForce(Vec2f(0, 20.0f));
								dropped.setPosition(this.getPosition() - Vec2f(0,-24.0));
								dropped.IgnoreCollisionWhileOverlapped(this);
								dropped.SetDamageOwnerPlayer(pilot.getPlayer());
								dropped.Tag("no pickup");
								dropped.Tag("change rotation");

								if (quantity > 0)
								{
									item.server_SetQuantity(quantity - 1);
								}
								if (item.getQuantity() == 0) 
								{
									item.server_Die();
								}
							}
						}
					}

					this.set_u32("lastDropTime",getGameTime() + (item !is null && item.hasTag("heavy weight") ? droptime_heavy : droptime));
				}
			}
			
			this.set_Vec2f("direction", dir);
		}		
	}
	else if (this.isOnGround())
	{
		this.set_f32("velocity", Maths::Max(0, this.get_f32("velocity") - 0.25f));
	}
	else
	{
		this.set_f32("velocity", Maths::Max(0, this.get_f32("velocity") - 0.01f));
	}

	if (this.hasTag("falling") || this.getHealth() <= this.getInitialHealth() * 0.33f)
	{
		u8 rand = 5;
		if (this.hasTag("falling"))
		{
			if (ap_pilot is null)
			{
				Vec2f old_pos = this.getOldPosition();
				Vec2f pos = this.getPosition();
				Vec2f dir = pos-old_pos;
				dir.Normalize();
				dir.RotateBy(this.isFacingLeft() ? -1.0f * (getGameTime()-this.get_u32("falling_time")) * 0.1f : 0.1f * (getGameTime()-this.get_u32("falling_time")));
				this.set_Vec2f("direction", dir);
			}

			rand = 1;
		}
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
	f32 v = this.get_f32("velocity");
	//printf(""+v);
	Vec2f d = this.get_Vec2f("direction");
	if (v < 48.0f && this.isOnGround())
	{
		d = Vec2f(d.x, d.y/10);
	}

	if (!this.hasAttached() && this.getVelocity().Length() > 0.5f
	&& (this.getAngleDegrees() < 85 || this.getAngleDegrees() > 275))
	{
		d.RotateBy(this.isFacingLeft() ? -0.75f - XORRandom(50)*0.01f : 0.75f + XORRandom(50)*0.01f);
		this.set_Vec2f("direction", d);
	}
	
	this.AddForce(-d * v * hmod);

	if ((this.getVelocity().Length() > (this.isOnGround()?2.5f:0.25f)) && v > 0.25f) this.setAngleDegrees((this.isFacingLeft() ? 180 : 0) - this.getVelocity().Angle());
	else if (this.getAngleDegrees() > 25 && this.getAngleDegrees() < 335 && this.get_f32("velocity") < 1.0f)
	{
		this.setVelocity(Vec2f(0,0));
		this.set_f32("velocity", 0);
		this.setAngleDegrees(0);
		this.set_u32("take_control", getGameTime()+5);
	}
	
	if (getNet().isClient())
	{
		if (this.hasAttached() && v > 4.0f)
		{
			this.set_f32("soundspeed", 0.4f + (this.get_f32("velocity") / SPEED_MAX * 0.35f) * (this.getVelocity().Length() * 0.15f));
		}
		else
		{
			if (this.hasAttached() && v < 4.0f)
			{
				this.add_f32("soundspeed", 0.05f);
				if (this.get_f32("soundspeed") > 0.4f) this.set_f32("soundspeed", 0.4f);
			}
			else
			{
				this.set_f32("soundspeed", Maths::Max(0, this.get_f32("soundspeed") - 0.01f));
			}
		}

		Animation@ anim = this.getSprite().getAnimation("default");
		if (anim !is null)
		{
			anim.time = Maths::Max(1, Maths::Min(5, (1.0f-this.get_f32("soundspeed"))*10));
			//printf(""+anim.time);
			//printf(""+this.get_f32("soundspeed"));
			if (anim.time == 5 && this.get_f32("soundspeed") == 0)
			{
				this.getSprite().SetFrameIndex(0);
				anim.time = 0;
			}
		}

		this.getSprite().SetEmitSoundPaused(this.get_f32("soundspeed") <= 0.1f);
		this.getSprite().SetEmitSoundVolume(Maths::Sqrt(this.get_f32("soundspeed"))*1.25f);
		this.getSprite().SetEmitSoundSpeed(this.get_f32("soundspeed"));
		
		
		if (hmod < 0.7 && u32(getGameTime() % 20 * hmod) == 0) ParticleAnimated(CFileMatcher(smokes[XORRandom(smokes.length)]).getFirst(), this.getPosition(), Vec2f(0, 0), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 3 + XORRandom(4), XORRandom(100) * -0.001f, true);
	}
	if (this.hasTag("falling"))
	{
		this.setAngleDegrees(this.getAngleDegrees() + (Maths::Sin(getGameTime() / 5.0f) * 6.0f));
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	if (blob.hasTag("rotated") && !blob.isOnGround())
	{
		blob.set_u32("rotate", getGameTime()+20);
		blob.Untag("rotated");
	}
	if (blob.get_u32("rotate") > getGameTime())
	{
		f32 diff = blob.get_u32("rotate") - getGameTime();
		this.ResetTransform();
		this.RotateBy(blob.isFacingLeft() ? diff : -diff, Vec2f(0,0));
	}
	else this.ResetTransform();
	if (blob.isOnGround())
	{
		this.ResetTransform();
		this.RotateBy(blob.isFacingLeft() ? 10 : -10, Vec2f(0,0));
		blob.Tag("rotated");
	}
	if ((blob.get_u32("fireDelay") - (shootDelay - 1)) < getGameTime()) this.getSpriteLayer("tracer").SetVisible(false);
}

void onDie(CBlob@ this)
{
	ExplodeInventory(this);
	DoExplosion(this);
}

void ExplodeInventory(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	if (inv is null) return;
	for (u8 i = 0; i < inv.getInventorySlots().x*inv.getInventorySlots().y; i++)
	{
		CBlob@ b = inv.getItem(i);
		if (b is null) continue;
		if (!b.hasTag("bomber ammo")) continue;
		
		if (b.hasTag("heavy weight"))
		{
			b.set_f32("damage", 99.0f);
			b.set_bool("booming", true);
			this.server_Hit(b, b.getPosition(), Vec2f_zero, 99.0f, HittersAW::bullet);
		}
		else
			b.server_Die();
	}
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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob is null) return false;
	if (blob.getName() == "bf109" || blob.getName() == "bomberplane") return false;
	if (!blob.isCollidable() || blob.isAttached()){
		return false;
	} // no colliding against people inside vehicles
	if (blob.getRadius() > this.getRadius() || (blob.hasTag("tank") || blob.hasTag("apc") || blob.hasTag("truck")) ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (solid && this.hasTag("falling"))
	{
		ExplodeInventory(this);
		if (isServer()) this.server_Die();
	}

	f32 impact = this.getOldVelocity().getLength();
	if (impact > 10.0f && blob is null
		&& (!this.exists("collision_dmg_delay") || this.get_u32("collision_dmg_delay") < getGameTime()))
	{
		f32 dmg = Maths::Sqrt(impact)*(impact/2);
		if (isServer()) this.server_Hit(this, this.getPosition(), Vec2f(0, 0), dmg, 0, true);
		this.set_u32("collision_dmg_delay", getGameTime()+30);
	}

	if (blob !is null && (blob.hasTag("tank") || blob.hasTag("apc") || blob.hasTag("truck"))
	&& this.getVelocity().Length() > 2.0f)
	{
		f32 mod_self = 15.0f;
		f32 mod_target = 6.0f;

		f32 dmgself = this.getVelocity().getLength()*mod_self;
		if (isServer())
		{
			blob.server_Hit(this, this.getPosition(), this.getVelocity(), dmgself, Hitters::fall);
			this.server_Hit(blob, this.getPosition(), this.getVelocity(), this.getVelocity().getLength()*mod_target, Hitters::fall);
		}
	}
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
	
	for (int i = 0; i < (v_fastrender ? 10 : 35); i++)
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

	if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 1.0f;
	}

	if (customData == HittersAW::aircraftbullet) 	 
	{
		damage += 0.15f;
		return damage * 0.5f;
	}
	else if (customData == HittersAW::heavybullet) 
	{
		damage += 0.25f;
	}
	else if (customData == HittersAW::machinegunbullet) 
	{
		damage += 0.25f;
	}
	else if (customData == HittersAW::bullet)
	{
		return damage * 0.75f;
	}
	else if (customData == HittersAW::apbullet)
	{
		return damage * 2.5f;
	}

	return damage;
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	AttachmentPoint@ pilot = blob.getAttachments().getAttachmentPointByName("PILOT");
	if (pilot !is null && pilot.getOccupied() !is null)
	{
		CBlob@ driver_blob = pilot.getOccupied();
		if (!driver_blob.isMyPlayer()) return;

		// draw ammo count
		Vec2f oldpos = driver_blob.getOldPosition();
		Vec2f pos = driver_blob.getPosition();
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , 0);

		GUI::DrawSunkenPane(pos2d-Vec2f(40.0f, -48.0f), pos2d+Vec2f(18.0f, 70.0f));
		GUI::DrawIcon("Materials.png", 50, Vec2f(16,16), pos2d+Vec2f(-42, 48.0f), 0.75f, 1.0f);
		GUI::SetFont("menu");
		if (blob.getInventory() !is null)
			GUI::DrawTextCentered(""+blob.getInventory().getCount("mat_smallbomb"), pos2d+Vec2f(-6, 58.0f), SColor(255, 255, 255, 0));
		
		if (blob.get_u8("mode") != 0) return;
		f32 deg = blob.getAngleDegrees();
		bool fl = blob.isFacingLeft();
		f32 new_deg = (fl?180:0)+deg;
		int d = 64.0f;

		Vec2f offset = Vec2f(0, 0).RotateBy(new_deg);
		Vec2f len = Vec2f(d, 0).RotateBy(new_deg);
		GUI::DrawLine2D(pos2d + offset, pos2d + offset + len, SColor(155,0,200,0));

		Vec2f dir = blob.get_Vec2f("direction");
		dir.Normalize();
		dir.RotateBy(this.isFacingLeft() ? -32.5f : 32.5f);

		Vec2f len2 = Vec2f(d, 0).RotateBy(-dir.Angle()+180);
		GUI::DrawLine2D(pos2d + offset, pos2d + offset + len2, SColor(155,200,200,0));
		
		Vec2f aimdir = driver_blob.getPosition() - driver_blob.getAimPos();
		aimdir.Normalize();
		Vec2f len3 = Vec2f(d, 0).RotateBy(-aimdir.Angle() + 180);
		GUI::DrawLine2D(pos2d + offset, pos2d + offset + len3, SColor(155,200,0,0));

		f32 vellen_raw = blob.getShape().vellen;
		f32 vellen = vellen_raw*8;
		f32 rpm = blob.get_f32("velocity");
		
		f32 total_diff = len3.getAngleDegrees()-len2.getAngleDegrees();
		total_diff += total_diff > 180 ? -360 : total_diff < -180 ? 360 : 0;
		total_diff = Maths::Abs(Maths::Round(total_diff*10.0f)/10.0f);

		f32 angle_factor = 1.0f-(total_diff/90.0f);
		f32 rpm_factor = rpm/SPEED_MAX;
		f32 vel_factor = Maths::Min(1.0f, vellen_raw/windage);

		f32 force_factor_raw = Maths::Lerp(blob.get_f32("force_factor"), angle_factor * rpm_factor * vel_factor, 0.05f);
		blob.set_f32("force_factor", force_factor_raw);
		f32 force_factor = Maths::Round(1000.0f * force_factor_raw)/10.0f;

		string state = "ACTIVE";
		SColor col = SColor(155,255,255,255);
		SColor col_eng = col;
		
		if (blob.isOnGround())
		{
			if (vel_factor == 1)
			{
				state = "TAKE OFF";
				col_eng = SColor(155,255,155,0);
			}
			else
			{
				state = "GROUNDED";
				col_eng = SColor(155,0,255,0);
			}
		}
		else if (force_factor_raw < 0.5f)
		{
			state = "CRITICAL";
			col_eng = SColor(155,255,0,0);
		}

		GUI::DrawTextCentered("RPM: "+(Maths::Max(0, Maths::Round(rpm)*10))+".0\nEFF: "+force_factor+"%", pos2d+Vec2f(0,96), col);
		GUI::DrawTextCentered("ENG: "+state, pos2d+Vec2f(0,112), col_eng);
	}
}