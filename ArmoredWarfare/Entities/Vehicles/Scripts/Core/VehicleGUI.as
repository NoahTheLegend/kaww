#include "VehicleCommon.as";

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	blob.set_u8("mode", 1);
	blob.set_f32("lastvel", 0);
	blob.set_f32("vel", 0);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	f32 lastvel = blob.get_f32("lastvel");
	f32 vel = Maths::Lerp(lastvel, Maths::Abs(blob.getVelocity().x), 0.25f);
	blob.set_f32("lastvel", vel);

	AttachmentPoint@ driver = blob.getAttachments().getAttachmentPointByName("DRIVER");
	if (driver !is null)
	{
		CBlob@ driverblob = driver.getOccupied();
		if (driverblob !is null && driverblob.isMyPlayer()
			&& driverblob.getControls() !is null)
		{
			if (driverblob.getControls().isKeyJustPressed(KEY_LCONTROL))
			{
				blob.add_u8("mode", 1);
				if (blob.get_u8("mode") > 1) blob.set_u8("mode", 0);
			}
		}
	}
}

void onRender(CSprite@ this)
{
	if (this is null) return; //can happen with bad reload

	// draw only for local player
	CBlob@ localBlob = getLocalPlayerBlob();
	CBlob@ blob = this.getBlob();

	if (localBlob is null)
	{
		return;
	}

	VehicleInfo@ v;
	if (!blob.get("VehicleInfo", @v))
	{
		return;
	}

	AttachmentPoint@ driver = blob.getAttachments().getAttachmentPointByName("DRIVER");
	if (!blob.hasTag("pass_60sec"))
	{
		if (getGameTime() <= 60*30 && driver !is null && driver.getOccupied() !is null)
		{
			//Vec2f pos2d = blob.getScreenPos() + Vec2f(0, -40);
			Vec2f oldpos = blob.getOldPosition();
			Vec2f pos = blob.getPosition();
			Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , -40);
			const f32 y = blob.getHeight() * 7.8f;
			Vec2f dim = Vec2f(115, 15);
			GUI::SetFont("menu");
			GUI::DrawShadowedText("Engines starting in: "+(60-(getGameTime()/30))+" seconds." , Vec2f(pos2d.x - dim.x - 3, pos2d.y + y - 1 + 55), SColor(0xffffffff));
		}
	}

	if (!blob.hasTag("turret") && driver !is null && driver.getOccupied() !is null && driver.getOccupied() is localBlob)
	{
		u8 mode = blob.get_u8("mode");
		// speedometer
		if (mode != 0) // not disabled
		{
			f32 screenWidth = getScreenWidth();
			f32 screenHeight = getScreenHeight();

			f32 lastvel = blob.get_f32("lastvel");
			f32 vel = blob.get_f32("lastvel");

			Vec2f drawpos = Vec2f(15, screenHeight*0.5f);
			GUI::DrawIcon("Speedometer.png", drawpos, 0.33f);

			s8 thickness = 7;
			drawpos = drawpos + Vec2f(49, 49); // shift to center

			f32 maxrot = 165+XORRandom(4); // cool effect on max speed
			f32 rot = Maths::Min(maxrot, vel*12);
			Vec2f target = drawpos + Vec2f(0, -40).RotateBy(-70+rot);
			f32 rotmod = rot / maxrot;
			f32 brightness = Maths::Max(0, (0.5f-Maths::Abs(rotmod-0.5f))*2);

			u8 red = Maths::Clamp(125 -(100*rotmod) + (50*brightness), 0, 255);
			u8 green = Maths::Clamp(25+(100*rotmod) + (50*brightness), 0, 255);
			u8 blue = Maths::Clamp(15 + (25*rotmod) + (25*brightness), 0, 255);
			SColor color = SColor(255, red, green, blue);
			
			for (s8 i = 0; i < thickness; i++)
			{
				GUI::DrawLine2D(drawpos-Vec2f(thickness/2-i, Maths::Abs(thickness/2-i)).RotateBy(-70+rot), target, color);
			}

			GUI::SetFont("menu");
			GUI::DrawTextCentered("CTRL", drawpos+Vec2f(-30, 25), SColor(100, 0, 0, 0));
			GUI::DrawTextCentered(""+((Maths::Round(30/6*vel*100)/100)), drawpos+Vec2f(-18, -70), SColor(100, 255, 255, 255));
			GUI::DrawTextCentered("Bl/s", drawpos+Vec2f(10, -70), SColor(100, 255, 255, 255));
		}

		// draw cooldown bar for driver if gunner is present
		AttachmentPoint@ tur = blob.getAttachments().getAttachmentPointByName("TURRET");
		if (tur !is null && tur.getOccupied() !is null)
		{
			CBlob@ turret = tur.getOccupied();
			if (turret !is null)
			{
				AttachmentPoint@ gunner = turret.getAttachments().getAttachmentPointByName("GUNNER");
				if (gunner !is null && gunner.getOccupied() !is null)
				{
					VehicleInfo@ tv;
					if (turret.get("VehicleInfo", @tv))
					{
						if (!tv.getCurrentAmmo().infinite_ammo)
							drawAmmoCount(turret, tv);
						if (tv.getCurrentAmmo().max_charge_time > 0)
						{
							drawCooldownBar(turret, tv);
						}
					}
				}
			}
		}
	}
	
	AttachmentPoint@ gunner = blob.getAttachments().getAttachmentPointByName("GUNNER");
	if (gunner !is null	&& gunner.getOccupied() is localBlob)
	{
		if (!v.getCurrentAmmo().infinite_ammo)
			drawAmmoCount(blob, v);

		if (v.getCurrentAmmo().max_charge_time > 0)
		{
			drawCooldownBar(blob, v);
		}

		//drawShellTrajectory(blob, v, gunner.getOccupied());

		Vec2f oldpos = blob.getOldPosition();
		Vec2f pos = blob.getPosition();
		Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(0 , 0);
		if (blob.hasTag("machinegun"))
		{
			f32 overheat = blob.get_f32("overheat");
			f32 max_overheat = blob.get_f32("max_overheat");
			f32 percent = overheat / max_overheat;
			const f32 y = blob.getHeight() * 4.0f;
			Vec2f dim = Vec2f(40, 10); //95
			Vec2f heatdim = Vec2f(40*percent, 10); //95

			SColor color = SColor(255, 200+55*percent, 125-100*percent, 75-75*percent);

			// Border
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2,                        pos2d.y + y - 4),
							   Vec2f(pos2d.x + dim.x + 2,                        pos2d.y + y + dim.y + 4));

			GUI::DrawRectangle(Vec2f(pos2d.x - heatdim.x + 2,                    pos2d.y + y + 0),
							   Vec2f(pos2d.x + heatdim.x - 1,                    pos2d.y + y + heatdim.y - 1), color);

			if (blob.isAttached())
			{
				GUI::SetFont("menu");
				if (blob.getHealth() == blob.getInitialHealth()) GUI::DrawTextCentered("Hold RMB to hide", pos2d+Vec2f(0, y+24), SColor(100, 255,255,255));
			}
		}
		else if (!blob.hasTag("machinegun"))
		{
			f32 angleWithNormal = blob.get_f32("gunelevation");
			
			f32 offset = 90.0f;
			if (blob.isFacingLeft()) offset = 270.0f;

			f32 sign = -1.0f;
			if (blob.isFacingLeft()) sign = 1.0f;
			
			f32 angleWithHorizon = (angleWithNormal - offset) * sign;


			Vec2f cursor_pos;
			AttachmentPoint@ gunner = blob.getAttachments().getAttachmentPointByName("GUNNER");
			if (gunner !is null && gunner.getOccupied() !is null && gunner.getOccupied().getControls() !is null)
			{
				cursor_pos = gunner.getOccupied().getControls().getMouseScreenPos();
			}

			GUI::DrawTextCentered(Maths::Round(angleWithHorizon)+"°", cursor_pos+Vec2f(24, 24), SColor(0xffffffff));
		}
	}
}

void drawAmmoCount(CBlob@ blob, VehicleInfo@ v)
{
	// draw ammo count
	Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

	//Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
	Vec2f oldpos = blob.getOldPosition();
	Vec2f pos = blob.getPosition();
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(20, 60);
	Vec2f dim = Vec2f(120, 8);
	const f32 y = blob.getHeight() * 2.4f;
	f32 charge_percent = 1.0f;

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + charge_percent * 2.0f * dim.x, pos2d.y + y + dim.y);

	if (blob.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);

		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	f32 dist = lr.x - ul.x;
	Vec2f upperleft((ul.x + (dist / 2.0f)) - 5.0f + 4.0f, pos2d1.y + blob.getHeight() + 30);
	Vec2f lowerright((ul.x + (dist / 2.0f))  + 5.0f + 4.0f, upperleft.y + 20);

	u16 ammo = v.getCurrentAmmo().ammo_stocked;

	string reqsText = "      " + v.getCurrentAmmo().ammo_inventory_name + ": " + ammo;

	u8 numDigits = reqsText.length();

	upperleft -= Vec2f((float(numDigits) * 2.5f), 0);
	lowerright += Vec2f((float(numDigits) * 2.5f), 0);

	GUI::DrawSunkenPane(upperleft, lowerright + Vec2f(39,0));
	GUI::SetFont("menu");
	GUI::DrawText(reqsText, upperleft + Vec2f(2, 1), color_white);

	u8 icon = 63;
	if (blob.getName()=="heavygun") icon = 31;
	GUI::DrawIcon("Materials", icon, Vec2f(16, 16), upperleft + Vec2f(-4,-15));
}

void drawCooldownBar(CBlob@ blob, VehicleInfo@ v)
{
	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 26);
	Vec2f dim = Vec2f(58, 7);
	const f32 y = blob.getHeight() * 2.4f;

	AmmoInfo@ a = v.ammo_types[v.last_fired_index];

	f32 modified_last_charge_percent = Maths::Min(1.0f, float(v.last_charge) / float(a.max_charge_time));
	f32 modified_cooldown_time_percent = modified_last_charge_percent * (v.cooldown_time / float(a.fire_delay));

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + (modified_cooldown_time_percent) * 2.0f * dim.x, pos2d.y + y + dim.y);

	ul -= Vec2f(8, 0);
	lr -= Vec2f(8, 0);

	f32 max_dist = ul.x - lr.x;
	ul.x += max_dist + dim.x * 2.0f;
	lr.x += max_dist + dim.x * 2.0f;

	GUI::DrawRectangle(ul + Vec2f(4, 4), lr + Vec2f(4, 4), SColor(0xff3B1406));
	GUI::DrawRectangle(ul + Vec2f(6, 6), lr + Vec2f(2, 4), SColor(0xff941B1B));
	GUI::DrawRectangle(ul + Vec2f(6, 6), lr + Vec2f(2, 2), SColor(0xffB73333));
}

void drawShellTrajectory(CBlob@ blob, VehicleInfo@ v, CBlob@ gunner)
{
	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 26);

	//GUI::DrawSpline(pos2d, blob.getAimPos(), pos2d+blob.getAimPos()/2, pos2d+blob.getAimPos()/3, 7, SColor(0xffB73333));

	//Vec2f offset(0.5f, 0.5f);
	//GUI::DrawSplineArrow(pos2d + offset, gunner.getAimPos() + offset, color_black);
	//GUI::DrawSplineArrow(pos2d, gunner.getAimPos(), color_white);

	//print("123");
	//GUI::DrawText("hi", pos2d, pos2d + Vec2f(5,5), color_white, true, true, false);
	//GUI::DrawText("hi2", (gunner.getAimPos() - gunner.getScreenPos()), (gunner.getAimPos() - gunner.getScreenPos()) + Vec2f(5,5), color_white, true, true, false);
}

void drawAngleCount(CBlob@ blob, VehicleInfo@ v)
{
	//Vec2f pos2d = blob.getScreenPos() - Vec2f(-48 , 52);
	Vec2f oldpos = blob.getOldPosition();
	Vec2f pos = blob.getPosition();
	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(Vec2f_lerp(oldpos, pos, getInterpolationFactor())) - Vec2f(-48 , 52);
	Vec2f upperleft(pos2d.x - 18, pos2d.y + blob.getHeight() + 30);
	Vec2f lowerright(pos2d.x + 18, upperleft.y + 20);

	GUI::DrawRectangle(upperleft, lowerright);

	string reqsText = " " + getAngle(blob, v.charge, v);
	GUI::DrawText(reqsText, upperleft, lowerright, color_white, true, true, false);
}

//stolen from ballista.as and slightly modified
u8 getAngle(CBlob@ this, const u8 charge, VehicleInfo@ v)
{
	const f32 high_angle = 20.0f;
	const f32 low_angle = 60.0f;

	f32 angle = 180.0f; //we'll know if this goes wrong :)
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");

	bool not_found = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		Vec2f aim_vec = gunner.getPosition() - gunner.getAimPos();

		if ((!facing_left && aim_vec.x < 0) ||
		        (facing_left && aim_vec.x > 0))
		{
			if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

			angle = (-(aim_vec).getAngle() + 270.0f);
			angle = Maths::Max(high_angle , Maths::Min(angle , low_angle));
			//printf("angle " + angle );
			not_found = false;
		}
	}

	if (not_found)
	{
		angle = Maths::Abs(Vehicle_getWeaponAngle(this, v));
		return (angle);
	}

	return Maths::Abs(Maths::Round(angle));
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}