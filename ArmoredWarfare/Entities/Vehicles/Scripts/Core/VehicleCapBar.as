#include "TeamColorCollections.as"

const string capture_prop = "capture time";
const string last_capture_prop = "last capture time";
const string teamcapping = "teamcapping";
const f32 capture_time = 350/15; // divide by tck frequency

void onInit(CBlob@ this)
{
	this.set_f32(capture_prop, 0);
	this.set_u8("numcapping", 0);
	this.set_s8(teamcapping, -1);
	this.getCurrentScript().tickFrequency = 15;
}

void onTick(CBlob@ this)
{
	if (this.isAttached()) return;
    float capture_distance = 38.0f; //Distance from this blob that it can be cpaped
	
    u8 num_teamleft = 0;
    u8 num_teamright = 0;

    array<CBlob@> blobs; //Blob array full of blobs
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition() + Vec2f(4.0f,0.0f), capture_distance, blobs);

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

    for (f32 i = 0; i < blobs.size(); i++)
    {
        if (blobs[i].hasTag("player") && !blobs[i].hasTag("dead")) // Only players
        {
        	if (blobs[i].getTeamNum() == teamleft)
        	{
        		num_teamleft++;
        	}
        	if (blobs[i].getTeamNum() == teamright)
        	{
        		num_teamright++;
        	}
        }
    }

	bool separatists_power = getRules().get_bool("enable_powers"); // team 4 buff
   	u8 extra_amount = 0;
    if (separatists_power)
	{
		if (teamleft == 4 && num_teamleft > 0) num_teamleft++;
		if (teamright == 4 && num_teamright > 0) num_teamright++; 
	}

    this.set_u8("numcapping", 0);

    if (num_teamright > 0 || num_teamleft > 0)
    {
    	if (num_teamright > 0 && num_teamleft == 0 && this.get_s8(teamcapping) != teamleft && (this.getTeamNum() == teamleft || this.getTeamNum() == 255)) // red capping
    	{
    		this.set_u8("numcapping", num_teamright);
    		this.set_s8(teamcapping, teamright);

    		this.set_f32(capture_prop, this.get_f32(capture_prop) + num_teamright);
    	}
    	else if (num_teamleft > 0 && num_teamright == 0 && this.get_s8(teamcapping) != teamright && (this.getTeamNum() == teamright || this.getTeamNum() == 255)) // blue capping
    	{
    		this.set_u8("numcapping", num_teamleft);
    		this.set_s8(teamcapping, teamleft);

    		this.set_f32(capture_prop, this.get_f32(capture_prop) + num_teamleft);
    	}
    }
    
    if ((this.get_f32(capture_prop) > 0 && getGameTime() % 2 == 0) && ((num_teamleft == 0 && this.getTeamNum() == teamright) 
		|| (num_teamright == 0 && this.getTeamNum() == teamleft) || (num_teamright == 0 && this.get_s8(teamcapping) == teamright
		&& this.getTeamNum() == 255) || (num_teamleft == 0 && this.get_s8(teamcapping) == teamleft&& this.getTeamNum() == 255)))
    {
    	this.set_f32(capture_prop, this.get_f32(capture_prop) - 1);
    }
    else if (this.get_f32(capture_prop) == 0) //returned to zero
    {
    	this.set_s8(teamcapping, -1);
    }

    if (this.get_f32(capture_prop) >= (this.getTeamNum() == 255 ? capture_time/2 : capture_time))
    {
    	this.set_f32(capture_prop, 0);
    	this.server_setTeamNum(this.get_s8(teamcapping));
    	this.getSprite().PlaySound("CapturePoint", 1.0f, 1.0f);
    }   
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || blob.hasTag("no_cap_bar")) return;

	blob.set_f32(last_capture_prop, Maths::Lerp(blob.get_f32(last_capture_prop), blob.get_f32(capture_prop), 0.1f));
	f32 returncount = Maths::Min(capture_time, blob.get_f32(last_capture_prop));
	if (returncount <= 1) return;

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

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	SColor color_team;

	if (blob.getTeamNum() == teamright && returncount > 0 || blob.getTeamNum() == teamleft && returncount == 0 || blob.getTeamNum() == 255 && blob.get_s8(teamcapping) == teamleft)
	{
		color_light = getNeonColor(teamleft, 0);
		color_mid	=  getNeonColor(teamleft, 1);
		color_dark	=  getNeonColor(teamleft, 2);
	}
	
	if (blob.getTeamNum() == teamleft && returncount > 0 || blob.getTeamNum() == teamright && returncount == 0 || blob.getTeamNum() == 255 && blob.get_s8(teamcapping) == teamright)
	{
		color_light = getNeonColor(teamright, 0);
		color_mid	= getNeonColor(teamright, 1);
		color_dark	= getNeonColor(teamright, 2);
	}

	if (blob.getTeamNum() == teamleft)
	{
		color_team = getNeonColor(teamleft, 0);
	}
	if (blob.getTeamNum() == teamright)
	{
		color_team = getNeonColor(teamright, 0);
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

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	this.set_f32(capture_prop, 0);
	this.set_f32(last_capture_prop, 0);
}