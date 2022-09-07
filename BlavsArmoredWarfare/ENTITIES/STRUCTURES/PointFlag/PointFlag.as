const string capture_prop = "capture time";
const string teamcapping = "teamcapping";

const u16 capture_time = 3000;

void onInit(CBlob@ this)
{
	//this.server_setTeamNum(0);
	this.getShape().getConsts().mapCollisions = false;

	this.set_u16(capture_prop, 0);
	this.set_s8(teamcapping, -1); //1 is red, 0 is blue, this is also a commentary on the nature of team colors and the effect it has on team performance. The color red, associated with blood will positively impact a team's competitive gameplay. For opposing teams, a red colored enemy player will subconsiously instill fear.
	//this.set_bool(isbluecapture, false); //false is red, true is blue, this is also a commentary on the nature of good and evil, and colors.
	this.set_u8("numcapping", 0);
	this.set_f32("offsety", -51.0f);

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ flag = sprite.addSpriteLayer("flag", "CTF_Flag.png", 32, 16);
	if (flag !is null)
	{
		flag.SetRelativeZ(10.0f);
		flag.SetOffset(Vec2f(9.0f, -51.0f));

		Animation@ anim_blue = flag.addAnimation("flag_wave_blue", XORRandom(3)+3, true);
		int[] frames_blue = {0,2,4,6};

		Animation@ anim_red = flag.addAnimation("flag_wave_red", XORRandom(3)+3, true);
		int[] frames_red = {1,3,5,7};

		if (anim_blue !is null && anim_red !is null)
		{
			anim_blue.AddFrames(frames_blue);
			anim_red.AddFrames(frames_red);
			u8 team = this.getTeamNum();
			if (team < 2) flag.SetAnimation((team == 0 ? anim_blue : anim_red));
		}
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (oldTeam > 1)
	{
		this.set_u16(capture_prop, 0);
	}
	CBlob@[] blobs;
	bool won = false;
	u8 blue = 0;
	u8 red = 0;
	getBlobsByName("pointflag", @blobs);
	{
		for (u8 i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b is null) continue;
			if (b.getTeamNum() != 0 && b.getTeamNum() != 1) return;
			b.getTeamNum() == 0 ? blue++ : red++;
		}
	}
	u8 team = 255;
	if (red == 0) team = 0;
	else if (blue == 0) team = 1;
	//printf(""+team);
	if (getRules() !is null && team < 2)
	{
		getRules().SetTeamWon(team);
		getRules().SetCurrentState(GAME_OVER);
		CTeam@ teamis = getRules().getTeam(team);
		if (teamis !is null) getRules().SetGlobalMessage(teamis.getName() + " wins the game!" );
	}
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
        if (blobs[i].hasTag("player") && !blobs[i].hasTag("dead") && blobs[i].getName() != "slave") // Only players and no builders
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
	else if (this.get_u16(capture_prop) > 0
	&& (this.get_u16(capture_prop) < (capture_time / 4) - 5
	|| this.get_u16(capture_prop) > (capture_time / 4) + 5)) this.add_u16(capture_prop, -1); // printf("prop "+this.get_u16(capture_prop));
    
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

    	this.getSprite().PlaySound("UnlockClass", 3.0f, 1.0f); //CapturePoint
    } 
	
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ flag = sprite.getSpriteLayer("flag");
	if (flag !is null)
	{
		f32 offsety = this.get_f32("offsety");
		bool down = false;
		u8 team = this.getTeamNum();
		if (this.get_u16(capture_prop) < (capture_time / 2)) down = true;
		if (down && !(team < 2)) flag.SetVisible(false);

		if (team < 2)
		{
			f32 max = capture_time / 4;
			f32 curr = this.get_u16(capture_prop);
			f32 mod = (curr/(max)) * 1.0f;
			offsety = (down ? -51.0f*(1.0f - mod) : 51.0f * (3.0f - mod));
			if (offsety > 49.0f)
			{
				for (u8 i = 0; i < 15; i++)
				{
					sparks(this.getPosition()+Vec2f(0, 56.0f),
					this.getAngleDegrees(),
					3.5f + (XORRandom(10) / 10.0f),
					(team == 0 ? SColor(255, 55, 75, 255) : SColor(255, 255, 75, 55)));
				}
			}
		}
		else
		{
			f32 max = capture_time / 4;
			f32 curr = this.get_u16(capture_prop);
			f32 mod = (curr/(max/2)) * 1.0f;
			offsety = 17.5f * (3.0f - mod*1.5);

			if (num_blue == 0 && num_red == 0 && this.get_u16(capture_prop) == 1)
			{
				for (u8 i = 0; i < 15; i++)
				{
					sparks(this.getPosition()+Vec2f(0, 56.0f),
					this.getAngleDegrees(),
					3.5f + (XORRandom(10) / 10.0f),
					SColor(255, (this.hasTag("last_cap_red") ? 255 : 55), 75, (this.hasTag("last_cap_blue") ? 255 : 55)));
				}
			}
		}

		this.set_f32("offsety", offsety);

		//printf(""+offsety);

		flag.SetOffset(Vec2f(9.0f, offsety));
		Animation@ anim_blue = flag.getAnimation("flag_wave_blue");
		Animation@ anim_red = flag.getAnimation("flag_wave_red");
		if (anim_blue !is null && anim_red !is null)
		{
			if (team < 2)
			{
				if (team == 0)
				{
					flag.SetAnimation(down ? anim_blue : anim_red);
				}
				else flag.SetAnimation(down ? anim_red : anim_blue);
			}
			else if (this.get_u16(capture_prop) > 0 || (num_blue > 0 || num_red > 0))
			{
				if (num_blue > num_red)
				{
					flag.SetAnimation(anim_blue);
					this.Tag("last_cap_blue");
					this.Untag("last_cap_red");
				}
				else if (num_red > num_blue)
				{
					flag.SetAnimation(anim_red);
					this.Tag("last_cap_red");
					this.Untag("last_cap_blue");
				}
				flag.SetVisible(true);
			}
		}
	}  
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 25.0f);
	at.y -= 2.5f;
	ParticlePixel(at, vel, color, true, 119);
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || blob.hasTag("no_cap_bar")) return;

	u16 returncount = blob.get_u16(capture_prop);
	if (returncount == 0) return;

	GUI::SetFont("menu");

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

	//GUI::SetFont("menu");
	GUI::DrawShadowedText("Capturing...", Vec2f(pos.x - dimension.x + -2, pos.y + 12), SColor(0xffffffff));
}