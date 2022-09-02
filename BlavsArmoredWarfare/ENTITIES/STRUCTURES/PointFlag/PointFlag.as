const string capture_prop = "capture time";
const string isbluecapture = "capture team";

const u16 capture_time = 650;

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;

	this.set_u16(capture_prop, 0);
	this.set_bool(isbluecapture, false); //false is red, true is blue, this is also a commentary on the nature of good and evil, and colors.
	this.set_u8("numcapping", 0);
}

void onTick(CBlob@ this)
{
    float capture_distance = 64.0f; //Distance from this blob that it can be cpaped

    u8 num_blue = 0;
    u8 num_red = 0;

    array<CBlob@> blobs; //Blob array full of blobs
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition() + Vec2f(4.0f,0.0f), capture_distance, blobs);

    for (u16 i = 0; i < blobs.size(); i++)
    {
        if (blobs[i].hasTag("player") && !blobs[i].hasTag("dead")) // Only players
        {
        	if (blobs[i].getTeamNum() == 0)
        	{
        		num_blue++;
        	}
        	if (blobs[i].getTeamNum() == 1)
        	{
        		num_red++;
        	}
        }
    }

    this.set_u8("numcapping", 0);

    if (num_red > 0 || num_blue > 0)
    {
    	if (num_red > 0 && num_blue == 0 && (this.getTeamNum() == 0 || this.getTeamNum() == 255)) // red capping
    	{
    		this.set_u8("numcapping", num_red);
    		this.set_bool(isbluecapture, false);

    		this.set_u16(capture_prop, this.get_u16(capture_prop) + num_red);
    	}
    	else if (num_blue > 0 && num_red == 0 && (this.getTeamNum() == 1 || this.getTeamNum() == 255)) // blue capping
    	{
    		this.set_u8("numcapping", num_blue);
    		this.set_bool(isbluecapture, true);

    		this.set_u16(capture_prop, this.get_u16(capture_prop) + num_blue);
    	}
    }
    
    if ((this.get_u16(capture_prop) > 0 && getGameTime() % 2 == 0) && ((num_blue == 0 && this.getTeamNum() == 1) || (num_red == 0 && this.getTeamNum() == 0)))
    {
    	this.set_u16(capture_prop, this.get_u16(capture_prop) - 1);
    }

    if (this.get_u16(capture_prop) >= (this.getTeamNum() == 255 ? capture_time/2 : capture_time))
    {
    	this.set_u16(capture_prop, 0);

    	if (this.get_bool(isbluecapture))
    	{
    		this.server_setTeamNum(0);
    	}
    	else
    	{
    		this.server_setTeamNum(1);
    	}

    	this.getSprite().PlaySound("UnlockClass", 3.0f, 1.0f); //CapturePoint
    }   
}