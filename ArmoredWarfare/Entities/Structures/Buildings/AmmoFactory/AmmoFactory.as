#include "TeamColorCollections.as"

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

	this.getSprite().SetZ(-150.0f); //background

	//commands
	this.addCommandID("add metal");

	this.set_s16(metal_prop, 0);
	this.set_bool(working_prop, false);
	this.set_u8(unique_prop, XORRandom(getTicksASecond() * 30));

	this.Tag("builder always hit");
	this.Tag("structure");

	this.set_string("prod_blob", "ammo");
	this.set_u8("prod_amount", 50);
	this.set_u8("prod_time", 0);
	this.set_u8("cost", 1);
	this.set_f32("mod", 1.0f);

	this.addCommandID("select");
	this.addCommandID("7mm");
	this.addCommandID("14mm");
	this.addCommandID("105mm");
	this.addCommandID("heats");
	this.addCommandID("molotov");
	this.addCommandID("grenade");
	this.addCommandID("mine");
	this.addCommandID("helmet");
	this.addCommandID("specammo");
	this.addCommandID("medkit");
	this.addCommandID("playsound");
	this.addCommandID("direct_pick");

	if (sprite is null) return;
	CSpriteLayer@ icon = sprite.addSpriteLayer("icon", "AmmoFactoryIcons.png", 8, 8);
	if (icon !is null)
	{
		int[] frames = {0,1,2,3,4,5,6,7,8,9};
		icon.SetOffset(Vec2f(-0.5f,-8));
		Animation@ anim = icon.addAnimation("default", 0, false);
		if (anim !is null)
		{
			anim.AddFrames(frames);
			icon.SetAnimation(anim);
			icon.SetFrameIndex(0);
		}
	}

	this.inventoryButtonPos = Vec2f(-8.0f, 0);
}

void onTick(CBlob@ this)
{
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			CSpriteLayer@ icon = sprite.getSpriteLayer("icon");
			if (icon !is null)
			{
				u8 index = 0;
				string b = this.get_string("prod_blob");

				if (b == "ammo")
					index = 0;
				else if (b == "mat_14mmround")
					index = 1;
				else if (b == "mat_bolts")
					index = 2;
				else if (b == "mat_heatwarhead")
					index = 3;
				else if (b == "mat_molotov")
					index = 4;
				else if (b == "grenade")
					index = 5;
				else if (b == "mine")
					index = 6;
				else if (b == "helmet")
					index = 7;
				else if (b == "specammo")
					index = 8;
				else if (b == "medkit")
					index = 9;

				icon.SetAnimation("default");
				icon.SetFrameIndex(index);
			}
		}
	}
	if (getNet().isServer())
	{
		int blobCount = this.get_s16(metal_prop);
		CInventory@ inventory = this.getInventory();

		if(blobCount >= this.get_u8("cost"))
		{
			this.set_bool(working_prop, true);

			//only convert every conversion_frequency seconds
			if (getGameTime() % ((((10 + this.get_u8("prod_time")))) * getTicksASecond()) == this.get_u8(unique_prop))
			{
				if(blobCount >= this.get_u8("cost")) this.sub_s16(metal_prop, this.get_u8("cost"));
				else this.TakeBlob(metal_prop, this.get_u8("cost"));
			
				spawnMetal(this);
				this.set_u32("last_prod", getGameTime());
				this.Sync("last_prod", true);

				this.set_bool(working_prop, false);

				this.Sync(metal_prop, true);
			}

			this.Sync(working_prop, true);
		}
		else this.set_u32("last_prod", getGameTime());
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
	if (!canSeeButtons(this, caller) || !this.isOverlapping(caller)) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton("$mat_scrap$", Vec2f(0.0f, 10.0f), this, this.getCommandID("add metal"), getTranslatedString("Add scrap"), params);
	if (button !is null)
	{
		button.deleteAfterClick = false;
		button.SetEnabled(caller.hasBlob(metal, 1));
	}

	caller.CreateGenericButton(16, Vec2f(0.0f, -10.0f), this, this.getCommandID("select"), "Select product", params);

	if (this.getInventory() !is null)
	{
		CBlob@ item = this.getInventory().getItem(this.get_string("prod_blob"));
		if (item !is null)
		{
			caller.CreateGenericButton(24, Vec2f(4.0f, 0.0f), this, this.getCommandID("direct_pick"), "Pick product", params);
		}
	}
}

void spawnMetal(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ b = server_CreateBlob(this.get_string("prod_blob"), -1, this.getPosition());
		b.server_SetQuantity(this.get_u8("prod_amount"));
		if (!this.server_PutInInventory(b))
		{
			b.setPosition(this.getPosition());
		}
		CBitStream params;
		this.SendCommand(this.getCommandID("playsound"), params);
	}
}

void ResetTimer(CBlob@ this)
{
	this.set_u32("last_prod", getGameTime());
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
	else if (cmd == this.getCommandID("direct_pick"))
	{
		if (isServer())
		{
			u16 callerid;
			if (!params.saferead_u16(callerid)) return;

			CBlob@ caller = getBlobByNetworkID(callerid);
			if (caller is null) return;

			if (this.getInventory() !is null)
			{
				CBlob@ item = this.getInventory().getItem(this.get_string("prod_blob"));
				if (item !is null)
				{
					this.server_PutOutInventory(item);
					if (!caller.server_PutInInventory(item))
					{
						caller.server_AttachTo(item, "PICKUP");
					}
				}
			}
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
		this.set_string("prod_blob", "ammo"); // blob cfg name
		this.set_u8("prod_amount", 50); // how many
		this.set_u8("prod_time", 2); // extra seconds time (10 sec for default)
		this.set_u8("cost", 1); // how many scrap to take

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("14mm"))
	{
		this.set_string("prod_blob", "mat_14mmround");
		this.set_u8("prod_amount", 15);
		this.set_u8("prod_time", 10);
		this.set_u8("cost", 1);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("105mm"))
	{
		this.set_string("prod_blob", "mat_bolts");
		this.set_u8("prod_amount", 4);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 1);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("heats"))
	{
		this.set_string("prod_blob", "mat_heatwarhead");
		this.set_u8("prod_amount", 3);
		this.set_u8("prod_time", 35);
		this.set_u8("cost", 7);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("molotov"))
	{
		bool rebels_power = getRules().get_bool("enable_powers") && this.getTeamNum() == 3; // team 3 buff
        u8 extra_amount = 0;
        if (rebels_power) extra_amount = 4;

		this.set_string("prod_blob", "mat_molotov");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 12-extra_amount);
		this.set_u8("cost", 2);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("grenade"))
	{
		this.set_string("prod_blob", "grenade");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 3);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("mine"))
	{
		this.set_string("prod_blob", "mine");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 20);
		this.set_u8("cost", 2);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("helmet"))
	{
		this.set_string("prod_blob", "helmet");
		this.set_u8("prod_amount", 1);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 2);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("specammo"))
	{
		this.set_string("prod_blob", "specammo");
		this.set_u8("prod_amount", 50);
		this.set_u8("prod_time", 15);
		this.set_u8("cost", 2);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("medkit"))
	{
		this.set_string("prod_blob", "medkit");
		this.set_u8("prod_amount", 2);
		this.set_u8("prod_time", 20);
		this.set_u8("cost", 3);

		ResetTimer(this);
	}
	else if (cmd == this.getCommandID("playsound"))
	{
		this.getSprite().PlaySound("MakeAmmo.ogg");
	}
}

void SelectMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(5, 2), "Select product");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;

			CGridButton@ button0 = menu.AddButton("$ammo$", "Ammo", this.getCommandID("7mm"), Vec2f(1, 1), params);
			CGridButton@ button8 = menu.AddButton("$specammo$", "Special Ammo", this.getCommandID("specammo"), Vec2f(1, 1), params);
			CGridButton@ button1 = menu.AddButton("$mat_14mmround$", "14mm Shells", this.getCommandID("14mm"), Vec2f(1, 1), params);
			CGridButton@ button2 = menu.AddButton("$mat_bolts$", "105mm Shells", this.getCommandID("105mm"), Vec2f(1, 1), params);
			CGridButton@ button3 = menu.AddButton("$mat_heatwarhead$", "HEAT Warheads", this.getCommandID("heats"), Vec2f(1, 1), params);
			CGridButton@ button4 = menu.AddButton("$mat_molotov$", "Molotov", this.getCommandID("molotov"), Vec2f(1, 1), params);
			CGridButton@ button5 = menu.AddButton("$grenade$", "Grenade", this.getCommandID("grenade"), Vec2f(1, 1), params);
			CGridButton@ button6 = menu.AddButton("$mine$", "Mine", this.getCommandID("mine"), Vec2f(1, 1), params);
			CGridButton@ button7 = menu.AddButton("$helmet$", "Helmet", this.getCommandID("helmet"), Vec2f(1, 1), params);
			CGridButton@ button9 = menu.AddButton("$medkit$", "Medkit", this.getCommandID("medkit"), Vec2f(1, 1), params);

			if (button0 !is null && button1 !is null && button2 !is null && button3 !is null && button4 !is null && button5 !is null && button6 !is null && button7 !is null)
			{
				string prod_prop = this.get_string("prod_blob");

				if (prod_prop == "ammo")
					button0.SetEnabled(false);
				else if (prod_prop == "mat_14mmround")
					button1.SetEnabled(false);
				else if (prod_prop == "mat_bolts")
					button2.SetEnabled(false);
				else if (prod_prop == "mat_heatwarhead")
					button3.SetEnabled(false);
				else if (prod_prop == "mat_molotov")
					button4.SetEnabled(false);
				else if (prod_prop == "grenade")
					button5.SetEnabled(false);
				else if (prod_prop == "mine")
					button6.SetEnabled(false);
				else if (prod_prop == "helmet")
					button7.SetEnabled(false);
				else if (prod_prop == "specammo")
					button8.SetEnabled(false);
				else if (prod_prop == "medkit")
					button9.SetEnabled(false);
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{  
	switch (customData)
	{
     	case Hitters::builder:
			damage *= 2.00f;
			break;
	}
	if (hitterBlob.getName() == "balista_bolt" || hitterBlob.hasTag("grenade") || hitterBlob.getName() == "c4")
	{
		damage *= 5.0f;
	} 
	return damage;
}

/*bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
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
}*/

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
	if (!mouseOnBlob) return;

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

	u32 time = blob.get_u32("last_prod");
	f32 req_time = (blob.get_u8("prod_time")+10) * 30;
	f32 time_left = time + req_time;
	f32 percent = (time_left - getGameTime()) / req_time;

	//printf("time "+time);
	//printf("req_time "+req_time);
	//printf("time_left "+time_left);
	//printf("getgametime "+getGameTime());
	//printf("perc "+percent);

	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 0);
	const f32 y = blob.getHeight() * 4.15f;
	Vec2f dim = Vec2f(24, 5); //95
	Vec2f percdim = Vec2f(Maths::Min(24-24*percent, 24), 5); //95

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	SColor color = getNeonColor(blob.getTeamNum(), 0);
	// Border
	GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2,                        pos2d.y + y - 4),
						Vec2f(pos2d.x + dim.x + 2,                        pos2d.y + y + dim.y + 4));

	GUI::DrawRectangle(Vec2f(pos2d.x - percdim.x + 2,                    pos2d.y + y + 0),
						Vec2f(pos2d.x + percdim.x - 1,                    pos2d.y + y + percdim.y - 1), color);
}

void onDie(CBlob@ this)
{
	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return this.getTeamNum() == forBlob.getTeamNum() || forBlob.isOverlapping(this);
}