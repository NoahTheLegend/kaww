#include "VehicleCommon.as";
#include "HittersAW.as";
#include "TurretStats.as";

const u8 shootDelay = 3;
const f32 projDamage = 0.35f;

void onInit(CBlob@ this)
{
	this.addCommandID("shoot");
	this.set_u8("type", this.getName() == "mausturret" ? 0 : this.getName() == "pinkmausturret" ? 1 : 2);

	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("blocks bullet");
	this.Tag("fireshe");
	this.Tag("secondary gun");

	// machinegun stuff
	this.set_u8("TTL", 45);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 18);
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

	sprite.SetOffset(Vec2f(-1,0));
	sprite.RemoveSpriteLayer("arm");

	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "Maus.png", 16, 48);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(10 + this.get_u8("type"));
		}
	}

	CSpriteLayer@ mg = sprite.addSpriteLayer("mg", "Maus.png", 16, 48);
	if (mg !is null)
	{
		Animation@ anim = mg.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrame(20 + this.get_u8("type"));
		}
	}
}

void onTick(CBlob@ this)
{
	s16 currentAngle = this.get_f32("gunelevation");

	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		bool broken = this.hasTag("broken");
		if (broken) return;

		AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
		if (gunner !is null && gunner.getOccupied() !is null)
		{
			CBlob@ hooman = gunner.getOccupied();
			Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

			TurretStats@ stats;
    		if (!this.get("TurretStats", @stats)) return;
			bool turned = this.get_bool("turned");

			bool flip = this.isFacingLeft();
			CBlob@ realPlayer = getLocalPlayerBlob();
			const bool pressed_m3 = gunner.isKeyPressed(key_action3);
			const f32 flip_factor = flip ? -1 : 1;
			f32 angle = this.get_f32("gunelevation") - 90 + this.getAngleDegrees() + (turned ? 180 : 0);
			Vec2f shootpos = this.getPosition()-Vec2f(stats.secondary_gun_offset).RotateBy(angle)-Vec2f(flip?8:-8,flip?-8:-4);

			if (pressed_m3)
			{
				if (getGameTime() > this.get_u32("fireDelayGun") && hooman.isMyPlayer())
				{
					if (this.hasBlob("ammo", 1))
					{
						f32 spread = XORRandom(5);
						shootVehicleGun(hooman.getNetworkID(), this.getNetworkID(),
							angle+spread, shootpos,
								gunner.getAimPos(), 0.0f, 1, 0, 0.4f, 0.6f, 2,
									this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));	

						CBitStream params;
						params.write_s32(this.get_f32("gunelevation")-90);
						params.write_Vec2f(this.getPosition()+(shootpos-Vec2f(6*flip_factor,0)));

						this.SendCommand(this.getCommandID("shoot"), params);
						this.set_u32("fireDelayGun", getGameTime() + (shootDelay));
					}
				}
			}
		}
	}
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
{return false;}
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{}