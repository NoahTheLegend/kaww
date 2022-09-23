#include "WarfareGlobal.as"
#include "SeatsCommon.as"
#include "VehicleAttachmentCommon.as"
#include "KnockedCommon.as"

// HOOKS THAT YOU MUST IMPLEMENT WHEN INCLUDING THIS FILE
// void Vehicle_onFire( CBlob@ this, CBlob@ bullet, const u8 charge )
//      bullet will be null on client! always check for null
// bool Vehicle_canFire( CBlob@ this, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue )

class AmmoInfo
{
	u8 loaded_ammo;
	string fire_sound;
	string empty_sound;
	bool blob_ammo;
	string ammo_name;
	string ammo_inventory_name;
	string bullet_name;
	bool infinite_ammo;
	u16 fire_delay;
	u8 fire_amount;
	u8 fire_cost_per_amount;
	u8 fire_style;
	u16 ammo_stocked;
	u16 max_charge_time;
}

class VehicleInfo
{
	s32 fire_time;
	bool firing;
	AmmoInfo[] ammo_types;
	u8 current_ammo_index;
	u8 last_fired_index;
	Vec2f fire_pos;
	f32 move_speed;
	f32 turn_speed;
	Vec2f out_vel;
	bool inventoryAccess;
	Vec2f mag_offset;
	f32 wep_angle;
	f32 fly_speed;
	f32 fly_amount;
	s8 move_direction;
	string ground_sound;
	f32 ground_volume;
	f32 ground_pitch;
	string water_sound;
	f32 water_volume;
	f32 water_pitch;
	u8 wheels_angle;
	u32 pack_secs;
	u32 pack_time;
	u16 charge;
	u16 last_charge;
	u16 cooldown_time;

	AmmoInfo@ getCurrentAmmo()
	{
		return ammo_types[current_ammo_index];
	}
};


namespace Vehicle_Fire_Style
{
	enum Style
	{
		normal = 0, //fires as soon as the charge is done
		custom, //fires if the charge is done, but also calls Vehicle_preFire
	};
};

void Vehicle_Setup(CBlob@ this,
                   f32 moveSpeed, f32 turnSpeed, Vec2f jumpOutVelocity, bool inventoryAccess
                  )
{
	VehicleInfo v;

	v.fire_time = 0;
	v.firing = false;
	v.fire_pos = Vec2f_zero;
	v.move_speed = moveSpeed;
	v.turn_speed = turnSpeed;
	v.out_vel = jumpOutVelocity;
	v.inventoryAccess = inventoryAccess;
	v.mag_offset = Vec2f_zero;
	v.charge = 0;
	v.last_charge = 0;
	v.cooldown_time = 0;
	v.fire_time = 0;
	v.current_ammo_index = 0;
	v.last_fired_index = 0;
	v.wep_angle = 0.0f;

	this.addCommandID("fire");
	this.addCommandID("fire blob");
	this.addCommandID("flip_over");
	this.addCommandID("getin_mag");
	this.addCommandID("load_ammo");
	this.addCommandID("ammo_menu");
	this.addCommandID("swap_ammo");
	this.addCommandID("sync_ammo");
	this.addCommandID("sync_last_fired");
	this.addCommandID("putin_mag");
	this.addCommandID("vehicle getout");
	this.addCommandID("reload");
	this.addCommandID("recount ammo");
	this.Tag("vehicle");
	this.getShape().getConsts().collideWhenAttached = false;
	AttachmentPoint@ mag = getMagAttachmentPoint(this);
	if (mag !is null)
	{
		v.mag_offset = mag.offset;
	}
	this.set("VehicleInfo", @v);
}

void Vehicle_AddAmmo(CBlob@ this, VehicleInfo@ v, int fireDelay, int fireAmount, int fireCost, const string& in ammoConfigName, const string& in ammoInvName, 
					 const string& in bulletConfigName, const string& in fireSound, const string& in emptySound, Vehicle_Fire_Style::Style fireStyle = Vehicle_Fire_Style::normal, Vec2f firePosition = Vec2f_zero, int chargeTime = 0)
{
	AmmoInfo a;
	a.loaded_ammo = 0;
	a.fire_sound = fireSound;
	a.empty_sound = emptySound;
	a.bullet_name = bulletConfigName;
	a.blob_ammo = hasMag(this);
	a.ammo_name = ammoConfigName;
	a.ammo_inventory_name = ammoInvName;
	a.fire_delay = fireDelay;
	a.fire_amount = fireAmount;
	a.fire_cost_per_amount = fireCost;
	a.max_charge_time = chargeTime;
	a.fire_style = fireStyle;
	a.ammo_stocked = 0;
	a.infinite_ammo = false;

	if (getRules().hasTag("singleplayer"))
	{
		a.infinite_ammo = true;
	}

	v.ammo_types.push_back(a);
}

void Vehicle_SetupAirship(CBlob@ this, VehicleInfo@ v,
                          f32 flySpeed)
{
	v.fly_speed = flySpeed;
	v.fly_amount = 0.25f;
	v.move_direction = 0;
	this.Tag("airship");
}

void Vehicle_SetupGroundSound(CBlob@ this, VehicleInfo@ v, const string& in movementSound, f32 movementVolumeMod, f32 movementPitchMod)
{
	v.ground_sound = movementSound;
	v.ground_volume = movementVolumeMod;
	v.ground_pitch = movementPitchMod;
	this.getSprite().SetEmitSoundPaused(true);
}

void Vehicle_SetupWaterSound(CBlob@ this, VehicleInfo@ v, const string& in movementSound, f32 movementVolumeMod, f32 movementPitchMod)
{
	v.water_sound = movementSound;
	v.water_volume = movementVolumeMod;
	v.water_pitch = movementPitchMod;
	this.getSprite().SetEmitSoundPaused(true);
}

int server_LoadAmmo(CBlob@ this, CBlob@ ammo, int take, VehicleInfo@ v)
{
	if (ammo is null)
	{
		v.getCurrentAmmo().loaded_ammo = take;
		CBitStream params;
		params.write_u8(take);
		this.SendCommand(this.getCommandID("reload"), params);
		return take;
	}

	u8 loadedAmmo = v.getCurrentAmmo().loaded_ammo;
	int amount = ammo.getQuantity();

	if (amount >= take)
	{
		loadedAmmo += take;
		ammo.server_SetQuantity(amount - take);
	}
	else if (amount > 0)  // take rest
	{
		loadedAmmo += amount;
		ammo.server_SetQuantity(0);
	}

	if (loadedAmmo > 0)
	{
		SetOccupied(this.getAttachments().getAttachmentPointByName("MAG"), 1);
	}

	v.getCurrentAmmo().loaded_ammo = loadedAmmo;
	CBitStream params;
	params.write_u8(loadedAmmo);
	this.SendCommand(this.getCommandID("reload"), params);

	// no ammo left - remove from inv and die
	const u16 ammoQuantity = ammo.getQuantity();
	if (ammoQuantity == 0)
	{
		this.server_PutOutInventory(ammo);
		ammo.server_Die();
	}

	// ammo count for GUI
	RecountAmmo(this, v);

	return loadedAmmo;
}

void RecountAmmo(CBlob@ this, VehicleInfo@ v)
{
	for(int i = 0; i < v.ammo_types.size(); ++i)
	{
		AmmoInfo@ current_ammo = v.ammo_types[i];
		int ammoStocked = current_ammo.loaded_ammo;
		const string ammoName = current_ammo.ammo_name;
		CInventory@ inventory = this.getInventory();

		for (int i = 0; i < inventory.getItemsCount(); i++)
		{
			CBlob@ invItem = inventory.getItem(i);
			if (invItem.getName() == ammoName)
			{
				ammoStocked += invItem.getQuantity();
			}
		}

		current_ammo.ammo_stocked = ammoStocked;

		CBitStream params;
		params.write_u8(i);
		params.write_u16(current_ammo.ammo_stocked);
		params.write_u8(current_ammo.loaded_ammo);
		this.SendCommand(this.getCommandID("recount ammo"), params);
	}
}

void swapAmmo(CBlob@ this, VehicleInfo@ v, u8 ammoIndex)
{
	if(ammoIndex >= v.ammo_types.size())
	{
		ammoIndex = 0;
	}

	v.current_ammo_index = ammoIndex;
}

AttachmentPoint@ getMagAttachmentPoint(CBlob@ this)
{
	return this.getAttachments().getAttachmentPointByName("MAG");
}

CBlob@ getMagBlob(CBlob@ this)
{
	AttachmentPoint@ a = getMagAttachmentPoint(this);
	if (a is null) return null;
	return a.getOccupied();
}

bool isMagEmpty(CBlob@ this)
{
	return (getMagBlob(this) is null);
}

bool hasMag(CBlob@ this)
{
	return (getMagAttachmentPoint(this) !is null);
}

bool canFireIgnoreFiring(CBlob@ this, VehicleInfo@ v)
{
	return (getGameTime() > v.fire_time);
}

bool canFire(CBlob@ this, VehicleInfo@ v)
{
	return (v.firing && canFireIgnoreFiring(this, v));
}

void Vehicle_SetWeaponAngle(CBlob@ this, f32 angleDegrees, VehicleInfo@ v)
{
	v.wep_angle = angleDegrees;
}

f32 Vehicle_getWeaponAngle(CBlob@ this, VehicleInfo@ v)
{
	return v.wep_angle;
}

void Vehicle_LoadAmmoIfEmpty(CBlob@ this, VehicleInfo@ v)
{
	if(v.current_ammo_index < v.ammo_types.size())
	{
		if (getNet().isServer() && (this.getInventory().getItemsCount() > 0 || v.getCurrentAmmo().infinite_ammo) &&
		        getMagBlob(this) is null &&
		        v.getCurrentAmmo().loaded_ammo == 0)
		{
			for (int i = 0; i < this.getInventory().getItemsCount(); ++i)
			{
				CBlob@ toLoad = this.getInventory().getItem(i);
				if (toLoad !is null)
				{
					if (toLoad.getName() == v.getCurrentAmmo().ammo_name)
					{
						server_LoadAmmo(this, toLoad, v.getCurrentAmmo().fire_amount * v.getCurrentAmmo().fire_cost_per_amount, v);
						break;
					}
					else if (v.getCurrentAmmo().blob_ammo && this.server_PutOutInventory(toLoad))
					{
						this.server_AttachTo(toLoad, "MAG");
					}
				}
				else
				{
					server_LoadAmmo(this, null, v.getCurrentAmmo().fire_amount * v.getCurrentAmmo().fire_cost_per_amount, v);
					break;
				}
			}
		}
	}
}

void SetFireDelay(CBlob@ this, int shot_delay, VehicleInfo@ v)
{
	v.firing = false;
	v.fire_time = (getGameTime() + shot_delay);
}

bool Vehicle_AddFlipButton(CBlob@ this, CBlob@ caller)
{ // moved to controls
	/*if (isFlipped(this))
	{
		CButton@ button = caller.CreateGenericButton(12, Vec2f(0, -4), this, this.getCommandID("flip_over"), "Flip back");

		if (button !is null)
		{
			button.deleteAfterClick = false;
			return true;
		}
	}*/

	return false;
}

bool MakeLoadAmmoButton(CBlob@ this, CBlob@ caller, Vec2f offset, VehicleInfo@ v)
{
	if (this.getName() != "heavygun") return false;
	// find ammo in inventory
	CInventory@ inv = caller.getInventory();

	if (inv !is null)
	{
		for (int i = 0; i < v.ammo_types.size(); i++)
		{
			string ammo = v.ammo_types[i].ammo_name;
			CBlob@ ammoBlob = inv.getItem(ammo);

			if (ammoBlob is null)
			{
				CBlob@ held = caller.getCarriedBlob();

				if (held !is null)
				{
					if (held.getName() == ammo)
					{
						@ammoBlob = held;
					}
				}
			}

			if (ammoBlob !is null)
			{
				CBitStream callerParams;
				callerParams.write_u16(caller.getNetworkID());
				caller.CreateGenericButton("$" + ammoBlob.getName() + "$", offset + Vec2f(0, -4), this, this.getCommandID("load_ammo"), getTranslatedString("Load {ITEM}").replace("{ITEM}", ammoBlob.getInventoryName()), callerParams);
				return true;
			}
		}

		/*else
		{
		    CButton@ button = caller.CreateGenericButton( "$DISABLED$", offset, this, 0, "Needs " + ammoBlob.getInventoryName() );
		    if (button !is null) button.enableRadius = 0.0f;
		    return true;
		}*/
	}

	return false;
}

bool Vehicle_AddLoadAmmoButton(CBlob@ this, CBlob@ caller)
{
	// MAG
	if (!hasMag(this))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return false;
		}
		return MakeLoadAmmoButton(this, caller, Vec2f_zero, v);
	}
	else
	{
		// put in what is carried
		CBlob@ carryObject = caller.getCarriedBlob();
		if (carryObject !is null && !carryObject.isSnapToGrid())  // not spikes or door
		{
			CBitStream callerParams;
			callerParams.write_u16(caller.getNetworkID());
			callerParams.write_u16(carryObject.getNetworkID());
			caller.CreateGenericButton("$" + carryObject.getName() + "$", getMagAttachmentPoint(this).offset, this, this.getCommandID("putin_mag"), getTranslatedString("Load {ITEM}").replace("{ITEM}", carryObject.getInventoryName()), callerParams);
			return true;
		}
		else  // nothing in hands - take automatic
		{
			VehicleInfo@ v;
			if (!this.get("VehicleInfo", @v))
			{
				return false;
			}
			return MakeLoadAmmoButton(this, caller, getMagAttachmentPoint(this).offset, v);
		}
	}
}

void Fire(CBlob@ this, VehicleInfo@ v, CBlob@ caller, const u8 charge)
{
	// normal fire
	if (canFireIgnoreFiring(this, v) && caller !is null)
	{
		CBlob @blobInMag = getMagBlob(this);
		CBlob @carryObject = caller.getCarriedBlob();
		AttachmentPoint@ mag = getMagAttachmentPoint(this);
		Vec2f bulletPos;

		if (mag !is null)
		{
			bulletPos = mag.getPosition();
		}
		else
		{
			bulletPos = v.fire_pos;
			if (!this.isFacingLeft())
			{
				bulletPos.x = -bulletPos.x;
			}
			bulletPos = caller.getPosition() + bulletPos;
		}

		//cast from position to bullet pos to prevent "clipping" through walls
		{
			Vec2f collect;
  			if (getMap().rayCastSolid(this.getPosition(), bulletPos, collect))
  			{
  				bulletPos = collect;
  			}
		}

		bool shot = false;

		// fire whatever was in the mag/bowl first
		if (blobInMag !is null)
		{
			this.server_DetachFrom(blobInMag);

			if (!blobInMag.hasTag("player"))
				blobInMag.SetDamageOwnerPlayer(caller.getPlayer());

			server_FireBlob(this, blobInMag, charge);
			shot = true;
		}
		else
		{
			u8 loadedAmmo = v.getCurrentAmmo().loaded_ammo;
			if (loadedAmmo != 0) // shoot if ammo loaded
			{
				shot = true;

				const int team = caller.getTeamNum();
				const bool isServer = getNet().isServer();
				for (u8 i = 0; i < loadedAmmo; i += v.getCurrentAmmo().fire_cost_per_amount)
				{
					CBlob@ bullet = isServer ? server_CreateBlobNoInit(v.getCurrentAmmo().bullet_name) : null;
					if (bullet !is null)
					{
						bullet.set_s8(penRatingString, this.get_s8(weaponRatingString));
						
						bullet.setPosition(bulletPos);
						bullet.server_setTeamNum(team);
						bullet.set_f32("linear_length", this.get_f32("linear_length"));
						bullet.set_f32("explosion_damage_scale", this.get_f32("explosion_damage_scale"));
						bullet.SetDamageOwnerPlayer(caller.getPlayer());
						bullet.Init();
					}

					server_FireBlob(this, bullet, charge);
				}
				
				v.getCurrentAmmo().loaded_ammo = 0;
				SetOccupied(mag, 0);

				v.last_fired_index = v.current_ammo_index;
				CBitStream params;
				params.write_u8(v.last_fired_index);
				this.SendCommand(this.getCommandID("sync_last_fired"), params);
			}
		}

		// sound

		if (shot)
		{
			this.getSprite().PlayRandomSound(v.getCurrentAmmo().fire_sound);
		}
		else
		{
			// empty shot
			this.getSprite().PlayRandomSound(v.getCurrentAmmo().empty_sound);
			Vehicle_onFire(this, v, null, 0);
		}

		// finally set the delay
		SetFireDelay(this, v.getCurrentAmmo().fire_delay, v);
	}
}

void server_FireBlob(CBlob@ this, CBlob@ blob, const u8 charge)
{
	if (blob !is null)
	{
		CBitStream params;
		params.write_netid(blob.getNetworkID());
		params.write_u8(charge);
		this.SendCommand(this.getCommandID("fire blob"), params);
	}
}

void Vehicle_StandardControls(CBlob@ this, VehicleInfo@ v)
{
	this.set_f32("engine_RPMtarget", 0); // shut off the engine by default (longer idle time?)

	v.move_direction = 0;
	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			CBlob@ blob = ap.getOccupied();

			if (blob !is null && ap.socket)
			{
				// GET OUT
				if (blob.isMyPlayer() && ap.isKeyJustPressed(key_up))
				{
					CBitStream params;
					params.write_u16(blob.getNetworkID());
					this.SendCommand(this.getCommandID("vehicle getout"), params);
					return;
				} // get out

				// DRIVER
				if (ap.name == "DRIVER" && !this.hasTag("immobile"))
				{
					bool moveUp = false;
					const f32 angle = this.getAngleDegrees();
					// set facing
					blob.SetFacingLeft(this.isFacingLeft());
					const bool left = ap.isKeyPressed(key_left);
					const bool right = ap.isKeyPressed(key_right);
					const bool onground = this.isOnGround();
					const bool onwall = this.isOnWall();

					// left / right
					if (angle < 80 || angle > 290)
					{
						f32 moveForce = v.move_speed/32;
						f32 turnSpeed = v.turn_speed;
						Vec2f groundNormal = this.getGroundNormal();

						Vec2f vel = this.getVelocity();
						Vec2f force;

						// more force when starting
						if (this.getShape().vellen < 1.75f)
						{
							moveForce *= 2.0f; // gear 1
						}

						const f32 engine_topspeed = v.move_speed; //5500;

						moveForce *= Maths::Clamp(this.get_f32("engine_RPM"), 0, engine_topspeed) / 4500;

						

						if (this.isOnGround() || this.wasOnGround())
						{
							this.AddForce(Vec2f(0.0f, this.getMass()*-0.24f)); // this is nice
						}

						bool slopeangle = (angle > 15 && angle < 345 && this.isOnMap());

						Vec2f pos = this.getPosition();

						if (!left && !right) //no input
						{
							this.set_f32("engine_throttle", Maths::Lerp(this.get_f32("engine_throttle"), 0.0f, 0.1f));
						}

						if (this.isFacingLeft())
						{
							if (this.getShape().vellen > 1.0f || this.get_f32("engine_RPM") > 2550)
							{
								this.add_f32("wheelsTurnAmount", (this.getVelocity().x >= 0 ? 1 : -1) * 1 * (this.get_f32("engine_RPM")- 1900)/30000);
							}

							if (ap.isKeyJustPressed(key_left))
							{
								this.getSprite().PlayRandomSound("/EngineThrottle", 1.7f, 0.90f + XORRandom(11)*0.01f);

								if (isClient())
								{	
									for(int i = 0; i < 9; ++i)
									{
										Vec2f velocity = Vec2f(7, 0);
										velocity *= this.isFacingLeft() ? 0.5 : -0.5;
										velocity += Vec2f(0, -0.15) + this.getVelocity()*0.35f;
										ParticleAnimated("Smoke", this.getPosition() + Vec2f_lengthdir(this.isFacingLeft() ? 35 : -35, this.getAngleDegrees()), velocity.RotateBy(this.getAngleDegrees()) + getRandomVelocity(0.0f, XORRandom(125) * 0.01f, 360), 45 + float(XORRandom(90)), 0.3f + XORRandom(50) * 0.01f, 1 + XORRandom(2), -0.02 - XORRandom(30) * -0.0005f, false );
									}
								}

								ShakeScreen(32.0f, 32, this.getPosition());
							}
							this.set_f32("engine_throttle", Maths::Lerp(this.get_f32("engine_throttle"), 0.5f, 0.5f));

							if (onground && groundNormal.y < -0.4f && groundNormal.x > 0.05f && vel.x < 1.0f && slopeangle)   // put more force when going up
							{
								force.x -= 4.0f * moveForce;
							}
							else
							{
								force.x -= moveForce;
							}

							if (ap.isKeyPressed(key_action2))
							{
								if (right) {force.x *= -0.45f;} // reverse
							}
							else 
							{
								if (vel.x < -turnSpeed)
								{
									this.SetFacingLeft(true);
								}

								if (right && getGameTime() % 4 == 0)
								{
									this.SetFacingLeft(false);
								}
							}
						}

						if (!this.isFacingLeft())
						{//spamable and has no effect
							if (this.getShape().vellen > 1.0f || this.get_f32("engine_RPM") > 2550)
							{						
								this.add_f32("wheelsTurnAmount", (this.getVelocity().x >= 0 ? -1 : 1) * -1 * (this.get_f32("engine_RPM")- 1900)/30000);
								//this.add_f32("wheelsTurnAmount", -1 * (this.get_f32("engine_RPM")- 1900)/30000);
							}

							if (ap.isKeyJustPressed(key_right))
							{
								this.getSprite().PlayRandomSound("/EngineThrottle", 1.7f, 0.90f + XORRandom(11)*0.01f);

								if (isClient())
								{	
									for(int i = 0; i < 9; ++i)
									{
										Vec2f velocity = Vec2f(7, 0);
										velocity *= this.isFacingLeft() ? 0.5 : -0.5;
										velocity += Vec2f(0, -0.15) + this.getVelocity()*0.35f;
										ParticleAnimated("Smoke", this.getPosition() + Vec2f_lengthdir(this.isFacingLeft() ? 35 : -35, this.getAngleDegrees()), velocity.RotateBy(this.getAngleDegrees()) + getRandomVelocity(0.0f, XORRandom(125) * 0.01f, 360), 45 + float(XORRandom(90)), 0.3f + XORRandom(50) * 0.01f, 1 + XORRandom(2), -0.02 - XORRandom(30) * -0.0005f, false );
									}
								}

								ShakeScreen(32.0f, 32, this.getPosition());
							}
							this.set_f32("engine_throttle", Maths::Lerp(this.get_f32("engine_throttle"), 0.5f, 0.5f));

							

							if (onground && groundNormal.y < -0.4f && groundNormal.x < -0.05f && vel.x > -1.0f && slopeangle)   // put more force when going up
							{
								force.x += 4.0f * moveForce;
							}
							else
							{
								force.x += moveForce;
							}

							if (ap.isKeyPressed(key_action2))
							{
								if (left) {force.x *= -0.45f;} // reverse
							}
							else
							{
								if (vel.x > turnSpeed)
								{
									this.SetFacingLeft(false);
								}

								if (left && getGameTime() % 4 == 0)
								{
									this.SetFacingLeft(true);
								}
							}
						}

						


						if (Maths::Abs(vel.x) < 3.0f) // range of speed to be in neutral
						{
							if ((left or right))
							{
								this.AddForce(force);
								force.RotateBy(this.getShape().getAngleDegrees());
							}
						}
						else 
						{
							this.AddForce(force);
							force.RotateBy(this.getShape().getAngleDegrees());
						}
					
						
					}

					// tilt 
					const bool down = ap.isKeyPressed(key_down) || ap.isKeyPressed(key_action3);
					if (down)
					{
						this.Tag("holding_down");
						f32 angle = this.getAngleDegrees();
						if (this.isOnGround())
						{
							f32 rotvel = 0;

							this.AddTorque(this.isFacingLeft() ? 420.0f : -420.0f);

							this.setAngleDegrees(this.getAngleDegrees() + rotvel);
						}
					}
					else{
						this.Untag("holding_down");
					}

					if (onground)
					{
						const bool faceleft = this.isFacingLeft();
						if (angle > 330 || angle < 30)
						{
							f32 wallMultiplier = (this.isOnWall() && (angle > 350 || angle < 10)) ? 4.0f : 1.0f;
							f32 torque = 450.0f * wallMultiplier;
							if (down)
							{
								f32 mod = 1.0f;
								if (isFlipped(this)) mod = 4.33f;
								{
									this.AddTorque(faceleft ? torque*mod : -torque*mod);
								}
							}

							this.AddForce(Vec2f(0.0f, -100.0f * wallMultiplier));
						}

						if (isFlipped(this))
						{
							f32 angle = this.getAngleDegrees();
							if (!left && !right)
								this.AddTorque(angle < 180 ? -900 : 900);
							else
								this.AddTorque(((faceleft && left) || (!faceleft && right)) ? 500 : -500);
							this.AddForce(Vec2f(0, -1800));
						}
					}

					if (this.get_f32("engine_throttle") >= 0.5f) // make this an equation
					{
						this.set_f32("engine_RPMtarget", 8000); // gas gas gas
					}
					else
					{
						this.set_f32("engine_RPMtarget", 2000); // let engine idle
					}
					
				}  // driver

				if (ap.name == "GUNNER" && !isKnocked(blob))
				{
					// set facing
					blob.SetFacingLeft(this.isFacingLeft());

					if (blob.isMyPlayer() && ap.isKeyJustPressed(key_inventory) && v.charge == 0)
					{
						this.SendCommand(this.getCommandID("swap_ammo"));
					}

					u8 style = v.getCurrentAmmo().fire_style;
					switch (style)
					{
						case Vehicle_Fire_Style::normal:
							//normal firing
							v.firing = false;
							if (ap.isKeyPressed(key_action1))
							{
								v.firing = true;
								if (canFire(this, v) && blob.isMyPlayer())
								{
									CBitStream fireParams;
									fireParams.write_u16(blob.getNetworkID());
									fireParams.write_u8(0);
									this.SendCommand(this.getCommandID("fire"), fireParams);
								}
							}
							break;

						case Vehicle_Fire_Style::custom:
							//custom firing requirements
						{
							u8 charge = 0;
							if (ap.isKeyPressed(key_action1))
							{
								v.firing = true;
								CBlob@ b = ap.getOccupied();

							}

							if (Vehicle_canFire(this, v, ap.isKeyPressed(key_action1), ap.isKeyPressed(key_action1), charge) && canFire(this, v) && blob.isMyPlayer())
							{
								CBitStream fireParams;
								fireParams.write_u16(blob.getNetworkID());
								fireParams.write_u8(charge);
								this.SendCommand(this.getCommandID("fire"), fireParams);
							}
						}

						break;
					}

				} // gunner

				// ROWER
				if ((ap.name == "ROWER" && this.isInWater()) || (ap.name == "SAIL" && !this.hasTag("no sail")))
				{
					const f32 moveForce = v.move_speed;
					const f32 turnSpeed = v.turn_speed;
					Vec2f force;
					bool moving = false;
					const bool left = ap.isKeyPressed(key_left);
					const bool right = ap.isKeyPressed(key_right);
					const Vec2f vel = this.getVelocity();

					bool backwards = false;

					// row left/right

					if (left)
					{
						force.x -= moveForce;

						if (vel.x < -turnSpeed)
						{
							this.SetFacingLeft(true);
						}
						else
						{
							backwards = true;
						}

						moving = true;
					}

					if (right)
					{
						force.x += moveForce;

						if (vel.x > turnSpeed)
						{
							this.SetFacingLeft(false);
						}
						else
						{
							backwards = true;
						}

						moving = true;
					}

					if (moving)
					{
						this.AddForce(force);
					}
				}
			}  // ap.occupied
		}   // for
	}

	if (this.hasTag("airship"))
	{
		f32 flyForce = v.fly_speed;
		f32 flyAmount = v.fly_amount;
		this.AddForce(Vec2f(0, flyForce * flyAmount));
	}

}

CSpriteLayer@ Vehicle_addWheel(CBlob@ this, VehicleInfo@ v, const string& in textureName, int frameWidth, int frameHeight, int frame, Vec2f offset)
{
	v.wheels_angle = 0;
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ wheel = sprite.addSpriteLayer("!w " + sprite.getSpriteLayerCount(), textureName, frameWidth, frameHeight);

	if (wheel !is null)
	{
		Animation@ anim = wheel.addAnimation("default", 0, false);
		anim.AddFrame(frame);
		wheel.SetOffset(offset);
		wheel.SetRelativeZ(0.1f);
	}

	return wheel;
}

CSpriteLayer@ Vehicle_addWoodenWheel(CBlob@ this, VehicleInfo@ v, int frame, Vec2f offset)
{
	return Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, frame, offset);
}
CSpriteLayer@ Vehicle_addPokeyWheel(CBlob@ this, VehicleInfo@ v, int frame, Vec2f offset)
{
	return Vehicle_addWheel(this, v, "PokeyWheels.png", 16, 16, frame, offset);
}
CSpriteLayer@ Vehicle_addRubberWheel(CBlob@ this, VehicleInfo@ v, int frame, Vec2f offset)
{
	return Vehicle_addWheel(this, v, "RubberWheels.png", 16, 16, frame, offset);
}
CSpriteLayer@ Vehicle_addTinyRubberWheel(CBlob@ this, VehicleInfo@ v, int frame, Vec2f offset)
{
	return Vehicle_addWheel(this, v, "TinyRubberWheels.png", 16, 16, frame, offset);
}
CSpriteLayer@ Vehicle_addRubberWheelBackground(CBlob@ this, VehicleInfo@ v, int frame, Vec2f offset)
{
	return Vehicle_addWheel(this, v, "RubberWheelsBack.png", 16, 16, frame, offset);
}

void UpdateWheels(CBlob@ this)
{
	if (this.hasTag("immobile"))
		return;

	//rotate wheels
	CSprite@ sprite = this.getSprite();
	uint sprites = sprite.getSpriteLayerCount();

	for (uint i = 0; i < sprites; i++)
	{
		CSpriteLayer@ wheel = sprite.getSpriteLayer(i);
		if (wheel.name.substr(0, 2) == "!w") // this is a wheel
		{
			f32 wheels_angle;
			if (0 == 1)
			{
				wheels_angle = ((this.getVelocity().x * 60) % 360); //Maths::Round
			}
			else {
				//wheels_angle = (Maths::Round(wheel.getWorldTranslation().x * 10) % 360);
				wheels_angle = (Maths::Round(((wheel.getWorldTranslation().x*8) + (this.get_f32("wheelsTurnAmount")*80))) % 360);
			}
						
			wheel.ResetTransform();
			wheel.RotateBy(wheels_angle + i * i * 16.0f, Vec2f_zero);
		}
	}
}

void RemoveWheelsOnFlight(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	uint sprites = sprite.getSpriteLayerCount();

	for (uint i = 0; i < sprites; i++)
	{
		CSpriteLayer@ wheel = sprite.getSpriteLayer(i);
		if (wheel.name.substr(0, 2) == "!w") // this is a wheel
		{
			wheel.SetVisible(this.isOnGround() || this.wasOnGround());
		}
	}
}

void Vehicle_LevelOutInAir(CBlob@ this)
{
	if (this.hasTag("holding_down"))
	{
		return;
	}

	f32 rotvel = 0;

	f32 angle = this.getAngleDegrees();
	if  (angle > 23 && angle < 337)
	{
		if (!getMap().isInWater(this.getPosition()) && !this.wasOnGround() && !this.isOnGround())
		{
			f32 diff = 360 - this.getAngleDegrees();
			diff = (diff + 180) % 360 - 180;

			if (Maths::Abs(diff) > 1)
				rotvel += (diff > 0 ? 1 : -1) * 0.75; // * 0.75 is rate

			this.AddTorque(this.isFacingLeft() ? -360.0f : 360.0f);

			this.setAngleDegrees(this.getAngleDegrees() + rotvel);
			return;
		}
	}
	else
	{
		f32 diff = 360 - this.getAngleDegrees();
		diff = (diff + 180) % 360 - 180;

		if (Maths::Abs(diff) > 1)
			rotvel += (diff > 0 ? 1 : -1) * 0.5;


		this.setAngleDegrees(this.getAngleDegrees() + rotvel);
		return;
	}
}

void Vehicle_LevelOutInAirCushion(CBlob@ this)
{
	if (this.hasTag("holding_down"))
	{
		return;
	}

	f32 angle = this.getAngleDegrees();
	if  (angle > 4 && angle < 356)
	{
		f32 rotvel = 0;

		f32 diff = 360 - this.getAngleDegrees();
		diff = (diff + 180) % 360 - 180;

		float rate = 1.6f;
		if  (angle > 10 && angle < 350)
		{
			rate = 2.5f;
		}

		if (Maths::Abs(diff) > 1)
			rotvel += (diff > 0 ? 1 : -1) * rate; // * 0.75 is rate

		this.AddTorque(this.isFacingLeft() ? -190.0f :190.0f);

		this.setAngleDegrees(this.getAngleDegrees() + rotvel);
		return;
	}
}

void Vehicle_DontRotateInWater(CBlob@ this)
{
	//  if (getGameTime() % 5 > 0)
	//  return;

	if (getMap().isInWater(this.getPosition() + Vec2f(0.0f, this.getHeight() * 0.5f)))
	{
		const f32 thresh = 15.0f;
		const f32 angle = this.getAngleDegrees();
		if ((angle < thresh || angle > 360.0f - thresh) && !this.hasTag("sinking"))
		{
			this.setAngleDegrees(0.0f);
			this.getShape().SetRotationsAllowed(false);
			return;

		}
	}

	this.getShape().SetRotationsAllowed(true);
}

bool Vehicle_doesCollideWithBlob_ground(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached()) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

bool Vehicle_doesCollideWithBlob_boat(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached()) // no colliding against people inside vehicles
		return false;
	// no colliding with shit underwater
	if (blob.hasTag("material") || (blob.isInWater() && (blob.getName() == "heart" || blob.getName() == "log" || blob.hasTag("dead"))))
		return false;

	return true;
	//return ((!blob.hasTag("vehicle") || this.getTeamNum() != blob.getTeamNum())); // don't collide with team boats (other vehicles will attach)
}

void Vehicle_onAttach(CBlob@ this, VehicleInfo@ v, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	// special-case stone material  - put in inventory
	if(v.current_ammo_index < v.ammo_types.size())
	{
		if (getNet().isServer() && attached.getName() == v.getCurrentAmmo().ammo_name)
		{
			attached.server_DetachFromAll();
			this.server_PutInInventory(attached);
			server_LoadAmmo(this, attached, v.getCurrentAmmo().fire_amount, v);
		}
	}

	// move mag offset
	if (attachedPoint.name == "MAG")
	{
		attachedPoint.offset = v.mag_offset;
		attachedPoint.offset.y += attached.getHeight() / 2.0f;
		attachedPoint.offsetZ = -60.0f;
	}

	// sync current ammo index
	if(isServer())
	{
		CBitStream params;
		params.write_u8(v.current_ammo_index);
		this.SendCommand(this.getCommandID("sync_ammo"), params);

		// recount all ammo so the client has proper numbers
		RecountAmmo(this, v);
	}

	if (attached.hasTag("player") && // is a player
		attachedPoint.name == "DRIVER" && // in driver seat 
		this.get_f32("engine_RPM") < 1000) // rpm is low
	{
		this.getSprite().PlaySound("EngineStart_tank", 1.0f, 0.95f + XORRandom(11)*0.01f);

		ShakeScreen(32.0f, 64, this.getPosition());

		if (isClient())
		{	
			for(int i = 0; i < 5; ++i)
			{
				Vec2f velocity = Vec2f(7, 0);
				velocity *= this.isFacingLeft() ? 0.25 : -0.25;
				velocity += Vec2f(0, -0.35) + this.getVelocity()*0.35f;
				ParticleAnimated("Smoke", this.getPosition() + Vec2f_lengthdir(this.isFacingLeft() ? 35 : -35, this.getAngleDegrees()), velocity.RotateBy(this.getAngleDegrees()) + getRandomVelocity(0.0f, XORRandom(35) * 0.01f, 360), 45 + float(XORRandom(90)), 0.3f + XORRandom(50) * 0.01f, Maths::Round(7 - Maths::Clamp(this.get_f32("engine_RPM")/2000, 1, 6)) + XORRandom(3), -0.02 - XORRandom(30) * -0.0005f, false );
			}
		}

		this.set_f32("engine_throttle", 0.3f);
	}
}

void Vehicle_onDetach(CBlob@ this, VehicleInfo@ v, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (attachedPoint.name == "MAG")
	{
		attachedPoint.offset = v.mag_offset;
	}

	// jump out - needs to be synced so do here

	if (detached.hasTag("player") && attachedPoint.socket)
	{
		// reset charge if gunner leaves while charging
		if (attachedPoint.name == "GUNNER")
		{
			v.charge = 0;
		}

		detached.setPosition(detached.getPosition() + Vec2f(0.0f, -4.0f));
		detached.setVelocity(v.out_vel + this.getVelocity());
		detached.IgnoreCollisionWhileOverlapped(null);
		this.IgnoreCollisionWhileOverlapped(null);
	}
}

bool isFlipped(CBlob@ this)
{
	f32 angle = this.getAngleDegrees();
	return (angle > 80 && angle < 290);
}
/*
void UpdateWheels(CBlob@ this)
{
	{
		CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 1

		if (soundmanager !is null)
		{
			soundmanager.set_bool("manager_Type", false);
			soundmanager.Init();
			soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));

			this.set_u16("followid", soundmanager.getNetworkID());
		}
	}
	{
		CBlob@ soundmanager = server_CreateBlobNoInit("soundmanager"); // manager 2

		if (soundmanager !is null)
		{
			soundmanager.set_bool("manager_Type", true);
			soundmanager.Init();
			soundmanager.setPosition(this.getPosition() + Vec2f(this.isFacingLeft() ? 20 : -20, 0));
			
			this.set_u16("followid2", soundmanager.getNetworkID());
		}
	}
}