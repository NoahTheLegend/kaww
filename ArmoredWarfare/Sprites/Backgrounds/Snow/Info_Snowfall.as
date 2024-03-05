#include "HolidayCommon.as";

const int present_interval = 30 * 60 * 10; // 10 minutes
const int gifts_per_hoho = 3;

// Snow stuff
Vertex[] Verts;
bool _snow_ready = false;
SColor snow_col(0xffffffff);
f64 frameTime = 0;

void onInit(CBlob@ this)
{
	if (isClient())
		this.set_s16("snow_render_id", 0);

	_snow_ready = false;

	this.addCommandID("xmas sound");

	this.set_s32("present timer", present_interval);
	frameTime = 0;
	
	int cb_id;
	if (isClient())
	{
		#ifdef STAGING

		cb_id = Render::addBlobScript(Render::layer_floodlayers, this, "Info_Snowfall.as", "DrawSnow");

		#endif
		#ifndef STAGING

		cb_id = Render::addBlobScript(Render::layer_background, this, "Info_Snowfall.as", "DrawSnow");	

		#endif
	}

	this.set_s16("snow_render_id", cb_id);
}

void onTick(CBlob@ this)
{
	/*//if (getGameTime()%150 == 0) this.set_s32("present timer", 0);
	if (!isServer() || getRules().isWarmup())
		return;

	if (!this.exists("present timer") || getBlobByName("info_desert") !is null)
	{
		return;
	}
	if (this.get_s32("present timer") <= 0)
	{
		// reset present timer
		this.set_s32("present timer", present_interval);

		CMap@ map = getMap();
		const f32 mapCenter = map.tilemapwidth * map.tilesize * 0.5;

        CBlob@[] spawns;
        getBlobsByTag("respawn", @spawns);

        for (u8 i = 0; i < spawns.size(); i++)
        {
            CBlob@ tent = spawns[i];
            if (tent is null || tent.getName() == "outpost") continue;

            spawnPresent(Vec2f(tent.getPosition().x, 0), XORRandom(8)).Tag("parachute");
        }

		CBitStream bt;
		this.SendCommand(this.getCommandID("xmas sound"), bt);
	}
	else
	{
		this.sub_s32("present timer", 1);
	}*/
}

CBlob@ spawnPresent(Vec2f spawnpos, u8 team)
{
	return server_CreateBlob("present", team, spawnpos);
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if(cmd == this.getCommandID("xmas sound"))
	{
		Sound::Play("Christmas.ogg");
	}
}

void InitSnow()
{
	if(_snow_ready) return;

	_snow_ready = true;

	Verts.clear();

	CMap@ map  = getMap();
	int chunksX = map.tilemapwidth  / 32 + 3;
	int chunksY = map.tilemapheight / 32 + 3;
	for(int cX = 0; cX < chunksX; cX++)
	{
		for(int cY = 0; cY < chunksY; cY++)
		{
			float patch = 256;
			Verts.push_back(Vertex((cX-1)*patch, (cY)*patch,   -500, 0, 0, snow_col));
			Verts.push_back(Vertex((cX)*patch,   (cY)*patch,   -500, 1, 0, snow_col));
			Verts.push_back(Vertex((cX)*patch,   (cY-1)*patch, -500, 1, 1, snow_col));
			Verts.push_back(Vertex((cX-1)*patch, (cY-1)*patch, -500, 0, 1, snow_col));
		}
	}
}

// Snow
void DrawSnow(CBlob@ this, int id)
{
	printf("draw");
	if (v_fastrender) return;
	InitSnow();

	frameTime += getRenderApproximateCorrectionFactor();

	float[] trnsfm;
	for(int i = 0; i < 3; i++)
	{
		float gt = frameTime * (1.0f + (0.031f * i)) + (997 * i);
		float X = Maths::Cos(gt/49.0f)*20 +
			Maths::Cos(gt/31.0f) * 5 +
			Maths::Cos(gt/197.0f) * 10;
		float Y = gt % 255;
		Matrix::MakeIdentity(trnsfm);

#ifdef STAGING
		Matrix::SetTranslation(trnsfm, X, Y, -500);
		Render::SetZBuffer(true, false);
#endif
#ifndef STAGING
		Matrix::SetTranslation(trnsfm, X, Y, 0);
#endif

		Render::SetAlphaBlend(true);
		Render::SetModelTransform(trnsfm);
		Render::RawQuads("Snow.png", Verts);
	}
}