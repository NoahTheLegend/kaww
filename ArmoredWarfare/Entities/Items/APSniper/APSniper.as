#include "GunStandard.as";
#include "Hitters.as"
#include "HittersAW.as"

const Vec2f arm_offset = Vec2f(-2, 0);
const u32 fire_rate = 150;

void onInit(CBlob@ this)
{
	this.Tag("gun");
	this.Tag("machinegun");
	this.Tag("heavy weight");

	this.set_u8("TTL", 30);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 35);
					   
	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 48, 16);
	this.Tag("builder always hit");
	this.Tag("destructable_nosoak");
	this.addCommandID("fire");

	this.set_string("shoot sound", "44magnum_fire.ogg");

	this.set_u32("cooldown", 0);
	this.set_s32("custom_hitter", HittersAW::apbullet);

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(0);
		anim.AddFrame(1);
		anim.AddFrame(2);
		arm.SetOffset(arm_offset);
		arm.SetRelativeZ(100.0f);

		arm.animation.frame = 2;
	}

	this.getShape().SetRotationsAllowed(true);
	sprite.SetZ(20.0f);

	if (getNet().isServer())
	{
		for (u8 i = 0; i < 1; i++)
		{
			CBlob@ ammo = server_CreateBlob("specammo");
			if (ammo !is null)
			{
				if (!this.server_PutInInventory(ammo))
					ammo.server_Die();
			}
		}
	}
}

f32 getAimAngle(CBlob@ this)
{
	f32 angle = 0;
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	bool failed = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();
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
	bool is_attached = this.isAttached();
	if (this.isAttachedToPoint("PICKUP") && this.hasAttached())
	{
		if (isServer()) this.server_DetachFromAll();
		return;
	}

	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	u8 ammo = inv.getCount("specammo");
	u32 cooldown = this.get_u32("cooldown");

	f32 angle = getAimAngle(this);
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (arm !is null && gunner !is null)
	{
		if (arm.animation !is null)
		{
			arm.animation.frame = cooldown > getGameTime() ? 1 : ammo > 5 ? 2 : 0;
		}
		
		bool facing_left = sprite.isFacingLeft();
		f32 rotation = angle * (facing_left ? -1 : 1);

		arm.ResetTransform();
		arm.SetFacingLeft((rotation > -90 && rotation < 90) ? facing_left : !facing_left);
		arm.SetOffset(Vec2f(this.isAttached() && (angle > 90 || angle <= -90) ?-2:0,0)+arm_offset);
		if (gunner.getOccupied() !is null)
		{
			if (gunner.getOccupied().isMyPlayer() && gunner.isKeyJustPressed(key_action1)
				&& cooldown < getGameTime())
			{
				CBitStream params;
				params.write_u16(gunner.getOccupied().getNetworkID());
				params.write_Vec2f(gunner.getAimPos());
				this.SendCommand(this.getCommandID("fire"), params);
			}

			arm.RotateBy(rotation - this.getAngleDegrees() + ((rotation > -90 && rotation < 90) ? 0 : 180), Vec2f(((rotation > -90 && rotation < 90) ? facing_left : !facing_left) ? -4.0f : 4.0f, 0.0f));
		}
	}
}

void onFire(CBlob@ this, Vec2f vel)
{
	f32 anglereal = getAimAngle(this);
	Vec2f pos = this.getPosition()+arm_offset;

	for (int i = 0; i < 3; i++)
	{
		ParticleAnimated("LargeSmokeGray", pos + Vec2f(-24,-2).RotateBy(this.isFacingLeft()?-anglereal:anglereal+180), this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/4, float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2 + XORRandom(2), -0.0031f, true);
	}

	float _angle = this.isFacingLeft() ? -anglereal+180 : anglereal; // on turret spawn it works wrong otherwise
	_angle += -0.099f + (XORRandom(4) * 0.01f);

	CPlayer@ p = getLocalPlayer();
	if (p !is null)
	{
		Vec2f offset = Vec2f(-2,0);

		CBlob@ local = getLocalPlayerBlob();
		if (local !is null)
		{
			const float recoilx = 200;
			const float recoily = 150;
			const float recoillength = 10; // how long to recoil (?)
			ShakeScreen(recoilx, recoillength, pos);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		if (blob is null) return;

		Vec2f aimPos = params.read_Vec2f();
		if (!this.hasBlob("specammo", 5))
		{
			if (isClient()) this.getSprite().PlaySound("EmptyGun.ogg", 1.0f, 1.0f);
			return;
		}

		if (isServer())
		{
			this.TakeBlob("specammo", 5);
		}

		f32 angle = getAimAngle(this);
		if (this.isFacingLeft())
		{
			angle = -1 * angle + 180;
		}
		shootVehicleGun(blob.getNetworkID(), this.getNetworkID(),
			angle, this.getPosition()-Vec2f(0,2),
			aimPos, 0, 1, 4, 3.0f, 4.0f, 6,
				this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));

		this.set_u32("cooldown", getGameTime() + fire_rate);

		if (isClient())
		{
			onFire(this, Vec2f(2,0).RotateBy(angle));
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "barge") return true;
	return (!blob.hasTag("flesh") && !blob.hasTag("trap") && !blob.hasTag("food") && !blob.hasTag("material") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.isAttached() && !this.hasAttached() && byBlob !is null;
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return damage;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.getTeamNum() == this.getTeamNum() && this.getDistanceTo(forBlob) < 64.0f;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached !is null && attached.hasTag("player"))
	{
		attached.Tag("distant_view");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached !is null && detached.hasTag("player"))
	{
		detached.Untag("distant_view");
	}
}