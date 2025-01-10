#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "VehiclesParams.as"

//Combined
void buildT1ShopCombined(CBlob@ this)
{
    this.set_Vec2f("shop size", Vec2f(4, 4));
    makeFactionArmedTransport(this, this.getTeamNum());
}

void buildT2ShopCombined(CBlob@ this)
{
}

void buildT3ShopCombined(CBlob@ this)
{
}

void buildT1ShopGround(CBlob@ this)
{
}

void buildT2ShopGround(CBlob@ this)
{
}

void buildT3ShopGround(CBlob@ this)
{
}

void buildT1ShopAir(CBlob@ this)
{
}

void buildT2ShopAir(CBlob@ this)
{
}