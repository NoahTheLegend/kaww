const string classname = "Revolver"; // case sensitive

// DAMAGE
const float damage_body = 0.35f;
const float damage_head = 1.05f;
// SHAKE
const float recoilx = 4; // x shake (20)
const float recoily = 80; // y shake (45)
const float recoillength = 230; // how long to recoil (?)
// RECOIL
const float recoilforce = 0.13f; // amount to push player
const u8 recoilcursor = 13; // amount to raise mouse pos
const u8 sidewaysrecoil = 2; // sideways recoil amount
const u8 sidewaysrecoildamp = 8; // higher number means less sideways recoil
const float adscushionamount = 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change

// spray pattern in logic

const float lengthofrecoilarc = 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65

// ACCURACY
const u8 inaccuracycap = 55; // max amount of inaccuracy
const u8 inaccuracypershot = 53; // aim inaccuracy  (+3 per shot)
// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down

const bool semiauto = true;

const s8 reloadtime = 64; // time to reload
const string reloadsfx = classname + "_reload.ogg";
const string shootsfx = classname + "_shoot.ogg";

const u8 delayafterfire = 5; // time between shots
//const u8 randdelay = 0; // + randomness

const float bulletvelocity = 1.6f; // speed that bullets fly

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