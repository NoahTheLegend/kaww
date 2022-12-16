const string stone = "mat_stone";
const string stone_prop = "stone_level";
const string working_prop = "working";

const int input = 20;					//input cost in fuel
const int output = 2;					//output amount in metal
const int min_input = Maths::Ceil(input/output);

#include "GenericButtonCommon.as";
#include "Hitters.as";

void onInit(CSprite@ this)
{
	this.SetEmitSound("/Refinery_fire.ogg");
	this.SetEmitSoundPaused(true);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.get_bool(working_prop))
	{
		this.SetAnimation("use");
	}
	else
	{
		this.SetAnimation("default");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum()) damage *= 5;
	switch (customData)
	{
     	case Hitters::builder:
			damage *= 3.50f;
			break;
	}
	if (hitterBlob.getName() == "grenade")
	{
		return damage * 3;
	}
	return damage;
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
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton("$mat_stone$", Vec2f(1.0f, 3.0f), this, this.getCommandID("add stone"), getTranslatedString("Convert stone to scrap"), params);
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
	_metal.setPosition(this.getPosition());
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
		int requestedAmount = Maths::Min(250, 500 - this.get_s16(stone_prop));
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

	if (XORRandom(2) == 0)
	{
		CBlob@[] blobsInRadius;
		if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.1f, @blobsInRadius))
		{
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob @b = blobsInRadius[i];

				if (b.isOnGround() && !b.isAttached() && b.getName() == "mat_stone") // stone on floor
				{
					if (b is null) return;

					//amount we'd _like_ to insert
					int ammountToStore = Maths::Clamp(b.getQuantity(), 0, 500 - this.get_s16(stone_prop));

					//can we even insert anything?
					if (ammountToStore > 0)
					{
						b.server_SetQuantity(b.getQuantity() - ammountToStore);
						this.set_s16(stone_prop, this.get_s16(stone_prop) + ammountToStore);

						this.getSprite().PlaySound("FireFwoosh.ogg");
					}
				}
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum() || blob.hasTag("vehicle")) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
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
		const f32 perc = blob.get_s16(stone_prop) / 500.0f;

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
}