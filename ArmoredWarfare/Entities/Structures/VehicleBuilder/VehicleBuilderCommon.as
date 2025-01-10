#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "VehiclesParams.as"

//Combined
void buildT1ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(12, 8));

    makeFactionTransport(this, this.getTeamNum());
    makeFactionArmedTransport(this, this.getTeamNum());
    makeFactionAPC(this, this.getTeamNum());
    makeFactionMediumTank(this, this.getTeamNum());
    makeFactionHeavyTank(this, this.getTeamNum());
    makeFactionSuperHeavyTank(this, this.getTeamNum());
    makeFactionArtillery(this, this.getTeamNum());
    makeFactionHelicopter(this, this.getTeamNum());
    makeFactionMachinegun(this, this.getTeamNum());
    makeFactionSpecial(this, this.getTeamNum());

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles and aircraft.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 200);
		}
	}
}

void buildT2ShopCombined(CBlob@ this)
{
    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3", "Tier 3 - Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 25*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 350);
		}
	}
}

void buildT3ShopCombined(CBlob@ this)
{
}

void buildT1ShopGround(CBlob@ this)
{
    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2ground", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 200);
		}
	}
}

void buildT2ShopGround(CBlob@ this)
{
    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3ground", "Tier 3 - Ground Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 25*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 350);
		}
	}
}

void buildT3ShopGround(CBlob@ this)
{
}

void buildT1ShopAir(CBlob@ this)
{
    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert3$", "vehiclebuildert2air", "Tier 2 - Aircraft Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 150);
		}
	}
}

void buildT2ShopAir(CBlob@ this)
{
}