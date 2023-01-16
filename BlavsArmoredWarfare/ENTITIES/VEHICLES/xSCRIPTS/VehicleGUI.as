#include "VehicleCommon.as";

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

	if (blob.getName() != "motorcycle")
	{
		AttachmentPoint@ driver = blob.getAttachments().getAttachmentPointByName("DRIVER");
		if (getGameTime() <= 60*30 && driver !is null && driver.getOccupied() !is null)
		{
			Vec2f pos2d = blob.getScreenPos() + Vec2f(0, -40);
			const f32 y = blob.getHeight() * 7.8f;
			Vec2f dim = Vec2f(115, 15);
			GUI::SetFont("menu");
			GUI::DrawShadowedText("Engines starting in: "+(60-(getGameTime()/30))+" seconds." , Vec2f(pos2d.x - dim.x - 3, pos2d.y + y - 1 + 55), SColor(0xffffffff));
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

		if (blob.getName() == "heavygun")
		{
			f32 overheat = blob.get_f32("overheat");
			f32 max_overheat = blob.get_f32("max_overheat");
			f32 percent = overheat / max_overheat;

			Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 0);
			const f32 y = blob.getHeight() * 4.0f;
			Vec2f dim = Vec2f(40, 10); //95
			Vec2f heatdim = Vec2f(40*percent, 10); //95

			SColor color = SColor(255, 200+55*percent, 125-100*percent, 75-75*percent);

			// Border
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2,                        pos2d.y + y - 4),
							   Vec2f(pos2d.x + dim.x + 2,                        pos2d.y + y + dim.y + 4));

			GUI::DrawRectangle(Vec2f(pos2d.x - heatdim.x + 2,                    pos2d.y + y + 0),
							   Vec2f(pos2d.x + heatdim.x - 1,                    pos2d.y + y + heatdim.y - 1), color);
		}

		// no one feels the angle count is necessary, so im taking it out to reduce GUI clutter
		//if (blob.getName() == "ballista")
		//drawAngleCount(blob, v);
	}
}

void drawAmmoCount(CBlob@ blob, VehicleInfo@ v)
{
	// draw ammo count
	Vec2f pos2d1 = blob.getScreenPos() - Vec2f(0, 10);

	Vec2f pos2d = blob.getScreenPos() - Vec2f(0, 60);
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

	GUI::DrawRectangle(upperleft, lowerright + Vec2f(39,0));
	GUI::SetFont("menu");
	GUI::DrawText(reqsText, upperleft + Vec2f(2, 1), color_white);

	GUI::DrawIcon("Materials", 31, Vec2f(16, 16), upperleft + Vec2f(-4,-15));
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