#include "Hitters.as";

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(50);
	
	this.getShape().getConsts().mapCollisions = false;

	this.getCurrentScript().tickFrequency = 60;

	this.Tag("builder always hit");
	this.Tag("structure");
}

void onTick(CBlob@ this)
{
	if (isServer() && this.getTickSinceCreated() == 180 && getGameTime() <= 210)
	{
		CMap@ map = this.getMap();
		if (map !is null)
		{//dont rotate it depending on side after constructing map
			this.server_setTeamNum(this.getPosition().x > map.tilemapwidth*4 ? 1 : 0);
			this.SetFacingLeft(this.getPosition().x > map.tilemapwidth*4);
		}
	}

    float repair_distance = 16.0f; //Distance from this blob where other blobs are repaired
    float repair_amount = 1.2f;   //Amount the blob is repaired every 15 ticks

    array<CBlob@> blobs;//Blob array full of blobs
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition(), repair_distance, blobs);//Put the blobs within the repair distance into the "blobs" array

    for (u16 i = 0; i < blobs.size(); i++)//For every blob in this array
    {
        if (blobs[i].hasTag("vehicle") && (blobs[i].getTeamNum() == this.getTeamNum())) //If they have the repair tag
        {
			if (blobs[i].getHealth() == blobs[i].getInitialHealth()) continue;
			if (blobs[i].get_u32("no_heal") > getGameTime()) continue; 
            if (blobs[i].getHealth() + repair_amount <= blobs[i].getInitialHealth())//This will only happen if the health does not go above the inital (max health) when repair_amount is added. 
            {
                blobs[i].server_SetHealth(blobs[i].getHealth() + repair_amount); //Add the repair amount.
				blobs[i].set_u32("no_heal", getGameTime() + 60);

                if (XORRandom(2) == 0)
                {
                	this.getSprite().PlaySound("RepairVehicle.ogg");
                }
                else
                {
                	this.getSprite().PlaySound("RepairVehicle2.ogg");
                }

            	const Vec2f pos = blobs[i].getPosition() + getRandomVelocity(0, blobs[i].getRadius()*0.3f, 360);
				CParticle@ p = ParticleAnimated("SparkParticle.png", pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), 0.0f, false);
				if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

				Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
				velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

				ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);

				break;
            }
            else //Repair amount would go above the inital health (max health). 
            {
                blobs[i].server_SetHealth(blobs[i].getInitialHealth());//Set health to the inital health (max health)
            }
        }
    }
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum()) damage *= 2;
	switch (customData)
	{
     	case Hitters::builder:
			damage *= 3.00f;
			break;
	}
	if (hitterBlob.getName() == "grenade")
	{
		return damage * 1.5;
	}
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum() || blob.hasTag("vehicle")) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onDie(CBlob@ this)
{
	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());
}