#include "Requirements.as"
#include "ShopCommon.as"

// initial costs
const u16 c_civcar = 5;
const u16 c_lada = 5;
const u16 c_moto = 5;
const u16 c_amoto = 7;
const u16 c_truck = 12;
const u16 c_humvee = 25;
const u16 c_truckbig = 30;
const u16 c_pszh = 15;
const u16 c_btr = 25;
const u16 c_bmp = 35;
const u16 c_bradley = 35;
const u16 c_m60 = 45;
const u16 c_e50 = 50;
const u16 c_obj430 = 50;
const u16 c_leopard1 = 50;
const u16 c_bc25t = 45;
const u16 c_t10 = 70;
const u16 c_kingtiger = 75;
const u16 c_m103 = 65;
const u16 c_abrams = 120;
const u16 c_maus = 130;
const u16 c_is7 = 125;
const u16 c_arti = 60;
const u16 c_m40 = 70;
const u16 c_grad = 75;
const u16 c_harti = 20;
const u16 c_bf109 = 30;
const u16 c_bomber = 65;
const u16 c_uh1 = 50;
const u16 c_ah1 = 65;
const u16 c_mi24 = 75;
const u16 c_nh90 = 70;
const u16 c_barge = 10;
const u16 c_armory = 30;
const u16 c_m2 = 8;
const u16 c_mg42 = 8;
const u16 c_ftw = 12;
const u16 c_c4 = 10;
const u16 c_jav = 15;
const u16 c_apsniper = 20;
// common
const string b = "blob";
const string s = "mat_scrap";
const string ds = "Scrap";
// names
const string n_civcar = "Build a Civilian Car";
const string n_lada = "Build a Lada";
const string n_moto = "Build a Motorcycle";
const string n_amoto = "Build a Motorcycle with machinegun";
const string n_truck = "Build a Truck";
const string n_humvee = "Build a Humvee";
const string n_truckbig = "Build a Cargo Truck";
const string n_pszh = "Build a PSZH-4 Light APC";
const string n_btr = "Build a BTR-82A Medium APC";
const string n_bmp = "Build a BMP-2 Heavy APC";
const string n_bradley = "Build a Braldey-M1A2 Heavy APC";
const string n_m60 = "Build a M60 Medium Tank";
const string n_e50 = "Build a E-50 Medium Tank";
const string n_obj430 = "Build a Object 430 Medium Tank";
const string n_leopard1 = "Build a Leopard 1 Medium Tank";
const string n_bc25t = "Build a Bat.-Chat. 25t Light Tank";
const string n_t10 = "Build a T10 Heavy Tank";
const string n_kingtiger = "Build a King Tiger Heavy Tank";
const string n_m103 = "Build a M-103 Heavy Tank";
const string n_abrams = "Build a M1 Abrams Super Heavy Tank";
const string n_maus = "Build a Maus Super Heavy Tank";
const string n_is7 = "Build a IS-7 Super Heavy Tank";
const string n_arti = "Build an Artillery";
const string n_m40 = "Build a M40 Artillery";
const string n_grad = "Build a BM-21 \"Grad\" MLRS";
const string n_harti = "Build an Infantry Mortar";
const string n_bf109 = "Build a Fighter plane";
const string n_bomber = "Build a Heavy Bomber plane";
const string n_uh1 = "Build a UH-1 Versatile Helicopter";
const string n_ah1 = "Build a AH-1 Fighter Helicopter";
const string n_mi24 = "Build a MI-24 Destroyer Helicopter";
const string n_nh90 = "Build a NH-90 Versatile Helicopter";
const string n_barge = "Build a Barge";
const string n_armory = "Build an Armory Truck";
const string n_m2 = "Construct a M2 Browning Machine gun";
const string n_mg42 = "Construct a MG42 Machine gun";
const string n_ftw = "Construct a Firethrower";
const string n_c4 = "Construct a C-4 Explosive";
const string n_jav = "Construct a Javelin Missile launcher";
const string n_apsniper = "Armor-Penetrating Sniper Rifle.";

// descriptions
const string d_civcar = "A civilian car.\n\nSpeedy transport.";
const string d_lada = "A civilian car.\n\nCyka blyat.";
const string d_moto = "Speedy transport.";
const string d_amoto = "Armed motorcycle.";
const string d_truck = "Lightweight transport.\n\nUses Ammunition.";
const string d_humvee = "Armored transport.\n\nUses Ammunition.";
const string d_truckbig = "A modernized heavy truck. Additionally has 2 machineguns mounted.\n\nUses Ammunition.\nYou can construct crane augments in the crane buildings.";
const string d_pszh = "Scout APC.\n\nVery fast, medium firerate, amphibious\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.";
const string d_btr = "Medium APC.\n\nFast, good firerate, good engine, amphibious\nWeak armor, bad elevation angles, long reload\n\nUses 14.5mm.";
const string d_bmp = "Heavy and armed with a Rocket launcher APC.\n\nBig caliber, good armor, moderately fast, amphibious\nWeak engine, bad elevation angles, long reload\nPress LMB to release Smoke cloud.\n\nUses 14.5mm and optionally HEAT warheads.";
const string d_bradley = "Heavy and armed with a Rocket launcher APC.\n\nPowerful engine, fast, good elevation angles\nWeak armor\n\nUses 14.5mm and optionally HEAT warheads.";
const string d_m60 = "Medium tank.\n\nPowerful engine, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & Ammunition.";
const string d_e50 = "Medium tank.\n\nFast, good elevation angles, fast projectile\nMedium armor, weaker turret armor (weakpoint)\n\nUses 105mm";
const string d_obj430 = "Medium tank.\n\nBig caliber, great turret armor\nSlow, fragile lower armor plate (weakpoint)\n\nUses 105mm & Ammunition.";
const string d_leopard1 = "Medium tank.\n\nFast, good elevation angles, good fire rate, fast projectile\nMedium armor, weak turret armor (weakpoint)\n\nUses 105mm & Ammunition.";
const string d_bc25t = "Light tank.\n\nFast, excellent elevation angles, 4 shells in loading cassette\nWeak engine, weak turret armor (weakpoint)\nPress LMB to release Smoke cloud.\n\nUses 105mm";
const string d_t10 = "Heavy tank.\n\nThick armor, big caliber.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & Ammunition.";
const string d_kingtiger = "Heavy tank.\n\nThick armor, good elevation angles, big caliber.\nVery slow, slow fire rate\n\nUses 105mm & Ammunition.";
const string d_m103 = "Heavy tank.\n\nThick armor, good elevation angles, good fire rate.\nVery slow, small damage\n\nUses 105mm & Ammunition.";
const string d_abrams = "Super heavy tank.\n\nThick armor, good engine, good fire rate\nBad elevation angles, fragile hull from above and back side (weakpoint)\nPress LMB to release Smoke cloud.\n\nUses 105mm";
const string d_maus = "Super heavy tank.\n\nThick armor, good turret armor, big caliber with high-explosive damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm";
const string d_is7 = "Super heavy tank.\n\nThick armor, best turret armor, big caliber, big max speed.\nVery weak engine, slow fire rate, fragile hull from above (weakpoint).\n\nUses 105mm";
const string d_arti = "A long-range, slow and fragile artillery.\n\nUses Bombs.";
const string d_m40 = "A medium-range, decently mobile and fragile artillery.\n\nUses Bombs.";
const string d_grad = "A short-range, mobile but fragile MLRS.\n\nUses 105mm.";
const string d_harti = "A short-range, less powerful but mobile mortar.\n\nUses Bombs.";
const string d_bf109 = "Fighter plane.\nUses Ammunition.";
const string d_bomber = "Heavy Bomber plane.\nUses Bombs.";
const string d_uh1 = "A helicopter with heavy machinegun.\nPress SPACEBAR to launch missiles";
const string d_ah1 = "A fast but weaker destroyer-helicopter with protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch rockets.\nPress LMB to release homing missile decoy.";
const string d_mi24 = "A stronger but slow destroyer-helicopter with protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch rockets.\nPress LMB to release homing missile decoy.";
const string d_nh90 = "A versatile helicopter with protected co-pilot seat operating machinegun.\nPress SPACEBAR to launch rockets.\nPress LMB to release homing missile decoy.";
const string d_barge = "An armored boat for transporting vehicles across water.";
const string d_armory = "Supply truck.\nAllows to switch class and perk.";
const string d_m2 = "M2 Browning machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.";
const string d_mg42 = "MG42 machinegun.\nCan be attached to and detached from some vehicles.\n\nUses Ammunition.";
const string d_ftw = "Fire thrower.\nCan be attached to and detached from some vehicles.\n\nUses Special Ammunition.";
const string d_c4 = "A strong explosive, very effective against blocks and doors.\n\nTakes some time after activation to explode.\nCan be defused.";
const string d_jav = "Homing Missile launcher.";
const string d_apsniper = "Armor-Penetrating Sniper Rifle.\nPenetrates non-solid blocks and flesh. Can penetrate tank armor.\n\nUses Special Ammunition.";
// blobnames
const string bn_civcar = "civcar";
const string bn_lada = "lada";
const string bn_moto = "motorcycle";
const string bn_amoto = "armedmotorcycle";
const string bn_truck = "techtruck";
const string bn_humvee = "humvee";
const string bn_truckbig = "techbigtruck";
const string bn_pszh = "pszh4";
const string bn_btr = "btr82a";
const string bn_bmp = "bmp";
const string bn_bradley = "bradley";
const string bn_m60 = "m60";
const string bn_e50 = "e50";
const string bn_obj430 = "obj430";
const string bn_leopard1 = "leopard1";
const string bn_bc25t = "bc25t";
const string bn_t10 = "t10";
const string bn_kingtiger = "kingtiger";
const string bn_m103 = "m103";
const string bn_abrams = "m1abrams";
const string bn_maus = "maus";
const string bn_is7 = "is7";
const string bn_arti = "artillery";
const string bn_m40 = "m40";
const string bn_grad = "grad";
const string bn_harti = "mortar";
const string bn_bf109 = "bf109";
const string bn_bomber = "bomberplane";
const string bn_uh1 = "uh1";
const string bn_ah1 = "ah1";
const string bn_mi24 = "mi24";
const string bn_nh90 = "nh90";
const string bn_barge = "barge";
const string bn_armory = "armory";
const string bn_m2 = "m2browning";
const string bn_mg42 = "mg42";
const string bn_ftw = "firethrower";
const string bn_c4 = "c4";
const string bn_jav = "launcher_javelin";
const string bn_apsniper = "apsniper";
// icon tokens
const string t_civcar = "$"+bn_civcar+"$";
const string t_lada = "$"+bn_lada+"$";
const string t_moto = "$"+bn_moto+"$";
const string t_amoto = "$"+bn_amoto+"$";
const string t_truck = "$"+bn_truck+"$";
const string t_humvee = "$"+bn_humvee+"$";
const string t_truckbig = "$"+bn_truckbig+"$";
const string t_pszh = "$"+bn_pszh+"$";
const string t_btr = "$"+bn_btr+"$";
const string t_bmp = "$"+bn_bmp+"$";
const string t_bradley = "$"+bn_bradley+"$";
const string t_m60 = "$"+bn_m60+"$";
const string t_e50 = "$"+bn_e50+"$";
const string t_obj430 = "$"+bn_obj430+"$";
const string t_leopard1 = "$"+bn_leopard1+"$";
const string t_bc25t = "$"+bn_bc25t+"$";
const string t_t10 = "$"+bn_t10+"$";
const string t_kingtiger = "$"+bn_kingtiger+"$";
const string t_m103 = "$"+bn_m103+"$";
const string t_abrams = "$"+bn_abrams+"$";
const string t_maus = "$"+bn_maus+"$";
const string t_is7 = "$"+bn_is7+"$";
const string t_arti = "$"+bn_arti+"$";
const string t_m40 = "$"+bn_m40+"$";
const string t_grad = "$"+bn_grad+"$";
const string t_harti = "$"+bn_harti+"$";
const string t_bf109 = "$"+bn_bf109+"$";
const string t_bomber = "$"+bn_bomber+"$";
const string t_uh1 = "$"+bn_uh1+"$";
const string t_ah1 = "$"+bn_ah1+"$";
const string t_mi24 = "$"+bn_mi24+"$";
const string t_nh90 = "$"+bn_nh90+"$";
const string t_barge = "$"+bn_barge+"$";
const string t_armory = "$"+bn_armory+"$";
const string t_m2 = "$icon_mg$";
const string t_mg42 = "$icon_mg$";
const string t_ftw = "$icon_ft$";
const string t_c4 = "$"+bn_c4+"$";
const string t_jav = "$icon_jav$";
const string t_apsniper = "$"+bn_apsniper+"$";

const string[][] alternatives = {
	/*transport*/				{n_civcar, n_lada, n_civcar}, {t_civcar, t_lada, t_civcar}, {bn_civcar, bn_lada, bn_civcar}, {d_civcar, d_lada, d_civcar}, {c_civcar, c_lada, c_civcar},
	/*armed transport*/			{n_truck, n_truck, n_truck}, {t_truck, t_truck, t_truck}, {bn_truck, bn_truck, bn_truck}, {d_truck, d_truck, d_truck}, {c_truck, c_truck, c_truck}, 	
	/*apc*/						{n_bradley, n_btr, n_pszh}, {t_bradley, t_btr, t_pszh}, {bn_bradley, bn_btr, bn_pszh}, {d_bradley, d_btr, d_pszh}, {c_bradley, c_btr, c_pszh}, 			
	/*medium tank*/				{n_m60, n_obj430, n_e50}, {t_m60, t_obj430, t_e50}, {bn_m60, bn_obj430, bn_e50}, {d_m60, d_obj430, d_e50}, {c_m60, c_obj430, c_e50}, 					
	/*heavy tank*/				{n_m103, n_t10, n_kingtiger}, {t_m103, t_t10, t_kingtiger}, {bn_m103, bn_t10, bn_kingtiger}, {d_m103, d_t10, d_kingtiger}, {c_m103, c_t10, c_kingtiger},
	/*super heavy tank*/		{n_abrams, n_is7, n_maus}, {t_abrams, t_is7, t_maus}, {bn_abrams, bn_is7, bn_maus}, {d_abrams, d_is7, d_maus}, {c_abrams, c_is7, c_maus}, 				
	/*artillery*/				{n_m40, n_grad, n_arti}, {t_m40, t_grad, t_arti}, {bn_m40, bn_grad, bn_arti}, {d_m40, d_grad, d_arti}, {c_m40, c_grad, c_arti},							
	/*helicopter*/				{n_ah1, n_mi24, n_nh90}, {t_ah1, t_mi24, t_nh90}, {bn_ah1, bn_mi24, bn_nh90}, {d_ah1, d_mi24, d_nh90}, {c_ah1, c_mi24, c_nh90},							
	/*machinegun*/				{n_m2, n_m2, n_mg42}, {t_m2, t_m2, t_mg42}, {bn_m2, bn_m2, bn_mg42}, {d_m2, d_m2, d_mg42}, {c_m2, c_m2, c_mg42}, 										
	/*special*/					{n_bc25t, n_bmp, n_leopard1}, {t_bc25t, t_bmp, t_leopard1}, {bn_bc25t, bn_bmp, bn_leopard1}, {d_bc25t, d_bmp, d_leopard1}, {c_bc25t, c_bmp, c_leopard1} 
};

void makeShopItem(CBlob@ this, string[] params, int cost, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	ShopItem@ s = addShopItem(this, params[0], params[1], params[2], params[3], inv, crate);
	if (inv || crate || dim.x > 1 || dim.y > 1)
	{
		s.customButton = true;
		s.buttonwidth = dim.x;
		s.buttonheight = dim.y;
	}
	AddRequirement(s.requirements, params[4], params[5], params[6], cost);
}

void makeFactionTransport(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[0][0], alternatives[1][0], alternatives[2][0], alternatives[3][0], alternatives[4][0]};
	string[] alt1 = {alternatives[0][1], alternatives[1][1], alternatives[2][1], alternatives[3][1], alternatives[4][1]};
	string[] alt2 = {alternatives[0][2], alternatives[1][2], alternatives[2][2], alternatives[3][2], alternatives[4][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[5][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[5][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[5][0]) - discount, dim, inv, crate);break;}
	}
}
void makeFactionArmedTransport(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[5][0], alternatives[6][0], alternatives[7][0], alternatives[8][0], alternatives[9][0]};
	string[] alt1 = {alternatives[5][1], alternatives[6][1], alternatives[7][1], alternatives[8][1], alternatives[9][1]};
	string[] alt2 = {alternatives[5][2], alternatives[6][2], alternatives[7][2], alternatives[8][2], alternatives[9][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[10][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[10][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[10][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionAPC(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[10][0], alternatives[11][0], alternatives[12][0], alternatives[13][0], alternatives[14][0]};
	string[] alt1 = {alternatives[10][1], alternatives[11][1], alternatives[12][1], alternatives[13][1], alternatives[14][1]};
	string[] alt2 = {alternatives[10][2], alternatives[11][2], alternatives[12][2], alternatives[13][2], alternatives[14][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[15][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[15][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[15][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionMediumTank(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[15][0], alternatives[16][0], alternatives[17][0], alternatives[18][0], alternatives[19][0]};
	string[] alt1 = {alternatives[15][1], alternatives[16][1], alternatives[17][1], alternatives[18][1], alternatives[19][1]};
	string[] alt2 = {alternatives[15][2], alternatives[16][2], alternatives[17][2], alternatives[18][2], alternatives[19][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[20][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[20][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[20][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionHeavyTank(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[20][0], alternatives[21][0], alternatives[22][0], alternatives[23][0], alternatives[24][0]};
	string[] alt1 = {alternatives[20][1], alternatives[21][1], alternatives[22][1], alternatives[23][1], alternatives[24][1]};
	string[] alt2 = {alternatives[20][2], alternatives[21][2], alternatives[22][2], alternatives[23][2], alternatives[24][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[25][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[25][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[25][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionSuperHeavyTank(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[25][0], alternatives[26][0], alternatives[27][0], alternatives[28][0], alternatives[29][0]};
	string[] alt1 = {alternatives[25][1], alternatives[26][1], alternatives[27][1], alternatives[28][1], alternatives[29][1]};
	string[] alt2 = {alternatives[25][2], alternatives[26][2], alternatives[27][2], alternatives[28][2], alternatives[29][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[30][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[30][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[30][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionArtillery(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[30][0], alternatives[31][0], alternatives[32][0], alternatives[33][0], alternatives[34][0]};
	string[] alt1 = {alternatives[30][1], alternatives[31][1], alternatives[32][1], alternatives[33][1], alternatives[34][1]};
	string[] alt2 = {alternatives[30][2], alternatives[31][2], alternatives[32][2], alternatives[33][2], alternatives[34][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[35][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[35][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[35][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionHelicopter(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[35][0], alternatives[36][0], alternatives[37][0], alternatives[38][0], alternatives[39][0]};
	string[] alt1 = {alternatives[35][1], alternatives[36][1], alternatives[37][1], alternatives[38][1], alternatives[39][1]};
	string[] alt2 = {alternatives[35][2], alternatives[36][2], alternatives[37][2], alternatives[38][2], alternatives[39][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[40][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[40][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[40][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionMachinegun(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[40][0], alternatives[41][0], alternatives[42][0], alternatives[43][0], alternatives[44][0]};
	string[] alt1 = {alternatives[40][1], alternatives[41][1], alternatives[42][1], alternatives[43][1], alternatives[44][1]};
	string[] alt2 = {alternatives[40][2], alternatives[41][2], alternatives[42][2], alternatives[43][2], alternatives[44][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[45][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[45][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[45][0]) - discount, dim, inv, crate);break;}
	}
}

void makeFactionSpecial(CBlob@ this, u8 team, const u8 discount = 0, const Vec2f dim = Vec2f(1,1), const bool inv = false, const bool crate = false)
{
	string[] alt0 = {alternatives[45][0], alternatives[46][0], alternatives[47][0], alternatives[48][0], alternatives[49][0]};
	string[] alt1 = {alternatives[45][1], alternatives[46][1], alternatives[47][1], alternatives[48][1], alternatives[49][1]};
	string[] alt2 = {alternatives[45][2], alternatives[46][2], alternatives[47][2], alternatives[48][2], alternatives[49][2]};
	
	switch (team)
	{
		case 1:
		{makeShopItem(this, alt1, parseInt(alternatives[50][1]) - discount, dim, inv, crate);break;}
		case 2:
		{makeShopItem(this, alt2, parseInt(alternatives[50][2]) - discount, dim, inv, crate);break;}
		case 0:
		default:
		{makeShopItem(this, alt0, parseInt(alternatives[50][0]) - discount, dim, inv, crate);break;}
	}
}