#include "VehicleCommon.as"
#include "WarfareGlobal.as"
#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";
#include "GunStandard.as";
#include "PerksCommon.as";
#include "AllHashCodes.as";

void onInit(CBlob@ this)
{
	bool figtherplane = false;
	bool bomberplane = false;
	
    bool has_main_gun = false;
    bool has_mid_gun = false;

	bool pilot_controls_main_gun = false;
	bool pilot_controls_mid_gun = false;

	Vec2f main_gun_offset = Vec2f(-30, 8.5f);
	Vec2f mid_gun_offset = Vec2f(0, 0);

	// 2D arrays for an experimental method of removing the snapping between 360 and 0
	int[][] main_gun_angle = {{8, 8}};
	int[][] mid_gun_angle = {{180, 360-15}};

    u16 bullet_ttl = 45;
    u16 bullet_speed = 25;
    u8 hitter = HittersAW::aircraftbullet;

	u32 fire_rate = 2;
	f32 bullet_damage = 0.65f;
	f32 bullet_spread = 40.0f;

	bool bomb_drop = false;
	u16 bomb_drop_rate_smallbomb = 15;
	u16 bomb_drop_rate_bigbomb = 120;

	bool custom_propeller = false;
	Vec2f propeller_offset = Vec2f_zero;

	f32 max_speed = 60.0f;
	f32 acceleration = 2.5f;
	f32 windage = 2.0f;
	f32 land_rotation = 7;

    switch (this.getName().getHash())
    {
        case _bf109:
        {
			fire_rate = 1;

			figtherplane = true;
            has_main_gun = true;
			pilot_controls_main_gun = true;

            break;
        }
        case _b24:
        {
			bomberplane = true;
			bomb_drop = true;

			has_main_gun = true;
			has_mid_gun = true;

			int[][] _main_gun_angle = {{360-60, 360}, {0, 60}};
			int[][] _mid_gun_angle = {{90-15, 180}};
			main_gun_angle = _main_gun_angle;
			mid_gun_angle = _mid_gun_angle;

			main_gun_offset = Vec2f(-40, -2);
			mid_gun_offset = Vec2f(18, 8);
			
			fire_rate = 3;
			bullet_damage = 0.4f;
			bullet_speed = 20;
			bullet_ttl = 30;
			
			acceleration = 1.5f;
			custom_propeller = true;
			propeller_offset = Vec2f(-12,-2);
			max_speed = 53.0f;

			land_rotation = 5;
            break;
        }
		case _he111:
		{
			bomberplane = true;
			bomb_drop = true;
			
			has_main_gun = true;
			has_mid_gun = true;
			int[][] _main_gun_angle = {{360-70, 360}, {0, 70}};
			int[][] _mid_gun_angle = {{180-45, 185}};
			main_gun_angle = _main_gun_angle;
			mid_gun_angle = _mid_gun_angle;

			main_gun_offset = Vec2f(-40, -2);
			mid_gun_offset = Vec2f(7, 9);

			fire_rate = 3;
			bullet_damage = 0.4f;
			bullet_speed = 20;
			bullet_ttl = 30;
			bullet_spread = 30.0f;
			bomb_drop_rate_smallbomb = 12;

			acceleration = 1.5f;
			custom_propeller = true;
			propeller_offset = Vec2f(-44,3);
			max_speed = 50.0f;

			land_rotation = 3;
            break;
		}
		case _pe2:
		{
			bomberplane = true;
			bomb_drop = true;

			has_main_gun = true;
			has_mid_gun = true;
			int[][] _main_gun_angle = {{360-60, 360}, {0, 60}};
			int[][] _mid_gun_angle = {{180, 360-5}};
			main_gun_angle = _main_gun_angle;
			mid_gun_angle = _mid_gun_angle;

			main_gun_offset = Vec2f(-38, -5);
			mid_gun_offset = Vec2f(14.5f, -8);

			fire_rate = 4;
			bullet_damage = 0.6f;
			bullet_speed = 22;
			bullet_ttl = 30;
			bomb_drop_rate_bigbomb = 75;

			acceleration = 1.5f;
			custom_propeller = true;
			propeller_offset = Vec2f(-35,6);
			max_speed = 52.0f;

			land_rotation = 6;
            break;
		}
    }

	if (figtherplane) this.Tag("fighterplane");
	if (bomberplane) this.Tag("bomberplane");

    this.set_bool("has_main_gun", has_main_gun);
    this.set_bool("has_mid_gun", has_mid_gun);

	this.set_bool("pilot_controls_main_gun", pilot_controls_main_gun);
	this.set_bool("pilot_controls_mid_gun", pilot_controls_mid_gun);

	this.set_Vec2f("main_gun_offset", main_gun_offset);
	this.set_Vec2f("mid_gun_offset", mid_gun_offset);

	this.set("main_gun_angle", main_gun_angle);
	this.set("mid_gun_angle", mid_gun_angle);

	this.set_f32("fire_rate", fire_rate);
	this.set_f32("bullet_damage", bullet_damage);
	this.set_f32("bullet_spread", bullet_spread);

	this.set_bool("bomb_drop", bomb_drop);
	this.set_u16("bomb_drop_rate_smallbomb", bomb_drop_rate_smallbomb);
	this.set_u16("bomb_drop_rate_bigbomb", bomb_drop_rate_bigbomb);

	this.set_bool("custom_propeller", custom_propeller);
	this.set_Vec2f("propeller_offset", propeller_offset);

	this.set_f32("max_speed", max_speed);
	this.set_f32("windage", windage);
	this.set_f32("land_rotation", land_rotation);
	this.set_f32("acceleration", acceleration);

    this.set_u8("TTL", bullet_ttl);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", bullet_speed);
	this.set_s32("custom_hitter", hitter);

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
    this.addCommandID("shoot bullet");

	this.set_f32("velocity", 0.0f);
	this.set_u8("mode", 0);
	
	this.set_bool("map_damage_raycast", true);
	this.Tag("map_damage_dirt");
	
	this.Tag("vehicle");
	this.Tag("aerial");
	this.Tag("wooden");
	this.Tag("plane");
	this.Tag("pass_bullet");
	this.Tag("parachute_ondetach");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("Aircraft_Loop.ogg");
	sprite.SetEmitSoundSpeed(0.0f);
	sprite.SetEmitSoundPaused(false);

	if (custom_propeller)
	{
		CSpriteLayer@ l = sprite.addSpriteLayer("propeller", "Propellers.png", 16, 32);
		if (l !is null)
		{
			Animation@ anim = l.addAnimation("default", 0, true);
			int[] frames = {0, 1, 2, 3};

			anim.AddFrames(frames);
			l.SetAnimation(anim);
			l.SetRelativeZ(1.0f);
		}
	}

	this.getShape().SetRotationsAllowed(true);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.set_Vec2f("direction", Vec2f(0, 0));
	
	if (getNet().isServer() &&
		(has_main_gun || has_mid_gun))
	{
		u8 ammo_stacks = 2;

		for (u8 i = 0; i < ammo_stacks; i++)
		{
			CBlob@ ammo = server_CreateBlob("ammo");
			if (ammo !is null)
			{
				if (!this.server_PutInInventory(ammo))
					ammo.server_Die();
			}
		}
	}
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
		this.set_u32("no_more_proj", 0);
	}
	if (this.hasTag("aerial") && getGameTime()%10==0)
	{
		if (getMap() !is null)
		{
			if (this.getPosition().x <= 8.0f || this.getPosition().x >= (getMap().tilemapwidth*8)-8.0f) this.server_Hit(this, this.getPosition(), this.getVelocity(), 1.0f, Hitters::fall);
		}
	}

	AttachmentPoint@ ap_gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (ap_gunner !is null)
	{
		CBlob@ gunner = ap_gunner.getOccupied();
		if (gunner !is null)
		{
			ControlMainGun(this, gunner, ap_gunner);
			ControlMidGun(this, gunner, ap_gunner);
		}
	}

	AttachmentPoint@ ap_pilot = this.getAttachments().getAttachmentPointByName("PILOT");
	if (ap_pilot !is null)
	{
		CBlob@ pilot = ap_pilot.getOccupied();
		
		if (pilot !is null)
		{
			StandardControls(this, pilot, ap_pilot);

			if (!this.isOnGround())
			{
				if (this.get_bool("bomb_drop")) DroppingBombsLogic(this, pilot, ap_pilot);
				if (this.get_bool("pilot_controls_main_gun")) ControlMainGun(this, pilot, ap_pilot);
				if (this.get_bool("pilot_controls_mid_gun")) ControlMidGun(this, pilot, ap_pilot);
			}
		}
	}
	else if (this.isOnGround()) this.set_f32("velocity", Maths::Max(0, this.get_f32("velocity") - 0.25f));
	else this.set_f32("velocity", Maths::Max(0, this.get_f32("velocity") - 0.01f));

	FallingLogic(this, ap_pilot);
	MovementLogic(this);

	if (this.hasTag("falling")) this.setAngleDegrees(this.getAngleDegrees() + (Maths::Sin(getGameTime() / 5.0f) * 6.0f));
}

void StandardControls(CBlob@ this, CBlob@ pilot, AttachmentPoint@ ap_pilot)
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
		dir = this.isFacingLeft() ? Vec2f(-8.0f,0) : Vec2f(8.0f,0);

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

	f32 max_speed = this.get_f32("max_speed");
	f32 windage = this.get_f32("windage");

	f32 vellen = this.getShape().vellen;
	f32 vellen_factor = Maths::Max((vellen*6)/max_speed, mod);
	dir = Vec2f_lerp(this.get_Vec2f("direction"), dir, mod * vellen_factor);

	if (vellen < windage)
	{
		dir.y = Maths::Lerp(dir.y, -0.0f, (1.0f-vellen/5.0f) / (4/ground_factor));
		if (!og) this.set_f32("velocity", this.get_f32("velocity")*0.95f);
	}

	bool pressed_w = ap_pilot.isKeyPressed(key_up);
	bool pressed_s = ap_pilot.isKeyPressed(key_down);
	bool pressed_key = ap_pilot.isKeyPressed(key_action1) && !this.isOnGround() && this.getVelocity().Length() > 4.0f;

	if (this.hasTag("falling"))
	{
		Vec2f old_pos = this.getOldPosition();
		Vec2f pos = this.getPosition();
		dir.RotateBy(this.isFacingLeft() ? -1.0f * (getGameTime()-this.get_u32("falling_time")) * 0.1f : 0.1f * (getGameTime()-this.get_u32("falling_time")));
	}

	f32 velocity_gain = this.get_f32("acceleration");
	if (pressed_w) 
	{
		this.set_f32("velocity", Maths::Min(max_speed, this.get_f32("velocity") + velocity_gain));
	}
	else if (this.get_f32("velocity") > 0.0f)
	{
		this.set_f32("velocity", Maths::Min(max_speed, this.get_f32("velocity") - (pressed_s ? velocity_gain : 0.5f)));
	}
	else this.set_f32("velocity", 0);

	if (!pressed_w && (this.getVelocity().Length() <= 3.0f))
	{
		this.set_f32("velocity", Maths::Max(0, this.get_f32("velocity") - 3.0f));
	}
	
	this.set_Vec2f("direction", dir);
}

void MovementLogic(CBlob@ this)
{
	const f32 hmod = 1.0f;
	f32 v = this.get_f32("velocity");
	Vec2f d = this.get_Vec2f("direction");

	AttachmentPoint@ ap_pilot = this.getAttachments().getAttachmentPointByName("PILOT");
	bool has_pilot = ap_pilot !is null && ap_pilot.getOccupied() !is null;

	if (!this.hasAttached() && !this.isOnGround() && this.getVelocity().Length() > 0.5f
	&& (this.getAngleDegrees() < 85 || this.getAngleDegrees() > 275))
	{
		d.RotateBy(this.isFacingLeft() ? -0.75f - XORRandom(50)*0.01f : 0.75f + XORRandom(50)*0.01f);
		this.set_Vec2f("direction", d);
	}
	
	Vec2f force = -d * v * hmod;
	this.AddForce(force);

	Vec2f vel = this.getVelocity();
	vel.x = Maths::Round(vel.x * 100.0f) * 0.01f;
	vel.y = Maths::Round(vel.y * 100.0f) * 0.01f;

	f32 vellen = vel.Length();
	bool facingleft = this.isFacingLeft();

	u32 last_touched_ground = this.exists("last_touched_ground") ? this.get_u32("last_touched_ground") : 0;
	u32 touch_diff = getGameTime() - last_touched_ground;
	
	bool pressed_w = ap_pilot.isKeyPressed(key_up);
	bool has_ground = getMap().rayCastSolid(this.getPosition(), this.getPosition() + Vec2f(0, 16).RotateBy(this.getAngleDegrees())) || getMap().rayCastSolid(this.getPosition(), this.getPosition() + Vec2f(0, -16).RotateBy(this.getAngleDegrees()));
	
	f32 angle = -vel.Angle();
	if (vellen > (has_ground ? 2.5f : 0.25f) && (v > 0.0f || touch_diff > 45))
	{
		this.setAngleDegrees(facingleft ? angle+180 : angle);
	}

	if (has_pilot)
	{
		if (this.getVelocity().Length() < 0.1f)
			this.SetFacingLeft(this.get_bool("last_faceleft"));
		else
			this.SetFacingLeft(this.getVelocity().x < 0);
	}
	else if (has_ground || vellen < 2.0f)
	{
		this.set_f32("velocity", Maths::Floor(v * 0.5f * 10) * 0.1f);
	}
	this.set_bool("last_faceleft", this.isFacingLeft());

	// sounds
	if (!isClient()) return;
	 
	f32 mod = 1.0f;
	if (this.hasTag("bomberplane")) mod = 0.825f;

	f32 sound_speed = 0.5f + (this.get_f32("velocity") / this.get_f32("max_speed") * 0.4f) * (this.getVelocity().Length() * 0.15f);
	sound_speed *= mod;

	if (this.hasAttached() && v > 4.0f)
	{
		f32 max_speed = this.get_f32("max_speed");
		this.set_f32("soundspeed", sound_speed);
	}
	else
	{
		if (this.hasAttached() && v < 4.0f)
		{
			this.add_f32("soundspeed", 0.05f);
			if (this.get_f32("soundspeed") > 0.5f * mod) this.set_f32("soundspeed", 0.5f * mod);
		}
		else
		{
			this.set_f32("soundspeed", Maths::Max(0, this.get_f32("soundspeed") - 0.01f));
		}
	}

	Animation@ anim = this.getSprite().getAnimation("default");
	if (anim !is null)
	{
		anim.time = Maths::Max(1, Maths::Min(5, (1.0f-this.get_f32("soundspeed")) * 10));

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

void FallingLogic(CBlob@ this, AttachmentPoint@ ap_pilot)
{
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
			this.setVelocity(vel * 0.98f);
		}
	}
}

void DroppingBombsLogic(CBlob@ this, CBlob@ pilot, AttachmentPoint@ ap_pilot)
{
	if (ap_pilot.isKeyPressed(key_action3) && !this.isOnGround() && this.getVelocity().Length() > 5.0f && this.get_u32("lastDropTime") < getGameTime()) 
	{
		CInventory@ inv = this.getInventory();
		if (inv !is null) 
		{
			u32 itemCount = inv.getItemsCount();
			bool can_drop =  this.getAngleDegrees() > 335 || this.getAngleDegrees() < 45;

			for (u8 i = 0; i < itemCount; i++)
			{
				CBlob@ item = inv.getItem(i);
				if (item is null || item.getName() == "ammo") continue;

				if (can_drop) 
				{
					u16 droptime = this.get_u16("bomb_drop_rate_smallbomb");
					u16 droptime_heavy = this.get_u16("bomb_drop_rate_bigbomb");

					bool not_ammo = item.getName() != "ammo";
					u32 quantity = item.getQuantity();

					if (!item.hasTag("bomber ammo") && not_ammo)
					{ 
						if (isServer())
						{
							CBlob@ b = server_CreateBlob("paracrate", this.getTeamNum(), this.getPosition()+Vec2f(0,8));
							if (b !is null)
							{
								b.Tag("no_expiration");
								for (u8 j = 0; j < inv.getItemsCount(); j++)
								{
									CBlob@ put = inv.getItem(j);
									if (put is null) continue;
									if (put.getName() == "mat_smallbomb"
										|| put.getName() == "ammo") continue;

									this.server_PutOutInventory(put);
									b.server_PutInInventory(put);
									j--;
								}
							}
						}

						this.set_u32("lastDropTime", getGameTime() + droptime);
						break;
					}
					else if (not_ammo)
					{
						const f32 v = this.get_f32("velocity");
						Vec2f d = this.get_Vec2f("direction");

						if (isServer())
						{
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

						if (isClient() && itemCount > 0) 
							this.getSprite().PlaySound("bridge_open", 1.0f, 1.0f);

						this.set_u32("lastDropTime", getGameTime() + (item !is null && item.hasTag("heavy weight") ? droptime_heavy : droptime));
					}
					break;
				}
			}
		}
	}
}

void ControlMainGun(CBlob@ this, CBlob@ pilot, AttachmentPoint@ ap_pilot)
{
	bool pressed_key = ap_pilot.isKeyPressed(key_action1);
	
	if (this.get_u32("no_more_proj") < getGameTime() && pilot.isMyPlayer() && pressed_key)
	{
		bool can_attack = canShoot(this);

		if (can_attack)
		{
			int[][] angles;
			this.get("main_gun_angle", angles);

			bool facingleft = this.isFacingLeft();
			Vec2f pos = this.getPosition();
			Vec2f offset = this.get_Vec2f("main_gun_offset");
			if (!facingleft) offset.x = -offset.x;

			offset.RotateBy(this.getAngleDegrees());
			ShootBullet(this, ap_pilot, angles, pos+offset, this.get_u8("speed"));
		}
	}
}

void ControlMidGun(CBlob@ this, CBlob@ pilot, AttachmentPoint@ ap_pilot)
{
	bool pressed_key = ap_pilot.isKeyPressed(key_action2);
	
	if (this.get_u32("no_more_proj") < getGameTime() && pilot.isMyPlayer() && pressed_key)
	{
		bool can_attack = canShoot(this);

		if (can_attack)
		{
			int[][] angles;
			this.get("mid_gun_angle", angles);

			bool facingleft = this.isFacingLeft();
			Vec2f pos = this.getPosition();
			Vec2f offset = this.get_Vec2f("mid_gun_offset");
			if (!facingleft) offset.x = -offset.x;

			offset.RotateBy(this.getAngleDegrees());
			ShootBullet(this, ap_pilot, angles, pos + offset, this.get_u8("speed"));
		}
	}
}

bool canShoot(CBlob@ this)
{
	bool can_shoot = false;

	CInventory@ inv = this.getInventory();
	if (inv !is null)
	{
		for (u8 i = 0; i < inv.getItemsCount(); i++)
		{
			if (inv.getItem(i) is null || inv.getItem(i).getName() != "ammo")
			{
				this.server_PutOutInventory(inv.getItem(i));
				continue;
			}

			can_shoot = true;
			break;
		}
	}

	return can_shoot;
}

f32 getAimAngle(CBlob@ this, AttachmentPoint@ ap_pilot, Vec2f offset, int[][] angles)
{
	Vec2f aimpos = ap_pilot.getAimPos();
	Vec2f pos = offset;
	Vec2f dir = aimpos - pos;
	bool facingleft = this.isFacingLeft();
	f32 angle = (facingleft ? 0 : 360.0f) - dir.Angle() - this.getAngleDegrees();
	
	while (angle < 0) angle += 360;
	while (angle >= 360) angle -= 360;

	f32 closestAngle = angle;
	f32 minDistance = 360;

	for (int i = 0; i < angles.length; i++)
	{
		int start = angles[i][0];
		int end = angles[i][1];

		if (facingleft)
		{
		    start = (540 - start) % 360;
		    end = (540 - end) % 360;
			
		    int temp = start;
		    start = end;
		    end = temp;
		}

		if (start == end)
		{
			return start;
		}

		if (start > end)
		{
			if (angle >= start || angle <= end)
			{
				return angle;
			}
			else
			{
				f32 distToStart = Maths::Min(Maths::Abs(angle - start), 360 - Maths::Abs(angle - start));
				f32 distToEnd = Maths::Min(Maths::Abs(angle - end), 360 - Maths::Abs(angle - end));
				if (distToStart < minDistance)
				{
					closestAngle = start;
					minDistance = distToStart;
				}
				if (distToEnd < minDistance)
				{
					closestAngle = end;
					minDistance = distToEnd;
				}
			}
		}
		else
		{
			if (angle >= start && angle <= end)
			{
				return angle;
			}
			else
			{
				f32 distToStart = Maths::Min(Maths::Abs(angle - start), 360 - Maths::Abs(angle - start));
				f32 distToEnd = Maths::Min(Maths::Abs(angle - end), 360 - Maths::Abs(angle - end));
				if (distToStart < minDistance)
				{
					closestAngle = start;
					minDistance = distToStart;
				}
				if (distToEnd < minDistance)
				{
					closestAngle = end;
					minDistance = distToEnd;
				}
			}
		}
	}
	
	return closestAngle;
}

void ShootBullet(CBlob@ this, AttachmentPoint@ ap_pilot, int[][] angles, Vec2f shoot_pos, f32 arrowspeed)
{
	if (this.get_u32("next_shoot") > getGameTime()) return;

	if (isClient())
		this.getSprite().PlaySound("AssaultFire.ogg", 1.25f, 0.95f + XORRandom(15) * 0.01f);

	f32 angle = getAimAngle(this, ap_pilot, shoot_pos, angles) + this.getAngleDegrees();
	f32 bullet_spread = this.get_f32("bullet_spread");
	angle += XORRandom(bullet_spread + 1) * 0.1f - bullet_spread * 0.1 * 0.5f;

	bool has_owner = false;
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName(this.hasTag("fighterplane") ? "PILOT" : "GUNNER");
	if (ap !is null && ap.getOccupied() !is null && ap.getOccupied().getPlayer() !is null)
		has_owner = true;

	shootVehicleGun(has_owner ? ap.getOccupied().getNetworkID() : this.getNetworkID(), this.getNetworkID(),
		angle, shoot_pos,
		Vec2f_zero, bullet_spread, 1, 0, 0.5f, 0.75f, 1,
		this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));

	if (has_owner && ap.getOccupied().isMyPlayer())
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("shoot bullet"), params);
	}
	
	f32 fire_rate = this.get_f32("fire_rate");
	this.set_u32("next_shoot", getGameTime()+fire_rate);
	this.set_u32("no_more_proj", getGameTime()+fire_rate);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot bullet"))
	{
		if (getNet().isServer())
		{
			CInventory@ inv = this.getInventory();
			if (inv !is null)
			{
				for (u8 i = 0; i < inv.getItemsCount(); i++)
				{
					if (XORRandom(2) != 0) continue;

					CBlob@ ammo = inv.getItem(i);
					if (ammo is null || ammo.getName() != "ammo") continue;

					if (ammo.getQuantity() > 1) ammo.server_SetQuantity(ammo.getQuantity()-1);
					else ammo.server_Die();

					break;
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
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
	if (blob is null && solid) this.set_u32("last_touched_ground", getGameTime());

	if (isServer())
	{
		if (solid && this.hasTag("falling"))
			this.server_Die();

		f32 impact = this.getOldVelocity().getLength();
		if (impact > 10.0f && blob is null
			&& (!this.exists("collision_dmg_delay") || this.get_u32("collision_dmg_delay") < getGameTime()))
		{
			this.server_Hit(this, this.getPosition(), Vec2f(0, 0), Maths::Sqrt(impact)*(impact/2), 0, true);
			this.set_u32("collision_dmg_delay", getGameTime()+30);
		}

		if (blob !is null && (blob.hasTag("tank") || blob.hasTag("apc") || blob.hasTag("truck"))
		&& this.getVelocity().Length() > 2.0f)
		{
			f32 mod_self = 15.0f;
			f32 mod_target = 4.0f;
			blob.server_Hit(this, this.getPosition(), this.getVelocity(), this.getVelocity().getLength()*mod_self, Hitters::fall);
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


	this.set_f32("map_damage_radius", (30.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.50f);
	
	Explode(this, 30.0f + random, 32.0f);
	
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
	if (!v_fastrender) this.getSprite().Gib();
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

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	if (oldHealth > this.getInitialHealth()/2 && this.getHealth() <= this.getInitialHealth()/2)
		sprite.SetAnimation("damaged");
	else if (oldHealth < this.getInitialHealth()/2 && this.getHealth() >= this.getInitialHealth()/2)
		sprite.SetAnimation("default");
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
	
	if (this.hasTag("figtherplane"))
	{
		if (hitterBlob.getName() == "missile_javelin")
		{
			return damage * 1.0f;
		}

		if (customData == HittersAW::aircraftbullet) 	 
		{
			damage += 0.1f;
			return damage * 0.35f;
		}
		else if (customData == HittersAW::heavybullet) 
		{
			damage += 0.05f;
			return damage;
		}
		else if (customData == HittersAW::machinegunbullet) 
		{
			damage += 0.15f;
			return damage;
		}
		else if (customData == HittersAW::bullet)
		{
			return damage * 0.65f;
		}
		else if (customData == HittersAW::apbullet)
		{
			return damage * 2.5f;
		}
	}
	else if (this.hasTag("bomberplane"))
	{
		if (hitterBlob.getName() == "missile_javelin" || hitterBlob.hasTag("rpg"))
		{
			return damage * 1.5f;
		}

		if (customData == HittersAW::aircraftbullet) 	 
		{
			//damage += 0.25f;
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
	}

	return damage;
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	f32 land_rotation = blob.get_f32("land_rotation");
	f32 rot = blob.get_f32("sprite_rotation");

	f32 step_rot = 0.1f;
	bool facingleft = blob.isFacingLeft();

	if (blob.isOnGround()) rot = land_rotation;
	else if (rot >= step_rot) rot -= step_rot;
	blob.set_f32("sprite_rotation", rot);

	f32 rotation = facingleft ? rot : -rot;
	this.ResetTransform();
	this.RotateBy(rotation, Vec2f_zero);

	CSpriteLayer@ propeller = this.getSpriteLayer("propeller");
	if (propeller !is null)
	{
		propeller.ResetTransform();
		propeller.SetOffset(blob.get_Vec2f("propeller_offset").RotateBy(rot));
		propeller.RotateBy(rotation, Vec2f_zero);

		Animation@ anim = propeller.getAnimation("default");
		if (anim !is null)
		{
			anim.time = Maths::Max(1, Maths::Min(5, (1.0f-blob.get_f32("soundspeed")) * 10));

			if (anim.time == 5 && blob.get_f32("soundspeed") == 0)
			{
				blob.getSprite().SetFrameIndex(0);
				anim.time = 0;
			}
		}
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	bool pilot_controls_main_gun = blob.get_bool("pilot_controls_main_gun");
	bool pilot_controls_mid_gun = blob.get_bool("pilot_controls_mid_gun");
	bool show_ammo = pilot_controls_main_gun || pilot_controls_mid_gun;

	AttachmentPoint@ gunner = blob.getAttachments().getAttachmentPointByName(show_ammo ? "PILOT" : "GUNNER");
	if (gunner !is null && gunner.getOccupied() !is null)
	{
		CBlob@ gunner_blob = gunner.getOccupied();
		if (!gunner_blob.isMyPlayer()) return;

		Vec2f oldpos = gunner_blob.getOldPosition();
		Vec2f pos = gunner_blob.getPosition();
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , 0);

		GUI::DrawSunkenPane(pos2d-Vec2f(40.0f, -48.0f), pos2d+Vec2f(18.0f, 70.0f));
		GUI::DrawIcon("Materials.png", 31, Vec2f(16,16), pos2d+Vec2f(-40, 42.0f), 0.75f, 1.0f);
		GUI::SetFont("menu");
		if (blob.getInventory() !is null)
			GUI::DrawTextCentered(""+blob.getInventory().getCount("ammo"), pos2d+Vec2f(-8, 58.0f), SColor(255, 255, 255, 0));
	}

	AttachmentPoint@ pilot = blob.getAttachments().getAttachmentPointByName("PILOT");
	if (pilot !is null && pilot.getOccupied() !is null)
	{
		CBlob@ pilot_blob = pilot.getOccupied();
		if (!pilot_blob.isMyPlayer()) return;

		// draw ammo count
		Vec2f oldpos = pilot_blob.getOldPosition();
		Vec2f pos = pilot_blob.getPosition();
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , 0);

		if (!show_ammo)
		{
			GUI::DrawSunkenPane(pos2d-Vec2f(40.0f, -48.0f), pos2d+Vec2f(18.0f, 70.0f));
			GUI::DrawIcon("Materials.png", 50, Vec2f(16,16), pos2d+Vec2f(-40, 42.0f), 0.75f, 1.0f);
			if (blob.getInventory() !is null)
				GUI::DrawTextCentered(""+blob.getInventory().getCount("mat_smallbomb"), pos2d+Vec2f(-8, 58.0f), SColor(255, 255, 255, 0));
		}

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

		Vec2f len2 = Vec2f(d, 0).RotateBy(-dir.Angle()+180);
		GUI::DrawLine2D(pos2d + offset, pos2d + offset + len2, SColor(155,200,200,0));
		
		Vec2f aimdir = pilot_blob.getPosition() - pilot_blob.getAimPos();
		aimdir.Normalize();
		Vec2f len3 = Vec2f(d, 0).RotateBy(-aimdir.Angle() + 180);
		GUI::DrawLine2D(pos2d + offset, pos2d + offset + len3, SColor(155,200,0,0));

		f32 vellen_raw = blob.getShape().vellen;
		f32 vellen = vellen_raw*8;
		f32 rpm = blob.get_f32("velocity");
		
		f32 total_diff = len3.getAngleDegrees()-len2.getAngleDegrees();
		total_diff += total_diff > 180 ? -360 : total_diff < -180 ? 360 : 0;
		total_diff = Maths::Abs(Maths::Round(total_diff*10.0f)/10.0f);
		
		f32 max_speed = blob.get_f32("max_speed");
		f32 windage = blob.get_f32("windage");

		f32 angle_factor = 1.0f-(total_diff/90.0f);
		f32 rpm_factor = rpm/max_speed;
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

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool canBePutInInventory(CBlob@ inventoryBlob)
{
	return false;
}

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

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}