const string metal = "mat_scrap";
const string metal_prop = "metal_level";
const string working_prop = "working";
const string unique_prop = "unique";

#include "GenericButtonCommon.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	this.set_TileType("background tile", CMap::tile_wood_back);
	this.getSprite().getConsts().accurateLighting = true;
	this.getShape().getConsts().mapCollisions = false;

	this.getSprite().SetZ(-50); //background

	//commands
	this.addCommandID("add metal");

	this.set_s16(metal_prop, 0);
	this.set_bool(working_prop, false);
	this.set_u8(unique_prop, XORRandom(getTicksASecond() * 30));

	this.Tag("builder always hit");
	this.Tag("structure");

	this.set_string("prod_blob", "mat_7mmround");
	this.set_u8("prod_amount", 50);
	this.set_u8("prod_time", 0);
	this.set_u8("cost", 1);

	this.addCommandID("select");
	this.addCommandID("7mm");
	this.addCommandID("14mm");
	this.addCommandID("105mm");
	this.addCommandID("heats");
	this.addCommandID("molotov");
	this.addCommandID("grenade");
	this.addCommandID("mine");
	this.addCommandID("helmet");
}

void onTick(CBlob@ this)
{
	if (getNet().isServer())
	{
		int blobCount = this.get_s16(metal_prop);
		CInventory@ inventory = this.getInventory();

		if((this.getBlobCount(metal) > 0 || blobCount >= 1) && inventory.getItemsCount() <= 24)
		{
			this.set_bool(working_prop, true);

			//only convert every conversion_frequency seconds
			if (getGameTime() % ((10 + (this.get_u8("prod_time"))) * getTicksASecond()) == this.get_u8(unique_prop))
			{
				if(blobCount >= this.get_u8("cost"))this.sub_s16(metal_prop, this.get_u8("cost"));
				else this.TakeBlob(metal_prop, this.get_u8("cost"));
			
				spawnMetal(this);

				this.set_bool(working_prop, false);

				this.Sync(metal_prop, true);
			}

			this.Sync(working_prop, true);
		}
		if (getGameTime() % (15 * getTicksASecond()) == this.get_u8(unique_prop))PickupOverlap(this);
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

void PickupOverlap(CBlob@ this)
{
	Vec2f tl, br;
	this.getShape().getBoundingRect(tl, br);
	CBlob@[] blobs;
	this.getMap().getBlobsInBox(tl, br, @blobs);
	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!blob.isAttached() && blob.isOnGround() && blob.getName() == metal)
		{
			this.server_PutInInventory(blob);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton("$mat_scrap$", Vec2f(0.0f, 10.0f), this, this.getCommandID("add metal"), getTranslatedString("Add scrap"), params);
	if (button !is null)
	{
		button.deleteAfterClick = false;
		button.SetEnabled(caller.hasBlob(metal, 1));
	}

	caller.CreateGenericButton(16, Vec2f(0.0f, -9.0f), this, this.getCommandID("select"), "Select product", params);
}

void spawnMetal(CBlob@ this)
{
	this.getSprite().PlaySound("MakeAmmo.ogg");
			
	if (isServer())
	{
		CBlob@ b = server_CreateBlob(this.get_string("prod_blob"), -1, this.getPosition());
		b.server_SetQuantity(this.get_u8("prod_amount"));
		if (!this.server_PutInInventory(b))
		{
			b.setPosition(this.getPosition());
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("add metal"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller is null) return;

		//amount we'd _like_ to insert
		int requestedAmount = Maths::Max(0, 20 - this.get_s16(metal_prop));
		//(possible with laggy commands from 2 players, faster to early out here if we can)
		if (requestedAmount <= 0) return;

		CBlob@ carried = caller.getCarriedBlob();
		//how much metal does the caller have including what's potentially in his hand?
		int callerQuantity = caller.getInventory().getCount(metal) + (carried !is null && carried.getName() == metal ? carried.getQuantity() : 0);

		//amount we _can_ insert
		int ammountToStore = Maths::Min(requestedAmount, callerQuantity);
		//can we even insert anything?
		if (ammountToStore > 0)
		{
			//print("added "+ammountToStore);
			caller.TakeBlob(metal, ammountToStore);
			this.add_s16(metal_prop, ammountToStore);

			this.getSprite().PlaySound("FireFwoosh.ogg");
		}
	}
	else if (cmd == this.getCommandID("select"))
	{
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		SelectMenu(this, blob);
	}
	else if (cmd == this.getCommandID("7mm"))
	{
		this.set_string("prod_blob", "mat_7mmround"); // blob cfg name
		this.set_u8("prod_amount", 50); // how many
		this.set_u8("prod_time", 2); // extra seconds time (10 sec for default)
		this.set_u8("cost", 1); // how many scrap to take
	}
	else if (cmd == this.getCommandID("14mm"))
	{
		this.set_string("prod_blob", "mat_14mmround");
		this.set_u8("prod_amount", 15);
		this.set_u8("prod_time", 10);
		this.set_u8("cost", 1);
	}
	else if (cmd == this.getCommandID("105mm"))
	{
		this.set_string("prod_blob", "mat_bolts");
		this.set_u8("prod_amount", 4);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 1);
	}
	else if (cmd == this.getCommandID("heats"))
	{
		this.set_string("prod_blob", "mat_heatwarhead");
		this.set_u8("prod_amount", 3);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 6);
	}
	else if (cmd == this.getCommandID("molotov"))
	{
		this.set_string("prod_blob", "mat_molotov");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 10);
		this.set_u8("cost", 2);
	}
	else if (cmd == this.getCommandID("grenade"))
	{
		this.set_string("prod_blob", "grenade");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 3);
	}
	else if (cmd == this.getCommandID("mine"))
	{
		this.set_string("prod_blob", "mine");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 20);
		this.set_u8("cost", 2);
	}
	else if (cmd == this.getCommandID("helmet"))
	{
		this.set_string("prod_blob", "helmet");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 2);
	}
}

void SelectMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(4, 2), "Select product");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;

			CGridButton@ button  = menu.AddButton("$mat_7mmround$", "7mm Rounds", this.getCommandID("7mm"), Vec2f(1, 1), params);
			CGridButton@ button1 = menu.AddButton("$mat_14mmround$", "14mm Shells", this.getCommandID("14mm"), Vec2f(1, 1), params);
			CGridButton@ button2 = menu.AddButton("$mat_bolts$", "105mm Shells", this.getCommandID("105mm"), Vec2f(1, 1), params);
			CGridButton@ button3 = menu.AddButton("$mat_heatwarhead$", "HEAT Warheads", this.getCommandID("heats"), Vec2f(1, 1), params);
			CGridButton@ button4 = menu.AddButton("$mat_molotov$", "Molotov", this.getCommandID("molotov"), Vec2f(1, 1), params);
			CGridButton@ button5 = menu.AddButton("$grenade$", "Grenade", this.getCommandID("grenade"), Vec2f(1, 1), params);
			CGridButton@ button6 = menu.AddButton("$mine$", "Mine", this.getCommandID("mine"), Vec2f(1, 1), params);
			CGridButton@ button7 = menu.AddButton("$helmet$", "Helmet", this.getCommandID("helmet"), Vec2f(1, 1), params);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum()) damage *= 5;
	switch (customData)
	{
	
     	case Hitters::builder:
			damage *= 7.00f;
			break;

	}
	return damage;
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

// draw a mat bar on mouse hover

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
		const f32 perc = blob.get_s16(metal_prop) / 20.0f;

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