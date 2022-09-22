#include "WarfareGlobal.as"
#include "AllHashCodes.as"
#include "SeatsCommon.as"
#include "VehicleCommon.as"
#include "VehicleAttachmentCommon.as"
#include "GenericButtonCommon.as"
#include "Hitters.as";

const string engineRPMString = "engine_RPM";
const string engineRPMTargetString = "engine_RPMtarget";

void onInit(CBlob@ this)
{
	this.Tag("vehicle");

	s8 armorRating = 0;
	bool hardShelled = false;

	s8 weaponRating = 0;

	string blobName = this.getName();
	int blobHash = blobName.getHash();
	switch(blobHash)
	{
		case _maus: // maus
		case _mausturret: // MAUS Shell cannon
		{
			armorRating = 5;
			hardShelled = true;
		}
		break;

		case _t10: // T10
		case _t10turret: // T10 Shell cannon
		armorRating = 4; break;
			
		case _m60: // normal tank
		case _m60turret: // M60 Shell cannon
		armorRating = 3; break;

		case _transporttruck: // vanilla truck?
		case _armory: // shop truck
		case _btr82a: // big APC
		case _btrturret: // big APC cannon
		case _heavygun: // MG
		armorRating = 2; break;

		case _uh1: // heli
		case _pszh4: // smol APC
		case _pszh4turret: // smol APC cannon
		case _techtruck: // MG truck
		case _gun: // light MG
		armorRating = 1; break;

		case _bf109: // plane
		case _civcar: // car
		armorRating = 0; break;

		case _motorcycle: // bike
		case _jourcop: // journalist
		armorRating = -1; break;

		default:
		{
			print ("blobName: "+ blobName + " hash: "+blobHash);
			print ("-");
		}
	}

	switch(blobHash) // weapon rating
	{
		case _uh1: // heli
		case _m60turret: // M60 Shell cannon
		weaponRating = 1; break;

		case _pszh4turret: // smol APC cannon
		case _btrturret: // big APC cannon
		weaponRating = 0; break;
	}

	this.set_s8(armorRatingString, armorRating);
	this.set_bool(hardShelledString, hardShelled);

	this.set_s8(weaponRatingString, weaponRating);

	this.set_f32(engineRPMString, 0.0f);
}

void onTick(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	// wheels
	if (this.getShape().vellen > 0.07f && !this.isAttached())
	{
		UpdateWheels(this);
	}

	// reload
	if (this.hasAttached() && getGameTime() % 2 == 0)
	{
		f32 time_til_fire = Maths::Max((v.fire_time - getGameTime()), 1);
		if (time_til_fire < 2)
		{
			Vehicle_LoadAmmoIfEmpty(this, v);
		}
	}

	//smooth collisions with other vehs
	//f32 vel = this.getVelocity().x;
	//f32 oldvel = this.getOldVelocity().x;
	//if ((vel > 0.0f
	//&& oldvel < vel / 10)
	//|| (vel < 0.0f
	//&& oldvel > vel / 10))
	//{
	//	this.setVelocity(Vec2f(this.getVelocity().x / 10, this.getVelocity().y));
	//}

	// update movement sounds
	f32 velx = Maths::Abs(this.getVelocity().x);

	// ground sound
	if (velx < 0.5f)
	{
		CSprite@ sprite = this.getSprite();
		f32 vol = sprite.getEmitSoundVolume();
		sprite.SetEmitSoundVolume(vol * 0.95f);
		if (vol < 0.05f)
		{
			sprite.SetEmitSoundPaused(true);
			sprite.SetEmitSoundVolume(1.0f);
		}
	}
	else
	{
		if (this.isOnGround() && !v.ground_sound.isEmpty())
		{
			CSprite@ sprite = this.getSprite();
			if ((this.getVelocity().x > 0.01f || this.getVelocity().x < -0.01f) && sprite.getEmitSoundPaused())
			{
				this.getSprite().SetEmitSound(v.ground_sound);
				sprite.SetEmitSoundPaused(false);
			}

			f32 volMod = v.ground_volume;
			f32 pitchMod = v.ground_pitch;

			if (volMod > 0.0f)
			{
				sprite.SetEmitSoundVolume(Maths::Min(velx * 0.667f * volMod, 1.0f));
			}

			if (pitchMod > 0.0f)
			{
				sprite.SetEmitSoundSpeed(Maths::Max(Maths::Min(Maths::Sqrt(0.5f * velx * pitchMod), 1.5f), 0.75f));
			}
		}
		if (!this.isOnGround() && !v.water_sound.isEmpty())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite.getEmitSoundPaused())
			{
				this.getSprite().SetEmitSound(v.water_sound);
				sprite.SetEmitSoundPaused(false);
			}

			f32 volMod = v.water_volume;
			f32 pitchMod = v.water_pitch;

			if (volMod > 0.0f)
			{
				sprite.SetEmitSoundVolume(Maths::Min(velx * 0.565f * volMod, 1.0f));
			}

			if (pitchMod > 0.0f)
			{
				sprite.SetEmitSoundSpeed(Maths::Max(Maths::Min(Maths::Sqrt(0.5f * velx * pitchMod), 1.5f), 0.75f));
			}
		}
	}

	/*
	if (this.set_f32("engine_RPMtarget") > this.get_f32("engine_RPM"))
	{
		this.add_f32("engine_RPM", 10.0f);
	}
	*/
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	/// LOAD AMMO
	if (isServer && cmd == this.getCommandID("load_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			array < CBlob@ > ammos;
			array < string > eligible_ammo_names;

			for (int i = 0; i < v.ammo_types.length(); ++i)
			{
				const string ammo = v.ammo_types[i].ammo_name;
				eligible_ammo_names.push_back(ammo);
			}

			CBlob@ carryObject = caller.getCarriedBlob();
			// if player has item in hand, we only put that item into vehicle's inventory
			if (carryObject !is null && eligible_ammo_names.find(carryObject.getName()) != -1)
			{
				ammos.push_back(carryObject);
			}
			else
			{
				CInventory@ inv = caller.getInventory();

				for (int i = 0; i < v.ammo_types.length(); ++i)
				{
					const string ammo = v.ammo_types[i].ammo_name;

					for (int i = 0; i < inv.getItemsCount(); i++)
					{
						CBlob@ invItem = inv.getItem(i);
						if (invItem.getName() == ammo)
						{
							ammos.push_back(invItem);
						}
					}
				}
			}

			for (int i = 0; i < ammos.length; i++)
			{
				if (!this.server_PutInInventory(ammos[i]))
				{
					caller.server_PutInInventory(ammos[i]);
				}
			}

			RecountAmmo(this, v);
		}
	}
	// SWAP AMMO
	else if (cmd == this.getCommandID("swap_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		swapAmmo(this, v, v.current_ammo_index + 1);

		if(isServer)
			RecountAmmo(this, v);
	}
	else if (!isServer && cmd == this.getCommandID("sync_ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		v.current_ammo_index = params.read_u8();
	}
	else if (!isServer && cmd == this.getCommandID("sync_last_fired"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		u8 last;
		if (!params.saferead_u8(last)) return;

		v.last_fired_index = last;
	}
	/// PUT IN MAG
	else if (isServer && cmd == this.getCommandID("putin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ blob = getBlobByNetworkID(params.read_u16());
		if (caller !is null && blob !is null)
		{
			// put what was in mag into inv
			CBlob@ magBlob = getMagBlob(this);
			if (magBlob !is null)
			{
				magBlob.server_DetachFromAll();
			}
			blob.server_DetachFromAll();
			this.server_AttachTo(blob, "MAG");
		}
	}
	/// FIRE
	else if (cmd == this.getCommandID("fire"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Fire(this, v, caller, charge);
		if (isServer)
			RecountAmmo(this, v);
	}
	/// FLIP OVER
	else if (cmd == this.getCommandID("flip_over"))
	{
		if (isFlipped(this))
		{
			this.getShape().SetStatic(false);
			this.getShape().doTickScripts = true;
			f32 angle = this.getAngleDegrees();
			this.AddTorque(angle < 180 ? -1000 : 1000);
			this.AddForce(Vec2f(0, -1000));
		}
	}
	/// GET IN MAG
	else if (isServer && cmd == this.getCommandID("getin_mag"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
			this.server_AttachTo(caller, "MAG");
	}
	/// GET OUT
	else if (isServer && cmd == this.getCommandID("vehicle getout"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());

		if (caller !is null)
		{
			this.server_DetachFrom(caller);
		}
	}
	/// RELOAD as in server_LoadAmmo   - client-side
	else if (!isServer && cmd == this.getCommandID("reload"))
	{
		u8 loadedAmmo = params.read_u8();

		if (loadedAmmo > 0 && this.getAttachments() !is null)
		{
			SetOccupied(this.getAttachments().getAttachmentPointByName("MAG"), 1);
		}

		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		v.getCurrentAmmo().loaded_ammo = loadedAmmo;
	}
	else if (isClient() && cmd == this.getCommandID("recount ammo"))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		u8 current_recounted = params.read_u8();
		v.ammo_types[current_recounted].ammo_stocked = params.read_u16();
		v.ammo_types[current_recounted].loaded_ammo = params.read_u8();
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	s8 armorRating = this.get_s8(armorRatingString);
	s8 penRating = hitterBlob.get_s8(penRatingString);
	bool hardShelled = this.get_bool(hardShelledString);

	const bool is_explosive = customData == Hitters::explosion;

	float damageNegation = 0.0f;
	print ("blob: "+this.getName()+" - damage: "+damage);
	s8 finalRating = getFinalRating(armorRating, penRating, hardShelled);
	switch (finalRating)
	{
		// negative armor, trickles up
		case -2:
		{
			if (is_explosive && damage != 0) damage += 0.5f; // suffer bonus base damage (you just got your entire vehicle burned)
			damage *= 1.3f;
		}
		case -1:
		{
			damage *= 1.1f;
		}
		break;

		// positive armor, trickles down
		case 5:
		{
			damageNegation += 2.0f; // reduction to final damage, extremely tanky
		}
		case 4:
		{
			damage *= 0.7f;
		}
		case 3:
		{
			damage *= 0.8f;
		}
		case 2:
		{
			damage *= 0.8f;
		}
		case 1:
		{
			damageNegation += 0.5f; // reduction to final damage, for negating small bullets
			damage = Maths::Max(damage - damageNegation, 0.0f); // nullification happens here
		}
		break;
	}
	print ("finalDamage: "+damage);
	// if damage is not insignificant, prevent repairs for a time
	if (damage > 0.25f)
	{
		this.set_u32("no_heal", getGameTime()+10*30);

		if (isClient())
		{
			CSprite@ thisSprite = this.getSprite();
			if (thisSprite != null && customData == Hitters::ballista && armorRating > 1) // ballista hits are usually anti-tank. Don't ask me.
			{
				if (this.hasTag("turret")) thisSprite.PlaySound("BigDamage", 2.5f, 0.85f + XORRandom(40)*0.01f); 
				thisSprite.PlaySound("shell_Hit", 3.5f, 0.85f + XORRandom(40)*0.01f);
			}
		}
		
	}

	return damage;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob.getTeamNum() == this.getTeamNum() && canSeeButtons(this, forBlob))
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return false;
		}
		return v.inventoryAccess;
	}
	return false;
}

// VehicleCommon.as
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}
