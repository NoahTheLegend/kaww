const string stone = "mat_gold";
const string stone_prop = "stone_level";
const string working_prop = "working";

const int input = 20;					//input cost in fuel
const int output = 4;					//output amount in metal
const int min_input = Maths::Ceil(input/output);

#include "GenericButtonCommon.as";
#include "Hitters.as";
#include "HittersAW.as";

void onInit(CSprite@ this)
{
	this.SetEmitSound("/Refinery_fire.ogg"); //Refinery_fire
	this.SetEmitSoundVolume(0.8f);
	this.SetEmitSoundPaused(true);
	this.SetZ(-150.0f); //background

	this.SetFacingLeft(XORRandom(2) == 0);

	CBlob@ b = this.getBlob();
	b.SetLight(false);
	b.SetLightRadius(50.0f);
	b.SetLightColor(SColor(255, 255, 200, 170));
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if (b.get_bool(working_prop)) {

		if (this.isAnimation("use"))
		{
			b.SetLight(true);
			if ((getGameTime() + b.getNetworkID()) % 30 == 0) {
				ParticleAnimated("LargeSmoke", b.getPosition() + Vec2f(b.isFacingLeft() ? -1 : 1 * (XORRandom(8) - 10), XORRandom(8) - 20), getRandomVelocity(0.0f, XORRandom(25) * 0.005f, 360) + Vec2f(0.15,-0.05), float(XORRandom(360)), 0.9f + XORRandom(20) * 0.01f, 16 + XORRandom(6), -0.005 + XORRandom(10) * -0.0001f, true);

				Vec2f velr = getRandomVelocity(90, 1.3f, 40.0f);
				velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;
			}
		}
		else {
			
			this.SetAnimation("start");

			if (getGameTime() % 4 == 0) this.PlaySound("lightup.ogg");

			if (this.isAnimationEnded())
			{
				this.SetAnimation("use");
			}
		}
	}
	else {
		if (this.isAnimation("use"))
		{
			this.SetAnimation("end");

			if (this.getFrameIndex() == 0) this.PlaySound("ExtinguishFire.ogg");
		}
		else if (this.isAnimation("end") && this.isAnimationEnded()) {
			b.SetLight(false);
			this.SetAnimation("default");
		}
		
	}
}

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	
	this.getShape().getConsts().mapCollisions = false;

	//commands
	this.addCommandID("add stone");
	this.set_s16(stone_prop, 0);
	this.set_bool(working_prop, false);

	this.Tag("ignore_arrow");
	this.Tag("builder always hit");
	this.Tag("structure");
	this.Tag("refinery");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	if (!caller.hasBlob("mat_gold", 1)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton("$mat_gold$", Vec2f(1.0f, 3.0f), this, this.getCommandID("add stone"), getTranslatedString("Smelt gold"), params);
	if (button !is null)
	{
		button.deleteAfterClick = false;
		button.SetEnabled(caller.hasBlob(stone, 1));
	}
}

void spawnMetal(CBlob@ this)
{
	int blobCount = this.get_s16(stone_prop);
	int actual_input = Maths::Min(input, blobCount);

	CBlob@ _metal = server_CreateBlobNoInit("mat_scrap");

	if (_metal is null) return;

	int amountToSpawn = Maths::Floor(output * actual_input / input);

	//setup res
	_metal.Tag("custom quantity");
	_metal.Init();
	_metal.setPosition(this.getPosition()-Vec2f(0,0));
	_metal.server_SetQuantity(output);

	this.set_s16(stone_prop, blobCount - actual_input); //burn wood
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("add stone"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller is null) return;

		//amount we'd _like_ to insert
		int requestedAmount = Maths::Min(25, 200 - this.get_s16(stone_prop));
		//(possible with laggy commands from 2 players, faster to early out here if we can)
		if (requestedAmount <= 0) return;

		CBlob@ carried = caller.getCarriedBlob();
		//how much stone does the caller have including what's potentially in his hand?
		int callerQuantity = caller.getInventory().getCount(stone) + (carried !is null && carried.getName() == stone ? carried.getQuantity() : 0);

		//amount we _can_ insert
		int ammountToStore = Maths::Min(requestedAmount, callerQuantity);
		//can we even insert anything?
		if (ammountToStore > 0)
		{
			caller.TakeBlob(stone, ammountToStore);
			this.set_s16(stone_prop, this.get_s16(stone_prop) + ammountToStore);

			this.getSprite().PlaySound("FireFwoosh.ogg");
		}
	}
}

void onTick(CBlob@ this)
{
	//only do "real" update logic on server
	if (getNet().isServer())
	{
		int blobCount = this.get_s16(stone_prop);
		if ((blobCount >= min_input))
		{
			this.set_bool(working_prop, true);

			//only convert every conversion_frequency seconds
			if (getGameTime() % (10 * getTicksASecond()) == 0)
			{
				spawnMetal(this);

				if (blobCount - input < min_input)
				{
					this.set_bool(working_prop, false);
				}

				this.Sync(stone_prop, true);
			}

			this.Sync(working_prop, true);
		}
	}

	CSprite@ sprite = this.getSprite();
	if (sprite.getEmitSoundPaused())
	{
		if (this.get_bool(working_prop))
		{
			sprite.SetEmitSoundPaused(false);
		}
	}
	else if (!this.get_bool(working_prop))
	{
		sprite.SetEmitSoundPaused(true);
	}
}

// draw a stone/mat bar on mouse hover

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
		Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 30);
		Vec2f dim = Vec2f(24, 8);
		const f32 y = blob.getHeight() * 2.4f;
		const f32 perc = blob.get_s16(stone_prop) / 200.0f;

		if (perc >= 0.0f)
		{
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xff8bbc7e));
		}
	}
}

void onDie(CBlob@ this)
{
	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());

	CBlob@ b = server_CreateBlob("mat_stone",this.getTeamNum(),this.getPosition());
	if (b !is null)
	{
		b.server_SetQuantity(100+XORRandom(51));
	}
	CBlob@ b1 = server_CreateBlob("mat_gold",this.getTeamNum(),this.getPosition());
	if (b1 !is null)
	{
		b1.server_SetQuantity(20+(XORRandom(11)*2));
	}
}