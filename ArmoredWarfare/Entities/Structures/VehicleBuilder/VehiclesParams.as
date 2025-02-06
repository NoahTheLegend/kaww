#include "Requirements.as"
#include "ShopCommon.as"
#include "ItemParams.as"
#include "GamemodeCheck.as"

// common
const string b = "blob";
const string s = "mat_scrap";
const string ds = "Scrap";

// =============
// INITIAL COSTS
// =============

// Transport
const u16 c_civcar = 5;
const u16 c_lada = 5;
const u16 c_moto = 3;
const u16 c_amoto = 7;
const u16 c_truck = 10;
const u16 c_humvee = 15;
const u16 c_truckbig = 30;
const u16 c_barge = 10;
const u16 c_armory = 30;

// APC
const u16 c_pszh = 15;
const u16 c_btr = 25;
const u16 c_bmp = 40;
const u16 c_bradley = 40;
const u16 c_radarapc = 60;

// Medium Tank
const u16 c_m60 = 45;
const u16 c_e50 = 50;
const u16 c_obj430 = 50;
const u16 c_leopard1 = 50;
const u16 c_bc25t = 45;

// Heavy Tank
const u16 c_t10 = 70;
const u16 c_kingtiger = 75;
const u16 c_m103 = 65;

// Super Heavy Tank
const u16 c_abrams = 135;
const u16 c_maus = 130;
const u16 c_is7 = 125;

// Artillery
const u16 c_arti = 65;
const u16 c_m40 = 70;
const u16 c_grad = 75;
const u16 c_mortar = 20;

// Fighter Planes
const u16 c_bf109 = 30;

// Bomber Planes
const u16 c_b24 = 75;
const u16 c_pe2 = 70;
const u16 c_he111 = 80;

// Helicopter
const u16 c_uh1 = 50;
const u16 c_ah1 = 65;
const u16 c_mi24 = 75;
const u16 c_nh90 = 70;

// Machinegun
const u16 c_m2 = 8;
const u16 c_mg42 = 8;
const u16 c_dshk = 8;

// Weapons 1
const u16 c_jav = 15;
const u16 c_apsniper = 20;
const u16 c_pak38 = 20;

// ==========
// BUILD TIME
// ==========

const u16 ct_civcar = 30;
const u16 ct_lada = 30;
const u16 ct_moto = 20;
const u16 ct_amoto = 40;
const u16 ct_truck = 60;
const u16 ct_humvee = 90;
const u16 ct_truckbig = 120;
const u16 ct_barge = 30;
const u16 ct_armory = 90;

const u16 ct_pszh = 60;
const u16 ct_btr = 90;
const u16 ct_bmp = 120;
const u16 ct_bradley = 120;
const u16 ct_radarapc = 180;

const u16 ct_m60 = 150;
const u16 ct_e50 = 180;
const u16 ct_obj430 = 180;
const u16 ct_leopard1 = 180;
const u16 ct_bc25t = 150;

const u16 ct_t10 = 240;
const u16 ct_kingtiger = 270;
const u16 ct_m103 = 210;

const u16 ct_abrams = 360;
const u16 ct_maus = 390;
const u16 ct_is7 = 360;

const u16 ct_arti = 180;
const u16 ct_m40 = 210;
const u16 ct_grad = 240;
const u16 ct_mortar = 60;

const u16 ct_bf109 = 90;
const u16 ct_b24 = 180;
const u16 ct_pe2 = 150;
const u16 ct_he111 = 210;

const u16 ct_uh1 = 120;
const u16 ct_ah1 = 150;
const u16 ct_mi24 = 180;
const u16 ct_nh90 = 150;

const u16 ct_m2 = 0;
const u16 ct_mg42 = 0;
const u16 ct_dshk = 0;

const u16 ct_jav = 60;
const u16 ct_apsniper = 60;
const u16 ct_pak38 = 0;

// ============
// CAPTION NAME
// ============

const string n_civcar = "Build a Civilian Car";
const string n_lada = "Build a Lada";
const string n_moto = "Build a Motorcycle";
const string n_amoto = "Build a Motorcycle with machinegun";
const string n_truck = "Build a Truck";
const string n_humvee = "Build a Humvee";
const string n_truckbig = "Build a Cargo Truck";
const string n_barge = "Build a Barge";
const string n_armory = "Build an Armory Truck";

const string n_pszh = "Build a D944 PSZH Light APC";
const string n_btr = "Build a BTR-82A Medium APC";
const string n_bmp = "Build a BMP-2 Heavy APC";
const string n_bradley = "Build a Braldey-M1A2 Heavy APC";
const string n_radarapc = "Build a Radio Locator APC";

const string n_m60 = "Build a M60 Medium Tank";
const string n_e50 = "Build a E-50 Medium Tank";
const string n_obj430 = "Build a Object 430 Medium Tank";
const string n_leopard1 = "Build a Leopard 1 Medium Tank";
const string n_bc25t = "Build a Bat.-Chat. 25t Light Tank";

const string n_t10 = "Build a T10 Heavy Tank";
const string n_kingtiger = "Build a Tiger II Heavy Tank";
const string n_m103 = "Build a M-103 Heavy Tank";

const string n_abrams = "Build a M1 Abrams Super Heavy Tank";
const string n_maus = "Build a Maus Super Heavy Tank";
const string n_is7 = "Build a IS-7 Super Heavy Tank";

const string n_arti = "Build an Artillery";
const string n_m40 = "Build a M40 Artillery";
const string n_grad = "Build a BM-21 \"Grad\" MLRS";
const string n_mortar = "Build an Infantry Mortar";

const string n_bf109 = "Build a Fighter plane";

const string n_b24 = "Build a B-24 Heavy Bomber plane";
const string n_pe2 = "Build a Pe-2 Heavy Bomber plane";
const string n_he111 = "Build a He-111 Heavy Bomber plane";

const string n_uh1 = "Build a UH-1 Versatile Helicopter";
const string n_ah1 = "Build a AH-1 Fighter Helicopter";
const string n_mi24 = "Build a MI-24 Destroyer Helicopter";
const string n_nh90 = "Build a NH-90 Versatile Helicopter";

const string n_m2 = "Construct a M2 Browning Machine gun";
const string n_mg42 = "Construct a MG42 Machine gun";
const string n_dshk = "Construct a DShK Machine gun";

const string n_jav = "Craft a Javelin Missile launcher";
const string n_apsniper = "Craft a Armor-Penetrating Sniper Rifle.";
const string n_pak38 = "Construct a Pak-38 Anti-Tank Cannon";

// ===========
// DESCRIPTION
// ===========

// Transport
const string d_civcar = "A civilian car.\n\nSpeedy transport.";
const string d_lada = "A civilian car.\n\nCyka blyat.";
const string d_moto = "Speedy transport.";
const string d_amoto = "Armed motorcycle.";
const string d_truck = "Lightweight transport.\n\nUses Ammunition.";
const string d_humvee = "Armored transport.\n\nUses Ammunition.";
const string d_truckbig = "A modernized heavy truck. Additionally has 2 machineguns mounted.\n\nUses Ammunition.\nYou can construct crane augments in the crane buildings.";
const string d_barge = "An armored boat for transporting vehicles across water.";
const string d_armory = "Supply truck.\nAllows to switch class and perk.";

// APC
const string d_pszh = "Scout APC.\n\nVery fast, medium firerate, amphibious\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.";
const string d_btr = "Medium APC.\n\nFast, good firerate, good engine, amphibious\nWeak armor, bad elevation angles, long reload\n\nUses 14.5mm.";
const string d_bmp = "Heavy and armed with a Rocket launcher APC.\n\nGood armor, moderately fast, amphibious\nWeak engine, bad elevation angles, long reload\nPress LMB to release Smoke cloud.\n\nUses 14.5mm and optionally HEAT warheads.";
const string d_bradley = "Heavy and armed with a Rocket launcher APC.\n\nPowerful engine, fast, good elevation angles\nWeak armor\n\nUses 14.5mm and optionally HEAT warheads.";
const string d_radarapc = "Light APC.\n\nLocates enemy vehicles on the map.\n\nDoesn't have any combat capabilities.";

// Medium Tank
const string d_m60 = "Medium tank.\n\nPowerful engine, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses Tank & Ammunition.";
const string d_e50 = "Medium tank.\n\nFast, good elevation angles, fast projectile\nMedium armor, weaker turret armor (weakpoint)\n\nUses Tank";
const string d_obj430 = "Medium tank.\n\nBig caliber, great turret armor\nSlow, fragile lower armor plate (weakpoint)\n\nUses Tank & Ammunition.";
const string d_leopard1 = "Medium tank.\n\nFast, good elevation angles, good fire rate, fast projectile\nMedium armor, weak turret armor (weakpoint)\n\nUses Tank & Ammunition.";
const string d_bc25t = "Light tank.\n\nFast, excellent elevation angles, 4 shells in loading cassette\nWeak engine, weak turret armor (weakpoint)\nPress LMB to release Smoke cloud.\n\nUses Tank";

// Heavy Tank
const string d_t10 = "Heavy tank.\n\nThick armor, big caliber.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses Tank & Ammunition.";
const string d_kingtiger = "Heavy tank.\n\nThick armor, good elevation angles, big caliber.\nVery slow, slow fire rate\n\nUses Tank & Ammunition.";
const string d_m103 = "Heavy tank.\n\nThick armor, good elevation angles, good fire rate.\nVery slow, small damage, big gap between turret and hull (weakpoint)\n\nUses Tank & Ammunition.";

// Super Heavy Tank
const string d_abrams = "Super heavy tank.\n\nThick armor, good engine, good fire rate\nBad elevation angles, fragile hull from above and back side (weakpoint)\nPress LMB to release Smoke cloud.\n\nUses Tank";
const string d_maus = "Super heavy tank.\n\nThick armor, good turret armor, big caliber with high-explosive damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses Tank";
const string d_is7 = "Super heavy tank.\n\nThick armor, best turret armor, big caliber, big max speed.\nVery weak engine, slow fire rate, fragile hull from above (weakpoint).\n\nUses Tank";

// Artillery
const string d_arti = "A long-range, slow and fragile artillery.\n\nUses Bombs.";
const string d_m40 = "A medium-range, decently mobile and fragile artillery.\n\nUses Bombs.";
const string d_grad = "A short-range, mobile but fragile MLRS.\n\nUses Tank.";
const string d_mortar = "A short-range, less powerful but mobile mortar.\n\nUses Bombs.";

// Fighter Planes
const string d_bf109 = "Fighter plane.\nUses Ammunition.";

// Bomber Planes
const string d_b24 = "B-24 Heavy Bomber plane.\nUses Ammo and Bombs.";
const string d_pe2 = "Pe-2 Heavy Bomber plane.\nUses Ammo and Bombs.";
const string d_he111 = "He-111 Heavy Bomber plane.\nUses Ammo and Bombs.";

// Helicopter
const string d_uh1 = "A helicopter with heavy machinegun.\nPress SPACEBAR to launch missiles";
const string d_ah1 = "A fast but weaker destroyer-helicopter with protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch rockets.\nPress LMB to release homing missile decoy.";
const string d_mi24 = "A stronger but slow destroyer-helicopter with protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch rockets.\nPress LMB to release homing missile decoy.";
const string d_nh90 = "A versatile helicopter with protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch rockets.\nPress LMB to release homing missile decoy.";

// Machinegun
const string d_m2 = "M2 Browning machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.";
const string d_mg42 = "MG42 machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.";
const string d_dshk = "DShK machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.";

// Weapons 1
const string d_jav = "Homing Missile launcher.\nScroll mouse wheel to change raising angle.\n\nUses HEAT warheads.";
const string d_apsniper = "Armor-Penetrating Sniper Rifle.\nPenetrates non-solid blocks and flesh. Designed to penetrate tank armor.\n\nUses Special Ammunition.";
const string d_pak38 = "Pak-38 Anti-Tank Cannon.\nA lightweight stationary weapon with good fire rate but tough control.\n\nUses Tank";

// ==========
// BLOB NAMES
// ==========

// Transport
const string bn_civcar = "civcar";
const string bn_lada = "lada";
const string bn_moto = "motorcycle";
const string bn_amoto = "armedmotorcycle";
const string bn_truck = "techtruck";
const string bn_humvee = "humvee";
const string bn_truckbig = "techbigtruck";
const string bn_barge = "barge";
const string bn_armory = "armory";

// APC
const string bn_pszh = "pszh4";
const string bn_btr = "btr82a";
const string bn_bmp = "bmp";
const string bn_bradley = "bradley";
const string bn_radarapc = "radarapc";

// Medium Tank
const string bn_m60 = "m60";
const string bn_e50 = "e50";
const string bn_obj430 = "obj430";
const string bn_leopard1 = "leopard1";
const string bn_bc25t = "bc25t";

// Heavy Tank
const string bn_t10 = "t10";
const string bn_kingtiger = "kingtiger";
const string bn_m103 = "m103";

// Super Heavy Tank
const string bn_abrams = "m1abrams";
const string bn_maus = "maus";
const string bn_is7 = "is7";

// Artillery
const string bn_arti = "artillery";
const string bn_m40 = "m40";
const string bn_grad = "grad";
const string bn_mortar = "mortar";

// Fighter Planes
const string bn_bf109 = "bf109";

// Bomber Planes
const string bn_b24 = "b24";
const string bn_pe2 = "pe2";
const string bn_he111 = "he111";

// Helicopter
const string bn_uh1 = "uh1";
const string bn_ah1 = "ah1";
const string bn_mi24 = "mi24";
const string bn_nh90 = "nh90";

// Machinegun
const string bn_m2 = "m2browning";
const string bn_mg42 = "mg42";
const string bn_dshk = "dshk";

// Weapons 1
const string bn_jav = "launcher_javelin";
const string bn_apsniper = "apsniper";
const string bn_pak38 = "pak38";

// ===========
// ICON TOKENS
// ===========

// Transport
const string t_civcar = "$"+bn_civcar+"$";
const string t_lada = "$"+bn_lada+"$";
const string t_moto = "$"+bn_moto+"$";
const string t_amoto = "$"+bn_amoto+"$";
const string t_truck = "$"+bn_truck+"$";
const string t_humvee = "$"+bn_humvee+"$";
const string t_truckbig = "$"+bn_truckbig+"$";
const string t_barge = "$"+bn_barge+"$";
const string t_armory = "$"+bn_armory+"$";

// APC
const string t_pszh = "$"+bn_pszh+"$";
const string t_btr = "$"+bn_btr+"$";
const string t_bmp = "$"+bn_bmp+"$";
const string t_bradley = "$"+bn_bradley+"$";
const string t_radarapc = "$"+bn_radarapc+"$";

// Medium Tank
const string t_m60 = "$"+bn_m60+"$";
const string t_e50 = "$"+bn_e50+"$";
const string t_obj430 = "$"+bn_obj430+"$";
const string t_leopard1 = "$"+bn_leopard1+"$";
const string t_bc25t = "$"+bn_bc25t+"$";

// Heavy Tank
const string t_t10 = "$"+bn_t10+"$";
const string t_kingtiger = "$"+bn_kingtiger+"$";
const string t_m103 = "$"+bn_m103+"$";

// Super Heavy Tank
const string t_abrams = "$"+bn_abrams+"$";
const string t_maus = "$"+bn_maus+"$";
const string t_is7 = "$"+bn_is7+"$";

// Artillery
const string t_arti = "$"+bn_arti+"$";
const string t_m40 = "$"+bn_m40+"$";
const string t_grad = "$"+bn_grad+"$";
const string t_mortar = "$"+bn_mortar+"$";

// Fighter Planes
const string t_bf109 = "$"+bn_bf109+"$";

// Bomber Planes
const string t_b24 = "$"+bn_b24+"$";
const string t_pe2 = "$"+bn_pe2+"$";
const string t_he111 = "$"+bn_he111+"$";

// Helicopter
const string t_uh1 = "$"+bn_uh1+"$";
const string t_ah1 = "$"+bn_ah1+"$";
const string t_mi24 = "$"+bn_mi24+"$";
const string t_nh90 = "$"+bn_nh90+"$";

// Machinegun
const string t_m2 = "$icon_mg$";
const string t_mg42 = "$icon_mg$";
const string t_dshk = "$icon_mg$";

// Weapons 1
const string t_jav = "$icon_jav$";
const string t_apsniper = "$"+bn_apsniper+"$";
const string t_pak38 = "$"+bn_pak38+"$";

enum VehicleType
{
	transport,
	armedtransport,
	apc,
	mediumtank,
	heavytank,
	superheavytank,
	artillery,
	fighterplane,
	bomberplane,
	helicopter,
	machinegun,
	weapons1,
	special1,
	TOTAL
};

class VehicleParams
{
	string name;
	string token;
	string blobName;
	string description;
	u16 cost;
	u16 buildTime;
	Vec2f dim;
	bool spawnInInventory;
	bool spawnInCrate;

	VehicleParams(const string& in name, const string& in token, const string& in blobName, const string& in description, u16 cost, u16 buildTime, const Vec2f& in dim, bool spawnInInventory = false, bool spawnInCrate = false)
	{
		this.name = name;
		this.token = token;
		this.blobName = blobName;
		this.description = description;
		this.cost = cost;
		this.buildTime = buildTime;
		this.dim = dim;
		this.spawnInInventory = spawnInInventory;
		this.spawnInCrate = spawnInCrate;
	}
}

const VehicleParams[][] vehicles = {
	/* Transport */
	{
		VehicleParams(n_civcar, t_civcar, bn_civcar, d_civcar, c_civcar, ct_civcar, Vec2f(2,2)),
		VehicleParams(n_lada, t_lada, bn_lada, d_lada, c_lada, ct_lada, Vec2f(2,2)),
		VehicleParams(n_civcar, t_civcar, bn_civcar, d_civcar, c_civcar, ct_civcar, Vec2f(2,2))
	},
	/* Armed Transport */
	{
		VehicleParams(n_humvee, t_humvee, bn_humvee, d_humvee, c_humvee, ct_humvee, Vec2f(2,2)),
		VehicleParams(n_truck, t_truck, bn_truck, d_truck, c_truck, ct_truck, Vec2f(2,2)),
		VehicleParams(n_amoto, t_amoto, bn_amoto, d_amoto, c_amoto, ct_amoto, Vec2f(2,2))
	},
	/* APC */
	{
		VehicleParams(n_bradley, t_bradley, bn_bradley, d_bradley, c_bradley, ct_bradley, Vec2f(2,2)),
		VehicleParams(n_btr, t_btr, bn_btr, d_btr, c_btr, ct_btr, Vec2f(2,2)),
		VehicleParams(n_pszh, t_pszh, bn_pszh, d_pszh, c_pszh, ct_pszh, Vec2f(2,2))
	},
	/* Medium Tank */
	{
		VehicleParams(n_m60, t_m60, bn_m60, d_m60, c_m60, ct_m60, Vec2f(2,2)),
		VehicleParams(n_obj430, t_obj430, bn_obj430, d_obj430, c_obj430, ct_obj430, Vec2f(2,2)),
		VehicleParams(n_e50, t_e50, bn_e50, d_e50, c_e50, ct_e50, Vec2f(2,2))
	},
	/* Heavy Tank */
	{
		VehicleParams(n_m103, t_m103, bn_m103, d_m103, c_m103, ct_m103, Vec2f(2,2)),
		VehicleParams(n_t10, t_t10, bn_t10, d_t10, c_t10, ct_t10, Vec2f(2,2)),
		VehicleParams(n_kingtiger, t_kingtiger, bn_kingtiger, d_kingtiger, c_kingtiger, ct_kingtiger, Vec2f(2,2))
	},
	/* Super Heavy Tank */
	{
		VehicleParams(n_abrams, t_abrams, bn_abrams, d_abrams, c_abrams, ct_abrams, Vec2f(2,2)),
		VehicleParams(n_is7, t_is7, bn_is7, d_is7, c_is7, ct_is7, Vec2f(2,2)),
		VehicleParams(n_maus, t_maus, bn_maus, d_maus, c_maus, ct_maus, Vec2f(2,2))
	},
	/* Artillery */
	{
		VehicleParams(n_m40, t_m40, bn_m40, d_m40, c_m40, ct_m40, Vec2f(2,2)),
		VehicleParams(n_grad, t_grad, bn_grad, d_grad, c_grad, ct_grad, Vec2f(2,2)),
		VehicleParams(n_arti, t_arti, bn_arti, d_arti, c_arti, ct_arti, Vec2f(2,2))
	},
	/* Fighter Plane */
	{
		VehicleParams(n_bf109, t_bf109, bn_bf109, d_bf109, c_bf109, ct_bf109, Vec2f(4,2)),
		VehicleParams(n_bf109, t_bf109, bn_bf109, d_bf109, c_bf109, ct_bf109, Vec2f(4,2)),
		VehicleParams(n_bf109, t_bf109, bn_bf109, d_bf109, c_bf109, ct_bf109, Vec2f(4,2))
	},
	/* Bomber Plane */
	{
		VehicleParams(n_b24, t_b24, bn_b24, d_b24, c_b24, ct_b24, Vec2f(4,2)),
		VehicleParams(n_pe2, t_pe2, bn_pe2, d_pe2, c_pe2, ct_pe2, Vec2f(4,2)),
		VehicleParams(n_he111, t_he111, bn_he111, d_he111, c_he111, ct_he111, Vec2f(4,2))
	},
	/* Helicopter */
	{
		VehicleParams(n_ah1, t_ah1, bn_ah1, d_ah1, c_ah1, ct_ah1, Vec2f(5,2)),
		VehicleParams(n_mi24, t_mi24, bn_mi24, d_mi24, c_mi24, ct_mi24, Vec2f(5,2)),
		VehicleParams(n_nh90, t_nh90, bn_nh90, d_nh90, c_nh90, ct_nh90, Vec2f(5,2))
	},
	/* Machinegun */
	{
		VehicleParams(n_m2, t_m2, bn_m2, d_m2, c_m2, ct_m2, Vec2f(1,1), false, true),
		VehicleParams(n_dshk, t_dshk, bn_dshk, d_dshk, c_dshk, ct_dshk, Vec2f(1,1), false, true),
		VehicleParams(n_mg42, t_mg42, bn_mg42, d_mg42, c_mg42, ct_mg42, Vec2f(1,1), false, true)
	},
	/* Weapons 1 */
	{
		VehicleParams(n_jav, t_jav, bn_jav, d_jav, c_jav, ct_jav, Vec2f(2,1)),
		VehicleParams(n_apsniper, t_apsniper, bn_apsniper, d_apsniper, c_apsniper, ct_apsniper, Vec2f(2,1)),
		VehicleParams(n_pak38, t_pak38, bn_pak38, d_pak38, c_pak38, ct_pak38, Vec2f(2,1), false, true)
	},
	/* Special 1 */
	{
		VehicleParams(n_bc25t, t_bc25t, bn_bc25t, d_bc25t, c_bc25t, ct_bc25t, Vec2f(2,2)),
		VehicleParams(n_bmp, t_bmp, bn_bmp, d_bmp, c_bmp, ct_bmp, Vec2f(2,2)),
		VehicleParams(n_leopard1, t_leopard1, bn_leopard1, d_leopard1, c_leopard1, ct_leopard1, Vec2f(2,2))
	}
};

CBlob@ spawnFactionVehicle(int tile_offset, VehicleType type, u8 team)
{
	return spawnFactionVehicle(getMap().getTileWorldPosition(tile_offset), type, team);
}

CBlob@ spawnFactionVehicle(Vec2f at, VehicleType type, u8 team)
{
	VehicleParams[] vehicleList = vehicles[type];
	const VehicleParams@ params;

	switch (team)
	{
		case 1:
			@params = vehicleList[1];
			break;
		case 2:
			@params = vehicleList[2];
			break;
		case 0:
		default:
			@params = vehicleList[0];
			break;
	}

	CBlob@ vehicle = server_CreateBlob(params.blobName, team, at);
	return vehicle;
}

void makeShopItem(CBlob@ this, const VehicleParams@ params, const bool inv = false, const bool crate = false)
{
	ShopItem@ item = addShopItem(this, params.name, params.token, params.blobName, params.description, inv, crate, params.buildTime == 0, params.buildTime);
	item.customButton = true;
	item.buttonwidth = params.dim.x;
	item.buttonheight = params.dim.y;
	
	AddRequirement(item.requirements, b, s, ds, params.cost);
}

void makeFactionVehicle(CBlob@ this, u8 team, VehicleType type, const u8 discount = 0, const bool inv = false, const bool crate = false)
{
	VehicleParams[] vehicleList = vehicles[type];
	const VehicleParams@ params;

	switch (team)
	{
		case 1:
			@params = vehicleList[1];
			break;
		case 2:
			@params = vehicleList[2];
			break;
		case 0:
		default:
			@params = vehicleList[0];
			break;
	}

	VehicleParams discountedParams = VehicleParams(params.name, params.token, params.blobName, params.description, params.cost - discount, params.buildTime, params.dim);
	makeShopItem(this, discountedParams, params.spawnInInventory, params.spawnInCrate);
}

void makePlanes(CBlob@ this, u8 discount = 0)
{
	makeFactionVehicle(this, 0, VehicleType::fighterplane, discount, false, false);
	makeFactionVehicle(this, 0, VehicleType::bomberplane, discount, false, false);
}

void makeBarge(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_barge, t_barge, bn_barge, d_barge, false, true, true);
	item.customButton = true;
	item.buttonwidth = 2;
	item.buttonheight = 2;
	AddRequirement(item.requirements, b, s, ds, c_barge - discount);
}

void makeArmory(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_armory, t_armory, bn_armory, d_armory, false, false, false, ct_armory);
	item.customButton = true;
	item.buttonwidth = 2;
	item.buttonheight = 2;
	AddRequirement(item.requirements, b, s, ds, c_armory - discount);
}

void makeMotorcycle(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_moto, t_moto, bn_moto, d_moto, false, false, false, ct_moto);
	item.customButton = true;
	item.buttonwidth = 2;
	item.buttonheight = 2;
	AddRequirement(item.requirements, b, s, ds, c_moto - discount);
}

void makeMortar(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_mortar, t_mortar, bn_mortar, d_mortar, false, false, false, ct_mortar);
	item.customButton = true;
	item.buttonwidth = 1;
	item.buttonheight = 1;
	AddRequirement(item.requirements, b, s, ds, c_mortar - discount);
}

void makeRadarAPC(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_radarapc, t_radarapc, bn_radarapc, d_radarapc, false, false, false, ct_radarapc);
	item.customButton = true;
	item.buttonwidth = 2;
	item.buttonheight = 2;
	AddRequirement(item.requirements, b, s, ds, c_radarapc - discount);
}

void makeTechBigTruck(CBlob@ this, u8 discount = 0)
{
	ShopItem@ item = addShopItem(this, n_truckbig, t_truckbig, bn_truckbig, d_truckbig, false, false, false, ct_truckbig);
	item.customButton = true;
	item.buttonwidth = 2;
	item.buttonheight = 2;
	AddRequirement(item.requirements, b, s, ds, c_truckbig - discount);
}