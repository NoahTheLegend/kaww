#define SERVER_ONLY

#include "KnockedCommon.as"
#include "EatCommon.as";
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

bool canHeal(CBlob@ this)
{
	if (this.getPlayer() is null) return true;
	if (getRules() !is null && hasPerk(this.getPlayer(), Perks::bloodthirsty))
		return false;

	return true;
}

void onTick(CBlob@ this)
{
	if (isServer() &&
		this.isKeyJustPressed(key_eat) &&
		!isKnocked(this) &&
		this.getHealth() < this.getInitialHealth()
	) {
        if (this.get_u32("regen") <= getGameTime() && canHeal(this))
        {
		    CBlob @carried = this.getCarriedBlob();
		    if (carried !is null && canEat(carried)) // consume what is held
		    {
		    	Heal(this, carried);
		    }
		    else // search in inventory
		    {
		    	CInventory@ inv = this.getInventory();

		    	// build list of all eatables
		    	CBlob@[] eatables;
		    	for (int i = 0; i < inv.getItemsCount(); i++)
		    	{
		    		CBlob @blob = inv.getItem(i);
		    		if (canEat(blob))
		    		{
		    			eatables.insertLast(blob);
		    		}
		    	}

		    	if (eatables.length() == 0) // nothing to eat
		    	{
		    		return;
		    	}

		    	// find the most appropriate food to eat
		    	CBlob@ bestFood;
		    	u8 bestHeal = 0;
		    	for (int i = 0; i < eatables.length(); i++)
		    	{
		    		CBlob@ food = eatables[i];
		    		u8 heal = getHealingAmount(food);
		    		int missingHealth = int(Maths::Ceil(this.getInitialHealth() - this.getHealth()) * 4);

		    		if (heal < missingHealth && (bestFood is null || bestHeal < heal ) )
		    		{
		    			@bestFood = food;
		    			bestHeal = heal;
		    		}
		    		else if (heal >= missingHealth && (bestFood is null || bestHeal < missingHealth || bestHeal > heal))
		    		{
		    			@bestFood = food;
		    			bestHeal = heal;
		    		}
		    	}

		    	Heal(this, bestFood);
		    }
        }
        else
        {
            // TODO, add a sound effect, note that this is serverside only and you'll need to send a command for that
        }
	}
}
