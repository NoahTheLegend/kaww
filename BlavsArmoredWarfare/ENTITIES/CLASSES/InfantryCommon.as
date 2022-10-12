#include "WarfareGlobal.as"
#include "AllHashCodes.as"
Random _infantry_r(67886);

namespace ArcherParams
{
	enum Aim
	{
		not_aiming = 0,
		readying,
		charging,
		fired,
		no_ammo,
		stabbing
	}
}

namespace ArrowType
{
	enum type
	{
		normal = 0,
		count
	};
}

u8 getArrowType(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return 0;
	}
	return archer.arrow_type;
}

class ArcherInfo
{
	s8 charge_time;
	u8 charge_state;

	bool isStabbing;
	bool isReloading;

	u8 arrow_type;

	ArcherInfo()
	{
		charge_time = 0;
		charge_state = 0;
	}
};

const string[] arrowTypeNames = { "mat_arrows" };

const string[] arrowNames = { "Ammo", };

const f32 SEEK_RANGE = 700.0f;
const f32 ENEMY_RANGE = 400.0f;

// Show emotes?
const bool USE_EMOTES = true;

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		attack_blob,
		goto_blob,
		find_healing,
		find_drill,
		dodge_spike,
		runaway
	};
};

class InfantryInfo
{
	string classname; // case sensitive
	int class_hash; // hash of the name
	// DAMAGE
	f32 damage_body; // damage dealt to body
	f32 damage_head; // damage dealt on headshot
	// SHAKE
	f32 recoil_x; // x shake (20)
	f32 recoil_y; // y shake (45)
	f32 recoil_length; // how long to recoil (?)
	// RECOIL
	f32 recoil_force; // amount to push player
	u8 recoil_cursor; // amount to raise mouse pos
	u8 sideways_recoil; // sideways recoil amount
	u8 sideways_recoil_damp; // higher number means less sideways recoil
	f32 ads_cushion_amount; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	f32 length_of_recoil_arc; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	u8 inaccuracy_cap; // max amount of inaccuracy
	u8 inaccuracy_pershot; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	bool semiauto;
	u8 burst_size; // bullets fired per click
	u8 burst_rate; // ticks per bullet fired in a burst
	s8 reload_time; // time to reload
	u32 mag_size; // max bullets in mag
	u8 delayafterfire; // time between shots 4
	u8 randdelay; // + randomness
	f32 bullet_velocity; // speed that bullets fly 1.6
	f32 bullet_lifetime; // in seconds, time for bullet to die
	s8 bullet_pen; // penRating for bullet
	// SOUND
	string reload_sfx;
	string shoot_sfx;

	InfantryInfo()
	{
		classname 				= "Shotgun"; // case sensitive
		class_hash 				= 234279893; // hash of the name
		// DAMAGE
		damage_body 			= 0.35f; // damage dealt to body
		damage_head 			= 0.42f; // damage dealt on headshot
		// SHAKE
		recoil_x 				= 20.0f; // x shake (20)
		recoil_y 				= 80.0f; // y shake (45)
		recoil_length 			= 180.0f; // how long to recoil (?)
		// RECOIL
		recoil_force 			= 0.2f; // amount to push player
		recoil_cursor 			= 13; // amount to raise mouse pos
		sideways_recoil 			= 2; // sideways recoil amount
		sideways_recoil_damp 	= 8; // higher number means less sideways recoil
		ads_cushion_amount 		= 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change
		// spray pattern in logic
		length_of_recoil_arc 	= 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
		// ACCURACY
		inaccuracy_cap 			= 80; // max amount of inaccuracy
		inaccuracy_pershot 		= 50; // aim inaccuracy  (+3 per shot)
		// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
		// GUN
		semiauto 				= false;
		burst_size 				= 5; // bullets fired per click
		burst_rate 				= 0; // ticks per bullet fired in a burst
		reload_time 			= 90; // time to reload
		mag_size 				= 4; // max bullets in mag
		delayafterfire 			= 20; // time between shots 4
		randdelay 				= 0; // + randomness
		bullet_velocity 		= 1.42f; // speed that bullets fly 1.6
		bullet_lifetime 		= 0.5f; // in seconds, time for bullet to die
		bullet_pen 				= -1; // penRating for bullet
		// SOUND
		reload_sfx 				= classname + "_reload.ogg";
		shoot_sfx 				= "ShotgunFire.ogg";
	}
};

namespace ShotgunParams
{
	const ::string CLASSNAME 			= "Shotgun"; // case sensitive
	// DAMAGE
	const ::f32 DAMAGE_BODY 			= 0.35f; // damage dealt to body
	const ::f32 DAMAGE_HEAD 			= 0.42f; // damage dealt on headshot
	// MOVEMENT
	const ::f32 WALK_STAT 				= 0.9f; // walk
	const ::f32 AIRWALK_STAT 			= 2.5f; // airwalk
	const ::f32 JUMP_STAT 				= 0.87f; // jump
	const ::f32 WALK_STAT_SPRINT 		= 1.05f; // walk (sprint)
	const ::f32 AIRWALK_STAT_SPRINT 	= 2.9f; // airwalk (sprint)
	const ::f32 JUMP_STAT_SPRINT 		= 0.87f; // jump (sprint)
	// SHAKE
	const ::f32 RECOIL_X 				= 20.0f; // x shake (20)
	const ::f32 RECOIL_Y 				= 80.0f; // y shake (45)
	const ::f32 RECOIL_LENGTH 			= 180.0f; // how long to recoil (?)
	// RECOIL
	const ::f32 RECOIL_FORCE 			= 0.2f; // amount to push player
	const ::u8 RECOIL_CURSOR 			= 13; // amount to raise mouse pos
	const ::u8 SIDEWAYS_RECOIL 			= 2; // sideways recoil amount
	const ::u8 SIDEWAYS_RECOIL_DAMP 	= 8; // higher number means less sideways recoil
	const ::f32 ADS_CUSHION_AMOUNT 		= 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	const ::f32 LENGTH_OF_RECOIL_ARC 	= 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	const ::u8 INACCURACY_CAP 			= 80; // max amount of inaccuracy
	const ::u8 INACCURACY_PER_SHOT 		= 50; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	const ::bool SEMIAUTO 				= false;
	const ::u8 BURST_SIZE 				= 5; // bullets fired per click
	const ::u8 BURST_RATE 				= 0; // ticks per bullet fired in a burst
	const ::s8 RELOAD_TIME 				= 90; // time to reload
	const ::u32 MAG_SIZE 				= 4; // max bullets in mag
	const ::u8 DELAYAFTERFIRE 			= 20; // time between shots
	const ::u8 RANDDELAY 				= 0; // + randomness
	const ::f32 BULLET_VELOCITY 		= 18.0f; // speed that bullets fly
	const ::f32 BULLET_LIFETIME 		= 0.5f; // in seconds, time for bullet to die
	const ::s8 BULLET_PEN 				= -1; // penRating for bullet
}

namespace RangerParams
{
	const ::string CLASSNAME 			= "Ranger"; // case sensitive
	// DAMAGE
	const ::f32 DAMAGE_BODY 			= 0.35f; // damage dealt to body
	const ::f32 DAMAGE_HEAD 			= 0.6f; // damage dealt on headshot
	// MOVEMENT
	const ::f32 WALK_STAT 				= 0.9f; // walk
	const ::f32 AIRWALK_STAT 			= 2.5f; // airwalk
	const ::f32 JUMP_STAT 				= 0.87f; // jump
	const ::f32 WALK_STAT_SPRINT 		= 1.05f; // walk (sprint)
	const ::f32 AIRWALK_STAT_SPRINT 	= 3.0f; // airwalk (sprint)
	const ::f32 JUMP_STAT_SPRINT 		= 0.87f; // jump (sprint)
	// SHAKE
	const ::f32 RECOIL_X 				= 0.0f; // x shake (20)
	const ::f32 RECOIL_Y 				= 65.0f; // y shake (45)
	const ::f32 RECOIL_LENGTH 			= 110.0f; // how long to recoil (?)
	// RECOIL
	const ::f32 RECOIL_FORCE 			= 0.09f; // amount to push player
	const ::u8 RECOIL_CURSOR 			= 6; // amount to raise mouse pos
	const ::u8 SIDEWAYS_RECOIL 			= 2; // sideways recoil amount
	const ::u8 SIDEWAYS_RECOIL_DAMP 	= 10; // higher number means less sideways recoil
	const ::f32 ADS_CUSHION_AMOUNT 		= 0.7f; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	const ::f32 LENGTH_OF_RECOIL_ARC 	= 1.65f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	const ::u8 INACCURACY_CAP 			= 35; // max amount of inaccuracy
	const ::u8 INACCURACY_PER_SHOT 		= 30; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	const ::bool SEMIAUTO 				= false;
	const ::u8 BURST_SIZE 				= 1; // bullets fired per click
	const ::u8 BURST_RATE 				= 0; // ticks per bullet fired in a burst
	const ::s8 RELOAD_TIME 				= 60; // time to reload
	const ::u32 MAG_SIZE 				= 30; // max bullets in mag
	const ::u8 DELAYAFTERFIRE 			= 4; // time between shots
	const ::u8 RANDDELAY 				= 1; // + randomness
	const ::f32 BULLET_VELOCITY 		= 28.5f; // speed that bullets fly
	const ::f32 BULLET_LIFETIME 		= 2.75f; // in seconds, time for bullet to die
	const ::s8 BULLET_PEN 				= 1; // penRating for bullet
}

namespace Mp5Params
{
	const ::string CLASSNAME 			= "Mp5"; // case sensitive
	// DAMAGE
	const ::f32 DAMAGE_BODY 			= 0.23f; // damage dealt to body
	const ::f32 DAMAGE_HEAD 			= 0.48f; // damage dealt on headshot
	// MOVEMENT
	const ::f32 WALK_STAT 				= 0.85f; // walk
	const ::f32 AIRWALK_STAT 			= 2.5f; // airwalk
	const ::f32 JUMP_STAT 				= 0.87f; // jump
	const ::f32 WALK_STAT_SPRINT 		= 1.0f; // walk (sprint)
	const ::f32 AIRWALK_STAT_SPRINT 	= 2.95f; // airwalk (sprint)
	const ::f32 JUMP_STAT_SPRINT 		= 1.0f; // jump (sprint)
	// SHAKE
	const ::f32 RECOIL_X 				= 22.0f; // x shake (20)
	const ::f32 RECOIL_Y 				= 48.0f; // y shake (45)
	const ::f32 RECOIL_LENGTH 			= 70.0f; // how long to recoil (?)
	// RECOIL
	const ::f32 RECOIL_FORCE 			= 0.03f; // amount to push player
	const ::u8 RECOIL_CURSOR 			= 10; // amount to raise mouse pos
	const ::u8 SIDEWAYS_RECOIL 			= 6; // sideways recoil amount
	const ::u8 SIDEWAYS_RECOIL_DAMP 	= 8; // higher number means less sideways recoil
	const ::f32 ADS_CUSHION_AMOUNT 		= 0.7f; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	const ::f32 LENGTH_OF_RECOIL_ARC 	= 1.8f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	const ::u8 INACCURACY_CAP 			= 36; // max amount of inaccuracy
	const ::u8 INACCURACY_PER_SHOT 		= 22; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	const ::bool SEMIAUTO 				= false;
	const ::u8 BURST_SIZE 				= 1; // bullets fired per click
	const ::u8 BURST_RATE 				= 0; // ticks per bullet fired in a burst
	const ::s8 RELOAD_TIME 				= 65; // time to reload
	const ::u32 MAG_SIZE 				= 30; // max bullets in mag
	const ::u8 DELAYAFTERFIRE 			= 3; // time between shots
	const ::u8 RANDDELAY 				= 1; // + randomness
	const ::f32 BULLET_VELOCITY 		= 25.0f; // speed that bullets fly
	const ::f32 BULLET_LIFETIME 		= 2.75f; // in seconds, time for bullet to die
	const ::s8 BULLET_PEN 				= 0; // penRating for bullet
}

namespace RevolverParams
{
	const ::string CLASSNAME 			= "Revolver"; // case sensitive
	// DAMAGE
	const ::f32 DAMAGE_BODY 			= 0.35f; // damage dealt to body
	const ::f32 DAMAGE_HEAD 			= 1.05f; // damage dealt on headshot
	// MOVEMENT
	const ::f32 WALK_STAT 				= 0.95f; // walk
	const ::f32 AIRWALK_STAT 			= 2.5f; // airwalk
	const ::f32 JUMP_STAT 				= 0.87f; // jump
	const ::f32 WALK_STAT_SPRINT 		= 1.1f; // walk (sprint)
	const ::f32 AIRWALK_STAT_SPRINT 	= 3.15f; // airwalk (sprint)
	const ::f32 JUMP_STAT_SPRINT 		= 1.0f; // jump (sprint)
	// SHAKE
	const ::f32 RECOIL_X 				= 4.0f; // x shake (20)
	const ::f32 RECOIL_Y 				= 80.0f; // y shake (45)
	const ::f32 RECOIL_LENGTH 			= 230.0f; // how long to recoil (?)
	// RECOIL
	const ::f32 RECOIL_FORCE 			= 0.13f; // amount to push player
	const ::u8 RECOIL_CURSOR 			= 13; // amount to raise mouse pos
	const ::u8 SIDEWAYS_RECOIL 			= 2; // sideways recoil amount
	const ::u8 SIDEWAYS_RECOIL_DAMP 	= 8; // higher number means less sideways recoil
	const ::f32 ADS_CUSHION_AMOUNT 		= 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	const ::f32 LENGTH_OF_RECOIL_ARC 	= 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	const ::u8 INACCURACY_CAP 			= 55; // max amount of inaccuracy
	const ::u8 INACCURACY_PER_SHOT 		= 54; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	const ::bool SEMIAUTO 				= false;
	const ::u8 BURST_SIZE 				= 1; // bullets fired per click
	const ::u8 BURST_RATE 				= 0; // ticks per bullet fired in a burst
	const ::s8 RELOAD_TIME 				= 64; // time to reload
	const ::u32 MAG_SIZE 				= 6; // max bullets in mag
	const ::u8 DELAYAFTERFIRE 			= 5; // time between shots
	const ::u8 RANDDELAY 				= 1; // + randomness
	const ::f32 BULLET_VELOCITY 		= 28.0f; // speed that bullets fly
	const ::f32 BULLET_LIFETIME 		= 1.5f; // in seconds, time for bullet to die
	const ::s8 BULLET_PEN 				= 0; // penRating for bullet
}

namespace SniperParams
{
	const ::string CLASSNAME 			= "Sniper"; // case sensitive
	// DAMAGE
	const ::f32 DAMAGE_BODY 			= 1.5f; // damage dealt to body
	const ::f32 DAMAGE_HEAD 			= 2.45f; // damage dealt on headshot
	// MOVEMENT
	const ::f32 WALK_STAT 				= 0.85f; // walk
	const ::f32 AIRWALK_STAT 			= 2.5f; // airwalk
	const ::f32 JUMP_STAT 				= 1.0f; // jump
	const ::f32 WALK_STAT_SPRINT 		= 0.95f; // walk (sprint)
	const ::f32 AIRWALK_STAT_SPRINT 	= 2.9f; // airwalk (sprint)
	const ::f32 JUMP_STAT_SPRINT 		= 1.0f; // jump (sprint)
	// SHAKE
	const ::f32 RECOIL_X 				= 14.0f; // x shake (20)
	const ::f32 RECOIL_Y 				= 80.0f; // y shake (45)
	const ::f32 RECOIL_LENGTH 			= 600.0f; // how long to recoil (?)
	// RECOIL
	const ::f32 RECOIL_FORCE 			= 0.03f; // amount to push player
	const ::u8 RECOIL_CURSOR 			= 13; // amount to raise mouse pos
	const ::u8 SIDEWAYS_RECOIL 			= 2; // sideways recoil amount
	const ::u8 SIDEWAYS_RECOIL_DAMP 	= 8; // higher number means less sideways recoil
	const ::f32 ADS_CUSHION_AMOUNT 		= 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	const ::f32 LENGTH_OF_RECOIL_ARC 	= 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	const ::u8 INACCURACY_CAP 			= 80; // max amount of inaccuracy
	const ::u8 INACCURACY_PER_SHOT 		= 50; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	const ::bool SEMIAUTO 				= false;
	const ::u8 BURST_SIZE 				= 1; // bullets fired per click
	const ::u8 BURST_RATE 				= 0; // ticks per bullet fired in a burst
	const ::s8 RELOAD_TIME 				= 58; // time to reload
	const ::u32 MAG_SIZE 				= 5; // max bullets in mag
	const ::u8 DELAYAFTERFIRE 			= 38; // time between shots
	const ::u8 RANDDELAY 				= 4; // + randomness
	const ::f32 BULLET_VELOCITY 		= 37.0f; // speed that bullets fly
	const ::f32 BULLET_LIFETIME 		= 3.0f; // in seconds, time for bullet to die
	const ::s8 BULLET_PEN 				= 2; // penRating for bullet
}

void getBasicStats( int blobNameHash, string &out classname, string &out reload_sfx, string &out shoot_sfx, float &out damage_body, float &out damage_head )
{
	switch (blobNameHash)
	{
		case _ranger:
		{
			classname = RangerParams::CLASSNAME;
			damage_body = RangerParams::DAMAGE_BODY;
			damage_head = RangerParams::DAMAGE_HEAD;
		}
		break;

		case _mp5:
		{
			classname = Mp5Params::CLASSNAME;
			damage_body = Mp5Params::DAMAGE_BODY;
			damage_head = Mp5Params::DAMAGE_HEAD;
		}
		break;

		case _revolver:
		{
			classname = RevolverParams::CLASSNAME;
			damage_body = RevolverParams::DAMAGE_BODY;
			damage_head = RevolverParams::DAMAGE_HEAD;
		}
		break;

		case _sniper:
		{
			classname = SniperParams::CLASSNAME;
			damage_body = SniperParams::DAMAGE_BODY;
			damage_head = SniperParams::DAMAGE_HEAD;
		}
		break;

		default: // _shotgun, but it'll be default stats
		{
			classname = ShotgunParams::CLASSNAME;
			damage_body = ShotgunParams::DAMAGE_BODY;
			damage_head = ShotgunParams::DAMAGE_HEAD;
		}
		break;
	}
	
	reload_sfx = classname + "_reload.ogg";
	shoot_sfx = classname + "_shoot.ogg";
}

void getRecoilStats( int blobNameHash, float &out recoil_x, float &out recoil_y, float &out recoil_length, float &out recoil_force, u8 &out recoil_cursor, u8 &out sideways_recoil, u8 &out sideways_recoil_damp, float &out ads_cushion_amount, float &out length_of_recoil_arc )
{
	switch (blobNameHash)
	{
		case _ranger:
		{
			recoil_x = RangerParams::RECOIL_X;
			recoil_y = RangerParams::RECOIL_Y;
			recoil_length = RangerParams::RECOIL_LENGTH;
			recoil_force = RangerParams::RECOIL_FORCE;
			recoil_cursor = RangerParams::RECOIL_CURSOR;
			sideways_recoil = RangerParams::SIDEWAYS_RECOIL;
			sideways_recoil_damp = RangerParams::SIDEWAYS_RECOIL_DAMP;
			ads_cushion_amount = RangerParams::RECOIL_CURSOR;
			length_of_recoil_arc = RangerParams::LENGTH_OF_RECOIL_ARC;
		}
		break;

		case _mp5:
		{
			recoil_x = Mp5Params::RECOIL_X;
			recoil_y = Mp5Params::RECOIL_Y;
			recoil_length = Mp5Params::RECOIL_LENGTH;
			recoil_force = Mp5Params::RECOIL_FORCE;
			recoil_cursor = Mp5Params::RECOIL_CURSOR;
			sideways_recoil = Mp5Params::SIDEWAYS_RECOIL;
			sideways_recoil_damp = Mp5Params::SIDEWAYS_RECOIL_DAMP;
			ads_cushion_amount = Mp5Params::RECOIL_CURSOR;
			length_of_recoil_arc = Mp5Params::LENGTH_OF_RECOIL_ARC;
		}
		break;

		case _revolver:
		{
			recoil_x = RevolverParams::RECOIL_X;
			recoil_y = RevolverParams::RECOIL_Y;
			recoil_length = RevolverParams::RECOIL_LENGTH;
			recoil_force = RevolverParams::RECOIL_FORCE;
			recoil_cursor = RevolverParams::RECOIL_CURSOR;
			sideways_recoil = RevolverParams::SIDEWAYS_RECOIL;
			sideways_recoil_damp = RevolverParams::SIDEWAYS_RECOIL_DAMP;
			ads_cushion_amount = RevolverParams::RECOIL_CURSOR;
			length_of_recoil_arc = RevolverParams::LENGTH_OF_RECOIL_ARC;
		}
		break;

		case _sniper:
		{
			recoil_x = SniperParams::RECOIL_X;
			recoil_y = SniperParams::RECOIL_Y;
			recoil_length = SniperParams::RECOIL_LENGTH;
			recoil_force = SniperParams::RECOIL_FORCE;
			recoil_cursor = SniperParams::RECOIL_CURSOR;
			sideways_recoil = SniperParams::SIDEWAYS_RECOIL;
			sideways_recoil_damp = SniperParams::SIDEWAYS_RECOIL_DAMP;
			ads_cushion_amount = SniperParams::RECOIL_CURSOR;
			length_of_recoil_arc = SniperParams::LENGTH_OF_RECOIL_ARC;
		}
		break;

		default: // _shotgun, but it'll be default stats
		{
			recoil_x = ShotgunParams::RECOIL_X;
			recoil_y = ShotgunParams::RECOIL_Y;
			recoil_length = ShotgunParams::RECOIL_LENGTH;
			recoil_force = ShotgunParams::RECOIL_FORCE;
			recoil_cursor = ShotgunParams::RECOIL_CURSOR;
			sideways_recoil = ShotgunParams::SIDEWAYS_RECOIL;
			sideways_recoil_damp = ShotgunParams::SIDEWAYS_RECOIL_DAMP;
			ads_cushion_amount = ShotgunParams::RECOIL_CURSOR;
			length_of_recoil_arc = ShotgunParams::LENGTH_OF_RECOIL_ARC;
		}
		break;
	}
}

void getWeaponStats( int blobNameHash,
	u8 &out inaccuracy_cap, u8 &out inaccuracy_pershot, 
	bool &out semiauto, u8 &out burst_size,	u8 &out burst_rate,
	s8 &out reload_time, u32 &out mag_size, u8 &out delayafterfire, u8 &out randdelay,
	float &out bullet_velocity, float &out bullet_lifetime, s8 &out bullet_pen )
{
	switch (blobNameHash)
	{
		case _ranger:
		{
			inaccuracy_cap = RangerParams::INACCURACY_CAP;
			inaccuracy_pershot = RangerParams::INACCURACY_PER_SHOT;

			semiauto = RangerParams::SEMIAUTO;
			burst_size = RangerParams::BURST_SIZE;
			burst_rate = RangerParams::BURST_RATE;

			reload_time = RangerParams::RELOAD_TIME;
			mag_size = RangerParams::MAG_SIZE;
			delayafterfire = RangerParams::DELAYAFTERFIRE;
			randdelay = RangerParams::RANDDELAY;

			bullet_velocity = RangerParams::BULLET_VELOCITY;
			bullet_lifetime = RangerParams::BULLET_LIFETIME;
			bullet_pen = RangerParams::BULLET_PEN;
		}
		break;

		case _mp5:
		{
			inaccuracy_cap = Mp5Params::INACCURACY_CAP;
			inaccuracy_pershot = Mp5Params::INACCURACY_PER_SHOT;

			semiauto = Mp5Params::SEMIAUTO;
			burst_size = Mp5Params::BURST_SIZE;
			burst_rate = Mp5Params::BURST_RATE;

			reload_time = Mp5Params::RELOAD_TIME;
			mag_size = Mp5Params::MAG_SIZE;
			delayafterfire = Mp5Params::DELAYAFTERFIRE;
			randdelay = Mp5Params::RANDDELAY;

			bullet_velocity = Mp5Params::BULLET_VELOCITY;
			bullet_lifetime = Mp5Params::BULLET_LIFETIME;
			bullet_pen = Mp5Params::BULLET_PEN;
		}
		break;

		case _revolver:
		{
			inaccuracy_cap = RevolverParams::INACCURACY_CAP;
			inaccuracy_pershot = RevolverParams::INACCURACY_PER_SHOT;

			semiauto = RevolverParams::SEMIAUTO;
			burst_size = RevolverParams::BURST_SIZE;
			burst_rate = RevolverParams::BURST_RATE;

			reload_time = RevolverParams::RELOAD_TIME;
			mag_size = RevolverParams::MAG_SIZE;
			delayafterfire = RevolverParams::DELAYAFTERFIRE;
			randdelay = RevolverParams::RANDDELAY;

			bullet_velocity = RevolverParams::BULLET_VELOCITY;
			bullet_lifetime = RevolverParams::BULLET_LIFETIME;
			bullet_pen = RevolverParams::BULLET_PEN;
		}
		break;

		case _sniper:
		{
			inaccuracy_cap = SniperParams::INACCURACY_CAP;
			inaccuracy_pershot = SniperParams::INACCURACY_PER_SHOT;

			semiauto = SniperParams::SEMIAUTO;
			burst_size = SniperParams::BURST_SIZE;
			burst_rate = SniperParams::BURST_RATE;

			reload_time = SniperParams::RELOAD_TIME;
			mag_size = SniperParams::MAG_SIZE;
			delayafterfire = SniperParams::DELAYAFTERFIRE;
			randdelay = SniperParams::RANDDELAY;

			bullet_velocity = SniperParams::BULLET_VELOCITY;
			bullet_lifetime = SniperParams::BULLET_LIFETIME;
			bullet_pen = SniperParams::BULLET_PEN;
		}
		break;

		default: // _shotgun, but it'll be default stats
		{
			inaccuracy_cap = ShotgunParams::INACCURACY_CAP;
			inaccuracy_pershot = ShotgunParams::INACCURACY_PER_SHOT;

			semiauto = ShotgunParams::SEMIAUTO;
			burst_size = ShotgunParams::BURST_SIZE;
			burst_rate = ShotgunParams::BURST_RATE;

			reload_time = ShotgunParams::RELOAD_TIME;
			mag_size = ShotgunParams::MAG_SIZE;
			delayafterfire = ShotgunParams::DELAYAFTERFIRE;
			randdelay = ShotgunParams::RANDDELAY;

			bullet_velocity = ShotgunParams::BULLET_VELOCITY;
			bullet_lifetime = ShotgunParams::BULLET_LIFETIME;
			bullet_pen = ShotgunParams::BULLET_PEN;
		}
		break;
	}
}

void getMovementStats( int blobNameHash, bool isSprinting,
	 float &out walkStat, float &out airwalkStat, float &out jumpStat )
{
	switch(blobNameHash)
	{
		case _ranger:
		{
			if (isSprinting)
			{
				walkStat 		= RangerParams::WALK_STAT_SPRINT;
				airwalkStat 	= RangerParams::AIRWALK_STAT_SPRINT;
				jumpStat 		= RangerParams::JUMP_STAT_SPRINT;
			}
			else
			{
				walkStat 		= RangerParams::WALK_STAT;
				airwalkStat 	= RangerParams::AIRWALK_STAT;
				jumpStat 		= RangerParams::JUMP_STAT;
			}
		}
		break;

		case _mp5:
		{
			if (isSprinting)
			{
				walkStat 		= Mp5Params::WALK_STAT_SPRINT;
				airwalkStat 	= Mp5Params::AIRWALK_STAT_SPRINT;
				jumpStat 		= Mp5Params::JUMP_STAT_SPRINT;
			}
			else
			{
				walkStat 		= Mp5Params::WALK_STAT;
				airwalkStat 	= Mp5Params::AIRWALK_STAT;
				jumpStat 		= Mp5Params::JUMP_STAT;
			}
		}
		break;

		case _revolver:
		{
			if (isSprinting)
			{
				walkStat 		= RevolverParams::WALK_STAT_SPRINT;
				airwalkStat 	= RevolverParams::AIRWALK_STAT_SPRINT;
				jumpStat 		= RevolverParams::JUMP_STAT_SPRINT;
			}
			else
			{
				walkStat 		= RevolverParams::WALK_STAT;
				airwalkStat 	= RevolverParams::AIRWALK_STAT;
				jumpStat 		= RevolverParams::JUMP_STAT;
			}
		}
		break;

		case _sniper:
		{
			if (isSprinting)
			{
				walkStat 		= SniperParams::WALK_STAT_SPRINT;
				airwalkStat 	= SniperParams::AIRWALK_STAT_SPRINT;
				jumpStat 		= SniperParams::JUMP_STAT_SPRINT;
			}
			else
			{
				walkStat 		= SniperParams::WALK_STAT;
				airwalkStat 	= SniperParams::AIRWALK_STAT;
				jumpStat 		= SniperParams::JUMP_STAT;
			}
		}
		break;

		default: // _shotgun, but it'll be default stats
		{
			if (isSprinting)
			{
				walkStat 		= ShotgunParams::WALK_STAT_SPRINT;
				airwalkStat 	= ShotgunParams::AIRWALK_STAT_SPRINT;
				jumpStat 		= ShotgunParams::JUMP_STAT_SPRINT;
			}
			else
			{
				walkStat 		= ShotgunParams::WALK_STAT;
				airwalkStat 	= ShotgunParams::AIRWALK_STAT;
				jumpStat 		= ShotgunParams::JUMP_STAT;
			}
		}
		break;
	}
	
}

void InAirLogic( CBlob@ this, u8 inaccuracyCap )
{
	if (!this.isOnGround() && !this.isOnLadder())
	{
		u8 inaccuracyFinal = Maths::Min(this.get_u8("inaccuracy") + 6, inaccuracyCap);
		this.set_u8("inaccuracy", inaccuracyFinal);
		this.setVelocity(Vec2f(this.getVelocity().x*0.92f, this.getVelocity().y));
	}
}

CBlob@ CreateBulletProj( CBlob@ this, Vec2f arrowPos, Vec2f arrowVel, 
	float damageBody, float damageHead, s8 penRating )
{
	CBlob@ proj = server_CreateBlobNoInit("bullet");
	if (proj !is null)
	{
		proj.SetDamageOwnerPlayer(this.getPlayer());
		proj.Init();

		proj.set_f32("bullet_damage_body", damageBody);
		proj.set_f32("bullet_damage_head", damageHead);
		proj.IgnoreCollisionWhileOverlapped(this);
		proj.server_setTeamNum(this.getTeamNum());
		proj.setPosition(arrowPos);
		proj.setVelocity(arrowVel);
		proj.set_s8(penRatingString, penRating); // buckshot isn't exactly known for its effectivness against tanks...
	}
	return proj;
}

/*
CBlob@ CreateRPGProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	CBlob@ proj = server_CreateBlobNoInit("ballista_bolt");
	if (proj !is null)
	{
		proj.SetDamageOwnerPlayer(this.getPlayer());
		proj.Init();

		proj.set_f32(projDamageString, damage_body);
		proj.set_f32(projExplosionRadiusString, 32.0f);
		proj.set_f32(projExplosionDamageString, 15.0f);
		proj.set_f32("linear_length", 12.0f);

		proj.set_f32("bullet_damage_body", damage_body);
		proj.set_f32("bullet_damage_head", damage_head);
		proj.IgnoreCollisionWhileOverlapped(this);
		proj.server_setTeamNum(this.getTeamNum());
		proj.setPosition(arrowPos);
		proj.setVelocity(arrowVel);
		proj.set_s8(penRatingString, 2);
	}
	return proj;
}*/

float getBulletSpread( int blobNameHash )
{
	float bulletSpread = 0.0f;
	switch (blobNameHash)
	{
		case _ranger:
		bulletSpread = 1.0f; break;

		case _mp5:
		bulletSpread = 5.0f; break;

		case _revolver:
		bulletSpread = 1.0f; break;

		case _sniper:
		bulletSpread = 0.0f; break;

		default: // _shotgun, but it'll be default stats
		bulletSpread = 55.0f; break;
	}

	return bulletSpread;
}

void onRevolverReload(CBlob@ this)
{
	this.getSprite().PlaySound("Revolver_reload.ogg", 0.8);
	for (uint i = 0; i < 6; i++)
	{
		makeGibParticle(
		"EmptyShellSmall",      		            // file name
		this.getPosition() + Vec2f(this.isFacingLeft() ? -6.0f : 6.0f, 0.0f), // position
		Vec2f(this.isFacingLeft() ? 1.0f+(0.1f * XORRandom(10) - 0.5f) : -1.0f-(0.1f * XORRandom(10) - 0.5f), 0.0f), // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		0.2f,                               // scale?
		0,                                  // ?
		"ShellCasing",                      // sound
		this.get_u8("team_color"));         // team number
	}
}

void onRangerReload(CBlob@ this)
{
	this.getSprite().PlaySound("Ranger_reload.ogg", 0.8);

	makeGibParticle(
	"EmptyMag",               // file name
	this.getPosition() + Vec2f(this.isFacingLeft() ? -6.0f : 6.0f, 0.5f),      // position
	Vec2f(this.isFacingLeft() ? -2.0f : 2.0f, -1.0f),                          // velocity
	0,                                  // column
	0,                                  // row
	Vec2f(16, 16),                      // frame size
	1.0f,                               // scale?
	0,                                  // ?
	"EmptyMagSound",                    // sound
	this.get_u8("team_color"));         // team number
}

void onSniperReload(CBlob@ this)
{
	if (this.get_bool("isReloading") && (this.get_s8("charge_time") == 0)) //  || this.get_s8("charge_time") == 17)
	{
		this.getSprite().PlaySound("Sniper_reload.ogg", 0.8);
		
		makeGibParticle(
		"EmptyMag",               // file name
		this.getPosition() + Vec2f(this.isFacingLeft() ? -4.0f : 4.0f, 1.0f),      // position
		Vec2f(this.isFacingLeft() ? -0.5f : 0.5f, 0.25f),                          // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		1.0f,                               // scale?
		0,                                  // ?
		"EmptyMagSound",                    // sound
		this.get_u8("team_color"));         // team number
	}
}

void onMp5Reload(CBlob@ this)
{
	if (this.get_s8("charge_time") >= 60) this.getSprite().PlaySound("Mp5_reload.ogg", 0.8);
	if (this.get_bool("isReloading") && (this.get_s8("charge_time") == 46 || this.get_s8("charge_time") == 45))
	{
		makeGibParticle(
		"EmptyMag",               // file name
		this.getPosition() + Vec2f(this.isFacingLeft() ? -3.0f : 3.0f, 2.0f),      // position
		Vec2f(this.isFacingLeft() ? -1.5f : 1.5f, -0.75f),                          // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		1.0f,                               // scale?
		0,                                  // ?
		"EmptyMagSound",                    // sound
		this.get_u8("team_color"));         // team number
	}
}