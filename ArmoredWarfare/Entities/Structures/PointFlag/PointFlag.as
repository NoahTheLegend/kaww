#include "PlayerRankInfo.as"

const string capture_prop = "capture time";
const string teamcapping = "teamcapping";

const u16 capture_time = 3000;
const u16 crate_frequency_seconds = 2.5*60;
const u16 min_items = 10;
const u16 rand_items = 2;

//flags HUD is in TDM_Interface

void onInit(CBlob@ this)
{
	//this.server_setTeamNum(0);
	this.getShape().getConsts().mapCollisions = false;

	this.set_u16(capture_prop, 0);
	this.set_s8(teamcapping, -1); //1 is red, 0 is blue, this is also a commentary on the nature of team colors and the effect it has on team performance. The color red, associated with blood will positively impact a team's competitive gameplay. For opposing teams, a red colored enemy player will subconsiously instill fear.
	//this.set_bool(isbluecapture, false); //false is red, true is blue, this is also a commentary on the nature of good and evil, and colors.
	this.set_u8("numcapping", 0);
	this.set_f32("offsety", -51.0f);

	this.set_u32("crate_timer", 0);

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
		if (getRules().get_u8("siege") == 255)
		{
			getRules().SetTeamWon(team);
			getRules().SetCurrentState(GAME_OVER);
			CTeam@ teamis = getRules().getTeam(team);
			if (teamis !is null) getRules().SetGlobalMessage(teamis.getName() + " wins the game!\n\nWell done. Loading next map..." );
		}
		else
		{
			if (getRules().get_u8("siege") == 0)
			{
				getRules().set_s16("redTickets", 0);
				getRules().Sync("redTickets", true);
			}
			else
			{
				getRules().set_s16("blueTickets", 0);
				getRules().Sync("blueTickets", true);
			}
		}
	}
}

void onTick(CBlob@ this)
{
    float capture_distance = 76.0f; //Distance from this blob that it can be cpaped

    u8 num_blue = 0;
    u8 num_red = 0;

    array<CBlob@> blobs; //Blob array full of blobs
    CMap@ map = getMap();
    map.getBlobsInRadius(this.getPosition() + Vec2f(4.0f,20.0f), capture_distance, blobs);
	
	u8 sieging_team = getRules().get_u8("siege");
	bool is_siege =  false; //sieging_team != 255;
	//printf("steam "+sieging_team);

    for (u16 i = 0; i < blobs.size(); i++)
    {
        if (blobs[i].hasTag("player") && !blobs[i].hasTag("dead") && !blobs[i].isAttached()) // Only players and builders    && blobs[i].getName() != "mechanic"
        {
			if (is_siege && blobs[i].getTeamNum() != sieging_team)
			{
				continue;
			}
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

	if (getGameTime() % 30 == 0 && ((num_blue == 0 && this.getTeamNum() == 1) || (num_red == 0 && this.getTeamNum() == 0)) && this.getTeamNum() < 2)
	{
		this.set_u32("crate_timer", Maths::Min(this.get_u32("crate_timer")+1, crate_frequency_seconds));

		if (this.get_u32("crate_timer") >= crate_frequency_seconds)
		{
			CBlob@ crate = getBlobByNetworkID(this.get_u16("last_crateid"));
			if (crate is null)
			{
				this.set_u32("crate_timer", 0);
				if (isServer()) SpawnLootCrate(this);
			}
		}
	}

    bool isTDM = (getMap().tilemapwidth < 200);

    this.set_u8("numcapping", 0);

    if (num_red > 0 || num_blue > 0)
    {
    	if (num_red > 0 && num_blue == 0 && this.get_s8(teamcapping) != 0 && (this.getTeamNum() == 0 || this.getTeamNum() == 255)) // red capping
    	{
    		this.set_u8("numcapping", num_red);
    		this.set_s8(teamcapping, 1);

    		num_red = Maths::Min(num_red, 2);
    		u16 time = this.get_u16(capture_prop) + num_red * (getMap() !is null && isTDM ? 1 : 2);
			if (time > capture_time*4) time = 0;
    		this.set_u16(capture_prop, time);
		}
    	else if (num_blue > 0 && num_red == 0 && this.get_s8(teamcapping) != 1 && (this.getTeamNum() == 1 || this.getTeamNum() == 255)) // blue capping
    	{
    		this.set_u8("numcapping", num_blue);
    		this.set_s8(teamcapping, 0);

    		num_blue = Maths::Min(num_blue, 2);
			u16 time = this.get_u16(capture_prop) + num_blue * (getMap() !is null && isTDM ? 1 : 2);
			if (time > capture_time*4) time = 0;
    		this.set_u16(capture_prop, time);
		}
    }
	else if (this.get_u16(capture_prop) > 0
	&& (this.get_u16(capture_prop) < (capture_time / 4) - 5
	|| this.get_u16(capture_prop) > (capture_time / 4) + 5)) this.add_u16(capture_prop, -1); // printf("prop "+this.get_u16(capture_prop));
    
    if ((this.get_u16(capture_prop) > 0
	&& getGameTime() % 2 == 0)
	&& ((num_blue == 0 && this.getTeamNum() == 1)
	|| (num_red == 0 && this.getTeamNum() == 0)
	|| (num_red == 0 && this.get_s8(teamcapping) == 1 && this.getTeamNum() == 255)
	|| (num_blue == 0 && this.get_s8(teamcapping) == 0 && this.getTeamNum() == 255)))
    {
		u8 mod = 0;
		if (this.get_u16(capture_prop) > 50+getPlayersCount())
			mod = num_blue+num_red;
		else
		{
			if (this.getTeamNum() == 0) this.set_s8(teamcapping, (num_blue > num_red ? 0 : 1));
			else if (this.getTeamNum() == 1) this.set_s8(teamcapping, (num_red > num_blue ? 0 : 1));
		}
		if (getMap() !is null && getMap().tilemapwidth < 200) mod *= 2; // twice faster on small maps

		//printf(""+mod);

		u16 time = this.get_u16(capture_prop) - (2+mod);
		if (time > capture_time*4) time = 0;
    	this.set_u16(capture_prop, time);
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
				flag.SetVisible(true);
				if (this.get_s8(teamcapping) == 0)
				{
					flag.SetAnimation(!down ? anim_blue : anim_red);
				}
				else if (this.get_s8(teamcapping) == 1 )
				{
					flag.SetAnimation(!down ? anim_red : anim_blue);
				}
				else if (this.get_s8(teamcapping) == -1)
				{
					flag.SetAnimation(this.getTeamNum() == 0 ? anim_blue : anim_red);
				}
			}
			else if (this.get_u16(capture_prop) > 0 || (num_blue > 0 || num_red > 0))
			{
				flag.SetVisible(true);
				if (this.get_s8(teamcapping) == 0)
				{
					flag.SetAnimation(anim_blue);
					this.Tag("last_cap_blue");
					this.Untag("last_cap_red");
				}
				else if (this.get_s8(teamcapping) == 1)
				{
					flag.SetAnimation(anim_red);
					this.Tag("last_cap_red");
					this.Untag("last_cap_blue");
				}
				else flag.SetVisible(false);
			}
		}
	} 
	if (this !is null) // danger zone, trying to fix smth
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

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	bool focus = false;
	if (getLocalPlayer() !is null && getLocalPlayer().getBlob() !is null
	&& (getLocalPlayer().getBlob().getAimPos() - blob.getPosition()).Length() <= 88.0f)
		focus = true;
	u16 returncount = blob.get_u16(capture_prop);

	if (returncount == 0 && !focus) return;
	GUI::SetFont("menu");
	// adjust vertical offset depending on zoom
	Vec2f pos2d =  blob.getInterpolatedScreenPos() + Vec2f(0.0f, (blob.getHeight()-50.0f));
	
	f32 wave = Maths::Sin(getGameTime() / 5.0f) * 5.0f - 25.0f;

	Vec2f pos = pos2d + Vec2f(8.0f, 150.0f);
	Vec2f dimension = Vec2f(115.0f - 8.0f, 22.0f);
	f32 y = 0.0f;//blob.getHeight() * 100.8f;
	
	f32 percentage = 1.0f - float(returncount) / float(blob.getTeamNum() == 255 ? capture_time/2 : capture_time);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

	f32 perc  = float(returncount) / float(blob.getTeamNum() == 255 ? capture_time/2 : capture_time);

	SColor color_light;
	SColor color_mid;
	SColor color_dark;
	SColor color_darker;

	SColor color_team;

	if (blob.getTeamNum() == 1 && returncount > 0 || blob.getTeamNum() == 0 && returncount == 0 || blob.getTeamNum() == 255 && blob.get_s8(teamcapping) == 0)
	{
		color_light = 0xff2cafde;
		color_mid	= 0xff1d85ab; //  0xff1d85ab
		color_dark	= 0xff1a4e83;
		color_darker= 0xff092751;
	}
	
	if (blob.getTeamNum() == 0 && returncount > 0 || blob.getTeamNum() == 1 && returncount == 0 || blob.getTeamNum() == 255 && blob.get_s8(teamcapping) == 1)
	{
		color_light = 0xffd5543f;
		color_mid	= 0xffb73333; // 0xffb73333
		color_dark	= 0xff941b1b;
		color_darker= 0xff520909;
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

	if (returncount != 0)
	{
		// Border
		GUI::DrawRectangle(Vec2f(pos.x - dimension.x - 1,                        pos.y + y - 1),
						   Vec2f(pos.x + dimension.x + 2,                        pos.y + y + dimension.y - 1));


		GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 3,                        pos.y + y + 1),
						   Vec2f(pos.x + dimension.x - 2,                        pos.y + y + dimension.y - 3), color_team);


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

	if (blob.getTeamNum() >= 2 || blob.get_u8("numcapping") > 0) return;
	
	// draw crate generation progress
	dimension = Vec2f(50, 15);
	y = 32.0f;
	perc = float(blob.get_u32("crate_timer")) / float(crate_frequency_seconds);

	// Border
	GUI::DrawRectangle(Vec2f(pos.x - dimension.x - 1,                        pos.y + y - 1),
						 Vec2f(pos.x + dimension.x + 2,                        pos.y + y + dimension.y - 1), color_darker);

	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 3,                        pos.y + y + 1),
					    Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 2, pos.y + y + dimension.y - 3), color_mid);

	GUI::DrawRectangle(Vec2f(pos.x - dimension.x + 7,                        pos.y + y + 1),
						Vec2f(pos.x - dimension.x + perc  * 2.0f * dimension.x - 6, pos.y + y + dimension.y - 4), color_light);
}

// resources
const array<string> _items_res =
{
	"mat_scrap",
    "mat_wood",
    "mat_stone",
    "mat_gold"
};
const array<float> _amounts_res =
{
	2+XORRandom(5),
	250+XORRandom(201),
	100+XORRandom(101),
	20+XORRandom(41),
};
const array<float> _chances_res =
{
	0.5,
	0.75,
	0.65,
	0.25
};

// offense
const array<string> _items_off =
{
	"ammo",
    "mat_14mmround",
    "mat_bolts",
    "mat_smallbomb",
	"grenade",
	"mat_molotov",
	"launcher_javelin",
	"mat_heatwarhead"
};
const array<float> _amounts_off =
{
	100,
	35,
	12,
	4,
	1,
	1,
	1,
	2
};
const array<float> _chances_off =
{
	0.5,
	0.2,
	0.4,
	0.15,
	0.35,
	0.4,
	0.05,
	0.3
};

// defence
const array<string> _items_def =
{
	"food",
    "medkit",
    "helmet",
    "mine",
	"binoculars",
	"pipewrench",
	"launcher_javelin"
};
const array<float> _amounts_def =
{
	1,
	1,
	1,
	1,
	1,
	1,
	1,
};
const array<float> _chances_def =
{
	0.4,
	0.3,
	0.6,
	0.25,
	0.15,
	0.3,
	0.05
};

void SpawnLootCrate(CBlob@ this)
{
	if (!isServer()) return;
	bool spawn_at_sky = true; // cast a ray from sky to make sure it wont stuck above
	for (f32 i = -2; i < 3; i++)
	{
		if (getMap().rayCastSolidNoBlobs(Vec2f(this.getPosition().x + 12*i, 0), this.getPosition()))
			spawn_at_sky = false;
	}

	CBlob@ crate = server_CreateBlob("paracrate", this.getTeamNum(), spawn_at_sky ? Vec2f(this.getPosition().x+XORRandom(23), 0) : Vec2f(this.getPosition().x+XORRandom(23), this.getPosition().y - this.getHeight()/2));
	if (crate !is null)
	{
		crate.Tag("no_expiration");
		this.set_u16("last_crateid", crate.getNetworkID());

		string[] _items;
		float[] _amounts;
		float[] _chances;

		u8 rand = XORRandom(3);
		switch(rand)
		{
			case 0: // resources
			{
				_items = _items_res;
				_amounts = _amounts_res;
				_chances = _chances_res;
				break;
			}
			case 1: // military (offensive)
			{
				_items = _items_off;
				_amounts = _amounts_off;
				_chances = _chances_off;
				break;
			}
			case 2: // military (defensive)
			{
				_items = _items_def;
				_amounts = _amounts_def;
				_chances = _chances_def;
				break;
			}
		}

		u8 items_amount = min_items + XORRandom(rand_items+1);

		for (int i = 0; i < items_amount; i++)
		{
			u32 element = RandomWeightedPicker(_chances, XORRandom(1000));

	        CBlob@ b = server_CreateBlob(_items[element], -1, this.getPosition());
			 
			if (b !is null)
			{
	        	if (b.getMaxQuantity() > 1)
	        	{
	        	    b.server_SetQuantity(_amounts[element]);
	        	}
				crate.server_PutInInventory(b);
			}
    	}
	}
}

shared u32 RandomWeightedPicker(array<float> chances, u32 seed = 0)
{
    if (seed == 0) {seed = (getGameTime() * 404 + 1337 - Time_Local());}

    u32 i;
    float sum = 0.0f;

    for (i = 0; i < chances.size(); i++) {sum += chances[i];}

    Random@ rnd = Random(seed);//Random with seed

    float random_number = (rnd.Next() + rnd.NextFloat()) % sum;//Get our random number between 0 and the sum

    float current_pos = 0.0f;//Current pos in the bar

    for (i = 0; i < chances.size(); i++)//For every chance
    {
        if(current_pos + chances[i] > random_number)
        {
            break;//Exit out with i untouched
        }
        else//Random number has not yet reached the chance
        {
            current_pos += chances[i];//Add to current_pos
        }
    }

    return i;//Return the chance that was got
}