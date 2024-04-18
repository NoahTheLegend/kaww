#include "VehicleCommon.as";
#include "GenericButtonCommon.as";
#include "Explosion.as";
#include "Hitters.as";
#include "PerksCommon.as";
#include "TurretStats.as";
#include "TankTurretCommon.as";

void onInit(CBlob@ this)
{
    Setup(this);

    VehicleInfo@ v;
    if (!this.get("VehicleInfo", @v))
    {
        error("Couldn't init VehicleInfo: "+this.getName()+" / "+this.getNetworkID());
        return;
    }

    LoadStats(this);

    TurretStats@ stats;
    if (!this.get("TurretStats", @stats))
    {
        error("Couldn't init TurretStats: "+this.getName()+" / "+this.getNetworkID());
        return;
    }

    InitGun(this, stats, v);
    
	CShape@ shape = this.getShape();
    shape.SetOffset(stats.shape_offset);
	ShapeConsts@ consts = shape.getConsts();
	consts.collideWhenAttached = true;

	if (stats.mg != "") CreateMachineGun(this, stats);
    Restock(this, stats, stats.ammo_quantity);

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 24, 80);
    if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(20);
	}

	sprite.SetZ(-100.0f);

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.set_f32("gunelevation", (this.getTeamNum() == teamright ? 270 : 90) - stats.init_gun_angle);

	sprite.SetEmitSound("Hydraulics.ogg");
	sprite.SetEmitSoundPaused(true);
	sprite.SetEmitSoundVolume(1.25f);
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
    if (!isServer()) return;

    AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW");
	if (point !is null && point.getOccupied() !is null)
	{
		CBlob@ mg = point.getOccupied();
		mg.server_setTeamNum(this.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

    TurretStats@ stats;
    if (!this.get("TurretStats", @stats))
    {
        return;
    }
	//debug
	/*
	{
		if (getControls().isKeyJustPressed(KEY_KEY_S)) LoadStats(this);

		Vec2f pos = this.getPosition();
        bool fl = this.isFacingLeft();
        s8 ff = fl ? -1 : 1;

        f32 deg = this.getAngleDegrees();
		f32 angle = this.get_f32("gunelevation") + deg;
		
        CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");

		Vec2f shape_offset = this.getShape().getOffset();
		Vec2f arm_offset = Vec2f(-ff*arm.getOffset().x, arm.getOffset().y) - Vec2f(0, stats.muzzle_offset) + stats.bullet_pos_offset;
		arm_offset.RotateBy(deg);
		Vec2f bullet_pos = pos + arm_offset + Vec2f(0,stats.muzzle_offset*2).RotateBy(angle);

		//Vec2f bullet_pos = arm.getWorldTranslation().RotateBy(deg, this.getPosition())
		//	+ Vec2f(ff * stats.arm_height, stats.muzzle_offset).RotateBy(angle);

		ParticleAnimated("LargeSmokeGray", bullet_pos, Vec2f_zero, float(XORRandom(360)), 0.5f, 1, -0.0031f, true);
		CParticle@ p = ParticleAnimated("SmallSteam", pos+arm_offset, Vec2f_zero, float(XORRandom(360)), 0.5f, 1, -0.0031f, true);
		if (p !is null) p.deadeffect = -1;
		CParticle@ p1 = ParticleAnimated("SmallSteam", pos+arm_offset, Vec2f_zero, float(XORRandom(360)), 0.25f, 1, -0.0031f, true);
		if (p1 !is null) p1.deadeffect = -1;
	}
	*/

    bool fl = this.isFacingLeft();
    if (stats.mg != "") ManageMG(this, fl);

    CShape@ shape = this.getShape();
    if (shape !is null) shape.SetOffset(Vec2f(fl ? -stats.shape_offset.x : stats.shape_offset.x, stats.shape_offset.y));

	bool was_fl = this.get_bool("fl");
	f32 currentAngle = this.get_f32("gunelevation");
	if ((!was_fl && fl) || (was_fl && !fl))
		currentAngle = 360 - currentAngle;
	this.set_f32("gunelevation", currentAngle);

	u8 high_angle = this.get_u8("high_angle");
	u8 low_angle = this.get_u8("low_angle");
	this.set_bool("fl", fl);

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		bool broken = this.hasTag("broken");
		if (!broken) Vehicle_StandardControls(this, v);

		if (v.cooldown_time > 0)
		{
			v.cooldown_time--;
		}

		f32 angle = getAngle(this, v.charge, stats, v);
		f32 targetAngle;
		bool isOperator = false;
		
		CSprite@ sprite = this.getSprite();

		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null && !broken)
		{
			Vec2f startpos = gunner.getPosition();
			Vec2f aim_vec = startpos - gunner.getAimPos();
			
			CPlayer@ p = gunner.getOccupied().getPlayer();
			PerkStats@ stats;
			if (p !is null && p.get("PerkStats", @stats))
			{
				isOperator = stats.id == Perks::operator;
				this.set_u8("high_angle", this.get_u8("init_high_angle") - stats.top_angle);
				this.set_u8("low_angle", this.get_u8("init_low_angle") + stats.top_angle);
			}
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
			//if (getGameTime()%2==0)
			{
				f32 factor = stats.elevation_speed;
				if (isOperator) factor *= 2;

				f32 difference = Maths::Abs(currentAngle - targetAngle);

				if (difference >= 1)
				{
					f32 req = Maths::Min(difference, factor);

					if (difference < 180) {
						if (currentAngle < targetAngle) currentAngle += req;
						else currentAngle -= req;
					} else {
						if (currentAngle < targetAngle) currentAngle += req;
						else currentAngle += req;
					}
					this.getSprite().SetEmitSoundPaused(false);
					this.getSprite().SetEmitSoundVolume(1.25f);
					this.set_f32("gunelevation", ((currentAngle % 360.0f) + 360.0f) % 360.0f);
					Vehicle_SetWeaponAngle(this, this.get_f32("gunelevation"), v);
				}
				else if (difference <= factor)
				{
					factor = stats.elevation_speed;
				}
			}
		}

		if (fl) this.set_f32("gunelevation", Maths::Min(360.0f-high_angle, Maths::Max(this.get_f32("gunelevation") , 360.0f-low_angle)));
		else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));
	}

	if (fl) this.set_f32("gunelevation", Maths::Min(360.0f-high_angle, Maths::Max(this.get_f32("gunelevation") , 360.0f-low_angle)));
	else this.set_f32("gunelevation", Maths::Max(high_angle, Maths::Min(this.get_f32("gunelevation") , low_angle)));

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
	if (arm !is null)
	{
		arm.ResetTransform();
		arm.RotateBy(this.get_f32("gunelevation"), stats.arm_joint_offset);
		arm.SetOffset(stats.arm_offset + (fl ? Vec2f(-1, -1) : Vec2f(0,0)));
        arm.SetRelativeZ(-50.0f);

		if (this.getName() == "bc25turret")
		{
			CSpriteLayer@ tur = sprite.getSpriteLayer("turret");
			if (tur !is null)
			{
				tur.ResetTransform();
				tur.RotateBy(this.get_f32("gunelevation"), stats.arm_joint_offset);
				tur.SetOffset(arm.getOffset());
				tur.SetRelativeZ(arm.getRelativeZ()+1.0f);
			}
		}
		if (this.hasTag("secondary gun"))
		{
			CSpriteLayer@ mg = sprite.getSpriteLayer("mg");
			if (mg !is null)
			{
				mg.ResetTransform();
				mg.RotateBy(this.get_f32("gunelevation"), Vec2f(-0.5f, 8.0f));
				mg.SetOffset(Vec2f(-16.0f + (this.isFacingLeft() ? -1.0f : 0.0f), -9.0f + (this.isFacingLeft() ? -0.5f : 0.5f)));
				mg.SetRelativeZ(-19.0f);
			}
		}

        //compression
		arm.SetOffset(arm.getOffset() - Vec2f(-stats.barrel_compression + Maths::Min(v.getCurrentAmmo().fire_delay - v.cooldown_time, stats.barrel_compression), 0).RotateBy(this.isFacingLeft() ? 90+this.get_f32("gunelevation") : 90-this.get_f32("gunelevation")));
	}
}

// Blow up
void onDie(CBlob@ this)
{
	AttachmentPoint@ turret = this.getAttachments().getAttachmentPointByName("BOW");
	if (turret !is null)
	{
		if (turret.getOccupied() !is null) turret.getOccupied().server_Die();
	}

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
}

f32 getAngle(CBlob@ this, const u8 charge, TurretStats@ stats, VehicleInfo@ v)
{
	f32 angle = 180.0f;
	bool fl = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null && !gunner.isKeyPressed(key_action2) && !this.hasTag("broken"))
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

		if ((!fl && aim_vec.x < 0) ||
		        (fl && aim_vec.x > 0))
		{
			this.getSprite().SetEmitSoundPaused(false);
			this.getSprite().SetEmitSoundVolume(stats.emitsound_volume);

			if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

			aim_vec.RotateBy((fl ? 1 : -1) * this.getAngleDegrees());

			angle = (-(aim_vec).getAngle() + 270.0f);
			angle = Maths::Max(this.get_u8("high_angle"), Maths::Min(angle, this.get_u8("low_angle")));

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
		return (fl ? -angle : angle);
	}

	this.Untag("nogunner");

	if (fl) { angle *= -1; }

	return angle;
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	v.firing = isActionPressed;
	bool hasammo = v.getCurrentAmmo().loaded_ammo > 0;

	f32 currentAngle = this.get_f32("gunelevation");
    if (this.hasTag("grad") && (this.isFacingLeft() ? currentAngle < 270+10 : currentAngle > 90-10)) return false;

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
    TurretStats@ stats;
    if (!this.get("TurretStats", @stats)) return;

	this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);

	if (bullet !is null)
	{
		bullet.Tag("shell");
		u8 charge_prop = _charge;

        Vec2f pos = this.getPosition();
        bool fl = this.isFacingLeft();
        s8 ff = fl ? -1 : 1;

        f32 deg = this.getAngleDegrees();
		f32 angle = this.get_f32("gunelevation") + deg;
		Vec2f vel = Vec2f(0.0f, stats.projectile_vel).RotateBy(angle);
        
        CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
        if (arm is null)
        {
            bullet.server_Die();
            return;
        }
		
		Vec2f shape_offset = this.getShape().getOffset();
		Vec2f arm_offset = Vec2f(-ff*arm.getOffset().x, arm.getOffset().y) - Vec2f(0, stats.muzzle_offset) + stats.bullet_pos_offset;
		arm_offset.RotateBy(deg);
		Vec2f bullet_pos = pos + arm_offset + Vec2f(0,stats.muzzle_offset*2).RotateBy(angle) - Vec2f(0,ff*1);

		bullet.setVelocity(vel);
		bullet.setPosition(bullet_pos);

		if (this.hasTag("artillery"))
		{
			ArtilleryFire(this, v, bullet, _charge, bullet_pos);
			return;
		}
		else if (this.hasTag("grad"))
		{
			GradFire(this, v, bullet, _charge, bullet_pos);
			return;
		}

		CBlob@ hull = getBlobByNetworkID(this.get_u16("tankid"));
		bool not_found = true;

		if (hull !is null)
		{
			hull.AddForce(Vec2f(this.isFacingLeft() ? stats.recoil_force : -stats.recoil_force, 0.0f));
		}

		if (isClient())
		{
            CShape@ shape = this.getShape();
            Vec2f shape_vel = shape.getVelocity();

			for (int i = 0; i < 16; i++)
			{
				ParticleAnimated("LargeSmokeGray", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(10+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2 + XORRandom(2), -0.0031f, true);
				//ParticleAnimated("LargeSmoke", bullet_pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 6 + XORRandom(3), -0.0031f, true);
			}

			bool apc = this.hasTag("apc");

			for (int i = 0; i < 4; i++)
			{
				if (!apc)
				{
					float angle = Maths::ATan2(vel.y, vel.x) + 20;
					ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.4f + XORRandom(40) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
					float angle2 = Maths::ATan2(vel.y, vel.x) - 20;
					ParticleAnimated("LargeSmoke", bullet_pos, shape_vel + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.4f + XORRandom(40) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				}

				ParticleAnimated("LargeSmokeGray", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 6 + XORRandom(3), -0.0031f, true);
				ParticleAnimated("Explosion", bullet_pos, shape_vel + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(40+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2, -0.0031f, true);
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

	CalculateCooldown(this, stats, v, _charge);
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