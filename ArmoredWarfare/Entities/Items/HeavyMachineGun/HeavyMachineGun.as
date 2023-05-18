#include "VehicleCommon.as"
#include "Hitters.as"

const Vec2f arm_offset = Vec2f(-2, 0);
const f32 MAX_OVERHEAT = 2.0f;
const f32 OVERHEAT_PER_SHOT = 0.089f;
const f32 COOLDOWN_RATE = 0.065f;
const u8 COOLDOWN_TICKRATE = 5;

void onInit(CBlob@ this)
{
	this.Tag("gun");
	this.Tag("machinegun");
	this.Tag("very heavy weight");

	this.set_u8("TTL", 60);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 20);
	
	Vehicle_Setup(this,
	              0.0f, // move speed
	              0.1f,  // turn speed
	              Vec2f(0.0f, -1.56f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	this.set_string("shoot sound", "M60fire.ogg");

	Vehicle_AddAmmo(this, v,
	                    2, // fire delay (ticks), +1 tick on server due to onCommand delay
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "ammo", // bullet ammo config name
	                    "Ammo", // name for ammo selection
	                    "bulletheavy", // bullet config name
	                    "M60fire", // fire sound  
	                    "EmptyFire", // empty fire sound
	                    Vehicle_Fire_Style::custom,
	                    Vec2f(-6.0f, 2.0f), // fire position offset
	                    0 // charge time
	                   );
	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 48, 16);
	this.Tag("builder always hit");
	this.Tag("destructable_nosoak");

	this.set_s32("custom_hitter", Hitters::machinegunbullet);

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(4);
		anim.AddFrame(5);
		arm.SetOffset(arm_offset);
		arm.SetRelativeZ(100.0f);

		arm.animation.frame = 1;
	}

	CSpriteLayer@ cage = sprite.addSpriteLayer("cage", sprite.getConsts().filename, 48, 16);

	if (cage !is null)
	{
		Animation@ anim = cage.addAnimation("default", 0, false);
		anim.AddFrame(0);
		cage.SetOffset(sprite.getOffset());
		cage.SetRelativeZ(20.0f);
	}

	this.getShape().SetRotationsAllowed(false);
	this.set_string("autograb blob", "ammo");

	this.addCommandID("set detaching");
	this.addCommandID("set attaching");
	sprite.SetZ(20.0f);

	this.addCommandID("sync overheat");

	this.set_f32("overheat", 0);
	this.set_f32("max_overheat", MAX_OVERHEAT);
	this.set_f32("overheat_per_shot", OVERHEAT_PER_SHOT);
	this.set_f32("cooldown_rate", COOLDOWN_RATE);
	this.set_bool("overheated", false);

	// auto-load some ammo initially
	if (getNet().isServer())
	{
		for (u8 i = 0; i < 3; i++)
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

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	attached.Tag("mgunner");
	if (!attached.hasTag("has mount")) return;
	CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");
	if (cage !is null)
	{
		cage.SetVisible(false);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.Untag("mgunner");
	if (detached.getSprite() !is null) detached.getSprite().ResetTransform();
	if (this.isAttached()) return;

	CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");
	if (cage !is null)
	{
		cage.SetVisible(true);
	}
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 first_angle = Vehicle_getWeaponAngle(this, v);
	f32 angle = first_angle;
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	bool failed = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos()+Vec2f(0,4);
		//aim_vec.RotateBy(-this.getAngleDegrees());

		if (this.isAttached())
		{
			if (facing_left) { aim_vec.x = -aim_vec.x; }
			angle = (-(aim_vec).getAngle() + 180.0f);
		}
		else
		{
			if ((!facing_left && aim_vec.x < 0) ||
			        (facing_left && aim_vec.x > 0))
			{
				if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

				angle = (-(aim_vec).getAngle() + 180.0f);
				angle = Maths::Max(-75.0f , Maths::Min(angle , 75.0f));
			}
			else
			{
				this.SetFacingLeft(!facing_left);
			}
		}
	}

	return angle;
}

void onTick(CBlob@ this)
{
	//if (isServer() && this.getPosition().x <= 8.0f && this.getPosition().y <= 64.0f) this.server_Die();

	bool is_attached = this.isAttached();
	if (this.isAttachedToPoint("PICKUP") && this.hasAttached())
	{
		if (isServer()) this.server_DetachFromAll();
		return;
	}

	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	v.firing = false;

	if (this.getTickSinceCreated() < 5 && is_attached)
	{
		if (!this.hasTag("angle_set"))
		{
			Vehicle_SetWeaponAngle(this, -30, v);
			if (this.getSprite().getSpriteLayer("arm") !is null)
			{
				this.getSprite().getSpriteLayer("arm").RotateBy(this.isFacingLeft()?30:-30, Vec2f(0,0));
			}
			this.Tag("angle_set");
		}
	}

	if (!(isClient() && isServer()) && (getGameTime() == 0 || getGameTime() < 60*30))
	{
		if (isClient() && this.getSprite() !is null) this.getSprite().SetEmitSoundPaused(true);
		return; // turn engines off!
	}

	if (isClient() && is_attached)
	{
		CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");
		if (cage !is null && cage.isVisible())
		{
			cage.SetVisible(false);
		}
	}

	if ((!v.firing || this.get_bool("overheated")) && getGameTime() % COOLDOWN_TICKRATE == 0)
	{
		if (this.get_f32("overheat") > COOLDOWN_RATE)
		{
			this.add_f32("overheat", -COOLDOWN_RATE);
		}
		else if (this.get_f32("overheat") <= COOLDOWN_RATE)
		{
			this.set_f32("overheat", 0);
			this.set_bool("overheated", false);
		}
	}
	else if (this.get_f32("overheat") >= this.get_f32("max_overheat") - this.get_f32("overheat_per_shot"))
	{
		this.set_bool("overheated", true);
		v.firing = false;
	}

	if (this.get_bool("overheated") && getGameTime() % 3 == 0)
	{
		if (this.getSprite() !is null)
		{
			if (this.get_f32("overheat") >= this.get_f32("max_overheat")-this.get_f32("overheat_per_shot"))
				this.getSprite().PlaySound("DrillOverheat.ogg", 1.0f, 0.95f);
			else if (getGameTime() % 3 + XORRandom(2) == 0) this.getSprite().PlaySound("Steam.ogg", 0.85f, 1.075f);
		}
		MakeParticle(this, Vec2f(0, -0.5), v);
	}

	if (is_attached)
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (ap !is null && ap.getOccupied() !is null)
		{
			CBlob@ gunner = ap.getOccupied();
			CSprite@ gsprite = gunner.getSprite();
			f32 perc = (gunner.get_u8("mg_offset")*0.8f) / 4.0f;

			if (gsprite !is null)
			{
				gsprite.ResetTransform();
				gsprite.SetOffset(Vec2f(0, -4.0f*perc));
			}
			if (ap.isKeyPressed(key_action2))
			{
				gunner.set_u32("mg_invincible", getGameTime()+1);
				if (gunner.get_u8("mg_offset") > 0) gunner.set_u8("mg_offset", gunner.get_u8("mg_offset") - 1);
			}
			else if (gunner.get_u8("mg_offset") < 5) gunner.set_u8("mg_offset", gunner.get_u8("mg_offset") + 1);
			if (gunner.get_u8("mg_offset") < 5) return;
		}
	}

	f32 angle = getAimAngle(this, v);
	Vehicle_SetWeaponAngle(this, angle, v);
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

	if (arm !is null)
	{
		//if (this.hasAttached())
		{
			bool facing_left = sprite.isFacingLeft();
			f32 rotation = angle * (facing_left ? -1 : 1);

			CInventory@ inventory = this.getInventory();
			if (inventory != null)
			{
				arm.animation.frame = 1;

				if (this.hasAttached() && inventory.getItemsCount() <= 0)
				{
					v.getCurrentAmmo().ammo_stocked = 0;
				}
			}

			arm.ResetTransform();
			arm.SetFacingLeft((rotation > -90 && rotation < 90) ? facing_left : !facing_left);
			arm.SetOffset(Vec2f(this.isAttached() && (angle > 90 || angle <= -90) ?-2:0,0)+arm_offset);
			arm.RotateBy(rotation + ((rotation > -90 && rotation < 90) ? 0 : 180), Vec2f(((rotation > -90 && rotation < 90) ? facing_left : !facing_left) ? -4.0f : 4.0f, 0.0f));
			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
			if (this.hasAttached()) arm.RotateBy(-this.getAngleDegrees(), Vec2f(0,0));
		}
	}

	Vehicle_StandardControls(this, v);
}

void MakeParticle(CBlob@ this, const Vec2f vel, VehicleInfo@ v, const string filename = "SmallSteam")
{
	if (isClient())
	{
		f32 angle = getAimAngle(this, v);
		Vec2f offset = Vec2f((11+XORRandom(10)) * (this.isFacingLeft() ? -1 : 1), 0).RotateBy(this.isFacingLeft() ? -angle : angle);
		ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 0.35f+(XORRandom(10)*0.1f), 2 + XORRandom(3), -0.1f, false);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	Vehicle_AddLoadAmmoButton(this, caller);

	if (this.isAttached())
	{
		if (caller is null || caller.getTeamNum() != this.getTeamNum()
			|| caller.getDistanceTo(this) > 48.0f || caller.getName() != "mechanic") return;

		CBlob@ carried  = caller.getCarriedBlob();

		bool disable = false;
		if (carried is null || carried.getName() != "pipewrench")
			disable = true;

		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CButton@ button = caller.CreateGenericButton(15, Vec2f(-9, 0), this, this.getCommandID("set detaching"), "\nDetach this weapon. "+(disable?"Requires a pipewrench.":""), params);
		if (button !is null && disable)
		{
			button.SetEnabled(false);
		}
	}
	else if (caller !is null && caller.getTeamNum() == this.getTeamNum()
		&& caller.getDistanceTo(this) <= 64.0f)
	{
		CBlob@[] nearby;
		if (getMap() is null) return;
		getMap().getBlobsInRadius(this.getPosition(), 32.0f, @nearby);

		bool try_to_attach = false;
		u16 id;
		for (u16 i = 0; i < nearby.length; i++)
		{
			if (nearby[i] !is null && nearby[i].getTeamNum() == this.getTeamNum()
				&& nearby[i].hasTag("has mount"))
			{
				try_to_attach = true;
				id = nearby[i].getNetworkID();
				break;
			}
		}

		if (try_to_attach)
		{
			CBitStream params;
			params.write_u16(id);
			CButton@ button = caller.CreateGenericButton(15, Vec2f(-9, 0), this, this.getCommandID("set attaching"), "\nAttach this weapon to nearby mount.", params);
		}
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	if (this.get_bool("overheated")) return false;
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
			if (isClient()) return true;
			return false;
		}
		chargeValue = charge;
		return true;
	}

	if (isClient()) return true; // gets stuck sometimes	

	return false;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused)
{
	if (bullet !is null)
	{
		Vec2f pos = this.getPosition();

		u16 charge = v.charge;
		f32 anglereal = Vehicle_getWeaponAngle(this, v);
		f32 angle = anglereal * (this.isFacingLeft() ? -1 : 1);
		angle += ((XORRandom(400) - 200) / 120.0f);

		Vec2f vel = Vec2f(500.0f / 16.5f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
		bullet.setVelocity(vel);
		Vec2f offset = arm_offset;
		offset.RotateBy(angle);
		bullet.setPosition(pos + offset * 0.2f);

		float overheat_mod = 1.0f;
		
		CBlob@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER").getOccupied();
		if (gunner !is null)
		{
			CPlayer@ p = gunner.getPlayer();
			if (p !is null)
			{
				if (getRules().get_string(p.getUsername() + "_perk") == "Operator")
				{
					overheat_mod = 0.85f;
				}

				bullet.SetDamageOwnerPlayer(p);
			}
		}
		else
		{
			return;
		}

		this.add_f32("overheat", this.get_f32("overheat_per_shot") * overheat_mod);

		if (isServer())
		{
			CBitStream params;
			params.write_f32(this.get_f32("overheat"));
			this.SendCommand(this.getCommandID("sync overheat"), params);
		}

		bullet.IgnoreCollisionWhileOverlapped(this);
		bullet.server_setTeamNum(this.getTeamNum());

		if (isClient())
		{
			ParticleAnimated("SmallExplosion3", (pos + Vec2f(-6,-1).RotateBy(-anglereal) + offset * .2f) + vel*0.6, getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		}

		float _angle = this.isFacingLeft() ? -anglereal+180 : anglereal; // on turret spawn it works wrong otherwise
		_angle += -0.099f + (XORRandom(4) * 0.01f);

		bool no_muzzle = false;

		#ifdef STAGING
			no_muzzle = true;
		#endif

		if (!no_muzzle)
		{
			if (this.isFacingLeft())
			{
				ParticleAnimated("Muzzleflash", pos + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 90) + Vec2f(0.0f, -0.05f), _angle, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
			}
			else
			{
				ParticleAnimated("Muzzleflashflip", pos + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 270) + Vec2f(0.0f, -0.05f), _angle + 180, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
			}
		}

		CPlayer@ p = getLocalPlayer();
		if (p !is null && !v_fastrender)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				CPlayer@ ply = local.getPlayer();

				if (ply !is null && ply.isMyPlayer())
				{
					const float recoilx = 15;
					const float recoily = 50;
					const float recoillength = 40; // how long to recoil (?)
	
					if (local.isAttachedTo(this)) ShakeScreen(28, 5, pos);

					makeGibParticle(
					"EmptyShellSmall",               // file name
					pos,                 // position
					(this.isFacingLeft() ? -offset : offset) + Vec2f((-20 + XORRandom(40))/18,-1.1f),                           // velocity
					0,                                  // column
					0,                                  // row
					Vec2f(16, 16),                      // frame size
					0.2f,                               // scale?
					0,                                  // ?
					"ShellCasing",                      // sound
					this.get_u8("team_color"));         // team number

					this.getSprite().PlaySound("M60fire.ogg", 1.0f, 0.93f + XORRandom(10) * 0.01f);
				}		
			}
		}
	}
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
		Vehicle_onFire(this, v, blob, charge);
	}
	else if (cmd == this.getCommandID("sync overheat"))
	{
		if (isClient())
		{
			f32 heat;
			if (!params.saferead_f32(heat)) return;
			this.set_f32("overheat", heat);
		}
	}
	else if (cmd == this.getCommandID("set detaching"))
	{
		u16 caller_id;
		if (!params.saferead_u16(caller_id)) return;
		CBlob@ caller = getBlobByNetworkID(caller_id);
		if (caller is null) return;

		caller.set_bool("detaching", true);
		caller.set_u16("detaching_id", this.getNetworkID());
		caller.Tag("init_detaching");
	}
	else if (cmd == this.getCommandID("set attaching"))
	{
		u16 turret_id;
		if (!params.saferead_u16(turret_id)) return;

		CBlob@ turret = getBlobByNetworkID(turret_id);
		if (turret is null) return;

		for (u8 i = 0; i < 5; i++)
		{
    		AttachmentPoint@ ap = turret.getAttachments().getAttachmentPointByName(i==0?"BOW":"BOW"+(i-1));
    		if (ap !is null && ap.getOccupied() is null)
    		{
				turret.server_AttachTo(this, ap);
				break;
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "barge") return true;
	return (!blob.hasTag("flesh") && !blob.hasTag("trap") && !blob.hasTag("food") && !blob.hasTag("material") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.isAttached() && !this.hasAttached() && byBlob !is null && this.getTeamNum() == byBlob.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	damage *= 0.2f;
	if (!this.isAttached())
	{
		if (customData == Hitters::explosion || customData == Hitters::keg) damage *= 2.5f;
		damage *= 1.5f;
	}
	
	if (this.isAttached()) return damage;
	if (customData == Hitters::bullet || customData == Hitters::heavybullet
		|| customData == Hitters::aircraftbullet || customData == Hitters::machinegunbullet)
	{
		damage *= 0.5f;
		damage += 0.1f;
	}

	return damage;
}