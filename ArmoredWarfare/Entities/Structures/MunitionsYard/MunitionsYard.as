#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "VehiclesParams.as"

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
