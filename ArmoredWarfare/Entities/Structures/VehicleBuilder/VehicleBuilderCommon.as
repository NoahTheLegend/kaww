#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"

//Combined
void buildT1ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(10, 4));
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 45);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 70);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy machinegun.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles and aircraft.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 8*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
		}
	}
}



void buildT2ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(17, 4));
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 22);
	}
	
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 65);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Maus", "$maus$", "maus", "Super heavy tank.\n\nThick armor, best turret armor, big cannon damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy MachineGun.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 7);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 18);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Bomber Plane", "$bomberplane$", "bomberplane", "A bomber plane.\nUses bomber bombs.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 65);
	}
	{
		ShopItem@ s = addShopItem(this, "Build UH1 Helicopter", "$uh1$", "uh1", "A helicopter with heavy machinegun.\nPress SPACEBAR to launch HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Barge", "$barge$", "barge", "An armored boat for transporting vehicles across the water.", false, true);
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3", "Tier 3 - Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 20*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 250);
		}
	}
}



void buildT3ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(18, 6));
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Bradley M2", "$bradley$", "bradley", "Light but armed with medium cannon APC.\nAlso has a javelin on the turret.\n\nExcellent engine power, fast, good elevation angles\nWeak armor\n\nUses 105mm and optionally HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 60);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Maus", "$maus$", "maus", "Super heavy tank.\n\nThick armor, best turret armor, big cannon damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 115);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Bomber Plane", "$bomberplane$", "bomberplane", "A bomber plane.\nUses bomber bombs.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 55);
	}
	{
		ShopItem@ s = addShopItem(this, "Build UH1 Huey Helicopter", "$uh1$", "uh1", "A common helicopter with heavy machinegun and passenger seats.\nPress SPACEBAR to launch HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Build AH1 Cobra Helicopter", "$ah1$", "ah1", "A fighter-helicopter with a co-pilot seat operating machinegun.\nPress SPACEBAR to launch 105mm Rockets.\nPress LMB to release missile traps.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 60);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Large Technical Truck", "$techbigtruck$", "techbigtruck", "A modernized truck. Commonly used for gang battles.\n\nUses Ammunition.");
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Artillery", "$artillery$", "artillery", "A long-range, slow and fragile artillery.\n\nUses Bomber Bombs.");
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 60);
	}
	{
		ShopItem@ s = addShopItem(this, "Barge", "$barge$", "barge", "An armored boat for transporting vehicles across the water.", false, true);
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy MachineGun.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Firethrower", "$icon_ft$", "firethrower", "Fire thrower.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "C-4 Explosive", "$c4$", "c4", "C-4\nA strong explosive, very effective against blocks and doors.\n\nTakes 10 seconds after activation to explode.\nYou can deactivate it as well.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
		//AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
	}
}



void buildT1ShopGround(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(8, 4));
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 45);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 70);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy machinegun.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2ground", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 8*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 100);
		}
	}
}



void buildT2ShopGround(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(11, 4));
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 4);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 8);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 22);
	}
	
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 65);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Maus", "$maus$", "maus", "Super heavy tank.\n\nThick armor, best turret armor, big cannon damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
    {
		ShopItem@ s = addShopItem(this, "Barge", "$barge$", "barge", "An armored boat for transporting vehicles across the water.", false, true);
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy MachineGun.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 7);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 18);
	}
	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3ground", "Tier 3 - Ground Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 20*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 175);
		}
	}
}



void buildT3ShopGround(CBlob@ this)
{
 this.set_Vec2f("shop menu size", Vec2f(15, 4));
	{
		ShopItem@ s = addShopItem(this, "Build a Motorcycle", "$motorcycle$", "motorcycle", "Speedy transport.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Technical Truck", "$techtruck$", "techtruck", "Lightweight transport.\n\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a PSZH-IV APC", "$pszh4$", "pszh4", "Scout car.\n\nVery fast, medium firerate\nVery fragile armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a BTR80a APC", "$btr82a$", "btr82a", "Armored transport.\n\nFast, good firerate\nWeak armor, bad elevation angles\n\nUses 14.5mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Bradley M2", "$bradley$", "bradley", "Light but armed with medium cannon APC.\nAlso has a javelin on the turret.\n\nExcellent engine power, fast, good elevation angles\nWeak armor\n\nUses 105mm and optionally HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a M60 Tank", "$m60$", "m60", "Medium tank.\n\nGood engine power, fast, good elevation angles\nMedium armor, weaker armor on backside (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a T-10 Tank", "$t10$", "t10", "Heavy tank.\n\nThick armor, big cannon damage.\nSlow, medium fire rate, big gap between turret and hull (weakpoint)\n\nUses 105mm & 7.62mm.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 60);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Maus", "$maus$", "maus", "Super heavy tank.\n\nThick armor, best turret armor, big cannon damage, good elevation angles\nVery slow, slow fire rate, very fragile lower armor plate (weakpoint)\n\nUses 105mm");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 115);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Armory", "$armory$", "armory", "A truck with supplies.\nAllows to switch class.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Build a Large Technical Truck", "$techbigtruck$", "techbigtruck", "A modernized truck. Commonly used for gang battles.\n\nUses Ammunition.");
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Build Artillery", "$artillery$", "artillery", "A long-range, slow and fragile artillery.\n\nUses Bomber Bombs.");
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 70); // more expensive because no aircraft
	}
	{
		ShopItem@ s = addShopItem(this, "Barge", "$barge$", "barge", "An armored boat for transporting vehicles across the water.", false, true);
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Heavy Machinegun", "$icon_mg$", "heavygun", "Heavy MachineGun.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Firethrower", "$icon_ft$", "firethrower", "Fire thrower.\nCCan be attached to and detached from some vehicles.\n\nUses Ammunition.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 12);
	}
	{
		ShopItem@ s = addShopItem(this, "C-4 Explosive", "$c4$", "c4", "C-4\nA strong explosive, very effective against blocks and doors.\n\nTakes 10 seconds after activation to explode.\nYou can deactivate it as well.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 10);
		//AddRequirement(s.requirements, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
	}
	{
		ShopItem@ s = addShopItem(this, "Javelin Launcher", "$icon_jav$", "launcher_javelin", "Homing Missile launcher.", false, true);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 15);
	}
    {
		ShopItem@ s = addShopItem(this, "Bomb", "$mat_smallbomb$", "mat_smallbomb", "Bombs for artillery.", false);
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 6);

		s.customButton = true;

		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
}

void buildT1ShopAir(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(10, 2));
    {
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build UH1 Huey Helicopter", "$uh1$", "uh1", "A common helicopter with heavy machinegun and passenger seats.\nPress SPACEBAR to launch HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 40);
	}
    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert3$", "vehiclebuildert2air", "Tier 2 - Aircraft Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 8*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
		}
	}
}

void buildT2ShopAir(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(9, 4));
    {
		ShopItem@ s = addShopItem(this, "Build Figther Plane", "$bf109$", "bf109", "A plane.\nUses Ammunition.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Build UH1 Huey Helicopter", "$uh1$", "uh1", "A common helicopter with heavy machinegun and passenger seats.\nPress SPACEBAR to launch HEAT warheads.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 40);
	}
    {
		ShopItem@ s = addShopItem(this, "Build Bomber Plane", "$bomberplane$", "bomberplane", "A bomber plane.\nUses bomber bombs.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 55);
	}
	{
		ShopItem@ s = addShopItem(this, "Build AH1 Cobra Helicopter", "$ah1$", "ah1", "A fighter-helicopter with a co-pilot seat operating machinegun.\nPress SPACEBAR to launch 105mm Rockets.\nPress LMB to release missile traps.");
		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 60);
	}
}