#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "GenericButtonCommon.as"
#include "VehicleBuilderCommon.as"

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
	this.set_string("shop description", "Construct Ground Vehicle");
	this.set_u8("shop icon", 15);

	this.Tag("ignore_arrow");
	this.Tag("builder always hit");

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","IconJav.png", Vec2f(32, 32), 0, 2);

	//Combined
	if (this.getName() == "vehiclebuilder" || this.getName() == "vehiclebuilderconst")
		buildT1ShopCombined(this);
	else if (this.getName() == "vehiclebuildert2" || this.getName() == "vehiclebuildert2const")
		buildT2ShopCombined(this);
	else if (this.getName() == "vehiclebuildert3" || this.getName() == "vehiclebuildert3const")
		buildT3ShopCombined(this);
	//Ground only
	if (this.getName() == "vehiclebuilderground" || this.getName() == "vehiclebuildergroundconst")
		buildT1ShopGround(this);
	else if (this.getName() == "vehiclebuildert2ground" || this.getName() == "vehiclebuildert2groundconst")
		buildT2ShopGround(this);
	else if (this.getName() == "vehiclebuildert3ground" || this.getName() == "vehiclebuildert3groundconst")
		buildT3ShopGround(this);
	//Air only
	if (this.getName() == "vehiclebuilderair" || this.getName() == "vehiclebuilderairconst")
		buildT1ShopAir(this);
	else if (this.getName() == "vehiclebuildert2air" || this.getName() == "vehiclebuildert2airconst")
		buildT2ShopAir(this);
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
		CBlob@ tree;
		Vec2f pos = this.getPosition();
		
		string name = params.read_string();
		
		if (name == "vehiclebuildert2" || name == "vehiclebuildert3"
		|| name == "vehiclebuildert2ground" || name == "vehiclebuildert3ground"
		|| name == "vehiclebuildert2air")
		{
			this.server_Die();
			if (blob.isMyPlayer()) blob.ClearMenus();
		}
	}
}