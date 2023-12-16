
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "PlayerRankInfo.as"
#include "TeamColorCollections.as"

const string capture_prop = "capture time";
const string teamcapping = "teamcapping";
const f32 capture_time = 3000;
const Vec2f startpos = Vec2f(9.0f, -51.0f);

//flags HUD is in TDM_Interface

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;

	this.set_f32(capture_prop, 0);
	this.set_s8(teamcapping, -1); //1 is teamright, 0 is teamleft, this is also a commentary on the nature of team colors and the effect it has on team performance. The color teamright, associated with blood will positively impact a team's competitive gameplay. For opposing teams, a teamright coloteamright enemy player will subconsiously instill fear.
	//this.set_bool(isteamleftcapture, false); //false is teamright, true is teamleft, this is also a commentary on the nature of good and evil, and colors.
	this.set_u8("numcapping", 0);
	this.set_f32("offsety", -51.0f);

	this.set_u8("oldteam", this.getTeamNum());

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	CSpriteLayer@ flag = sprite.addSpriteLayer("flag", "CTF_Flag.png", 32, 16);
	if (flag !is null)
	{
		flag.SetRelativeZ(10.0f);
		flag.SetOffset(startpos);

		u8 teamleft = getRules().get_u8("teamleft");
		u8 teamright = getRules().get_u8("teamright");

		Animation@ anim_default = flag.addAnimation("flag_wave255", XORRandom(3)+3, true);
		int[] frames = {28,29,30,31};
		if (anim_default !is null)
			anim_default.AddFrames(frames);

		Animation@ anim_teamleft = flag.addAnimation("flag_wave"+teamleft, XORRandom(3)+3, true);
		Animation@ anim_teamright = flag.addAnimation("flag_wave"+teamright, XORRandom(3)+3, true);

		if (anim_teamleft !is null && anim_teamright !is null)
		{
			for (u8 i = 0; i < 4; i++)
			{
				u8 frameleft = 4*teamleft+i;
				u8 frameright = 4*teamright+i;

				//printf("adding frameleft "+frameleft);
				//printf("adding framerihgt "+frameright);

				anim_teamleft.AddFrame(frameleft);
				anim_teamright.AddFrame(frameright);
			}

			u8 team = this.getTeamNum();
			if (team < 7) flag.SetAnimation((team == getRules().get_u8("teamleft") ? anim_teamleft : anim_teamright));
		}
	}
}

const f32 pole_height = 100.0f;
void onTick(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;
	{
		CSpriteLayer@ flag = sprite.getSpriteLayer("flag");
		if (flag !is null)
		{
			u8 teamleft = getRules().get_u8("teamleft");
			u8 teamright = getRules().get_u8("teamright");
			u8 cap_team = this.getTeamNum();

			f32 cap = this.get_f32(capture_prop);
			f32 slide = cap/capture_time * pole_height;
			if (cap_team == 255) slide *= 2;

			flag.SetOffset(Vec2f(0, slide) + startpos);
			flag.SetAnimation("flag_wave"+cap_team);
		}
	}
}

void onTick(CBlob@ this)
{
    float capture_distance = 76.0f; //Distance from this blob that it can be cpaped

    u8 num_teamleft = 0;
    u8 num_teamright = 0;

    array<CBlob@> blobs;
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition() + Vec2f(4.0f,20.0f), capture_distance, blobs);

    for (u16 i = 0; i < blobs.size(); i++)
    {
        if (blobs[i].hasTag("player") && !blobs[i].hasTag("dead") && !blobs[i].isAttached()) // Only players and builders    && blobs[i].getName() != "mechanic"
        {
        	if (blobs[i].getTeamNum() == getRules().get_u8("teamleft"))
        	{
        		num_teamleft++;
        	}
        	if (blobs[i].getTeamNum() == getRules().get_u8("teamright"))
        	{
        		num_teamright++;
        	}
        }
    }

	bool isTDM = (getMap().tilemapwidth <= 300);
	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

    this.set_u8("numcapping", 0);

    if (num_teamright > 0 || num_teamleft > 0)
    {
    	if (num_teamright > 0 && num_teamleft == 0 && this.get_s8(teamcapping) != teamleft && (this.getTeamNum() == teamleft || this.getTeamNum() == 255)) // teamright capping
    	{
    		this.set_u8("numcapping", num_teamright);
    		this.set_s8(teamcapping, teamright);

    		num_teamright = Maths::Min(num_teamright, 2);
    		u16 time = this.get_f32(capture_prop) + num_teamright * (getMap() !is null && isTDM ? 1 : 2);
			if (time > capture_time*4) time = 0;
    		this.set_f32(capture_prop, time);
		}
    	else if (num_teamleft > 0 && num_teamright == 0 && this.get_s8(teamcapping) != teamright && (this.getTeamNum() == teamright || this.getTeamNum() == 255)) // teamleft capping
    	{
    		this.set_u8("numcapping", num_teamleft);
    		this.set_s8(teamcapping, teamleft);

    		num_teamleft = Maths::Min(num_teamleft, 2);
			u16 time = this.get_f32(capture_prop) + num_teamleft * (getMap() !is null && isTDM ? 1 : 2);
			if (time > capture_time*4) time = 0;
    		this.set_f32(capture_prop, time);
		}
    }
	else if (this.get_f32(capture_prop) > 0
	&& (this.get_f32(capture_prop) < (capture_time / 4) - 5
	|| this.get_f32(capture_prop) > (capture_time / 4) + 5)) this.add_f32(capture_prop, -1); // printf("prop "+this.get_f32(capture_prop));

    if ((this.get_f32(capture_prop) > 0
	&& getGameTime() % 2 == 0)
	&& ((num_teamleft == 0 && this.getTeamNum() == teamright)
	|| (num_teamright == 0 && this.getTeamNum() == teamleft)
	|| (num_teamright == 0 && this.get_s8(teamcapping) == teamright&& this.getTeamNum() == 255)
	|| (num_teamleft  == 0 && this.get_s8(teamcapping) == teamleft && this.getTeamNum() == 255)))
    {
		u8 mod = 0;
		if (this.get_f32(capture_prop) > 50+getPlayersCount())
			mod = num_teamleft+num_teamright;
		else
		{
			if (this.getTeamNum() == teamleft) this.set_s8(teamcapping, (num_teamleft > num_teamright ? teamleft : teamright));
			else if (this.getTeamNum() == teamright) this.set_s8(teamcapping, (num_teamright > num_teamleft ? teamleft : teamright));
		}
		if (getMap() !is null && getMap().tilemapwidth <= 300) mod *= 2; // twice faster on small maps

		//printf(""+mod);

		u16 time = this.get_f32(capture_prop) - (2+mod);
		if (time > capture_time*4) time = 0;
    	this.set_f32(capture_prop, time);
    }
    else if (this.get_f32(capture_prop) == 0) //returned to zero
    {
    	this.set_s8(teamcapping, -1);
    }

    if (this.get_f32(capture_prop) >= (this.getTeamNum() == 255 ? capture_time/2 : capture_time))
    {
    	this.set_f32(capture_prop, 0);
    	this.server_setTeamNum(this.get_s8(teamcapping));
    	this.getSprite().PlaySound("UnlockClass", 3.0f, 1.0f); //CapturePoint
    } 
	
	if (isServer())
	{
		this.Sync(capture_prop, true);
		this.Sync(teamcapping, true);
		this.Sync("offsety", true);
	}
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 25.0f);
	at.y -= 2.5f;
	ParticlePixel(at, vel, color, true, 119);
}

void onRender(CSprite@ this) // draw own capture bar
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	bool focus = false;
	if (getLocalPlayer() !is null && getLocalPlayer().getBlob() !is null
	&& (getLocalPlayer().getBlob().getAimPos() - blob.getPosition()).Length() <= 88.0f)
		focus = true;
	u16 returncount = blob.get_f32(capture_prop);

	if (returncount == 0 && !focus) return;
	GUI::SetFont("menu");
	// adjust vertical offset depending on zoom
	Vec2f pos2d =  blob.getInterpolatedScreenPos() + Vec2f(0.0f, (blob.getHeight()-50.0f));
	
	f32 wave = Maths::Sin(getGameTime() / 5.0f) * 5.0f - 25.0f;

	Vec2f pos = pos2d + Vec2f(8.0f, 150.0f);
	Vec2f dimension = Vec2f(115.0f - 8.0f, 22.0f);
	f32 y = 0.0f;//blob.getHeight() * 100.8f;
	u8 teamnum = blob.getTeamNum();
	
	f32 percentage = 1.0f - float(returncount) / float(teamnum == 255 ? capture_time/2 : capture_time);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	f32 perc  = float(returncount) / float(blob.getTeamNum() == 255 ? capture_time/2 : capture_time);

	SColor color_light;
	SColor color_mid;
	SColor color_dark;
	SColor color_darker;
	SColor flag_color_team = 0xff1c2525;

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	u8 team = 255;
	u8 cap_team = blob.get_s8(teamcapping);

	if (returncount > 0) 
	{
		if (teamnum == teamleft) // flag is left team
		{
			team = teamright;    // then set cap gauge to opposite
			flag_color_team = getNeonColor(teamleft, 2); // and background to flagteam
		}
		else if (teamnum == teamright)
		{
			team = teamleft;
			flag_color_team = getNeonColor(teamright, 2);
		}
		else
		{
			team = cap_team;
		}
	}
		
	color_light = getNeonColor(team, 0);
	color_mid	= getNeonColor(team, 1);
	color_dark	= getNeonColor(team, 2);
	color_darker= 0xff222222;

	if (returncount != 0)
	{
		// Border
		GUI::DrawRectangle(Vec2f(pos.x - dimension.x - 1,                        pos.y + y - 1),
						   Vec2f(pos.x + dimension.x + 2,                        pos.y + y + dimension.y - 1));


		GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 3,                        pos.y + y + 1),
						   Vec2f(pos.x + dimension.x - 2,                        pos.y + y + dimension.y - 3), flag_color_team);


		// whiteness
		GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 1),
						   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 1, pos.y + y + dimension.y - 3), SColor(0xffffffff));
		// growing outline
		GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 2,                        pos.y + y + 0),
						   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 1, pos.y + y + dimension.y - 2), SColor(perc*255, 255, 255, 255));

		// Health meter trim
		GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 3,                        pos.y + y + 1),
						   Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 2, pos.y + y + dimension.y - 3), color_mid);

		// Health meter inside
		GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 7,                        pos.y + y + 1),
							Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 6, pos.y + y + dimension.y - 4), color_light);

		if (blob.get_u8("numcapping") > 0)
		{
			//GUI::SetFont("menu");
			GUI::DrawShadowedText("★ " + blob.get_u8("numcapping") + " player" + (blob.get_u8("numcapping") > 1 ? "s are" : " is") + " capturing... ★", Vec2f(pos.x - dimension.x + -2, pos.y + 22), SColor(0xffffffff));
		}
	}

	if (teamnum >= 7 || blob.get_u8("numcapping") > 0) return;

	bool isTDM = (getMap().tilemapwidth <= 300);
	if (isTDM) return;
}


void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (oldTeam > 6)
	{
		this.set_f32(capture_prop, 0);
	}

	//this.set_u8("oldteam", this.getTeamNum());

	for (u8 i = 0; i < (v_fastrender ? 25 : 75); i++)
	{
		sparks(this.getPosition()+Vec2f(0, pole_height/2), -90+XORRandom(181), XORRandom(4)+1, getNeonColor(this.getTeamNum(), XORRandom(3)));
	}

	CBlob@[] blobs;
	bool won = false;
	u8 numteamleft = getRules().get_u8("teamleft");
	u8 numteamright = getRules().get_u8("teamright");

	u8 teamleft = 0;
	u8 teamright = 0;
	getBlobsByName("pointflag", @blobs);
	{
		for (u8 i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b is null) continue;
			if (b.getTeamNum() != numteamleft && b.getTeamNum() != numteamright) return;
			b.getTeamNum() == numteamleft ? teamleft++ : teamright++;
		}
	}
	u8 team = 255;
	if (teamright == 0) team = numteamleft;
	else if (teamleft == 0) team = numteamright;
	//printf("old "+oldteam);
	//printf("team "+team);
	if (getRules() !is null && team != 255)
	{
		getRules().SetTeamWon(team);
		getRules().SetCurrentState(GAME_OVER);
		CTeam@ teamis = getRules().getTeam(team);
		if (teamis !is null) getRules().SetGlobalMessage(teamis.getName() + " wins the game!\n\nWell done. Loading next map..." );
	}
}