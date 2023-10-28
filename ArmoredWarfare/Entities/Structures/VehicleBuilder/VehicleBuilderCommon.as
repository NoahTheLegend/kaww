#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "VehiclesParams.as"

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

//Combined
void buildT1ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(10, 4));
	//title, $icon_token$, blobname, description, type (blob\coins), matname (mat_scrap), mat description

	{string[] params = {n_moto,t_moto,bn_moto,d_moto,b,s,ds};
	makeShopItem(this,params,c_moto);}

	{string[] params = {n_truck,t_truck,bn_truck,d_truck,b,s,ds};
	makeShopItem(this,params,c_truck);}

	{string[] params = {n_pszh,t_pszh,bn_pszh,d_pszh,b,s,ds};
	makeShopItem(this,params,c_pszh);}

	{string[] params = {n_btr,t_btr,bn_btr,d_btr,b,s,ds};
	makeShopItem(this,params,c_btr);}

	{string[] params = {n_m60,t_m60,bn_m60,d_m60,b,s,ds};
	makeShopItem(this,params,c_m60);}
	
	{string[] params = {n_t10,t_t10,bn_t10,d_t10,b,s,ds};
	makeShopItem(this,params,c_t10);}

	{string[] params = {n_armory,t_armory,bn_armory,d_armory,b,s,ds};
	makeShopItem(this,params,c_armory);}
	
	{string[] params = {n_bf109,t_bf109,bn_bf109,d_bf109,b,s,ds};
	makeShopItem(this,params,c_bf109);}

	{string[] params = {n_mgun,t_mgun,bn_mgun,d_mgun,b,s,ds};
	makeShopItem(this,params,c_mgun, Vec2f(1,1), false, true);}

	{string[] params = {n_jav,t_jav,bn_jav,d_jav,b,s,ds};
	makeShopItem(this,params,c_jav, Vec2f(1,1), true, false);}


	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles and aircraft.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
		}
	}
}



void buildT2ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(17, 4));

	{string[] params = {n_moto,t_moto,bn_moto,d_moto,b,s,ds};
	makeShopItem(this,params,c_moto-1);}

	{string[] params = {n_truck,t_truck,bn_truck,d_truck,b,s,ds};
	makeShopItem(this,params,c_truck-2);}

	{string[] params = {n_pszh,t_pszh,bn_pszh,d_pszh,b,s,ds};
	makeShopItem(this,params,c_pszh-3);}

	{string[] params = {n_btr,t_btr,bn_btr,d_btr,b,s,ds};
	makeShopItem(this,params,c_btr-5);}

	{string[] params = {n_m60,t_m60,bn_m60,d_m60,b,s,ds};
	makeShopItem(this,params,c_m60-5);}

	{string[] params = {n_t10,t_t10,bn_t10,d_t10,b,s,ds};
	makeShopItem(this,params,c_t10-5);}

	{string[] params = {n_maus,t_maus,bn_maus,d_maus,b,s,ds};
	makeShopItem(this,params,c_maus);}

	{string[] params = {n_armory,t_armory,bn_armory,d_armory,b,s,ds};
	makeShopItem(this,params,c_armory-5);}

	{string[] params = {n_mgun,t_mgun,bn_mgun,d_mgun,b,s,ds};
	makeShopItem(this,params,c_mgun-1, Vec2f(1,1), false, true);}

	{string[] params = {n_jav,t_jav,bn_jav,d_jav,b,s,ds};
	makeShopItem(this,params,c_jav-3, Vec2f(1,1), true, false);}

	{string[] params = {n_bf109,t_bf109,bn_bf109,d_bf109,b,s,ds};
	makeShopItem(this,params,c_bf109-5);}

	{string[] params = {n_bomber,t_bomber,bn_bomber,d_bomber,b,s,ds};
	makeShopItem(this,params,c_bomber);}

	{string[] params = {n_uh1,t_uh1,bn_uh1,d_uh1,b,s,ds};
	makeShopItem(this,params,c_uh1);}

	{string[] params = {n_barge,t_barge,bn_barge,d_barge,b,s,ds};
	makeShopItem(this,params,c_barge, Vec2f(3,2), false, true);}

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

	{string[] params = {n_moto,t_moto,bn_moto,d_moto,b,s,ds};
	makeShopItem(this,params,c_moto-2);}

	{string[] params = {n_truck,t_truck,bn_truck,d_truck,b,s,ds};
	makeShopItem(this,params,c_truck-5);}

	{string[] params = {n_pszh,t_pszh,bn_pszh,d_pszh,b,s,ds};
	makeShopItem(this,params,c_pszh-5);}

	{string[] params = {n_btr,t_btr,bn_pszh,d_btr,b,s,ds};
	makeShopItem(this,params,c_btr-10);}

	{string[] params = {n_bradley,t_bradley,bn_bradley,d_bradley,b,s,ds};
	makeShopItem(this,params,c_bradley);}

	{string[] params = {n_m60,t_m60,bn_m60,d_m60,b,s,ds};
	makeShopItem(this,params,c_m60-10);}

	{string[] params = {n_t10,t_t10,bn_t10,d_t10,b,s,ds};
	makeShopItem(this,params,c_t10-10);}

	{string[] params = {n_maus,t_maus,bn_maus,d_maus,b,s,ds};
	makeShopItem(this,params,c_maus-10);}

	{string[] params = {n_armory,t_armory,bn_armory,d_armory,b,s,ds};
	makeShopItem(this,params,c_armory-10);}

	{string[] params = {n_bf109,t_bf109,bn_bf109,d_bf109,b,s,ds};
	makeShopItem(this,params,c_bf109-10);}

	{string[] params = {n_bomber,t_bomber,bn_bomber,d_bomber,b,s,ds};
	makeShopItem(this,params,c_bomber-5);}

	{string[] params = {n_uh1,t_uh1,bn_uh1,d_uh1,b,s,ds};
	makeShopItem(this,params,c_uh1-10);}

	{string[] params = {n_ah1,t_ah1,bn_ah1,d_ah1,b,s,ds};
	makeShopItem(this,params,c_ah1);}

	{string[] params = {n_truckbig,t_truckbig,bn_truckbig,d_truckbig,b,s,ds};
	makeShopItem(this,params,c_truckbig);}

	{string[] params = {n_arti,t_arti,bn_arti,d_arti,b,s,ds};
	makeShopItem(this,params,c_arti);}

	{string[] params = {n_barge,t_barge,bn_barge,d_barge,b,s,ds};
	makeShopItem(this,params,c_barge-2, Vec2f(3,2), false, true);}
	
	{string[] params = {n_mgun,t_mgun,bn_mgun,d_mgun,b,s,ds};
	makeShopItem(this,params,c_mgun-3, Vec2f(1,1), false, true);}

	{string[] params = {n_ftw,t_ftw,bn_ftw,d_ftw,b,s,ds};
	makeShopItem(this,params,c_ftw, Vec2f(1,1), false, true);}

	{string[] params = {n_jav,t_jav,bn_jav,d_jav,b,s,ds};
	makeShopItem(this,params,c_jav-7, Vec2f(1,1), true, false);}

	{string[] params = {n_c4,t_c4,bn_c4,d_c4,b,s,ds};
	makeShopItem(this,params,c_c4, Vec2f(1,1), true, false);}
}

void buildT1ShopGround(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(8, 4));

	{string[] params = {n_moto,t_moto,bn_moto,d_moto,b,s,ds};
	makeShopItem(this,params,c_moto);}

	{string[] params = {n_truck,t_truck,bn_truck,d_truck,b,s,ds};
	makeShopItem(this,params,c_truck);}

	{string[] params = {n_pszh,t_pszh,bn_pszh,d_pszh,b,s,ds};
	makeShopItem(this,params,c_pszh);}

	{string[] params = {n_btr,t_btr,bn_btr,d_btr,b,s,ds};
	makeShopItem(this,params,c_btr);}

	{string[] params = {n_m60,t_m60,bn_m60,d_m60,b,s,ds};
	makeShopItem(this,params,c_m60);}
	
	{string[] params = {n_t10,t_t10,bn_t10,d_t10,b,s,ds};
	makeShopItem(this,params,c_t10);}

	{string[] params = {n_armory,t_armory,bn_armory,d_armory,b,s,ds};
	makeShopItem(this,params,c_armory);}

	{string[] params = {n_mgun,t_mgun,bn_mgun,d_mgun,b,s,ds};
	makeShopItem(this,params,c_mgun, Vec2f(1,1), false, true);}

	{string[] params = {n_jav,t_jav,bn_jav,d_jav,b,s,ds};
	makeShopItem(this,params,c_jav, Vec2f(1,1), true, false);}

	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert2$", "vehiclebuildert2ground", "Tier 2 - Vehicle builder.\n\nUnlocks stronger ground vehicles.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 100);
		}
	}
}



void buildT2ShopGround(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(11, 4));
	{string[] params = {n_moto,t_moto,bn_moto,d_moto,b,s,ds};
	makeShopItem(this,params,c_moto-1);}

	{string[] params = {n_truck,t_truck,bn_truck,d_truck,b,s,ds};
	makeShopItem(this,params,c_truck-2);}

	{string[] params = {n_pszh,t_pszh,bn_pszh,d_pszh,b,s,ds};
	makeShopItem(this,params,c_pszh-3);}

	{string[] params = {n_btr,t_btr,bn_btr,d_btr,b,s,ds};
	makeShopItem(this,params,c_btr-5);}

	{string[] params = {n_m60,t_m60,bn_m60,d_m60,b,s,ds};
	makeShopItem(this,params,c_m60-5);}

	{string[] params = {n_t10,t_t10,bn_t10,d_t10,b,s,ds};
	makeShopItem(this,params,c_t10-5);}

	{string[] params = {n_maus,t_maus,bn_maus,d_maus,b,s,ds};
	makeShopItem(this,params,c_maus);}

	{string[] params = {n_armory,t_armory,bn_armory,d_armory,b,s,ds};
	makeShopItem(this,params,c_armory-5);}

	{string[] params = {n_mgun,t_mgun,bn_mgun,d_mgun,b,s,ds};
	makeShopItem(this,params,c_mgun-1, Vec2f(1,1), false, true);}

	{string[] params = {n_jav,t_jav,bn_jav,d_jav,b,s,ds};
	makeShopItem(this,params,c_jav-3, Vec2f(1,1), true, false);}

	{string[] params = {n_barge,t_barge,bn_barge,d_barge,b,s,ds};
	makeShopItem(this,params,c_barge, Vec2f(3,2), false, true);}

	{
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 3", "$vehiclebuildert3$", "vehiclebuildert3ground", "Tier 3 - Ground Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 2;
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
	{string[] params = {n_moto,t_moto,bn_moto,d_moto,b,s,ds};
	makeShopItem(this,params,c_moto-2);}

	{string[] params = {n_truck,t_truck,bn_truck,d_truck,b,s,ds};
	makeShopItem(this,params,c_truck-5);}

	{string[] params = {n_pszh,t_pszh,bn_pszh,d_pszh,b,s,ds};
	makeShopItem(this,params,c_pszh-5);}

	{string[] params = {n_btr,t_btr,bn_pszh,d_btr,b,s,ds};
	makeShopItem(this,params,c_btr-10);}

	{string[] params = {n_bradley,t_bradley,bn_bradley,d_bradley,b,s,ds};
	makeShopItem(this,params,c_bradley);}

	{string[] params = {n_m60,t_m60,bn_m60,d_m60,b,s,ds};
	makeShopItem(this,params,c_m60-10);}

	{string[] params = {n_t10,t_t10,bn_t10,d_t10,b,s,ds};
	makeShopItem(this,params,c_t10-10);}

	{string[] params = {n_maus,t_maus,bn_maus,d_maus,b,s,ds};
	makeShopItem(this,params,c_maus-10);}

	{string[] params = {n_armory,t_armory,bn_armory,d_armory,b,s,ds};
	makeShopItem(this,params,c_armory-10);}

	{string[] params = {n_truckbig,t_truckbig,bn_truckbig,d_truckbig,b,s,ds};
	makeShopItem(this,params,c_truckbig, Vec2f(3,2));}

	{string[] params = {n_arti,t_arti,bn_arti,d_arti,b,s,ds};
	makeShopItem(this,params,c_arti, Vec2f(3,2));}

	{string[] params = {n_barge,t_barge,bn_barge,d_barge,b,s,ds};
	makeShopItem(this,params,c_barge-2, Vec2f(4,2), false, true);}
	
	{string[] params = {n_mgun,t_mgun,bn_mgun,d_mgun,b,s,ds};
	makeShopItem(this,params,c_mgun-3, Vec2f(1,1), false, true);}

	{string[] params = {n_ftw,t_ftw,bn_ftw,d_ftw,b,s,ds};
	makeShopItem(this,params,c_ftw, Vec2f(1,1), false, true);}

	{string[] params = {n_jav,t_jav,bn_jav,d_jav,b,s,ds};
	makeShopItem(this,params,c_jav-7, Vec2f(1,1), true, false);}

	{string[] params = {n_c4,t_c4,bn_c4,d_c4,b,s,ds};
	makeShopItem(this,params,c_c4, Vec2f(1,1), true, false);}
}

void buildT1ShopAir(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(11, 2));

    {string[] params = {n_bf109,t_bf109,bn_bf109,d_bf109,b,s,ds};
	makeShopItem(this,params,c_bf109, Vec2f(5,2));}

	{string[] params = {n_bomber,t_bomber,bn_bomber,d_bomber,b,s,ds};
	makeShopItem(this,params,c_bomber, Vec2f(5,2));}

    {
		ShopItem@ s = addShopItem(this, "Upgrade to Tier 2", "$vehiclebuildert3$", "vehiclebuildert2air", "Tier 2 - Aircraft Vehicle builder.\n\nUnlocks more specific vehicles for late-game.", false, false);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 2;
		
		if (this.getName().findLast("const", -1) != -1) AddRequirement(s.requirements, "blob", "chest", "You can't upgrade it on this map!\n", 1);
		else
		{
			AddRequirement(s.requirements, "gametime", "", "Unlocks at", 10*30 * 60);
			AddRequirement(s.requirements, "blob", "mat_scrap", "Scrap", 125);
		}
	}
}

void buildT2ShopAir(CBlob@ this)
{
    this.set_Vec2f("shop menu size", Vec2f(10, 4));
    
	{string[] params = {n_bf109,t_bf109,bn_bf109,d_bf109,b,s,ds};
	makeShopItem(this,params,c_bf109-10, Vec2f(5,2));}

	{string[] params = {n_bomber,t_bomber,bn_bomber,d_bomber,b,s,ds};
	makeShopItem(this,params,c_bomber-10, Vec2f(5,2));}

	{string[] params = {n_uh1,t_uh1,bn_uh1,d_uh1,b,s,ds};
	makeShopItem(this,params,c_uh1-10);}

	{string[] params = {n_ah1,t_ah1,bn_ah1,d_ah1,b,s,ds};
	makeShopItem(this,params,c_ah1);}
}