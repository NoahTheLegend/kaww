#include "VehicleCommon.as"
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as"
#include "PerksCommon.as";

string[] smoke = 
{
	"Explosion.png",
	"LargeSmoke"
};

const u16 cooldown_time = 360;
const f32 damage_modifier = 1.25f;

const s16 init_gunoffset_angle = -2; // up by so many degrees
const u8 barrel_compression = 12; // max barrel movement
const u16 recoil = 180;

const u8 shootDelay = 3;
const f32 projDamage = 0.25f;

// 0 == up, 90 == sideways
f32 high_angle = 76.5f; // upper depression limit
f32 low_angle = 99.0f; // lower depression limit

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("blocks bullet");

	// machinegun stuff
	this.set_u8("TTL", 75);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 15);
	this.set_s32("custom_hitter", HittersAW::machinegunbullet);
	this.addCommandID("shoot");

	this.Tag("fireshe");
	this.set_f32("damage_modifier", damage_modifier);

	this.set_u8("type", this.getName() == "mausturret" ? 0 : this.getName() == "pinkmausturret" ? 1 : 2);

	Vehicle_Setup(this,
	    0.0f, // move speed
	    0.3f,  // turn speed
	    Vec2f(0.0f, 0.56f), // jump out velocity
	    true);  // inventory access

	VehicleInfo@ v; if (!this.get("VehicleInfo", @v)) {return;}

	Vehicle_AddAmmo(this, v,
	    cooldown_time, // fire delay (ticks)
	    1, // fire bullets amount
	    1, // fire cost
	    "mat_bolts", // bullet ammo config name
	    "105mm Shells", // name for ammo selection
	    "ballista_bolt", // bullet config name
	    //"sound_100mm", // fire sound
		"sound_128mm",
	    "EmptyFire", // empty fire sound
	    Vehicle_Fire_Style::custom,
	    Vec2f(-6.0f, -4.0f), // fire position offset
	    1); // charge time

	Vehicle_SetWeaponAngle(this, low_angle, v);
	this.set_string("autograb blob", "mat_bolts");

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.collideWhenAttached = true;	 // we have our own map collision

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ shells = server_CreateBlob("mat_bolts");
		if (shells !is null)
		{
			if (!this.server_PutInInventory(shells))
				shells.server_Die();
		}

		CBlob@ ammo = server_CreateBlob("ammo");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();

			ammo.server_SetQuantity(ammo.getQuantity()*3);
		}
	}

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "Maus.png", 16, 48);

	if (arm !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = arm.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(10 + this.get_u8("type"));
		}
	}

	CSpriteLayer@ mg = sprite.addSpriteLayer("mg", "Maus.png", 16, 48);
	if (mg !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = mg.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(20 + this.get_u8("type"));
		}
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.set_f32("gunelevation", (this.getTeamNum() == teamright ? 270 : 90) - init_gunoffset_angle);

	sprite.SetEmitSound("Hydraulics.ogg");
	sprite.SetEmitSoundPaused(true);
	sprite.SetEmitSoundVolume(1.25f);
}

f32 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null && !gunner.isKeyPressed(key_action2) && !this.hasTag("broken"))
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos()+Vec2f(0,6);

		if ((!facing_left && aim_vec.x < 0) ||
		        (facing_left && aim_vec.x > 0))
		{
			this.getSprite().SetEmitSoundPaused(false);
			this.getSprite().SetEmitSoundVolume(1.25f);

			if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

			aim_vec.RotateBy((facing_left ? 1 : -1) * this.getAngleDegrees());

			angle = (-(aim_vec).getAngle() + 270.0f);
			angle = Maths::Max(high_angle , Maths::Min(angle , low_angle));

			not_found = false;
		}
		else
		{
			this.getSprite().SetEmitSoundPaused(true);
		}
	}

	if (not_found)
	{
		angle = Maths::Abs(Vehicle_getWeaponAngle(this, v));
		this.Tag("nogunner");
		return (facing_left ? -angle : angle);
	}

	this.Untag("nogunner");
	if (facing_left) { angle *= -1; }

	return angle;
}

void onTick(CBlob@ this)
{
	s16 currentAngle = this.get_f32("gunelevation");

	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	if (getGameTime() % 5 == 0)
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW");
		if (point !is null && point.getOccupied() !is null)
		{
			CBlob@ tur = point.getOccupied();
			tur.SetFacingLeft(this.isFacingLeft());
			if (isServer()) tur.server_setTeamNum(this.getTeamNum());
		}
	}

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		bool broken = this.hasTag("broken");
		if (!broken) Vehicle_StandardControls(this, v);

		if (v.cooldown_time > 0)
		{
			v.cooldown_time--;
		}

		f32 angle = getAngle(this, v.charge, v);
		s16 targetAngle;
		bool isOperator = false;
		
		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null && !broken)
		{
			CBlob@ hooman = gunner.getOccupied();
			Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

			bool flip = this.isFacingLeft();
			CBlob@ realPlayer = getLocalPlayerBlob();
			const bool pressed_m3 = gunner.isKeyPressed(key_action3);
			const f32 flip_factor = flip ? -1 : 1;
			f32 angle = this.get_f32("gunelevation")-90 + this.getAngleDegrees();

			if (pressed_m3)
			{
				if (getGameTime() > this.get_u32("fireDelayGun") && hooman.isMyPlayer())
				{
					if (this.hasBlob("ammo", 1))
					{
						f32 spread = XORRandom(5)-2.5f;
						Vec2f shootpos = Vec2f(26*flip_factor,-2);
						shootVehicleGun(hooman.getNetworkID(), this.getNetworkID(),
							angle+spread, this.getPosition()+shootpos.RotateBy(this.getAngleDegrees()),
								gunner.getAimPos(), 0.0f, 1, 0, 0.4f, 0.6f, 2,
									this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));	

						CBitStream params;
						params.write_s32(this.get_f32("gunelevation")-90);
						params.write_Vec2f(this.getPosition()+(shootpos-Vec2f(6*flip_factor,0)).RotateBy(this.getAngleDegrees()));

						this.SendCommand(this.getCommandID("shoot"), params);
						this.set_u32("fireDelayGun", getGameTime() + (shootDelay));
					}
				}
			}
			
			CPlayer@ p = gunner.getOccupied().getPlayer();
			PerkStats@ stats;
			if (p !is null && p.get("PerkStats", @stats))
			{
				isOperator = stats.id == Perks::operator;
				high_angle = 76.5f - stats.top_angle;
				low_angle =  99.0f + stats.down_angle;
			}

			bool facing_left = this.isFacingLeft();
		}

		if (angle < 0)
		{
			targetAngle = 360 + angle; // facing left
		}
		else
		{
			targetAngle = angle;
		}

		this.getSprite().SetEmitSoundPaused(true);

		if (!this.hasTag("nogunner"))
		{
			int factor = 1;
			if (isOperator) factor = 2;

			int difference = Maths::Abs(currentAngle - targetAngle);

			if (difference > 1)
			{	
				if (difference < 180) {
					if (currentAngle < targetAngle) currentAngle += factor;
					else currentAngle -= factor;
				} else {
					if (currentAngle < targetAngle) currentAngle += factor;
					else currentAngle += factor;
				}
				this.getSprite().SetEmitSoundPaused(false);
				this.getSprite().SetEmitSoundVolume(1.25f);

				this.set_f32("gunelevation", ((currentAngle % 360.0f) + 360.0f) % 360.0f);
				Vehicle_SetWeaponAngle(this, this.get_f32("gunelevation"), v);
			}
			else if (difference <= factor)
			{
				factor = 1;
			}
		}

		if (this.isFacingLeft()) this.set_f32("gunelevation", Maths::Min(360.0f-high_angle, Maths::Max(this.get_f32("gunelevation") , 360.0f-low_angle)));
		else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));
	}

	if (this.isFacingLeft()) this.set_f32("gunelevation", Maths::Min(360.0f-high_angle, Maths::Max(this.get_f32("gunelevation") , 360.0f-low_angle)));
	else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));
	
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
	if (arm !is null)
	{
		arm.ResetTransform();
		arm.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 8.0f));
		arm.SetOffset(Vec2f(-19.0f + (this.isFacingLeft() ? -1.0f : 0.0f), -10.0f + (this.isFacingLeft() ? -0.5f : 0.5f)));
		arm.SetOffset(arm.getOffset() - Vec2f(-barrel_compression + Maths::Min(v.getCurrentAmmo().fire_delay - v.cooldown_time, barrel_compression), 0).RotateBy(this.isFacingLeft() ? 90+this.get_f32("gunelevation") : 90-this.get_f32("gunelevation")));
		arm.SetRelativeZ(-20.0f);

		CSpriteLayer@ mg = sprite.getSpriteLayer("mg");
		if (mg !is null)
		{
			mg.ResetTransform();
			mg.ScaleBy(Vec2f(1.1f,1.1f));
			mg.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 8.0f));
			mg.SetOffset(Vec2f(-16.0f + (this.isFacingLeft() ? -1.0f : 0.0f), -9.0f + (this.isFacingLeft() ? -0.5f : 0.5f)));
			mg.SetOffset(mg.getOffset() - Vec2f(-barrel_compression + Maths::Min(v.getCurrentAmmo().fire_delay - v.cooldown_time, barrel_compression), 0).RotateBy(this.isFacingLeft() ? 90+this.get_f32("gunelevation") : 90-this.get_f32("gunelevation")));
			mg.SetRelativeZ(-19.0f);
		}
	}
}


void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 35.0f);
	this.set_f32("map_damage_ratio", 0.41f);
	
	Explode(this, 156.0f, 2.0f);
	if (isClient())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
		
		for (int i = 0; i < (v_fastrender ? 12 : 32); i++)
		{
			ParticleAnimated(smoke[XORRandom(smoke.length)], (this.getPosition() + Vec2f((this.isFacingLeft() ? -1 : 1)*12.0f, 0.0f)) + Vec2f(XORRandom(36) - 18, XORRandom(36) - 18), getRandomVelocity(0.0f, XORRandom(130) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.16f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 9 + XORRandom(5), XORRandom(70) * -0.00005f, true);
			
			if (i%3!=0 || this.hasTag("apc")) continue;
			makeGibParticle(
			"EmptyShell",               		// file name
			this.getPosition(),                 // position
			(Vec2f(0.0f,-0.5f) + getRandomVelocity(180, 5, 360)), // velocity
			0,                                  // column
			0,                                  // row
			Vec2f(16, 16),                      // frame size
			0.5f,                               // scale?
			0,                                  // ?
			"ShellCasing",                      // sound
			this.get_u8("team_color"));         // team number
		}
	}

	this.Tag("exploded");
	if (!v_fastrender) this.getSprite().Gib();
}

// Blow up
void onDie(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	DoExplosion(this);
	Explode(this, 64.0f, 1.0f);

	this.getSprite().PlaySound("/turret_die");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire blob"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		
		// check for valid ammo
		if (blob.getName() != v.getCurrentAmmo().bullet_name)
		{
			return;
		}
		
		Vehicle_onFire(this, v, blob, charge);
	}
	else if (cmd == this.getCommandID("shoot"))
	{
		this.set_u32("next_shoot", getGameTime()+shootDelay);
		s32 arrowAngle;
		if (!params.saferead_s32(arrowAngle)) return;
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;

		if (this.hasBlob("ammo", 1))
		{
			if (isServer()) this.TakeBlob("ammo", 1);
			ParticleAnimated("SmallExplosion3", (arrowPos + Vec2f(8,1).RotateBy(arrowAngle)), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
			this.getSprite().PlaySound("M60fire.ogg", 0.75f, 1.0f + XORRandom(15) * 0.01f);
		}
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	v.firing = v.firing || isActionPressed;

	bool hasammo = v.getCurrentAmmo().loaded_ammo > 0;

	u8 charge = v.charge;
	if ((charge > 0 || isActionPressed) && hasammo)
	{
		if (charge < v.getCurrentAmmo().max_charge_time && isActionPressed)
		{
			charge++;
			v.charge = charge;

			chargeValue = charge;
			return false;
		}
		chargeValue = charge;
		return true;
	}

	return false;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{
	this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);
	if (bullet !is null)
	{
		bullet.Tag("shell");
		u8 charge_prop = _charge;

		f32 angle = this.get_f32("gunelevation") + this.getAngleDegrees();
		Vec2f vel = Vec2f(0.0f, -27.5f).RotateBy(angle);
		bullet.setVelocity(vel);
		Vec2f pos = this.getPosition() + Vec2f((this.isFacingLeft() ? -1 : 1)*60.0f, -5.5f).RotateBy((this.isFacingLeft()?angle+90:angle-90));
		bullet.setPosition(pos + (this.isFacingLeft()?Vec2f(-12.0f,0):Vec2f(12.0f,0)).RotateBy((this.isFacingLeft()?angle+90:angle-90)));

		CBlob@ hull = getBlobByNetworkID(this.get_u16("tankid"));

		bool not_found = true;

		if (hull !is null)
		{
			hull.AddForce(Vec2f(hull.isFacingLeft() ? (recoil*5.0f) : (recoil*-5.0f), 0.0f));
		}

		if (isClient())
		{
			bool facing = this.isFacingLeft();
			for (int i = 0; i < 16; i++)
			{
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(10+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2 + XORRandom(2), -0.0031f, true);
				//ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 6 + XORRandom(3), -0.0031f, true);
			}

			for (int i = 0; i < 6; i++)
			{
				float angle = Maths::ATan2(vel.y, vel.x) + 20;
				ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle2 = Maths::ATan2(vel.y, vel.x) - 20;
				ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle3 = Maths::ATan2(vel.y, vel.x) + 10;
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle4 = Maths::ATan2(vel.y, vel.x) - 10;
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);

				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 10 + XORRandom(3), -0.0031f, true);
				ParticleAnimated("Explosion", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.0065f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 2, -0.0031f, true);
			}
		}

		makeGibParticle(
		"EmptyShell",               		// file name
		this.getPosition(),                 // position
		(Vec2f(0.0f,-0.5f) + getRandomVelocity(90, 2, 360)), // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		0.5f,                               // scale?
		0,                                  // ?
		"ShellCasing",                      // sound
		this.get_u8("team_color"));         // team number
	}	

	v.last_charge = _charge;
	v.charge = 0;
	v.cooldown_time = v.getCurrentAmmo().fire_delay;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle") || blob.hasTag("boat"))
	{
		return true;
	}

	if (blob.hasTag("flesh") && !blob.isAttached())
	{
		return true;
	}
	else
	{
		return Vehicle_doesCollideWithBlob_ground(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player")) attached.Tag("covered");
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	attachedPoint.offsetZ = 1.0f;
	this.getShape().SetStatic(true);
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("player")) detached.Untag("covered");
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	this.getShape().SetStatic(false);
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 0.9f;
	}
	if (customData >= HittersAW::bullet) return 0;
	return damage;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	AttachmentPoint@ GUNNER = blob.getAttachments().getAttachmentPointByName("GUNNER");
	if (GUNNER !is null && GUNNER.getOccupied() !is null)
	{
		CBlob@ driver_blob = GUNNER.getOccupied();
		if (!driver_blob.isMyPlayer()) return;

		// draw ammo count
		Vec2f oldpos = driver_blob.getOldPosition();
		Vec2f pos = driver_blob.getPosition();
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) + Vec2f(0, -22);

		GUI::DrawSunkenPane(pos2d-Vec2f(40.0f, -48.0f), pos2d+Vec2f(18.0f, 70.0f));
		GUI::DrawIcon("Materials.png", 31, Vec2f(16,16), pos2d+Vec2f(-40, 42.0f), 0.75f, 1.0f);
		GUI::SetFont("menu");
		if (blob.getInventory() !is null)
			GUI::DrawTextCentered(""+blob.getInventory().getCount("ammo"), pos2d+Vec2f(-8, 58.0f), SColor(255, 255, 255, 0));
	}
}