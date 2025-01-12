#include "GenericButtonCommon.as";
#include "Hitters.as";
#include "HittersAW.as";
#include "Explosion.as";
#include "GamemodeCheck.as";

const string fuel_prop = "fuel_level";
const string working_prop = "working";
const string sound_cooldown_prop = "charge_cooldown";

const int spawnmetal_frequency = 30; // how often to spawn metal
const string[] mats = {"mat_wood", "mat_stone", "mat_gold"};
const int[] input = {100, 35, 20};
const int[] output = {20, 30, 40};

const int fuel_per_scrap = 10; // how much fuel is needed to make 1 scrap
const int max_fuel = 1500.0f;
const int sound_cooldown = 6*30;
const f32 sound_fadeout_start = 150.0f;

const u8 boom_max = 20;

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	this.getShape().getConsts().mapCollisions = false;

	this.setPosition(this.getPosition() + Vec2f(0, -24));
	this.inventoryButtonPos = Vec2f(-20, 30);

	//commands
	this.addCommandID("add fuel");
	this.set_s16(fuel_prop, 0);
	this.set_bool(working_prop, false);
	this.set_s16(sound_cooldown_prop, 0);

	this.Tag("ignore_arrow");
	this.Tag("structure");

	this.set_u8("boom_start", 0);
	this.set_bool("booming", false);

	//CShape@ shape = this.getShape();
	//Vec2f[] topShape;
	//topShape.push_back(Vec2f(20.0f, 14.0f));
	//topShape.push_back(Vec2f(62.0f , 14.0f));
	//topShape.push_back(Vec2f(62.0f , 18.0f));
	//topShape.push_back(Vec2f(20.0f, 18.0f));
	//this.getShape().AddShape(topShape);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	CBlob@ carry = caller.getCarriedBlob();
	if (carry is null) return;

	const int mat_idx = mats.find(carry.getName());
	if (mat_idx == -1) return;
	if (this.get_s16(fuel_prop) > max_fuel - output[mat_idx]) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	
	CButton@ button = caller.CreateGenericButton("$"+carry.getName()+"$", Vec2f(1.0f, 3.0f), this, this.getCommandID("add fuel"), getTranslatedString("Smelt into scrap"), params);
	if (button !is null)
	{
		button.deleteAfterClick = false;
	}
}

void spawnMetal(CBlob@ this)
{
	Vec2f spawnpos = this.getPosition() + this.inventoryButtonPos;

	if (isClient())
	{
		for (u8 i = 0; i < 5; i++)
		{
			ParticleAnimated("LargeSmokeGray", spawnpos + Vec2f(XORRandom(16)-8 - 4, XORRandom(16)-8), Vec2f_zero, float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2, -0.0031f, true);
		}

		this.getSprite().PlaySound("ProduceSound.ogg", 0.5f, 1.15f+XORRandom(11)*0.01f);
	}
	
	if (!isServer()) return;

	int fuelCount = this.get_s16(fuel_prop);
	if (fuelCount < fuel_per_scrap) return;

	CBlob@ _metal = server_CreateBlobNoInit("mat_scrap");

	if (_metal is null) return;

	//setup res
	_metal.Tag("custom quantity");
	_metal.Init();
	_metal.setPosition(spawnpos);
	_metal.setVelocity(Vec2f(-2 - XORRandom(11)*0.1f, -3));
	_metal.server_SetQuantity(1); // assuming output[0] is the amount of scrap produced

	this.set_s16(fuel_prop, fuelCount - fuel_per_scrap); // burn fuel
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("add fuel"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller is null) return;
		
		CBlob@ carry = caller.getCarriedBlob();
		if (carry is null) return;

		string carriedName = carry.getName();
		int index = mats.find(carriedName);
		if (index == -1) return;

		f32 fuelAmount = carry.getQuantity();
		f32 fuelNeededPerOutput = f32(input[index]) / f32(output[index]);
		f32 currentFuel = this.get_s16(fuel_prop);
		f32 maxFuelToAdd = Maths::Min(output[index], max_fuel - currentFuel);

		if (fuelAmount >= fuelNeededPerOutput && currentFuel < max_fuel && fuelNeededPerOutput > 0)
		{
			f32 possibleOutput = f32(fuelAmount) / f32(fuelNeededPerOutput);
			f32 fuelToAdd = Maths::Min(possibleOutput, maxFuelToAdd);
			f32 currentFuel = this.get_s16(fuel_prop);
			
			this.set_s16(fuel_prop, currentFuel + fuelToAdd);
			if (isClient() && currentFuel < 10 && this.get_s16(fuel_prop) >= 10 && this.get_s16(sound_cooldown_prop) == 0)
			{
				this.getSprite().PlaySound("PowerUp.ogg", 1.0f, 0.6f+XORRandom(11)*0.01f);
				this.set_s16(sound_cooldown_prop, sound_cooldown);
			}

			carry.server_SetQuantity(fuelAmount - fuelToAdd * fuelNeededPerOutput);

			if (carry.getQuantity() <= 0)
			{
				carry.server_Die();
			}
		}
	}
}

void onTick(CBlob@ this)
{
	if (isClient())
	{
		if (this.get_bool(working_prop)) this.set_s16(sound_cooldown_prop, sound_cooldown);
		else if (this.get_s16(sound_cooldown_prop) > 0) this.set_s16(sound_cooldown_prop, this.get_s16(sound_cooldown_prop) - 1);
	}

	int fuelCount = this.get_s16(fuel_prop);
	if (fuelCount >= fuel_per_scrap)
	{
		this.set_bool(working_prop, true);

		if (getGameTime() % spawnmetal_frequency == 0)
		{
			spawnMetal(this);

			if (isServer())
			{
				if (fuelCount < fuel_per_scrap)
				{
					this.set_bool(working_prop, false);
				}

				this.Sync(fuel_prop, true);
			}
		}

		if (isServer()) this.Sync(working_prop, true);
	}
	else if (isServer())
	{
		this.set_bool(working_prop, false);
		this.Sync(working_prop, true);
	}

	if (this.get_bool("booming") && this.get_u8("boom_start") < boom_max && getGameTime() % 5 == 0)
	{
		if (!this.hasTag("set_new_spawn"))
		{
			this.Tag("set_new_spawn");
			
			CBlob@[] cores;
			getBlobsByName("core", @cores);
		
			f32 temp = 99999.0f;
			u16 closest_core_id = 0;
		
			for (uint i = 0; i < cores.length; i++)
			{
				CBlob@ core = cores[i];
				if (core is null) continue;
		
				f32 dist = (core.getPosition() - this.getPosition()).getLength();
				if (dist < temp)
				{
					temp = dist;
					closest_core_id = core.getNetworkID();
				}
			}
		
			if (closest_core_id != 0)
			{
				this.Untag("respawn");

				CBlob@ core = getBlobByNetworkID(closest_core_id);
				if (core !is null)
				{
					core.Tag("respawn");
				}
				else if (isServer()) // set team won
				{
					CRules@ rules = getRules(); // better to have a npe than no winner

					u8 teamleft = rules.get_u8("teamleft");
					u8 teamright = rules.get_u8("teamright");

					u8 teamwon = teamleft == this.getTeamNum() ? teamright : teamleft;
					CTeam@ winteam = rules.getTeam(teamwon);
					if (winteam !is null)
					{
						rules.SetTeamWon(teamwon);   //game over!
						rules.SetCurrentState(GAME_OVER);
						rules.SetGlobalMessage("Team \"{WINNING_TEAM}\" wins the game!\nAll reactors are gone!" );
						rules.AddGlobalMessageReplacement("WINNING_TEAM", winteam.getName());
					}
					else
					{
						error("Core.as couldn't find winning team");
					}
				}
			}
		}

		if (this.getShape() !is null) this.getShape().SetStatic(true);
		DoExplosion(this, Vec2f(0, 0));
		this.set_u8("boom_start", this.get_u8("boom_start") + 1);
		
		if (this.get_u8("boom_start") == boom_max) this.server_Die();
	}
}


bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

// draw a fuel/mat bar on mouse hover
void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;

	if (mouseOnBlob)
	{
		//VV right here VV
		f32 camFactor = getCamera().targetDistance;
		Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 30) * camFactor;
		Vec2f dim = Vec2f(64, 12) * camFactor;
		const f32 y = blob.getHeight() * 1.1f * camFactor;
		const f32 perc = float(blob.get_s16(fuel_prop)) / float(max_fuel);

		if (perc >= 0.0f)
		{
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xff8bbc7e));
		}

		GUI::SetFont("menu");
		GUI::DrawTextCentered("Fuel: " + blob.get_s16(fuel_prop) + " / " + max_fuel, Vec2f(pos2d.x - 1, pos2d.y + y + dim.y / 2), SColor(255, 255, 255, 255));
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (!isPTB()) return 0;

	if (hitterBlob.getName() == "c4" && hitterBlob.getTeamNum() != this.getTeamNum())
	{
		if (!this.get_bool("booming")) ExplosionEffects(this);
		this.set_bool("booming", true);
		this.set_u8("boom_start", 0);

		return damage;
	}
	return 0;
}

void DoExplosion(CBlob@ this, Vec2f velocity)
{
	ShakeScreen(1080, 128, this.getPosition());
	f32 modifier = this.get_u8("boom_start") / 3.0f;
	
	this.set_f32("map_damage_radius", 14.0f * this.get_u8("boom_start"));
	
	for (int i = 0; i < 4; i++)
	{
		Explode(this, 86.0f * modifier, 32.0f);
		//guarantly hit blobs
		if (getNet().isServer())
		{
			CMap@ map = getMap();

			CBlob@[] bs;
			map.getBlobsInRadius(this.getPosition(), 80.0f*modifier, bs);
			for (u32 i = 0; i < bs.length; i++)
			{
				CBlob@ b = bs[i];
				if (b is null) continue;

				if (map.rayCastSolidNoBlobs(b.getPosition(), this.getPosition())) continue;

				if (b.hasTag("flesh") || b.hasTag("vehicle"))
				{
					this.server_Hit(b, b.getPosition(), this.getOldVelocity(), 5.0f / (modifier+1), Hitters::keg);
				}
			}
		}
	}
}

void onInit(CSprite@ this)
{
	this.SetEmitSound("Core_loop.ogg");
	this.SetEmitSoundVolume(0.5f);
	this.SetEmitSoundPaused(true);
	this.SetZ(-150.0f); //background

	CSpriteLayer@ decor = this.addSpriteLayer("decor", "Core.png", 48, 16, -1, -1);
	if (decor !is null)
	{
		Animation@ anim = decor.addAnimation("default", 0, false);
		anim.AddFrame(5);

		decor.SetOffset(Vec2f(0, -34));
		decor.SetRelativeZ(1.0f);
	}

	this.SetFacingLeft(false);
	CBlob@ blob = this.getBlob();

	blob.SetLight(true);
	blob.SetLightRadius(256.0f);
	blob.SetLightColor(SColor(255, 255, 200, 170));
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (blob.get_s16(fuel_prop) >= fuel_per_scrap)
	{
		f32 factor = Maths::Min(1.0f, f32(blob.get_s16(fuel_prop)) / f32(sound_fadeout_start));
		float volume = 0.0f + 0.5f * factor;
		float speed = 0.5f + 0.5f * factor;

		this.SetEmitSoundVolume(volume);
		this.SetEmitSoundSpeed(speed);
	}

	if (blob.get_bool(working_prop))
	{
		if ((getGameTime() + blob.getNetworkID()) % 10 == 0)
		{
			CParticle@ p = ParticleAnimated("LargeSmokeWhite", blob.getPosition() - Vec2f(XORRandom(8), 44+XORRandom(16)), getRandomVelocity(0.0f, XORRandom(25) * 0.005f, 360) + Vec2f(0.15,-0.05), float(XORRandom(360)), 1.1f + XORRandom(16) * 0.01f, 16 + XORRandom(6), -0.005 + XORRandom(10) * -0.0001f, true);
			if (p !is null)
			{
				p.Z = 500.0f;
				p.deadeffect = -1;
			}
		}

		this.SetEmitSoundPaused(false);
	}
	else
	{
		this.SetEmitSoundPaused(true);
	}
}

void ExplosionEffects(CBlob@ this)
{
	Vec2f pos = this.getPosition();

	CParticle@ p = ParticleAnimated("explosion-huge1.png",
		pos - Vec2f(0,40),
		Vec2f(0.0,0.0f),
		1.0f, 1.5f,
		5,
		0.0f, true );
	if (p != null)
	{
		p.Z = 100;
	}

	SetScreenFlash(200, 255, 255, 100);
	Sound::Play("explosion-big1.ogg");

    this.getSprite().SetEmitSoundPaused( true );
}

void onDie(CBlob@ this)
{
		
}