#include "Hitters.as"
#include "HittersAW.as"

void onInit(CBlob@ this)
{
    this.set_u32("damage_succession_reset", 0);
    this.set_f32("damage_succession_multi", 0);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (solid || blob is null)
	{
		return;
	}

    if (blob.exists("inserted") && blob.get_u32("inserted") > getGameTime())
    {
        return;
    }

    if (this.hasTag("refinery") && blob.hasTag("material"))
    {
        bool die = false;
        int max = 500;
        int requestedAmount;
        string prop = "stone_level";
        string mat = "mat_stone";

        if (this.getName() == "refinery")
        {
            //default is refinery
            if (blob.getName() != "mat_stone") return;
        }
        else if (this.getName() == "advancedrefinery")
        {
            mat = "mat_gold";
            max = 200;
            if (blob.getName() != "mat_gold") return;
        }
        else // quarry
        {
            mat = "mat_wood";
            max = 1000;
            prop = "fuel_level";
            if (blob.getName() != "mat_wood") return;
        }  
    
        if (this.get_s16(prop) + blob.getQuantity() <= max)
        {
            requestedAmount = blob.getQuantity();
            die = true;
        }
        else requestedAmount = max-this.get_s16(prop);
        int ammount = Maths::Min(requestedAmount, blob.getQuantity());
	    if (requestedAmount > 0)
	    {
            if (isServer())
            {
	    	    if (die) blob.server_Die();
                else blob.server_SetQuantity(Maths::Max(0, blob.getQuantity()-requestedAmount));
            }
            if (this.get_u32("insert_sound")+10 < getGameTime())
            {
                //if (this.get_s16(prop) == 0) this.getSprite().PlaySound("lightup.ogg"); // already activated in refinery script
                this.getSprite().PlaySound("FireFwoosh.ogg");
            }
            blob.set_u32("inserted", getGameTime()+1);
            this.set_u32("insert_sound", getGameTime());
	    	this.add_s16(prop, requestedAmount);
        }
    }
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
     	case Hitters::builder:
        {
            f32 extra = 0.0f + this.get_f32("damage_succession_multi");

            if (this.get_u32("damage_succession_reset") < getGameTime())
            {
                this.set_f32("damage_succession_multi", 0);
                extra = 0.5f;
            }

            this.set_u32("damage_succession_reset", getGameTime()+30);
            this.set_f32("damage_succession_multi", Maths::Min(16, this.get_f32("damage_succession_multi")+2));

            damage *= extra;
			break;
        }
	}
	if (hitterBlob.hasTag("atgrenade") || hitterBlob.getName() == "c4")
	{
		return damage * 2.5f;
	}
	return damage;
}