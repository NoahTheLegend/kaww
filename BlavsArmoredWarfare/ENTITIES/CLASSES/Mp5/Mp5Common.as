const string classname = "Mp5"; // case sensitive

// DAMAGE
const float damage_body = 0.25f;
const float damage_head = 0.5f;
// SHAKE
const float recoilx = 22; // x shake (20)
const float recoily = 38; // y shake (45)
const float recoillength = 70; // how long to recoil (?)
// RECOIL
const float recoilforce = 0.05f; // amount to push player (0.15)
const u8 recoilcursor = 10; // amount to raise mouse pos
const u8 sidewaysrecoil = 6; // sideways recoil amount
const u8 sidewaysrecoildamp = 8; // higher number means less sideways recoil
const float adscushionamount = 0.7f; // lower means less recoil when aiming down sights. 1.0 is no change

const float lengthofrecoilarc = 1.8f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65

// ACCURACY
const u8 inaccuracycap = 36; // max amount of inaccuracy
const u8 inaccuracypershot = 18; // aim inaccuracy  (+3 per shot)
// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down

const bool semiauto = false;

const s8 reloadtime = 65; // time to reload
const string reloadsfx = classname + "_reload.ogg";
const string shootsfx = classname + "_shoot.ogg";

const u8 delayafterfire = 3; // time between shots
const u8 randdelay = 1; // + randomness

const float bulletvelocity = 1.52f; // speed that bullets fly

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