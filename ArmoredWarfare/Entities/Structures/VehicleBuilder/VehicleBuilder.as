#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "GenericButtonCommon.as"
#include "VehicleBuilderCommon.as"
#include "ProgressBar.as"
#include "MakeDustParticle.as"

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(-50); //background

	//INIT COSTS
	InitCosts();
	
	if (this.getName().findFirst("t3", 0) != -1)
	{
		this.SetLightRadius(128.0f);
		this.SetLightColor(SColor(255, 255, 155, 0));
		this.SetLight(true);
	}

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 15);
	this.Tag(SHOP_AUTOCLOSE);

	this.Tag("ignore_arrow");
	this.Tag("builder always hit");
	this.Tag("structure");
	this.Tag("team use only");

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_ft$", "IconFT.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","JavelinLauncher.png", Vec2f(32, 16), 2, 2);

	string name = this.getName();

	//Combined
	if (name == "vehiclebuilder" || name == "vehiclebuilderconst")
		buildT1ShopCombined(this);
	else if (name == "vehiclebuildert2" || name == "vehiclebuildert2const")
		buildT2ShopCombined(this);
	else if (name == "vehiclebuildert3")
		buildT3ShopCombined(this);
	//Ground only
	if (name == "vehiclebuilderground" || name == "vehiclebuildergroundconst")
		buildT1ShopGround(this);
	else if (name == "vehiclebuildert2ground" || name == "vehiclebuildert2groundconst")
		buildT2ShopGround(this);
	else if (name == "vehiclebuildert3ground" || name == "vehiclebuildert3groundconst")
		buildT3ShopGround(this);
	//Air only
	if (name == "vehiclebuilderair" || name == "vehiclebuilderairconst")
		buildT1ShopAir(this);
	else if (name == "vehiclebuildert2air" || name == "vehiclebuildert2airconst")
		buildT2ShopAir(this);
	//Defensives only
	if (name =="vehiclebuilderdefense" || name == "vehiclebuilderdefenseconst")
		buildT1ShopDefense(this);
	else if (name == "vehiclebuildert2defense" || name == "vehiclebuildert2defenseconst")
		buildT2ShopDefense(this);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("projectile") && blob.getTeamNum() != this.getTeamNum())
		return true;
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum()) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onTick(CBlob@ this)
{
	ConstructionEffects(this);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", caller.getTeamNum() == this.getTeamNum());
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/UpgradeT2.ogg" );
		
		bool isServer = (getNet().isServer());
			
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		CBlob@ blob = getBlobByNetworkID( caller );
		CBlob@ purchase = getBlobByNetworkID( item );
		Vec2f pos = this.getPosition();
		
		string name = params.read_string();

		if (isServer && name == "maus")
		{
			if (blob.getPlayer() !is null && (blob.getPlayer().getSex() == 1 || blob.getSexNum() == 1))
			{
				CBlob@ newblob = server_CreateBlob("pinkmaus", purchase.getTeamNum(), this.getPosition());
				if (newblob !is null)
				{
					purchase.Tag("dead");
					purchase.server_Die();
				}
			}
			else if (getBlobByName("info_desert") !is null)
			{
				CBlob@ newblob = server_CreateBlob("desertmaus", purchase.getTeamNum(), this.getPosition());
				if (newblob !is null)
				{
					purchase.Tag("dead");
					purchase.server_Die();
				}
			}
		}
		
		if (name.find("vehiclebuilder") != -1)
		{
			this.server_Die();
			if (blob.isMyPlayer()) blob.ClearMenus();
		}
	}
}

void ConstructionEffects(CBlob@ this)
{
	if (this.get_bool("constructing") && getMap() !is null)
	{
		CBlob@[] overlapping;
		getMap().getBlobsInBox(this.getPosition()-Vec2f(32, 16), this.getPosition()+Vec2f(32, 16), @overlapping);

		bool has_caller = false;
		s8 caller_team = -1;
		s8 count = -1;
		for (u16 i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			if (blob is null || blob.isAttached() || blob.hasTag("dead"))
					continue;

			if (blob.getNetworkID() == this.get_u16("builder_id"))
			{
				has_caller = true;
				caller_team = blob.getTeamNum();
			}
		}

		for (u16 i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			if (blob is null || blob.isAttached() || blob.hasTag("dead"))
					continue;

			if (caller_team == blob.getTeamNum() && blob.hasTag("player"))
			{
				count++;
			}
		}

		if (has_caller)
		{
			if (isClient() && getGameTime()%25==0)
			{
				this.add_u32("step", 1);
				if (this.get_u32("step") > 2) this.set_u32("step", 0);

				if (XORRandom(4)==0) this.set_u32("step", XORRandom(3));

				u8 rand = XORRandom(5);
				for (u8 i = 0; i < rand; i++)
				{
					MakeDustParticle(this.getPosition()+Vec2f(XORRandom(24)-12, XORRandom(16)), XORRandom(5)<2?"Smoke.png":"dust2.png");
					
					if (XORRandom(3) != 0)
					{
						CParticle@ p = makeGibParticle("WoodenGibs.png", this.getPosition()+Vec2f(XORRandom(24)-12, XORRandom(16)), Vec2f(0, (-1-XORRandom(3))).RotateBy(XORRandom(61)-30.0f), XORRandom(16), 0, Vec2f(8, 8), 1.0f, 0, "", 7);
					}
				}

				this.getSprite().PlaySound("Construct"+(this.get_u32("step")+1), 0.6f+XORRandom(11)*0.01f, 0.95f+XORRandom(6)*0.01f);
			}
		}
		this.add_f32("construct_time", has_caller || this.get_f32("construct_time") / this.get_u32("construct_endtime") > 0.975f ? 1 + count : -1);
		
		if (this.get_f32("construct_time") <= 0)
		{
			this.set_f32("construct_time", 0);
			this.set_string("constructing_name", "");
			this.set_s8("constructing_index", 0);
			this.set_bool("constructing", false);

			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				if (hasBar(bars, "construct"))
				{
					bars.RemoveBar("construct", false);
				}
			}
		}
	}
}