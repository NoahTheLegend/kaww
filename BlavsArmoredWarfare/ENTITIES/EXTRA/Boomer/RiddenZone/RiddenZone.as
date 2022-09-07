#include "Hitters.as";

const float hurt_distance = 50.0f;

void onInit(CBlob@ this)
{
	this.getSprite().SetEmitSound("CampfireSound.ogg");

	this.server_SetTimeToDie(45.0f);

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0);

	this.getCurrentScript().tickFrequency = 5;
}

void onTick(CBlob@ this)
{
    array<CBlob@> blobs;
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition(), hurt_distance, blobs);

    for (u16 i = 0; i < blobs.size(); i++)
    {
        if (blobs[i].hasTag("player"))
        {
            this.server_Hit(blobs[i], blobs[i].getPosition(), Vec2f_zero, 0.3f, Hitters::drown);

            if (blobs[i].isMyPlayer())
		    {
		        SetScreenFlash( 100, 150, 0, 0, 10.0f);
		        ShakeScreen(200, 200, this.getInterpolatedPosition());
		    }
        }
        else if (blobs[i].hasTag("zombie"))
        {
        	blobs[i].server_Heal(0.5f);

        	ParticleAnimated("BloodSplatBigger.png", blobs[i].getPosition(), Vec2f_zero, float(XORRandom(360)), 1.0f + XORRandom(100) * 0.01f, 4, XORRandom(100) * -0.00005f, true);
        }
    }

    for (u16 i = 0; i < 4; i++)
    {
    	ParticleAnimated("BloodSplatBigger.png", this.getPosition() + Vec2f(XORRandom(100) - 50, XORRandom(100) - 50), Vec2f_zero, float(XORRandom(360)), 0.6f + XORRandom(200) * 0.01f, 4 + XORRandom(10), XORRandom(100) * -0.00005f, true);
	}
}