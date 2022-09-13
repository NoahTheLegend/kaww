#include "VehicleCommon.as"

const Vec2f arm_offset = Vec2f(-2, 0);

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              0.0f, // move speed
	              0.1f,  // turn speed
	              Vec2f(0.0f, -4.3f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_AddAmmo(this, v,
	                    3, // fire delay (ticks)
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "mat_7mmround", // bullet ammo config name
	                    "Bullet", // name for ammo selection
	                    "bullet", // bullet config name
	                    "", // fire sound  
	                    "EmptyFire", // empty fire sound
	                    Vehicle_Fire_Style::custom,
	                    Vec2f(-6.0f, 2.0f), // fire position offset
	                    0 // charge time
	                   );
	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 48, 16);
	this.Tag("builder always hit");

	if (isServer())
	{
		CMap@ map = this.getMap();
		if (map !is null)
		{
			this.server_setTeamNum(this.getPosition().x <= map.tilemapwidth*4 ? 0 : 1);
		}
	}

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(4);
		anim.AddFrame(5);
		arm.SetOffset(arm_offset);

		arm.animation.frame = 1;
	}

	CSpriteLayer@ cage = sprite.addSpriteLayer("cage", sprite.getConsts().filename, 48, 16);

	if (cage !is null)
	{
		Animation@ anim = cage.addAnimation("default", 0, false);
		anim.AddFrame(1);
		anim.AddFrame(5);
		anim.AddFrame(7);
		cage.SetOffset(sprite.getOffset());
		cage.SetRelativeZ(20.0f);
	}

	this.getShape().SetRotationsAllowed(false);
	this.set_string("autograb blob", "mat_7mmround");

	sprite.SetZ(20.0f);

	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	// auto-load some ammo initially
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_7mmround");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

	if (arm !is null)
	{
		arm.animation.frame = 1;
	}
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 angle = Vehicle_getWeaponAngle(this, v);
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	bool failed = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		gunner.offsetZ = -9.0f;   //5.0f
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

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
				angle = Maths::Max(-80.0f , Maths::Min(angle , 80.0f));
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
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	f32 angle = getAimAngle(this, v);
	Vehicle_SetWeaponAngle(this, angle, v);
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

	if (arm !is null)
	{
		bool facing_left = sprite.isFacingLeft();
		f32 rotation = angle * (facing_left ? -1 : 1);

		//if (this.hasAttached())
		//{
			CInventory@ inventory = this.getInventory();
			if (inventory != null)
			{
				if (inventory.getItemsCount() <= 0)
				{
					arm.animation.frame = 1;
					if (this.hasAttached()) v.getCurrentAmmo().ammo_stocked = 0;
				}
				else
				{
					if (Vehicle_canFire(this, v, this.isKeyPressed(key_action1), this.wasKeyPressed(key_action1), 0))
					{
						arm.animation.frame = 1;
					}
					else
					{
						arm.animation.frame = 1;
					}
				}
			}
		//}

		arm.ResetTransform();
		arm.SetFacingLeft(facing_left);
		arm.SetRelativeZ(1.0f);
		arm.SetOffset(arm_offset);
		arm.RotateBy(rotation, Vec2f(facing_left ? -4.0f : 4.0f, 0.0f));
	}

	Vehicle_StandardControls(this, v);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!Vehicle_AddFlipButton(this, caller))
	{
		Vehicle_AddLoadAmmoButton(this, caller);
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
		u16 charge = v.charge;
		f32 anglereal = Vehicle_getWeaponAngle(this, v);
		f32 angle = anglereal * (this.isFacingLeft() ? -1 : 1);
		angle += ((XORRandom(512) - 256) / 225.0f);

		Vec2f vel = Vec2f(500.0f / 16.0f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
		bullet.setVelocity(vel);
		Vec2f offset = arm_offset;
		offset.RotateBy(angle);
		bullet.setPosition(this.getPosition() + offset * 0.2f);
		
		CBlob@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER").getOccupied();
		if (gunner !is null)
		{
			if (gunner.getPlayer() !is null)
			{
				bullet.SetDamageOwnerPlayer(gunner.getPlayer());
			}
		}
		else
		{
			return;
		}

		bullet.IgnoreCollisionWhileOverlapped(this);
		bullet.server_setTeamNum(this.getTeamNum());
		//bullet.getShape().setDrag(bullet.getShape().getDrag() * 0.28f);

		if (isClient())
		{
			Vec2f pos = this.getPosition();
			CMap@ map = getMap();
			
			ParticleAnimated("SmallExplosion3", (this.getPosition() + offset * .2f) + vel*0.6, getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		}

		float _angle = this.isFacingLeft() ? -anglereal+180 : anglereal; // on turret spawn it works wrong otherwise
		_angle += -0.099f + (XORRandom(4) * 0.01f);
		if (this.isFacingLeft())
		{
			ParticleAnimated("Muzzleflash", this.getPosition() + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 90) + Vec2f(0.0f, -0.05f), _angle, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
		}
		else
		{
			ParticleAnimated("Muzzleflashflip", this.getPosition() + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 270) + Vec2f(0.0f, -0.05f), _angle + 180, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
		}

		CPlayer@ p = getLocalPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				CPlayer@ ply = local.getPlayer();

				if (ply !is null && ply.isMyPlayer())
				{
					const float recoilx = 5;
					const float recoily = 45;
					const float recoillength = 25; // how long to recoil (?)
					if (local.isAttachedTo(this)) ShakeScreen(Vec2f( recoilx - XORRandom(recoilx*2) + 1, -recoily + XORRandom(recoily) + 1), recoillength, gunner.getInterpolatedPosition());
					if (local.isAttachedTo(this)) ShakeScreen(28, 8, this.getPosition());

					//this.set_u8("recoil_count", recoilcursor);
					//this.set_u8("inaccuracy", this.get_u8("inaccuracy") + inaccuracypershot * (this.hasTag("sprinting")?2.0f:1.0f));

					makeGibParticle(
					"EmptyShellSmall",               // file name
					this.getPosition(),                 // position
					(this.isFacingLeft() ? -offset : offset) + Vec2f((-20 + XORRandom(40))/18,0.0f),                           // velocity
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
	return false;
}