#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "VehiclesParams.as"

//Combined
void buildT1ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(12, 4));
	u8 tn = this.getTeamNum();

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::transport, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					0, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			0, false, false);
	makeArmory(this);

	makeBarge(this);
	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			0, false, false);

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles and aircraft.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks in", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 150);
		}
	}
}

void buildT2ShopCombined(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(12, 6));
	u8 tn = this.getTeamNum();

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::transport, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					3, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			5, false, false);
	makeFactionVehicle(this, tn, VehicleType::heavytank, 			0, false, false);
	makeArmory(this, 3);

	makeFactionVehicle(this, tn, VehicleType::artillery, 			0, false, false);
	makeTechBigTruck(this);
	makeBarge(this);
	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		5, false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			5, false, false);
	makeFactionVehicle(this, tn, VehicleType::helicopter, 			0, false, false);
	makeFactionVehicle(this, this.getTeamNum(), VehicleType::machinegun, 0, false, true);

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3", "Tier 3 - Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks in", 25*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 250);
		}
	}

	makeFirethrower(this);
}

void buildT3ShopCombined(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(14, 6));
	u8 tn = this.getTeamNum();

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::transport, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					7, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			10,false, false);
	makeFactionVehicle(this, tn, VehicleType::heavytank, 			5, false, false);
	makeFactionVehicle(this, tn, VehicleType::superheavytank, 		0, false, false);

	makeFactionVehicle(this, tn, VehicleType::special1, 			0, false, false);
	makeArmory(this, 5);
	makeRadarAPC(this);
	makeFactionVehicle(this, tn, VehicleType::artillery, 			5, false, false);
	makeTechBigTruck(this, 5);
	makeBarge(this, 5);
	makeFactionVehicle(this, tn, VehicleType::machinegun, 			3, false, true);
	makeFirethrower(this, 3);

	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		10,false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			10,false, false);
	makeFactionVehicle(this, tn, VehicleType::helicopter, 			5, false, false);
}

void buildT1ShopGround(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(8, 4));
	u8 tn = this.getTeamNum();

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::transport, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					0, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			0, false, false);
	makeArmory(this);
	makeFactionVehicle(this, tn, VehicleType::weapons1, 			0, false, false);

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2ground", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks in", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
		}
	}
	makeFactionVehicle(this, tn, VehicleType::machinegun, 			0, false, false);
	makeFirethrower(this);
}

void buildT2ShopGround(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(12, 4));
	u8 tn = this.getTeamNum();

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::transport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 	0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 				3, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 		5, false, false);
	makeFactionVehicle(this, tn, VehicleType::heavytank, 		0, false, false);
	makeArmory(this, 3);

	makeFactionVehicle(this, tn, VehicleType::artillery, 		0, false, false);
	makeTechBigTruck(this);
	makeBarge(this);
	makeFactionVehicle(this, tn, VehicleType::weapons1, 		3, false, false);

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3ground", "Tier 3 - Ground Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks in", 25*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 200);
		}
	}

	makeFactionVehicle(this, tn, VehicleType::machinegun, 		3, false, true);
	makeFirethrower(this, 3);
}

void buildT3ShopGround(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(14, 4));
	u8 tn = this.getTeamNum();

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::transport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					7, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			10,false, false);
	makeFactionVehicle(this, tn, VehicleType::heavytank, 			5, false, false);
	makeFactionVehicle(this, tn, VehicleType::superheavytank, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::special1, 			0, false, false);

	makeArmory(this, 5);
	makeRadarAPC(this);
	makeFactionVehicle(this, tn, VehicleType::artillery, 			5, false, false);
	makeTechBigTruck(this, 5);
	makeBarge(this, 5);
	makeFactionVehicle(this, tn, VehicleType::machinegun, 			3, false, true);
	makeFirethrower(this, 3);
}

void buildT1ShopAir(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(6, 4));
	u8 tn = this.getTeamNum();

	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			0, false, false);

	{
        ShopItem@ s = addShopItem(this, n_standard_ammo, t_standard_ammo, bn_standard_ammo, d_standard_ammo, true, false, false, ct_standard_ammo);
        AddRequirement(s.requirements, "coin", "", "Coins", 3);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
		//pipe wrench
		ShopItem@ s = addShopItem(this, n_pipe_wrench, t_pipe_wrench, bn_pipe_wrench, d_pipe_wrench, true, false, false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	
	makeSmallBombs(this);
	makeBigBombs(this);

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert3$", "vehiclebuildert2air", "Tier 2 - Aircraft Vehicle builder.\n\nUnlocks a helicopter.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks in", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 75);
		}
	}
}

void buildT2ShopAir(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(8, 4));
	u8 tn = this.getTeamNum();

	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		5, false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			5, false, false);
	makeFactionVehicle(this, tn, VehicleType::helicopter, 			0, false, false);

	{
        ShopItem@ s = addShopItem(this, n_standard_ammo, t_standard_ammo, bn_standard_ammo, d_standard_ammo, true, false, false, ct_standard_ammo);
        AddRequirement(s.requirements, "coin", "", "Coins", 3);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
		//pipe wrench
		ShopItem@ s = addShopItem(this, n_pipe_wrench, t_pipe_wrench, bn_pipe_wrench, d_pipe_wrench, true, false, false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
        ShopItem@ s = addShopItem(this, n_105mm_rounds, t_105mm_rounds, bn_105mm_rounds, d_105mm_rounds, true, false, false, ct_105mm_rounds);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_105mm_rounds);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }

	makeSmallBombs(this);
	makeBigBombs(this);
}

void buildT1ShopDefense(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(6, 2));
	u8 tn = this.getTeamNum();

	{
        ShopItem@ s = addShopItem(this, n_standard_ammo, t_standard_ammo, bn_standard_ammo, d_standard_ammo, true, false, false, ct_standard_ammo);
        AddRequirement(s.requirements, "coin", "", "Coins", 3);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
		//pipe wrench
		ShopItem@ s = addShopItem(this, n_pipe_wrench, t_pipe_wrench, bn_pipe_wrench, d_pipe_wrench, true, false, false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
        ShopItem@ s = addShopItem(this, n_105mm_rounds, t_105mm_rounds, bn_105mm_rounds, d_105mm_rounds, true, false, false, ct_105mm_rounds);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_105mm_rounds);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	makeSmallBombs(this);
	{
        ShopItem@ s = addShopItem(this, n_heat_warheads, t_heat_warheads, bn_heat_warheads, d_heat_warheads, true, false, false, ct_heat_warheads);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_heat_warheads);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
        ShopItem@ s = addShopItem(this, n_land_mine, t_land_mine, bn_land_mine, d_land_mine, true, false, false, ct_land_mine);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_land_mine);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
        ShopItem@ s = addShopItem(this, n_tank_trap, t_tank_trap, bn_tank_trap, d_tank_trap, false, false, false, ct_tank_trap);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_tank_trap);
        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }

	makeFactionVehicle(this, tn, VehicleType::weapons1, 				0, false, false);
	makeMortar(this);
	makeFactionVehicle(this, tn, VehicleType::machinegun, 				0, false, false);

	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2defense", "Tier 2 - Defense constructor.\n\nUnlocks more defense.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks in", 15*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 75);
		}
	}
}

void buildT2ShopDefense(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(9, 2));
	u8 tn = this.getTeamNum();
	
	{
        ShopItem@ s = addShopItem(this, n_standard_ammo, t_standard_ammo, bn_standard_ammo, d_standard_ammo, true, false, false, ct_standard_ammo);
        AddRequirement(s.requirements, "coin", "", "Coins", 3);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
        ShopItem@ s = addShopItem(this, n_special_ammo, t_special_ammo, bn_special_ammo, d_special_ammo, true, false, false, ct_special_ammo);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_special_ammo);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
		//pipe wrench
		ShopItem@ s = addShopItem(this, n_pipe_wrench, t_pipe_wrench, bn_pipe_wrench, d_pipe_wrench, true, false, false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
        ShopItem@ s = addShopItem(this, n_105mm_rounds, t_105mm_rounds, bn_105mm_rounds, d_105mm_rounds, true, false, false, ct_105mm_rounds);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_105mm_rounds);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	makeSmallBombs(this);
	{
        ShopItem@ s = addShopItem(this, n_tank_trap, t_tank_trap, bn_tank_trap, d_tank_trap, false, false, false, ct_tank_trap);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_tank_trap);
        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
        ShopItem@ s = addShopItem(this, n_land_mine, t_land_mine, bn_land_mine, d_land_mine, true, false, false, ct_land_mine);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_land_mine);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
        ShopItem@ s = addShopItem(this, n_heat_warheads, t_heat_warheads, bn_heat_warheads, d_heat_warheads, true, false, false, ct_heat_warheads);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_heat_warheads);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }
	{
        ShopItem@ s = addShopItem(this, n_binoculars, t_binoculars, bn_binoculars, d_binoculars, true, false, false, ct_binoculars);
        AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", c_binoculars);

        s.customButton = true;
        s.buttonwidth = 1;
        s.buttonheight = 1;
    }

	makeFactionVehicle(this, 0, VehicleType::weapons1, 				0, false, false);
	makeFactionVehicle(this, 1, VehicleType::weapons1, 				0, false, false);
	makeFactionVehicle(this, 2, VehicleType::weapons1, 				0, false, false);
	makeMortar(this);
	makeFactionVehicle(this, tn, VehicleType::machinegun, 				0, false, false);
	makeFirethrower(this);
}

void buildT1ImportantArmoryShop(CBlob@ this)
{
	this.set_Vec2f("shop menu size", Vec2f(11, 6));
	{
		ShopItem@ s = addShopItem(this, "Ammuniton", "$ammo$", "ammo", "Ammo for machine guns and infantry.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Special Ammunition", "$specammo$", "specammo", "Special ammunition for advanced weapons.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "14.5mm Rounds", "$mat_14mmround$", "mat_14mmround", "Ammo for an APC.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "105mm Shells", "$mat_bolts$", "mat_bolts", "Ammo for a tank's main gun.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "HEAT Warheads", "$mat_heatwarhead$", "mat_heatwarhead", "Ammo for RPGs.\nHas a small explosion radius.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Anti-Tank Grenade", "$atgrenade$", "mat_atgrenade", "Press SPACE while holding to arm, ~5 seconds until boom.\nEffective against vehicles.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Grenade", "$grenade$", "grenade", "Very effective against vehicles or in close quarter rooms.\nPress [SPACEBAR] to pull the pin, [C] to throw.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Molotov", "$mat_molotov$", "mat_molotov", "A home-made cocktail with highly flammable liquid.\nPress [SPACEBAR] before throwing", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Helmet", "$helmet$", "helmet", "Standard issue millitary helmet, blocks a moderate amount of headshot damage.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy wood (400)", "$mat_wood$", "mat_wood", "Purchase 400 wood.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy stone (300)", "$mat_stone$", "mat_stone", "Purchase 300 stone.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press [E] to heal. Has 4 uses total. Bonus: allows medics to perform healing faster.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Binoculars", "$binoculars$", "binoculars", "A pair of zooming binoculars that allow you to see much further.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
	}

	makeSmallBombs(this);
	makeC4(this);
	makeExtraUtils(this);

	u8 tn = this.getTeamNum();
	makeFactionVehicle(this, tn, VehicleType::weapons1, 0, false, false);
	makeFactionVehicle(this, tn, VehicleType::machinegun, 0, false, false);
	makeFirethrower(this);

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					0, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::heavytank, 			0, false, false);
	makeBarge(this);
	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			0, false, false);

	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "importantarmoryt2", "Armory Tier 2\n\nUnlocks stronger ground vehicles and helicopters.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 4;

		AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 250);
	}
}

void buildT2ImportantArmoryShop(CBlob@ this)
{	
	this.set_Vec2f("shop menu size", Vec2f(12, 8));
	{
		ShopItem@ s = addShopItem(this, "Ammuniton", "$ammo$", "ammo", "Ammo for machine guns and infantry.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 3);
	}
	{
		ShopItem@ s = addShopItem(this, "Special Ammunition", "$specammo$", "specammo", "Special ammunition for advanced weapons.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "14.5mm Rounds", "$mat_14mmround$", "mat_14mmround", "Ammo for an APC.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "105mm Shells", "$mat_bolts$", "mat_bolts", "Ammo for a tank's main gun.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "HEAT Warheads", "$mat_heatwarhead$", "mat_heatwarhead", "Ammo for RPGs.\nHas a small explosion radius.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Anti-Tank Grenade", "$atgrenade$", "mat_atgrenade", "Press SPACE while holding to arm, ~5 seconds until boom.\nEffective against vehicles.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Grenade", "$grenade$", "grenade", "Very effective against vehicles or in close quarter rooms.\nPress [SPACEBAR] to pull the pin, [C] to throw.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Molotov", "$mat_molotov$", "mat_molotov", "A home-made cocktail with highly flammable liquid.\nPress [SPACEBAR] before throwing", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Helmet", "$helmet$", "helmet", "Standard issue millitary helmet, blocks a moderate amount of headshot damage.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy wood (400)", "$mat_wood$", "mat_wood", "Purchase 400 wood.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Buy stone (300)", "$mat_stone$", "mat_stone", "Purchase 300 stone.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}

	makeBigBombs(this);
	
	{
		ShopItem@ s = addShopItem(this, "Medkit", "$medkit$", "medkit", "If hurt, press [E] to heal. Has 4 uses total. Bonus: allows medics to perform healing faster.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Binoculars", "$binoculars$", "binoculars", "A pair of zooming binoculars that allow you to see much further.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
	}

	makeMortar(this);

	makeSmallBombs(this);
	makeC4(this);
	makeExtraUtils(this);

	u8 tn = this.getTeamNum();
	makeFactionVehicle(this, tn, VehicleType::weapons1, 0, false, false);
	makeFactionVehicle(this, tn, VehicleType::machinegun, 0, false, false);
	makeFirethrower(this);

	makeMotorcycle(this);
	makeFactionVehicle(this, tn, VehicleType::armedtransport, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::apc, 					0, false, false);
	makeFactionVehicle(this, tn, VehicleType::mediumtank, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::heavytank, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::superheavytank, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::special1, 		    0, false, false);
	
	makeRadarAPC(this);
	makeFactionVehicle(this, tn, VehicleType::artillery, 			0, false, false);
	makeBarge(this);
	makeFactionVehicle(this, tn, VehicleType::fighterplane, 		0, false, false);
	makeFactionVehicle(this, tn, VehicleType::bomberplane, 			0, false, false);
	makeFactionVehicle(this, tn, VehicleType::helicopter, 			0, false, false);
}