const string classname = "Ranger"; // case sensitive

// DAMAGE
const float damage_body = 0.35f;
const float damage_head = 0.6f;
// SHAKE
const float recoilx = 0; // x shake (20)
const float recoily = 65; // y shake (45)
const float recoillength = 110; // how long to shake
// RECOIL
const float recoilforce = 0.09f; // amount to push player (0.1)
const u8 recoilcursor = 6; // amount to raise mouse pos per shot
const u8 sidewaysrecoil = 2; // sideways recoil amount
const u8 sidewaysrecoildamp = 10; // higher number means less sideways recoil
const float adscushionamount = 0.7f; // lower means less recoil when aiming down sights. 1.0 is no change

const float lengthofrecoilarc = 1.65f; // 2.0 is regular, -- 1.5 long arc   -- ak is 1.65

// ACCURACY
const u8 inaccuracycap = 35; // max amount of inaccuracy
const u8 inaccuracypershot = 30; // aim inaccuracy  (+3 per shot)
// delayafterfire + randdelay + 1 = no change in accuracy when holding lmb down

const bool semiauto = false;

const s8 reloadtime = 60; // time to reload
const string reloadsfx = classname + "_reload.ogg";
const string shootsfx = classname + "_shoot.ogg";

const u8 delayafterfire = 4; // time between shots 4
const u8 randdelay = 1; // + randomness

const float bulletvelocity = 1.62f; // speed that bullets fly 1.6













