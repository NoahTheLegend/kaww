#include "VehicleCommon.as"

const Vec2f arm_offset = Vec2f(0, -3);
const f32 MAX_OVERHEAT = 3.0f;
const f32 OVERHEAT_PER_SHOT = 0.05f;
const f32 COOLDOWN_RATE = 0.075f;
const u8 COOLDOWN_TICKRATE = 7;

void onInit(CBlob@ this)
{
	this.set_f32("max_overheat", MAX_OVERHEAT);
	this.set_f32("overheat_per_shot", OVERHEAT_PER_SHOT);
	this.set_f32("cooldown_rate", COOLDOWN_RATE);
	this.set_u8("cooldown_tickrate", COOLDOWN_TICKRATE);
	this.set_Vec2f("arm offset", arm_offset);

	this.set_u8("TTL", 60);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 23);
	this.set_u16("gui_mat_icon", 31);

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

	this.set_string("shoot sound", "MGfire.ogg");

	Vehicle_AddAmmo(this, v,
	                    2, // fire delay (ticks), +1 tick on server due to onCommand delay
	                    1, // fire bullets amount
	                    1, // fire cost
	                    "ammo", // bullet ammo config name
	                    "Ammo", // name for ammo selection
	                    "arrow", // bullet config name
	                    "MGfire", // fire sound  
	                    "EmptyFire", // empty fire sound
	                    Vehicle_Fire_Style::custom,
	                    Vec2f(-6.0f, 2.0f), // fire position offset
	                    0 // charge time
	                   );
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused)
{}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{return false;}