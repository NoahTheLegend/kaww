#include "Hitters.as"

void onInit(CBlob@ this)
{
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

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	f32 dmg = damage/2;

	if (isExplosionHitter(customData) || customData == Hitters::keg)
	{
		if (customData == Hitters::keg)
		{
			dmg = Maths::Max(dmg, this.getInitialHealth() * 2); // Keg always kills crate
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
        "mat_bolts"
    };
    array<float> _chances =
    {
        0.7,
        0.25,
        0.25,
        0.01,

        0.08,
        0.08,
        0.02,
        0.03,
        0.02,
        0.01
    };
    array<u8> _amount =
    {
        (XORRandom(5)+2),
        (XORRandom(6)+1)*20,
        (XORRandom(4)+1)*20,
        50,

        1,
        1,
        1,
        1,
        1,
        1,
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