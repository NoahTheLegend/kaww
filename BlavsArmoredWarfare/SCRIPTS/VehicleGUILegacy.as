#include "VehicleCommon.as";

f32 getHUDX()
{
	return getScreenWidth() / 3;
}

f32 getHUDY()
{
	return getScreenHeight();
}

const f32 HUD_X = getHUDX();
const f32 HUD_Y = getHUDY();

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_hasattached;
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

	AttachmentPoint@ gunner = blob.getAttachments().getAttachmentPointByName("GUNNER");
	if (gunner !is null	&& gunner.getOccupied() is localBlob)
	{
		drawAmmoCount(blob, v);

		if (blob.getName() == "m60" || blob.getName() == "mortar")
		{
			drawChargeBar(blob, v);
			drawCooldownBar(blob, v);
		}

		// no one feels the angle count is necessary, so im taking it out to reduce GUI clutter
		//if (blob.getName() == "ballista")
		//drawAngleCount(blob, v);

		Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

		Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
		Vec2f dim = Vec2f(20, 8);
		const f32 y = blob.getHeight() * 2.4f;

		Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
		Vec2f lr = Vec2f(pos2d.x - dim.x + 1.0f * 2.0f * dim.x, pos2d.y + y + dim.y);

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

		string reqsText = "Gunner";

		u8 numDigits = reqsText.length();

		upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
		lowerright += Vec2f((float(numDigits) * 4.0f), 0);

		GUI::SetFont("menu");
		GUI::DrawText(reqsText, upperleft + Vec2f(2, 1 + 16), SColor(255, 105, 223, 86));

		Vec2f barpos(getHUDX() + 268, getHUDY() - 86);

		GUI::DrawIcon("FireButton", gunner.isKeyPressed(key_action1) ? 1 : 0, Vec2f(30, 43), barpos, 1.0f);
		GUI::DrawIcon("BlankButtonRight", gunner.isKeyPressed(key_action2) ? 1 : 0, Vec2f(30, 43), barpos + Vec2f(64,0), 1.0f);
		
		GUI::DrawIcon("HullView.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}

	AttachmentPoint@ driver = blob.getAttachments().getAttachmentPointByName("DRIVER");
	if (driver !is null	&& driver.getOccupied() is localBlob)
	{
		Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

		Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
		Vec2f dim = Vec2f(20, 8);
		const f32 y = blob.getHeight() * 2.4f;

		Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
		Vec2f lr = Vec2f(pos2d.x - dim.x + 1.0f * 2.0f * dim.x, pos2d.y + y + dim.y);

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

		string reqsText = "Driver";

		u8 numDigits = reqsText.length();

		upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
		lowerright += Vec2f((float(numDigits) * 4.0f), 0);

		GUI::SetFont("menu");
		GUI::DrawText(reqsText, upperleft + Vec2f(2, 1 + 16), SColor(255, 105, 223, 86));

		Vec2f barpos(getHUDX() + 268, getHUDY() - 86);

		GUI::DrawIcon("BrakeButton", driver.isKeyPressed(key_action1) ? 1 : 0, Vec2f(30, 43), barpos, 1.0f);
		GUI::DrawIcon("LockButton", driver.isKeyPressed(key_action2) ? 1 : 0, Vec2f(30, 43), barpos + Vec2f(64,0), 1.0f);
		
		GUI::DrawIcon("HullView.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}

	AttachmentPoint@ flyer = blob.getAttachments().getAttachmentPointByName("FLYER");
	if (flyer !is null	&& flyer.getOccupied() is localBlob)
	{
		Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

		Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
		Vec2f dim = Vec2f(20, 8);
		const f32 y = blob.getHeight() * 2.4f;

		Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
		Vec2f lr = Vec2f(pos2d.x - dim.x + 1.0f * 2.0f * dim.x, pos2d.y + y + dim.y);

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

		string reqsText = "Pilot";

		u8 numDigits = reqsText.length();

		upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
		lowerright += Vec2f((float(numDigits) * 4.0f), 0);

		GUI::SetFont("menu");
		GUI::DrawText(reqsText, upperleft + Vec2f(2, 1 + 16), SColor(255, 105, 223, 86));

		Vec2f barpos(getHUDX() + 268, getHUDY() - 86);

		if (blob.getName() == "fighterplane")
		{
			GUI::DrawIcon("FireButton", flyer.isKeyPressed(key_action1) ? 1 : 0, Vec2f(30, 43), barpos, 1.0f);
			GUI::DrawIcon("BlankButtonRight", flyer.isKeyPressed(key_action2) ? 1 : 0, Vec2f(30, 43), barpos + Vec2f(64,0), 1.0f);
		}

		if (blob.getName() == "bomberplane")
		{
			GUI::DrawIcon("FireButton", flyer.isKeyPressed(key_action1) ? 1 : 0, Vec2f(30, 43), barpos, 1.0f);
			GUI::DrawIcon("BombButton", flyer.isKeyPressed(key_action2) ? 1 : 0, Vec2f(30, 43), barpos + Vec2f(64,0), 1.0f);
		}
		
		GUI::DrawIcon("HullView.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}

	AttachmentPoint@ pass = blob.getAttachments().getAttachmentPointByName("PASSENGER");
	AttachmentPoint@ pass2 = blob.getAttachments().getAttachmentPointByName("PASSENGER2");
	AttachmentPoint@ pass3 = blob.getAttachments().getAttachmentPointByName("PASSENGER3");
	AttachmentPoint@ pass4 = blob.getAttachments().getAttachmentPointByName("PASSENGER4");
	if ((pass !is null	&& pass.getOccupied() is localBlob) ||
		(pass2 !is null	&& pass2.getOccupied() is localBlob) ||
		(pass3 !is null	&& pass3.getOccupied() is localBlob) ||
		(pass4 !is null	&& pass4.getOccupied() is localBlob))
	{
		Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

		Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
		Vec2f dim = Vec2f(20, 8);
		const f32 y = blob.getHeight() * 2.4f;

		Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
		Vec2f lr = Vec2f(pos2d.x - dim.x + 1.0f * 2.0f * dim.x, pos2d.y + y + dim.y);

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

		string reqsText = "Passenger";

		u8 numDigits = reqsText.length();

		upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
		lowerright += Vec2f((float(numDigits) * 4.0f), 0);

		GUI::SetFont("menu");
		GUI::DrawText(reqsText, upperleft + Vec2f(2, 1 + 16), SColor(255, 105, 223, 86));

		//GUI::DrawIcon("BlankButtonLeft", driver.isKeyPressed(key_action1) ? 1 : 0, Vec2f(30, 43), barpos, 1.0f);
		//GUI::DrawIcon("BlankButtonRight", driver.isKeyPressed(key_action2) ? 1 : 0, Vec2f(30, 43), barpos + Vec2f(64,0), 1.0f);
		
		GUI::DrawIcon("HullView.png", 0, Vec2f(960, 540), Vec2f(0, 0), (getScreenWidth()*0.5f)/960, (getScreenHeight()*0.5f)/540, SColor(255, 255, 255, 255));
	}
}

void drawAmmoCount(CBlob@ blob, VehicleInfo@ v)
{
	// draw ammo count
	Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

	Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
	Vec2f dim = Vec2f(20, 8);
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

	//GUI::DrawRectangle(upperleft - Vec2f(0,20), lowerright , SColor(255,0,0,255));

	u16 ammo = v.ammo_stocked;

	string reqsText = "" + ammo;

	u8 numDigits = reqsText.length();

	upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
	lowerright += Vec2f((float(numDigits) * 4.0f), 0);

	GUI::DrawRectangle(upperleft, lowerright);
	GUI::SetFont("menu");
	GUI::DrawText(reqsText, upperleft + Vec2f(2, 1), color_white);
}

void drawChargeBar(CBlob@ blob, VehicleInfo@ v)
{
	Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
	Vec2f dim = Vec2f(20, 8);
	const f32 y = blob.getHeight() * 2.4f;
	f32 last_charge_percent = v.last_charge / float(v.max_charge_time);
	f32 charge_percent = v.charge / float(v.max_charge_time);

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + charge_percent * 2.0f * dim.x, pos2d.y + y + dim.y);

	if (blob.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);
	}

	AddIconToken("$empty_charge_bar$", "../Mods/VehicleGUI/Entities/Vehicles/Common/ChargeBar.png", Vec2f(24, 8), 0);
	GUI::DrawIconByName("$empty_charge_bar$", ul);

	if (blob.isFacingLeft())
	{
		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	GUI::DrawRectangle(ul + Vec2f(4, 4), lr + Vec2f(4, 4), SColor(0xff0C280D));
	GUI::DrawRectangle(ul + Vec2f(6, 6), lr + Vec2f(2, 4), SColor(0xff316511));
	GUI::DrawRectangle(ul + Vec2f(6, 6), lr + Vec2f(2, 2), SColor(0xff9BC92A));
}

void drawCooldownBar(CBlob@ blob, VehicleInfo@ v)
{
	if (v.cooldown_time > 0)
	{
		Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
		Vec2f dim = Vec2f(20, 8);
		const f32 y = blob.getHeight() * 2.4f;

		f32 modified_last_charge_percent = Maths::Min(1.0f, float(v.last_charge) / float(v.max_charge_time));
		f32 modified_cooldown_time_percent = modified_last_charge_percent * (v.cooldown_time / float(5.0f));

		Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
		Vec2f lr = Vec2f(pos2d.x - dim.x + (modified_cooldown_time_percent) * 2.0f * dim.x, pos2d.y + y + dim.y);

		if (blob.isFacingLeft())
		{
			ul -= Vec2f(8, 0);
			lr -= Vec2f(8, 0);

			f32 max_dist = ul.x - lr.x;
			ul.x += max_dist + dim.x * 2.0f;
			lr.x += max_dist + dim.x * 2.0f;
		}

		GUI::DrawRectangle(ul + Vec2f(4, 4), lr + Vec2f(4, 4), SColor(0xff3B1406));
		GUI::DrawRectangle(ul + Vec2f(6, 6), lr + Vec2f(2, 4), SColor(0xff941B1B));
		GUI::DrawRectangle(ul + Vec2f(6, 6), lr + Vec2f(2, 2), SColor(0xffB73333));
	}
}

void drawSeatName(CBlob@ blob, VehicleInfo@ v)
{
	Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
	Vec2f dim = Vec2f(20, 8);
	const f32 y = blob.getHeight() * 2.9f;

	f32 modified_last_charge_percent = Maths::Min(1.0f, float(v.last_charge) / float(v.max_charge_time));
	f32 modified_cooldown_time_percent = modified_last_charge_percent * (v.cooldown_time / float(5.0f));

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + (modified_cooldown_time_percent) * 2.0f * dim.x, pos2d.y + y + dim.y);

	if (blob.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);

		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	GUI::DrawText("Driver", blob.getPosition() + Vec2f(0.0f, 16.0f), SColor(255, 135, 243, 106));
}

/*
void onRender(CSprite@ this, VehicleInfo@ v)
{
	CBlob@ thisblob = this.getBlob();

	AttachmentPoint@[] aps;
	if (thisblob.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			CBlob@ blob = ap.getOccupied();

			if (blob !is null && ap.socket)
			{
				if (ap.name == "DRIVER")
				{
					GUI::DrawText("Driver", blob.getPosition() + Vec2f(0.0f, 16.0f), SColor(255, 110, 150, 140));
				}
				if (ap.name == "GUNNER")
				{
					GUI::DrawText("Gunner", blob.getPosition() + Vec2f(0.0f, 16.0f), SColor(255, 110, 150, 140));
				}
				if (ap.name == "BOW")
				{
					GUI::DrawText("Machine Gunner", blob.getPosition() + Vec2f(0.0f, 16.0f), SColor(255, 110, 150, 140));
				}
				if (ap.name == "PASSENGER")
				{
					GUI::DrawText("Passenger", blob.getPosition() + Vec2f(0.0f, 16.0f), SColor(255, 110, 150, 140));
				}
			}
		}
	}
}
*/


void drawAngleCount(CBlob@ blob, VehicleInfo@ v)
{
	Vec2f pos2d = blob.getScreenPos() - Vec2f(-48 , 52);
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
