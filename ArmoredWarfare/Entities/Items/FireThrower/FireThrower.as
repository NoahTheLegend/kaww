#include "VehicleCommon.as"
#include "Hitters.as"
#include "Explosion.as";
#include "PerksCommon.as";

const Vec2f arm_offset = Vec2f(4, 0);
const f32 MAX_OVERHEAT = 25.0f;
const f32 OVERHEAT_PER_SHOT = 0.25f;
const f32 COOLDOWN_RATE = 0.5f;
const u8 COOLDOWN_TICKRATE = 5;

void onInit(CBlob@ this)
{
	this.Tag("gun");
	this.Tag("machinegun");
	this.Tag("firethrower");
	this.Tag("heavy weight");
	this.Tag("weapon");
	this.Tag("lag_ondie");
	this.set_u16("gui_mat_icon", 59);

	this.set_f32("hand_rotation_damp", 0.15f);
	
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

	Vehicle_AddAmmo(this, v,
	                    5, // fire delay (ticks), +1 tick on server due to onCommand delay
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "specammo", // bullet ammo config name
	                    "Special Ammunition", // name for ammo selection
	                    "", // bullet config name
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
	this.Tag("destructable_nosoak");

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(4);
		anim.AddFrame(5);
		arm.SetOffset(Vec2f(this.isAttached()?4:0,0)+arm_offset);
		arm.SetRelativeZ(101.0f);

		arm.animation.frame = 1;
	}

	CSpriteLayer@ cage = sprite.addSpriteLayer("cage", sprite.getConsts().filename, 48, 16);

	if (cage !is null)
	{
		Animation@ anim = cage.addAnimation("default", 0, false);
		anim.AddFrame(0);
		cage.SetOffset(sprite.getOffset());
		cage.SetRelativeZ(-11.0f);
	}

	this.getShape().SetRotationsAllowed(false);
	this.set_string("autograb blob", "specammo");

	this.addCommandID("throw fire");
	this.addCommandID("set detaching");
	this.addCommandID("set attaching");
	this.addCommandID("sync overheat");

	sprite.SetZ(100.0f);

	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 155, 0));
	this.SetLight(false);

	sprite.SetEmitSound("FlamethrowerFire.ogg");
	sprite.SetEmitSoundSpeed(1.15f);
	sprite.SetEmitSoundVolume(0.66f);
	sprite.SetEmitSoundPaused(true);

	this.set_f32("overheat", 0);
	this.set_f32("max_overheat", MAX_OVERHEAT);
	this.set_f32("overheat_per_shot", OVERHEAT_PER_SHOT);
	this.set_f32("cooldown_rate", COOLDOWN_RATE);
	this.set_bool("overheated", false);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.name == "GUNNER")
	{
		attached.Tag("machinegunner");
	}

	if (!attached.hasTag("has mount")) return;
	CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");

	if (cage !is null)
	{
		this.getSprite().SetVisible(false);
		cage.SetVisible(false);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.name == "GUNNER")
	{
		detached.Untag("machinegunner");
	}
	if (detached.getSprite() !is null && detached !is this && detached.getPlayer() !is null)
	{
		detached.getSprite().ResetTransform();
		detached.getSprite().SetOffset(Vec2f(0,-4));
		detached.set_u8("mg_hidelevel", 5);
	}
	if (this.isAttached()) return;

	CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");
	if (cage !is null)
	{
		this.getSprite().SetVisible(true);
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
		Vec2f aim_vec = this.getPosition() - gunner.getAimPos();
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

const f32 max_scale = 750.0f;
const u8 aftershot_delay = 30;

void onTick(CBlob@ this)
{
	bool is_attached = this.isAttached();
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	if (this.getTickSinceCreated() == 1)
	{
		if (isServer())
		{
			for (u8 i = 0; i < 3; i++)
			{
				CBlob@ ammo = server_CreateBlob("specammo");
				if (ammo !is null)
				{
					if (!this.server_PutInInventory(ammo))
						ammo.server_Die();
				}
			}
		}
		v.getCurrentAmmo().loaded_ammo = 1;
		v.getCurrentAmmo().ammo_stocked = 50;
	}

	if (!(isClient() && isServer()) && getGameTime() < 60*30)
	{
		if (isClient() && this.getSprite() !is null) this.getSprite().SetEmitSoundPaused(true);
		return; // turn engines off!
	}

	CSprite@ sprite = this.getSprite();

	float overheat_mod = 1.0f;
	f32 angle = getAimAngle(this, v);

	this.set_f32("timer", Maths::Max(0, this.get_f32("timer")-1));
	bool not_null = false;
	bool can_fire = false;

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (ap !is null)
	{
		if (ap.getOccupied() !is null && v.getCurrentAmmo() !is null)
		{
			not_null = true;
			CBlob@ gunner = ap.getOccupied();

			CPlayer@ p = gunner.getPlayer();
			if (p !is null)
			{
				PerkStats@ stats;
				if (p.get("PerkStats", @stats))
					overheat_mod = stats.ftw_overheat;
			}

			if (ap.isKeyPressed(key_action1) && gunner.get_u8("mg_hidelevel") > 0
				&& !this.get_bool("overheated"))
			{
				if (v.getCurrentAmmo().loaded_ammo != 0)
				{
					can_fire = true;

					if (this.getInventory() !is null)
					{
						v.getCurrentAmmo().ammo_stocked = this.getInventory().getCount("specammo");
					}

					this.add_f32("overheat", this.get_f32("overheat_per_shot") * overheat_mod);

					if (isServer())
					{
						CBitStream params;
						params.write_f32(this.get_f32("overheat"));
						this.SendCommand(this.getCommandID("sync overheat"), params);
					}

					this.add_f32("scale", 1.0f*Maths::Sqrt(this.get_f32("scale")+max_scale));
					this.set_f32("scale", Maths::Min(max_scale-XORRandom(max_scale/5), this.get_f32("scale")));
					if (this.get_f32("timer") == 0)
					{
						this.set_f32("timer", v.getCurrentAmmo().fire_delay);
						if (isClient())
						{
							this.set_u32("endtime", getGameTime()+aftershot_delay);
							this.SetLight(true);

							sprite.SetEmitSoundSpeed(1.0f+XORRandom(21)*0.01f);
							sprite.SetEmitSoundVolume(0.66f);
							sprite.SetEmitSoundPaused(false);
						}
						if (isServer())
						{
							CBitStream params;
							params.write_f32(this.isFacingLeft()?-angle-90:angle+90);
							this.SendCommand(this.getCommandID("throw fire"), params);
						}
					}
				}
			}
			else
			{
				this.set_f32("scale", 0);
				if (isClient())
				{
					if (this.get_u32("endtime") < getGameTime())
					{
						this.SetLight(false);
						sprite.SetEmitSoundPaused(true);
					}
					else
					{
						sprite.SetEmitSoundPaused(false);
						
						u32 diff = this.get_u32("endtime") - getGameTime();
						sprite.SetEmitSoundSpeed(1.0f+XORRandom(21)*0.01f - (0.5f-0.5f*(float(diff)/float(aftershot_delay))));
						sprite.SetEmitSoundVolume(0.5f - (0.4f-0.4f*(float(diff)/float(aftershot_delay))));
					}
				}
			}
		}
		else
		{
			this.set_f32("scale", Maths::Max(0, this.get_f32("scale") - 1.0f*Maths::Sqrt(this.get_f32("scale"))));
		}
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

	if (isClient() && is_attached)
	{
		CSpriteLayer@ cage = this.getSprite().getSpriteLayer("cage");
		if (cage !is null && cage.isVisible())
		{
			cage.SetVisible(false);
		}
	}

	if (((ap !is null && !ap.isKeyPressed(key_action1)) || this.get_bool("overheated")) && getGameTime() % COOLDOWN_TICKRATE == 0)
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
		if (ap !is null && ap.getOccupied() !is null)
		{
			CBlob@ gunner = ap.getOccupied();
			CSprite@ gsprite = gunner.getSprite();
			f32 perc = (gunner.get_u8("mg_hidelevel")*0.8f) / 4.0f;

			if (gsprite !is null)
			{
				gsprite.ResetTransform();
				gsprite.SetOffset(Vec2f(0, -4.0f*perc));
			}
			if (ap.isKeyPressed(key_action2))
			{
				if (gunner.get_u8("mg_hidelevel") > 0) gunner.set_u8("mg_hidelevel", gunner.get_u8("mg_hidelevel") - 1);
			}
			else if (gunner.get_u8("mg_hidelevel") < 5) gunner.set_u8("mg_hidelevel", gunner.get_u8("mg_hidelevel") + 1);
			if (gunner.get_u8("mg_hidelevel") < 5)
			{
				this.set_f32("scale", 0);
				return;
			}
		}
	}

	Vehicle_SetWeaponAngle(this, angle, v);
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

			if (ap !is null && ap.getOccupied() !is null)
				arm.SetRelativeZ(100.0f);
			else
				arm.SetRelativeZ(100.0f);

			arm.ResetTransform();
			arm.SetFacingLeft((rotation > -90 && rotation < 90) ? facing_left : !facing_left);
			arm.SetOffset(Vec2f(this.isAttached() && (angle > 90 || angle <= -90) ?-8:0,0)+arm_offset);
			arm.RotateBy(rotation + ((rotation > -90 && rotation < 90) ? 0 : 180), Vec2f(((rotation > -90 && rotation < 90) ? facing_left : !facing_left) ? -1.0f : 1.0f, 0.0f));
			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
			if (this.hasAttached()) arm.RotateBy(-this.getAngleDegrees(), Vec2f(0,0));
		}
	}

	Vehicle_StandardControls(this, v);

	if (arm !is null)
	{
		AttachmentPoint@ pickup = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (pickup is null) return;
    	CBlob@ holder = pickup.getOccupied();
		if (holder is null) return;

		if (holder.getPlayer() !is null)
		{
			arm.ResetTransform();
			arm.SetRelativeZ(-10.0f);
			arm.RotateBy(this.isFacingLeft() ? 90 : -90, Vec2f_zero);
		}
		else arm.SetRelativeZ(100.0f);
	}
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
	v.firing = isActionPressed;

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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "barge") return true;
	return (!blob.hasTag("flesh") && !blob.hasTag("trap") && !blob.hasTag("food")
		&& !blob.hasTag("material") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
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

	if (damage >= this.getHealth())
	{
		CInventory@ inv = this.getInventory();
		if (inv is null) return damage;

		int quantity = 0;
		for (u8 i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob@ item = inv.getItem(i);
			if (item is null || item.getName() != "specammo") continue;
			quantity += item.getQuantity();
		}

		this.server_Die();
	}

	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet);

	if (this.isAttached()) return damage;
	if (is_bullet)
	{
		damage *= 0.5f;
		damage += 0.1f;
	}

	return damage;
}

const f32 fire_length_raw = 80.0f;
const f32 fire_angle = 10.0f;
const f32 fire_damage = 0.5f;
const u32 firehit_delay = 1;

bool solidHit(CBlob@ this, CBlob@ blob)
{
	return (!blob.isAttached() || blob.hasTag("collidewithbullets") || blob.hasTag("machinegunner"))
			&& !blob.hasTag("machinegun") && (blob.hasTag("wooden")
			|| blob.hasTag("door") || blob.hasTag("flesh") || blob.hasTag("vehicle"));
}

bool canDamage(CBlob@ this, CBlob@ blob)
{
	return blob.get_u32("firehit_delay") < getGameTime()
			&& blob.getTeamNum() != this.getTeamNum() && (blob.hasTag("apc")
			|| blob.hasTag("weak vehicle") || blob.hasTag("truck")
			|| blob.hasTag("wooden") || blob.hasTag("door") || blob.hasTag("flesh"));
}

void ThrowFire(CBlob@ this, Vec2f pos, f32 angle)
{
	bool client = isClient();
	if (client && !this.isOnScreen()) return;
	
	if (getMap() is null) return;
	Vec2f vel = Vec2f_zero;
	
	f32 fire_length = fire_length_raw * (this.get_f32("scale")/max_scale);
	f32 rot = float(XORRandom(fire_angle))-fire_angle*0.5f;

	if (client)
	{
		ParticleAnimated("FireDust"+(XORRandom(3)+1)+".png", pos+Vec2f(0, -20).RotateBy(angle), vel, angle, 0.75f+XORRandom(51)*0.01f, 2+XORRandom(3), 0, true);

		for (u8 i = 0; i < 3; i++)
		{
			ParticleAnimated("SmallFire", pos+Vec2f(0, -16).RotateBy(angle), Vec2f(0, -1).RotateBy(rot), 0, 1.0f, 3, 0, false);
		}
	}

	const f32 shorten = 8*2.5f;
	int mapsize = getMap().tilemapwidth * getMap().tilemapheight;
	f32 current_angle = fire_angle*0.5f;

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (ap is null) return;

	for (u8 i = 1; i <= current_angle; i++)
	{
		f32 initpoint = fire_length/8;
		f32 endpoint = initpoint;
		HitInfo@[] infos;
		getMap().getHitInfosFromRay(pos, angle-90-fire_angle+i*4, fire_length*2.75f, this, @infos); // this code is so bad XD

		bool doContinue = false;
		for (u16 j = 0; j < infos.length; j++)
		{
			if (doContinue) continue;
			HitInfo@ info = infos[j];
			if (info is null) continue;

			if (info.blob is null && info.tileOffset < mapsize && info.distance < endpoint*8*2.75f)
			{
				if (XORRandom(10) == 0) getMap().server_setFireWorldspace(info.hitpos, true); // 10% chance to ignite
				endpoint = info.distance/shorten;
			}
			if (info.blob !is null && !info.blob.isInWater())
			{
				if (info.blob.hasTag("structure") || info.blob.hasTag("trap")
					|| info.blob.isLadder() || info.blob.isOverlapping(this)) continue;

				if (solidHit(this, info.blob))
				{
					f32 damage = fire_damage;
					if (info.blob.isAttached()) damage *= 0.5f;

					if (!info.blob.hasTag("flesh"))
					{
						endpoint = info.distance/shorten;
						doContinue = true;
					}
					if (isServer() && canDamage(this, info.blob))
					{
						if (ap.getOccupied() !is null)
							ap.getOccupied().server_Hit(info.blob, info.blob.getPosition(), Vec2f(0, 0.35f), fire_damage, Hitters::fire, true);
						else
							this.server_Hit(info.blob, info.blob.getPosition(), Vec2f(0, 0.35f), damage, Hitters::fire, true);
						info.blob.set_u32("firehit_delay", getGameTime()+firehit_delay);
					}
				}
			}
		}
		if (client)
		{
			for (u8 j = 0; j < endpoint; j++)
			{
				CParticle@ p = ParticleAnimated("SmallFire"+(1+XORRandom(2)), pos-Vec2f(0,1)+Vec2f(0, -16 + -j*(20*(endpoint/initpoint))).RotateBy(angle-fire_angle+i*4), Vec2f(0,-2).RotateBy(angle-fire_angle/2+i+XORRandom(100)-50), 0, 2.0f, 3, 0, false);
				if (p !is null)
				{
					p.growth = -0.075f;
					p.deadeffect = -1;
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("throw fire"))
	{
		f32 angle = params.read_f32();
		ThrowFire(this, this.getPosition(), angle);
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

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused) {}

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!getNet().isClient()) return;

	ParticleAnimated(CFileMatcher(filename).getFirst(), this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}