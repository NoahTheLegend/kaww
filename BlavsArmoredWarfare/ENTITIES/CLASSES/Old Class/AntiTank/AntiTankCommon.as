const string classname = "AntiTank"; // case sensitive

// DAMAGE
const float damage_body = 2.0f;
const float damage_head = 3.0f;
// SHAKE
const float recoilx = 120; // x shake (20)
const float recoily = 150; // y shake (45)
const float recoillength = 430; // how long to recoil (?)
// RECOIL
const float recoilforce = 1.13f; // amount to push player
const u8 recoilcursor = 13; // amount to raise mouse pos
const u8 sidewaysrecoil = 2; // sideways recoil amount
const u8 sidewaysrecoildamp = 8; // higher number means less sideways recoil
const float adscushionamount = 1.0f; // lower means less recoil when aiming down sights. 1.0 is no change

// spray pattern in logic

const float lengthofrecoilarc = 1.5f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65

// ACCURACY
const u8 inaccuracycap = 120; // max amount of inaccuracy
const u8 inaccuracypershot = 110; // aim inaccuracy  (+3 per shot)
// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down

const bool semiauto = true;

const s8 reloadtime = 41; // time to reload 45
const string reloadsfx = classname + "_reload.ogg";
const string shootsfx = "RPGFire.ogg";

const u8 delayafterfire = 85; // time between shots 4
const u8 randdelay = 5; // + randomness

const float bulletvelocity = 3.25f; // speed that bullets fly 1.6













