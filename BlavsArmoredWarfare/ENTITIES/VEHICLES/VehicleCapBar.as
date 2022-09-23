const string capture_prop = "capture time";
const string teamcapping = "teamcapping";
const u16 capture_time = 350;

void onInit(CBlob@ this)
{
	this.set_u16(capture_prop, 0);
	this.set_u8("numcapping", 0);
	this.set_s8(teamcapping, -1);
}

void onTick(CBlob@ this)
{
	if (this.isAttached()) return;
    float capture_distance = 38.0f; //Distance from this blob that it can be cpaped

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
    	if (num_red > 0 && num_blue == 0 && this.get_s8(teamcapping) != 0 && (this.getTeamNum() == 0 || this.getTeamNum() == 255)) // red capping
    	{
    		this.set_u8("numcapping", num_red);
    		this.set_s8(teamcapping, 1);

    		this.set_u16(capture_prop, this.get_u16(capture_prop) + num_red);
    	}
    	else if (num_blue > 0 && num_red == 0 && this.get_s8(teamcapping) != 1 && (this.getTeamNum() == 1 || this.getTeamNum() == 255)) // blue capping
    	{
    		this.set_u8("numcapping", num_blue);
    		this.set_s8(teamcapping, 0);

    		this.set_u16(capture_prop, this.get_u16(capture_prop) + num_blue);
    	}
    }
    
    if ((this.get_u16(capture_prop) > 0 && getGameTime() % 2 == 0) && ((num_blue == 0 && this.getTeamNum() == 1) || (num_red == 0 && this.getTeamNum() == 0) || (num_red == 0 && this.get_s8(teamcapping) == 1 && this.getTeamNum() == 255) || (num_blue == 0 && this.get_s8(teamcapping) == 0 && this.getTeamNum() == 255)))
    {
    	this.set_u16(capture_prop, this.get_u16(capture_prop) - 1);
    }
    else if (this.get_u16(capture_prop) == 0) //returned to zero
    {
    	this.set_s8(teamcapping, -1);
    }

    if (this.get_u16(capture_prop) >= (this.getTeamNum() == 255 ? capture_time/2 : capture_time))
    {
    	this.set_u16(capture_prop, 0);

    	this.server_setTeamNum(this.get_s8(teamcapping));

    	this.getSprite().PlaySound("CapturePoint", 1.0f, 1.0f);
    }   
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || blob.hasTag("no_cap_bar")) return;

	u16 returncount = blob.get_u16(capture_prop);
	if (returncount == 0) return;

	const f32 scalex = getDriver().getResolutionScaleFactor()/2;
	const f32 zoom = getCamera().targetDistance * scalex;
	// adjust vertical offset depending on zoom
	Vec2f pos2d =  blob.getInterpolatedScreenPos() + Vec2f(0.0f, (-blob.getHeight() - 20.0f) * zoom);
	
	f32 wave = Maths::Sin(getGameTime() / 5.0f) * 5.0f - 25.0f;

	Vec2f pos = pos2d + Vec2f(8.0f, 150.0f);
	Vec2f dimension = Vec2f(70.0f - 8.0f, 12.0f);
	const f32 y = 0.0f;//blob.getHeight() * 100.8f;
	
	f32 percentage = 1.0f - float(returncount) / float(blob.getTeamNum() == 255 ? capture_time/2 : capture_time);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	const f32 perc  = float(returncount) / float(blob.getTeamNum() == 255 ? capture_time/2 : capture_time);

	SColor color_light;
	SColor color_mid;
	SColor color_dark;

	SColor color_team;

	if (blob.getTeamNum() == 1 && returncount > 0 || blob.getTeamNum() == 0 && returncount == 0 || blob.getTeamNum() == 255 && blob.get_s8(teamcapping) == 0)
	{
		color_light = 0xff2cafde;
		color_mid	= 0xff1d85ab; //  0xff1d85ab
		color_dark	= 0xff1a4e83;
	}
	
	if (blob.getTeamNum() == 0 && returncount > 0 || blob.getTeamNum() == 1 && returncount == 0 || blob.getTeamNum() == 255 && blob.get_s8(teamcapping) == 1)
	{
		color_light = 0xffd5543f;
		color_mid	= 0xffb73333; // 0xffb73333
		color_dark	= 0xff941b1b;
	}

	if (blob.getTeamNum() == 0)
	{
		color_team = 0xff2cafde;
	}
	if (blob.getTeamNum() == 1)
	{
		color_team = 0xffd5543f;
	}
	if (blob.getTeamNum() == 255)
	{
		color_team = 0xff1c2525;//ff36373f;
	}

	// Border
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x - 1,                        pos.y + y - 1),
					   Vec2f(pos.x + dimension.x + 2,                        pos.y + y + dimension.y - 1));

	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 0),
					   Vec2f(pos.x + dimension.x - 1,                        pos.y + y + dimension.y - 2), color_team);

	// whiteness
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 1,                        pos.y + y + 0),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x + 0, pos.y + y + dimension.y - 2), SColor(0xffffffff));
	// growing outline
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 1,                        pos.y + y - 1),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x + 0, pos.y + y + dimension.y - 1), SColor(perc*255, 255, 255, 255));

	// Health meter trim
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 0),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 1, pos.y + y + dimension.y - 2), color_mid);
	// Health meter inside
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 6,                        pos.y + y + 0),
					   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 5, pos.y + y + dimension.y - 3), color_light);

	GUI::SetFont("menu");
	GUI::DrawShadowedText("★ Capturing... ★", Vec2f(pos.x - dimension.x + -2, pos.y + 12), SColor(0xffffffff));
}