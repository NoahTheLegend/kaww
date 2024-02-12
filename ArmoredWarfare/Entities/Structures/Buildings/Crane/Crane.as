#include "StandardControlsCommon.as"
#include "CustomBlocks.as";
#include "GenericButtonCommon.as";
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"

const f32 arm_length = 48.0f;
const f32 rotary_speed = 5.0f;

void onInit(CBlob@ this)
{
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PASSENGER");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
	}

	this.set_u16("arm1_id", 0);
	this.set_u16("arm2_id", 0);

	if (isServer())
	{
		CBlob@ arm1 = server_CreateBlob("cranearm", this.getTeamNum(), this.getPosition());
		if (arm1 !is null)
		{
			this.set_u16("arm1_id", arm1.getNetworkID());
		}
		CBlob@ arm2 = server_CreateBlob("cranearm_articulated", this.getTeamNum(), this.getPosition());
		if (arm2 !is null)
		{
			this.set_u16("arm2_id", arm2.getNetworkID());
		}
	}

	this.set_f32("arm1_angle", 0);
	this.set_f32("arm2_angle", 0);

	this.set_f32("arm1_target_angle", (this.isFacingLeft()?-1:1) * -25);
	this.set_f32("arm2_target_angle", (this.isFacingLeft()?-1:1) * 150);

	this.addCommandID("sync");
	this.addCommandID("grab");
	this.addCommandID("rotate");
	this.addCommandID("add_mount");

	CSprite@ sprite = this.getSprite();

	if (!this.hasTag("vehicle"))
	{
		sprite.SetEmitSound("crane_rotary_loop.ogg");
		sprite.SetEmitSoundSpeed(1.0f);
		sprite.SetRelativeZ(75.0f);
	}

	this.set_u8("playsound", 0);
	this.set_f32("volume", 0);

	this.Tag("builder always hit");
	this.Tag("structure");

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(3, 1));
	this.set_string("shop description", "Construct Augments");
	this.set_u8("shop icon", 25);
	{
		ShopItem@ s = addShopItem(this, "Claw Augment", "$claw$", "claw", "Grabs items, has a tension limit.\n\nDisabled on-hit.\n[SPACEBAR]", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Buzz Saw Augment", "$buzzsaw$", "buzzsaw", "Chops trees and cuts weak materials.\n\n[SPACEBAR]", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Welder Augment", "$welder$", "welder", "Repairs friendly vehicles and structures.\n\nUnlimited uses.\n[SPACEBAR]", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
}

const u8 playsound_fadeout_time = 15;
const f32 max_volume = 0.5f;
const f32 volume_kick = 0.1f;

void onTick(CBlob@ this)
{
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		u8 play_sound_remain = this.get_u8("playsound");

		if (sprite.animation !is null)
		{
			sprite.animation.time = play_sound_remain > 0 ? 6 : 0;
		}

		if (play_sound_remain > 0)
		{
			if (this.get_f32("volume") < max_volume)
				this.add_f32("volume", volume_kick);
		}
		else if (this.get_f32("volume") > 0)
		{
			this.add_f32("volume", -volume_kick);
		}
		
		if (!this.hasTag("vehicle"))
		{
			sprite.SetEmitSoundPaused(play_sound_remain == 0);
			sprite.SetEmitSoundVolume(Maths::Min(this.get_f32("volume"), max_volume * play_sound_remain / playsound_fadeout_time));
		}

		if (play_sound_remain > 0) this.add_u8("playsound", -1);
	}

	if (!isServer()) return;
	CMap@ map = getMap();
	if (map is null) return;

	CBlob@ arm1 = getBlobByNetworkID(this.get_u16("arm1_id"));
	CBlob@ arm2 = getBlobByNetworkID(this.get_u16("arm2_id"));

	if (arm1 is null || arm2 is null) return;
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PASSENGER");

	if (ap is null) return;
	CBlob@ driver = ap.getOccupied(); // NO NULL CHECK HERE!

	Vec2f pos = this.getPosition()-Vec2f(1,0);
	
	const bool a1 = ap.isKeyPressed(key_action1);
	const bool a2 = ap.isKeyPressed(key_action2);
	const bool a3 = ap.isKeyPressed(key_action3);

	f32 new_angle1 = this.get_f32("arm1_angle");
	f32 new_target_angle1 = this.get_f32("arm1_target_angle");
	f32 old_angle1 = new_angle1;
	f32 old_target_angle1 = new_target_angle1;

	f32 new_angle2 = this.get_f32("arm2_angle");
	f32 new_target_angle2 = this.get_f32("arm2_target_angle");
	f32 old_angle2 = new_angle2;
	f32 old_target_angle2 = new_target_angle2;

	Vec2f aimpos = ap.getAimPos()-this.getPosition();
	if (driver !is null) aimpos = driver.getAimPos()-this.getPosition();

	f32 aimangle = -aimpos.Angle()+90;

	// rotate arm 1
	f32 diff = aimangle - new_target_angle1;
	if (a1 && Maths::Abs(diff) > 2)
	{
	    if (diff > 180.0f) 		 diff -= 360.0f;
	    else if (diff < -180.0f) diff += 360.0f;
	    new_target_angle1 += (diff > 0.0f) ? rotary_speed / 2 : -rotary_speed / 2;
	}
	// clip
	if (new_angle1 > 360.0f)
	{new_angle1 -= 360.0f;new_target_angle1 -= 360.0f;}
	else if (new_angle1 < -360.0f)
	{new_angle1 += 360.0f;new_target_angle1 += 360.0f;}
	// return if stuck TODO: make a better collision
	Vec2f checkpos1 = pos + Vec2f(0,-arm_length).RotateBy(new_target_angle1);
	TileType t1 = map.getTile(checkpos1).type;
	if (map.isTileSolid(t1) || isTileCustomSolid(t1) || map.rayCastSolidNoBlobs(pos, checkpos1))
	{
		f32 backwards = new_target_angle1 - new_angle1;
		new_target_angle1 -= backwards*2;
	}
	else
	{
		Vec2f checkpos2 = this.get_Vec2f("attach_pos");
		TileType t2 = map.getTile(checkpos2).type;
		if (map.isTileSolid(t2) || isTileCustomSolid(t2) || map.rayCastSolidNoBlobs(checkpos1, checkpos2))
		{
			f32 backwards = new_target_angle1 - new_angle1;
			new_target_angle1 -= backwards*2;
		}
	}

	// recalculate angle arm 1
	new_angle1 = Maths::Lerp(new_angle1, new_target_angle1, 0.25f);

	Vec2f arm1_pos = pos + Vec2f(0,-arm_length/2).RotateBy(new_angle1);
	Vec2f pos_end1 = pos + Vec2f(0,-arm_length*1.5f).RotateBy(new_angle1, Vec2f(0,0));
	// set position
	arm1.setPosition(arm1_pos);
	arm1.setAngleDegrees(new_angle1 + 90);

	Vec2f pos_joint = pos + Vec2f(0,-arm_length).RotateBy(new_angle1, Vec2f(0,0));
	aimpos = ap.getAimPos()-pos_joint;
	if (driver !is null) aimpos = driver.getAimPos()-pos_joint;

	aimangle = -aimpos.Angle()+90;

	// rotate arm 2
	diff = aimangle - new_target_angle2 - new_angle1;
	if (a2 && Maths::Abs(diff) > 2)
	{
	    if (diff > 180.0f)	 	 diff -= 360.0f;
	    else if (diff < -180.0f) diff += 360.0f;
	    new_target_angle2 += (diff > 0.0f) ? rotary_speed : -rotary_speed;
	}
	// clip
	if (new_angle2 > 360.0f) 
	{new_angle2 -= 360.0f;new_target_angle2 -= 360.0f;}
	else if (new_angle2 < -360.0f)
	{new_angle2 += 360.0f;new_target_angle2 += 360.0f;}
	// return if stuck
	Vec2f checkpos2 = this.get_Vec2f("attach_pos");
	TileType t2 = map.getTile(checkpos2).type;
	if (map.isTileSolid(t2) || isTileCustomSolid(t2) || map.rayCastSolidNoBlobs(checkpos1, checkpos2))
	{
		f32 backwards = new_target_angle2 - new_angle2;
		new_target_angle2 -= backwards*2;
	}

	// recalculate angle arm 2
	new_angle2 = Maths::Lerp(new_angle2, new_target_angle2, 0.2f);

	Vec2f arm2_pos = (pos_end1 - pos).RotateBy(new_angle2, Vec2f(0, -arm_length).RotateBy(new_angle1));
	arm2.setPosition(pos + arm2_pos);
	arm2.setAngleDegrees(new_angle2 + new_angle1 + 90);

	this.set_Vec2f("attach_pos", pos + Vec2f(0,-arm_length*2).RotateBy(new_angle2, Vec2f(0,-arm_length)).RotateBy(new_angle1));

	// send command for visuals and sound
	if (Maths::Abs(new_target_angle1 - new_angle1) > 2
		|| Maths::Abs(new_target_angle2 - new_angle2) > 2)
	{
		CBitStream params;
		params.write_f32(Maths::Abs(new_target_angle2 - new_angle2));
		this.SendCommand(this.getCommandID("rotate"), params);
	}

	// save angles
	this.set_f32("arm1_angle", new_angle1);
	this.set_f32("arm1_target_angle", new_target_angle1);
	this.set_f32("arm2_angle", new_angle2);
	this.set_f32("arm2_target_angle", new_target_angle2);

	bool has_augment = this.get_u16("augment_id") != 0;
	if (has_augment)
	{
		CBlob@ augment = getBlobByNetworkID(this.get_u16("augment_id"));
		if (augment is null) this.set_u16("augment_id", 0);
		else
		{
			if (driver !is null && driver.getPlayer() !is null)
			{
				if (a3) augment.Tag("active");
				else augment.Untag("active");

				augment.SetDamageOwnerPlayer(driver.getPlayer());
				augment.server_setTeamNum(driver.getTeamNum());
			}

			augment.Tag("attached");
			if (augment.isAttached()) augment.server_DetachFromAll();

			if (augment.hasTag("rotary_joint"))
			{
				augment.setVelocity(Vec2f(0,0));

				Vec2f augment_pos = augment.getPosition();
				Vec2f augment_oldpos = augment.getOldPosition();

				Vec2f augment_dir = augment_pos - this.get_Vec2f("attach_pos");
				f32 augment_dir_angle = -augment_dir.Angle();

				f32 augment_angle = Maths::Abs(augment.getVelocity().Angle());
				f32 augment_new_angle = augment_angle + augment_dir_angle+180;

				augment.setPosition(this.get_Vec2f("attach_pos")+Vec2f(-3,0).RotateBy(arm2.getAngleDegrees()));
				augment.setAngleDegrees(augment_new_angle);
			}
			else
			{
				augment.setPosition(this.get_Vec2f("attach_pos"));
				augment.setVelocity(Vec2f(0,0));
				augment.set_f32("angle", arm2.getAngleDegrees());
			}
			
			augment.SetFacingLeft(true);

			if (driver !is null || getGameTime() % 30 == 0)
			{
				CBitStream params;
    			params.write_bool(a3);
				params.write_bool(true);
    			augment.SendCommand(augment.getCommandID("sync"), params);
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || this.getDistanceTo(caller) > 32.0f) return;

	CBlob@ carried = caller.getCarriedBlob();
	if (carried is null) return;
	bool valid = carried.hasTag("crane_mount");
	
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	CButton@ button = caller.CreateGenericButton(21, Vec2f(0, -10), this, this.getCommandID("add_mount"), valid ? "Add augment" : "Requires an augment", params);
	if (button !is null && !valid)
	{
		button.SetEnabled(false);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (isClient())
	{
		if (cmd == this.getCommandID("rotate"))
		{
			f32 diff = params.read_f32();

			CSprite@ sprite = this.getSprite();
			if (!this.hasTag("vehicle"))
			{
				sprite.SetEmitSoundSpeed(1.0f + diff * 0.01f);
			}

			if (this.get_u8("playsound") == 0 && !this.hasTag("vehicle"))
			{
				sprite.RewindEmitSound();
			}
			this.set_u8("playsound", playsound_fadeout_time);
		}
	}
	if (cmd == this.getCommandID("add_mount"))
	{
		u16 callerid;
		if (!params.saferead_u16(callerid)) return;

		CBlob@ caller = getBlobByNetworkID(callerid);
		if (caller is null) return;

		CBlob@ carried = caller.getCarriedBlob();
		if (carried is null) return;
	
		if (!carried.hasTag("crane_mount")) return;
		
		if (isServer() && this.get_u16("augment_id") != 0)
		{
			CBlob@ augment = getBlobByNetworkID(this.get_u16("augment_id"));
			if (augment !is null)
			{
				augment.Untag("active");
				augment.Untag("attached");

				CBitStream params;
    			params.write_bool(false);
				params.write_bool(false);
    			augment.SendCommand(augment.getCommandID("sync"), params);
			}
		}

		this.set_u16("augment_id", carried.getNetworkID());

		if (isServer())
		{
			carried.Tag("attached");

			CBitStream params;
    		params.write_bool(false);
			params.write_bool(true);
    		carried.SendCommand(carried.getCommandID("sync"), params);
		}
	}
}

void onDie(CBlob@ this)
{
	if (!isServer()) return;
	CBlob@ arm1 = getBlobByNetworkID(this.get_u16("arm1_id"));
	CBlob@ arm2 = getBlobByNetworkID(this.get_u16("arm2_id"));
	CBlob@ augment = getBlobByNetworkID(this.get_u16("augment_id"));

	if (arm1 !is null) arm1.server_Die();
	if (arm2 !is null) arm2.server_Die();
	if (augment !is null) augment.server_Die();
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	attached.Tag("machinegunner");
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.Untag("machinegunner");
}

//f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
//{
//	if (isServer())
//	{
//		bool has_augment = this.get_u16("augment_id") != 0;
//	
//		if (has_augment && hitterBlob !is null && hitterBlob.getTeamNum() != this.getTeamNum())
//		{
//			CBlob@ augment = getBlobByNetworkID(this.get_u16("augment_id"));
//			if (augment !is null && augment.getName() == "claw")
//			{
//				augment.Tag("crane_was_hit");
//			}
//		}
//	}
//	return damage;
//}