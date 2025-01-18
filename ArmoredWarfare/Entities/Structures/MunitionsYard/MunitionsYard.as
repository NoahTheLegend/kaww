#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "VehiclesParams.as"
#include "ProgressBar.as"
#include "MakeDustParticle.as"

void onInit(CBlob@ this)
{
	InitCosts(); //read from cfg

	//this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-150); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(6, 4));
	this.set_string("shop description", "Craft Equipment");
	this.set_u8("shop icon", 21);
	this.Tag(SHOP_AUTOCLOSE);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_ft$", "IconFT.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","JavelinLauncher.png", Vec2f(32, 16), 2, 2);
	AddIconToken("$icon_barge$","IconBarge.png", Vec2f(32, 32), 0, 2);
}

void InitShop(CBlob@ this)
{
	this.set_Vec2f("shop offset", Vec2f(-18, 0));

	if (isCTF()) this.set_Vec2f("shop menu size", Vec2f(9, 3));
	else 		 this.set_Vec2f("shop menu size", Vec2f(9, 3));

	makeDefaultAmmo(this);
	makeDefaultExplosives(this);
	makeDefaultGear(this);
	makeDefaultUtils(this);
	makeExtraUtils(this);
	makeSmallBombs(this);
	makeC4(this);
	makeFactionVehicle(this, this.getTeamNum(), VehicleType::weapons1, 0, false, true);
	makeMortar(this);
	makeFactionVehicle(this, this.getTeamNum(), VehicleType::machinegun, 0, false, true);
	makeFirethrower(this);
	makeBigBombs(this);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1) InitShop(this);
	ConstructionEffects(this);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f_zero);

	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		if (this.get_u32("next_tick") > getGameTime()) return;
		this.set_u32("next_tick", getGameTime()+1);
		this.getSprite().PlaySound("/ChaChing.ogg");

		if (!getNet().isServer()) return; /////////////////////// server only past here

        u16 caller, item;
        if (!params.saferead_netid(caller) || !params.saferead_netid(item))
        {
            return;
        }
        string name = params.read_string();
        CBlob@ callerBlob = getBlobByNetworkID(caller);
        if (callerBlob is null){
            return;
        }
        string[] spl = name.split("-");
        if (spl[0] == "coin")
        {
            CPlayer@ callerPlayer = callerBlob.getPlayer();
            if (callerPlayer is null){
                return;
            }
            callerPlayer.server_setCoins(callerPlayer.getCoins() + parseInt(spl[1]));
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