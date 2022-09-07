#include "Requirements.as"
#include "ShopCommon.as"

void onInit(CBlob@ this)
{
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(3, 4));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Stone", "$mat_stone$", "mat_stone", "Buy 250 Stone.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", (XORRandom(12)+30));
	}

	{
		ShopItem@ s = addShopItem(this, "Scorpion in a Vase", "$scorpionvase$", "scorpionvase", "Buy a scorpion in a vase.", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", (XORRandom(8)+30));
	}

	this.set_u8("spriteType", 0);
	this.server_setTeamNum(-1);
	this.Tag("flesh");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("messageChat"))
	{
		this.Chat(params.read_string());
	}
    if (cmd == this.getCommandID("shop made item"))
    {
        if (!isServer())//Is client?
        {
            if (XORRandom(2) == 0) 
            {
                this.getSprite().PlaySound("MigrantHmm");
            }
            this.getSprite().PlaySound("ChaChing");
            
            return;//Don't go any further
        }
        
        //Server only past here
        u16 caller, item;
        if(!params.saferead_netid(caller) || !params.saferead_netid(item))
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