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

class ArcherInfo
{
	s8 charge_time;
	u8 charge_state;

	bool isStabbing;
	bool isReloading;

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
	s8 reloadtime; // time to reload
	u8 delayafterfire; // time between shots 4
	u8 randdelay; // + randomness
	f32 bulletvelocity; // speed that bullets fly 1.6
	// SOUND
	string reloadsfx;
	string shootsfx;

	InfantryInfo()
	{
		classname 				= "Shotgun"; // case sensitive
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
		reloadtime 				= 90; // time to reload
		delayafterfire 			= 20; // time between shots 4
		randdelay 				= 0; // + randomness
		bulletvelocity 			= 1.42f; // speed that bullets fly 1.6
		// SOUND
		reloadsfx 				= classname + "_reload.ogg";
		shootsfx 				= "ShotgunFire.ogg";
	}
};

namespace ShotgunParams
{
	const ::string classname 			= "Shotgun"; // case sensitive
	// DAMAGE
	const ::f32 damage_body 			= 0.35f; // damage dealt to body
	const ::f32 damage_head 			= 0.42f; // damage dealt on headshot
	// SHAKE
	const ::f32 recoil_x 				= 20.0f; // x shake (20)
	const ::f32 recoil_y 				= 80.0f; // y shake (45)
	const ::f32 recoil_length 			= 180.0f; // how long to recoil (?)
	// RECOIL
	const ::f32 recoil_force 			= 0.2f; // amount to push player
	const ::u8 recoil_cursor 			= 13; // amount to raise mouse pos
	const ::u8 sideways_recoil 			= 2; // sideways recoil amount
	const ::u8 sideways_recoil_damp 	= 8; // higher number means less sideways recoil
	const ::f32 ads_cushion_amount 		= 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change
	// spray pattern in logic
	const ::f32 length_of_recoil_arc 	= 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65
	// ACCURACY
	const ::u8 inaccuracy_cap 			= 80; // max amount of inaccuracy
	const ::u8 inaccuracy_pershot 		= 50; // aim inaccuracy  (+3 per shot)
	// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down
	// GUN
	const ::bool semiauto 				= false;
	const ::u8 burst_size 				= 5; // bullets fired per click
	const ::s8 reloadtime 				= 90; // time to reload
	const ::u8 delayafterfire 			= 20; // time between shots 4
	const ::u8 randdelay 				= 0; // + randomness
	const ::f32 bulletvelocity 			= 1.42f; // speed that bullets fly 1.6
	// SOUND
	const ::string shootsfx 			= "ShotgunFire.ogg";
}

void getRecoilStats( int blobNameHash, bool &out isHitUnderside )

void InAirLogic(CBlob@ this)
{
	if (!this.isOnGround() && !this.isOnLadder())
	{
		this.set_u8("inaccuracy", this.get_u8("inaccuracy") + 6);
		if (this.get_u8("inaccuracy") > inaccuracycap) { this.set_u8("inaccuracy", inaccuracycap); }
		this.setVelocity(Vec2f(this.getVelocity().x*0.92f, this.getVelocity().y));
	}
}