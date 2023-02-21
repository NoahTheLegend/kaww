#include "Hitters.as"
#include "HoverMessage.as";

void onInit(CBlob@ this)
{
    this.Tag("trap");
	this.getSprite().SetZ(-10.0f);
}

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	u16 netID = blob.getNetworkID();
	this.animation.frame = (netID % this.animation.getFramesCount());
	this.SetFacingLeft(((netID % 13) % 2) == 0);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage/2;

    if (isServer() && XORRandom(10) == 0 && hitterBlob !is null
	&& hitterBlob.getPlayer() !is null)
	{
		u8 exp_reward = XORRandom(2)+1;
		CBitStream params;
		params.write_u8(exp_reward);

		getRules().add_u32(this.getPlayer().getUsername() + "_exp", exp_reward);
		getRules().Sync(this.getPlayer().getUsername() + "_exp", true);
		hitterBlob.server_SendCommandToPlayer(hitterBlob.getCommandID("addxp_universal"), params, hitterBlob.getPlayer());
	}

    if (hitterBlob !is null && hitterBlob.getTeamNum() != this.getTeamNum() && hitterBlob.hasTag("player"))
	{
		if (hitterBlob.getPlayer() !is null && getRules().get_string(hitterBlob.getPlayer().getUsername() + "_perk") == "Field Engineer")
		{
			return damage;
		}
	}

	if (isExplosionHitter(customData) || customData == Hitters::keg)
	{
		if (customData == Hitters::keg)
		{
			dmg = Maths::Max(dmg, this.getInitialHealth() * 2); // Keg always kills crate
		}
	}

    if (isServer() && dmg/2 >= this.getHealth())
    {
        CRules@ rules = getRules();
        if (rules !is null && hitterBlob.hasTag("player"))
        {
            u8 exp_reward = XORRandom(3);
            CPlayer@ killer = hitterBlob.getPlayer();
            if (killer !is null)
            {
                rules.add_u32(killer.getUsername() + "_exp", exp_reward);
		        rules.Sync(killer.getUsername() + "_exp", true);

                if(getLocalPlayer() !is null
				&& killer is getLocalPlayer())
				{
					add_message(ExpMessage(exp_reward));
				}
            }
        }
    }

	return dmg;
}

void onDie(CBlob@ this)
{
    if (this.hasTag("despawned")) return;

    this.getSprite().Gib();

    // Drop loot on break

    array<string> _items =
    {
    	"mat_scrap", //common
        "mat_wood",
        "mat_stone",
        "mat_gold", //rare

    	"grenade",
    	"helmet",
    	"medkit",
        "food",
        "mat_7mmround",
        "mat_14mmround",
        "mat_bolts",
        "mat_heatwarhead"
    };
    array<float> _chances =
    {
        0.5,
        0.5,
        0.5,
        0.025,

        0.03,
        0.05,
        0.03,
        0.04,
        0.03,
        0.02,
        0.01,
        0.01
    };
    array<u8> _amount =
    {
        (XORRandom(3)+1),
        (XORRandom(8)+6)*10,
        (XORRandom(8)+3)*10,
        20 + (XORRandom(26)*2),

        1,
        1,
        1,
        1,
        50+(XORRandom(2)==0?50:0),
        15,
        4,
        1
    };

    if (getNet().isServer())
    {
    	for (int i = 0; i < 2; i++)
		{
	        u32 element = RandomWeightedPicker(_chances, XORRandom(1000));
	        CBlob@ b = server_CreateBlob(_items[element],-1,this.getPosition());  
	        b.AddForce(Vec2f((XORRandom(5)-2)/1.3, -5));  
	        if (b.getMaxQuantity() > 1)
	        {
	            b.server_SetQuantity(_amount[element]);
	        }
    	}
    }
}

shared u32 RandomWeightedPicker(array<float> chances, u32 seed = 0)
{
    if (seed == 0) {seed = (getGameTime() * 404 + 1337 - Time_Local());}

    u32 i;
    float sum = 0.0f;

    for (i = 0; i < chances.size(); i++) {sum += chances[i];}

    Random@ rnd = Random(seed);//Random with seed

    float random_number = (rnd.Next() + rnd.NextFloat()) % sum;//Get our random number between 0 and the sum

    float current_pos = 0.0f;//Current pos in the bar

    for (i = 0; i < chances.size(); i++)//For every chance
    {
        if(current_pos + chances[i] > random_number)
        {
            break;//Exit out with i untouched
        }
        else//Random number has not yet reached the chance
        {
            current_pos += chances[i];//Add to current_pos
        }
    }

    return i;//Return the chance that was got
}