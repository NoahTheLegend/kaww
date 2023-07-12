#include "Hitters.as";
#include "HittersAW.as";

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(50);
	
	this.getShape().getConsts().mapCollisions = false;

	this.getCurrentScript().tickFrequency = 60;

	this.Tag("builder always hit");
	this.Tag("structure");

	//if (this.getPosition().x < getMap().tilemapwidth * 8.0f / 2)
	//{
	//	this.server_setTeamNum(0);
	//}
	//else{
	//	this.server_setTeamNum(1);
	//}
}

void onTick(CBlob@ this)
{
	//if (isServer() && this.getTickSinceCreated() == 180 && getGameTime() <= 210)
	//{
	//	CMap@ map = this.getMap();
	//	if (map !is null)
	//	{//dont rotate it depending on side after constructing map
	//		this.server_setTeamNum(this.getPosition().x > map.tilemapwidth*4 ? 1 : 0);
	//		this.SetFacingLeft(this.getPosition().x > map.tilemapwidth*4);
	//	}
	//}

    float repair_distance = 16.0f;
    float repair_amount = 1.2f;  

	f32 weakest = 999.0f;
	u16 blobid = 0;

    array<CBlob@> blobs;//Blob array full of blobs
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition(), repair_distance, blobs);

    for (u16 i = 0; i < blobs.size(); i++)
    {
		CBlob@ blob = blobs[i];

        if (blob.hasTag("vehicle") && (blob.getTeamNum() == this.getTeamNum() || blob.getTeamNum() >= 7))
        {
			//printf(blob.getName()+" "+(blob.getHealth()/blob.getInitialHealth()));
			if (blob.getHealth()/blob.getInitialHealth() >= weakest) continue;
			if (blob.hasTag("never_repair")) continue;
			if (blob.getHealth() == blob.getInitialHealth()) continue;
			if (blob.get_u32("no_heal") > getGameTime()) continue; 
            
			weakest = blob.getHealth()/blob.getInitialHealth();
			blobid = blob.getNetworkID();

			if (blob.hasTag("importantarmory"))
			{
				repair_amount *= 0.33f;
			}
        }
    }

	CBlob@ repair_blob = getBlobByNetworkID(blobid);
	if (repair_blob !is null)
	{
		//printf(""+weakest);
		if (repair_blob.getHealth() + repair_amount <= repair_blob.getInitialHealth())
        {
			repair_blob.server_SetHealth(repair_blob.getHealth() + repair_amount); //Add the repair amount.
			repair_blob.set_u32("no_heal", getGameTime() + 60);
			if (repair_amount > 2.0f)
			{
				this.getSprite().PlayRandomSound("RepairVehicle.ogg", 1.2f, 0.7f + XORRandom(10) * 0.01f);
			}
			else
			{
				this.getSprite().PlayRandomSound("RepairVehicle.ogg", 1.2f, 0.9f + XORRandom(20) * 0.01f);
			}
			    
        	const Vec2f pos = repair_blob.getPosition() + getRandomVelocity(0, repair_blob.getRadius()*0.3f, 360);
			CParticle@ p = ParticleAnimated("SparkParticle.png", pos, Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), 0.0f, false);
			if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }
			Vec2f velr = getRandomVelocity(!this.isFacingLeft() ? 70 : 110, 4.3f, 40.0f);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;
			ParticlePixel(pos, velr, SColor(255, 255, 255, 0), true);
		}
        else
        {
            repair_blob.server_SetHealth(repair_blob.getInitialHealth());
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
	if (hitterBlob.hasTag("atgrenade") || hitterBlob.getName() == "c4")
	{
		return damage * 2.0f;
	}
	return damage;
}

void onDie(CBlob@ this)
{
	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());
}