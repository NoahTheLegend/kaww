#include "Hitters.as";
#include "KnockedCommon.as";

void onInit(CSprite@ this)
{
	this.getBlob().getShape().SetRotationsAllowed(false);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	this.SetAnimation("default");
}

void onInit(CBlob@ this)
{
	this.Tag("door");


	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
}

void onTick(CBlob@ this)
{
    array<CBlob@> blobs;
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition(), 9.0f, blobs);    

    if (!this.hasTag("linked"))
    {
    	this.Tag("linked");

    	CBlob@[] doors;
		if (getBlobsByTag("door", @doors))
		{
			for (uint i = 0; i < doors.length; i++)
			{
				CBlob@ mydoor = doors[i];
				
				if (mydoor !is null)
				{
					if (mydoor.getTeamNum() == this.getTeamNum())
					{
						if (mydoor.getNetworkID() != this.getNetworkID())
						{
							this.set_Vec2f("linkPos", mydoor.getPosition());
						}
					}
				}
			}
		}
    }

    this.Untag("helptext");

    for (u16 i = 0; i < blobs.size(); i++)
    {
        if (blobs[i].hasTag("player"))
        {
        	if (!isKnocked(blobs[i]))
        	{
	        	this.Tag("helptext");

	        	if (blobs[i].isKeyJustPressed(key_down))
	        	{
	        		blobs[i].setPosition(this.get_Vec2f("linkPos"));

	        		if (blobs[i].isMyPlayer())
	        		{
	        			SetScreenFlash(255, 0, 0, 0, 1.4);
	        		}

	        		blobs[i].getSprite().PlaySound("/DoorOpen.ogg");

	        		if (isKnockable(blobs[i]))
					{
						//if you travel, you lose invincible
						blobs[i].Untag("invincible");
						blobs[i].Sync("invincible", true);

						//actually do the knocking
						setKnocked(blobs[i], 26, true);
					}
	        	}
        	}
        }
    }
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("helptext"))
	{
		return;
	}

	if (!isClient())
	{
		return;
	}
	

	const f32 scalex = getDriver().getResolutionScaleFactor();
	const f32 zoom = getCamera().targetDistance * scalex;

	Vec2f pos2d =  blob.getInterpolatedScreenPos() + Vec2f(0.0f, (-blob.getHeight() - 20.0f) * zoom);

	GUI::SetFont("menu");
	GUI::DrawShadowedText("Press S to enter", Vec2f(pos2d.x - 60, pos2d.y), SColor(0xffffffff));
}