#include "VehicleCommon.as";
#include "HittersAW.as";
#include "TurretStats.as";

const u8 shootDelay = 3;
const f32 projDamage = 0.35f;
const int base_spread = 5;

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("respawn_if_crew_present");
	this.Tag("has mount");
	this.Tag("blocks bullet");

	// machinegun stuff
	this.addCommandID("shoot");
	this.set_u8("TTL", 40);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 16);
	this.set_s32("custom_hitter", HittersAW::machinegunbullet);

	// auto-load on creation
	if (getNet().isServer())
	{
		CBlob@ ammo = server_CreateBlob("ammo");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();

			ammo.server_SetQuantity(ammo.getQuantity()*3);
		}
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetOffset(Vec2f(-3,0));
	sprite.RemoveSpriteLayer("arm");
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 32, 64);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(18);
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
    if (!isServer()) return;

    AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW1");
	if (point !is null && point.getOccupied() !is null)
	{
		CBlob@ mg = point.getOccupied();
		mg.server_setTeamNum(this.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
    bool fl = this.isFacingLeft();
    ManageMG(this, fl);

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		bool broken = this.hasTag("broken");
		if (broken) return;

		if (isClient() && !this.hasTag("init mg"))
		{
			this.Tag("init mg");
			
			CSprite@ sprite = this.getSprite();
			CSpriteLayer@ mg = sprite.addSpriteLayer("mg", "M1AbramsMG.png", 16, 24);
			if (mg !is null)
			{
				TurretStats@ stats;
				if (!this.get("TurretStats", @stats)) return;
				bool flip = this.isFacingLeft();

				mg.SetRelativeZ(20.0f);
				mg.SetFacingLeft(flip);
				Vec2f mg_offset = stats.secondary_gun_offset;
				mg.SetOffset(mg_offset);
				mg.RotateBy(flip ? -90 : 90, Vec2f(0,0));
			}
		}

		AttachmentPoint@ vehicle = this.getAttachments().getAttachmentPointByName("TURRET");
		if (vehicle !is null && vehicle.getOccupied() !is null)
		{
			AttachmentPoint@ gunner = vehicle.getOccupied().getAttachments().getAttachmentPointByName("DRIVER");
			if (gunner !is null && gunner.getOccupied() !is null)
			{
				CBlob@ hooman = gunner.getOccupied();
				bool flip = this.isFacingLeft();
				CBlob@ realPlayer = getLocalPlayerBlob();

				TurretStats@ stats;
				if (!this.get("TurretStats", @stats)) return;
				bool turned = this.get_bool("turned");
				
				Vec2f offset = stats.secondary_gun_offset;
				if (!flip) offset.x += 16;

				f32 vehicle_angle = s16(this.getAngleDegrees());
				Vec2f rotated_offset = offset.RotateBy(vehicle_angle);
				
				Vec2f aim_vec = gunner.getAimPos() - (this.getPosition() + rotated_offset);
				aim_vec.RotateBy(-base_spread*0.5f);

				const bool pressed_m3 = gunner.isKeyPressed(key_action3);
				s16 angle = -(aim_vec.Angle());
				Vec2f shootpos = this.getPosition() + rotated_offset;

				// TODO apply vehicle angle, rn the problem is in 360-0 snapping, in top right half, when vehicle is rotated clock-wise
				s16 angleDifference = 20;
				s16 minAngle = -180 - angleDifference;
				s16 maxAngle = -180 + angleDifference;
				s16 minAngle2 = 0 - angleDifference;
				s16 maxAngle2 = -360 + angleDifference;

				if (minAngle > 0) minAngle -= 360;
				if (maxAngle > 0) maxAngle -= 360;
				if (minAngle2 > 0) minAngle2 -= 360;
				if (maxAngle2 > 0) maxAngle2 -= 360;

				if (angle <= minAngle && angle >= minAngle - 90) angle = minAngle;
				else if (angle >= maxAngle && angle <= maxAngle + 90) angle = maxAngle;
				if (angle <= minAngle2 && angle >= minAngle2 - 90) angle = minAngle2;
				else if (angle >= maxAngle2 && angle <= maxAngle2 + 90) angle = maxAngle2;

				if (isClient())
				{
					CSprite@ sprite = this.getSprite();
					CSpriteLayer@ mg = sprite.getSpriteLayer("mg");
					if (mg !is null)
					{
						mg.ResetTransform();
						mg.SetRelativeZ(20.0f);
						mg.SetFacingLeft(flip);
						Vec2f mg_offset = stats.secondary_gun_offset;
						mg.SetOffset(mg_offset);
						mg.RotateBy(angle - this.getAngleDegrees() + 90, Vec2f(0,0));
					}
				}

				if (pressed_m3)
				{
					if (getGameTime() > this.get_u32("fireDelayGun") && hooman.isMyPlayer())
					{
						if (this.hasBlob("ammo", 1))
						{
							f32 spread = XORRandom(base_spread);
							shootVehicleGun(hooman.getNetworkID(), this.getNetworkID(),
								angle+spread, shootpos,
									gunner.getAimPos(), 0.0f, 1, 0, 0.4f, 0.6f, 2,
										this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));	

							CBitStream params;
							params.write_s32(this.get_f32("gunelevation")-90);
							params.write_Vec2f(shootpos);

							this.SendCommand(this.getCommandID("shoot"), params);
							this.set_u32("fireDelayGun", getGameTime() + (shootDelay));
						}
					}
				}
			}
		}
	}
}

void ManageMG(CBlob@ this, bool fl)
{
	if (!isServer()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW1");
	if (point !is null && point.getOccupied() !is null)
	{
		CBlob@ mg = point.getOccupied();
		mg.SetFacingLeft(fl);
	}
}

void onDie(CBlob@ this)
{
	AttachmentPoint@ turret = this.getAttachments().getAttachmentPointByName("BOW1");
	if (turret !is null)
	{
		if (turret.getOccupied() !is null) turret.getOccupied().server_Die();
	}

	this.getSprite().PlaySound("/turret_die");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot"))
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
			this.getSprite().PlaySound("MGfire.ogg", 0.75f, 1.0f + XORRandom(15) * 0.01f);
		}
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge) {}
