
void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (solid || blob is null)
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
            this.set_u32("insert_sound", getGameTime());
	    	this.add_s16(prop, requestedAmount);
        }
    }
}