#include "Requirements.as"
#include "ShopCommon.as"

void onInit(CBlob@ this)
{
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "M60 Patton", "$m60$", "m60", "Buy a m60.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", (XORRandom(12)+2));
	}

	{
		ShopItem@ s = addShopItem(this, "Technical truck", "$techtruck$", "techtruck", "Buy a techtruck.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", (XORRandom(12)+2));
	}

    {
        ShopItem@ s = addShopItem(this, "Btr82a 8x8", "$btr82a$", "btr82a", "Buy a btr.", false);
        AddRequirement(s.requirements, "coin", "", "Coins", (XORRandom(12)+2));
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
        if (callerBlob is null)
        {
            return;
        }
        /*
        if (name == "filled_bucket")
        {
            CBlob@ b = server_CreateBlobNoInit("bucket");
            b.setPosition(callerBlob.getPosition());
            b.server_setTeamNum(callerBlob.getTeamNum());
            b.Tag("_start_filled");
            b.Init();
            callerBlob.server_Pickup(b);
        }
        */

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