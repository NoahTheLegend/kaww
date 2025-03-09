#include "TeamColorCollections.as"

const string metal = "mat_scrap";
const string metal_prop = "metal_level";
const string working_prop = "working";

#include "GenericButtonCommon.as";
#include "Hitters.as";
#include "HittersAW.as";

const string[] prod_blobs = {
	"ammo", "mat_14mmround", "mat_bolts", "mat_heatwarhead", "mat_molotov", 
	"grenade", "mine", "helmet", "specammo", "mat_atgrenade"
};
const u32[] prod_amounts = {
	200, 18, 6, 3, 1, 
	1, 1, 1, 50, 1
};
const u32[] prod_times = {
	8, 15, 20, 35, 12, 
	20, 30, 15, 15, 25
};
const u8[] costs = {
	1, 1, 1, 7, 2, 
	2, 3, 2, 2, 3
};

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
	this.set_u32("timer", 0);
	this.set_bool(working_prop, false);

	this.Tag("builder always hit");
	this.Tag("structure");

	this.set_string("prod_blob", prod_blobs[0]);
	this.set_u32("prod_amount", prod_amounts[0]);
	this.set_u32("prod_time", prod_times[0]);
	this.set_u8("cost", costs[0]);
	this.set_f32("mod", 1.0f);
	this.set_bool("drop_items", false);
	this.set_u32("timer", 0);

	this.addCommandID("select");
	this.addCommandID("7mm");
	this.addCommandID("14mm");
	this.addCommandID("tankshell");
	this.addCommandID("heats");
	this.addCommandID("molotov");
	this.addCommandID("grenade");
	this.addCommandID("mine");
	this.addCommandID("helmet");
	this.addCommandID("specammo");
	this.addCommandID("medkit");
	this.addCommandID("atgrenade");
	this.addCommandID("playsound");
	this.addCommandID("direct_pick");
	this.addCommandID("switch_mode");

	if (sprite is null) return;
	CSpriteLayer@ icon = sprite.addSpriteLayer("icon", "AmmoFactoryIcons.png", 8, 8);
	if (icon !is null)
	{
		int[] frames = {0,1,2,3,4,5,6,7,8,9,10};
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
				icon.SetFrameIndex(this.get_u8("id"));
			}
		}
	}
	if (getNet().isServer())
	{
		int blobCount = this.get_s16(metal_prop);
		CInventory@ inventory = this.getInventory();

		if (blobCount >= this.get_u8("cost"))
		{
			this.set_bool(working_prop, true);

			u32 timer = this.get_u32("timer");
			u32 prod_time = this.get_u32("prod_time");
			
			if (timer == prod_time * getTicksASecond())
			{
				if (blobCount >= this.get_u8("cost")) this.sub_s16(metal_prop, this.get_u8("cost"));
				else this.TakeBlob(metal_prop, this.get_u8("cost"));

				spawnBlob(this);
				this.set_u32("last_prod", getGameTime());
				//this.Sync("last_prod", true);

				this.set_bool(working_prop, false);
				this.Sync(metal_prop, true);
			}
			
			this.set_u32("timer", timer >= prod_time * getTicksASecond() ? 0 : timer + 1);
			this.Sync("timer", true);
			this.Sync(working_prop, true);
		}
		else this.set_u32("last_prod", getGameTime());
		if (getGameTime() % (15 * getTicksASecond()) == 0) PickupOverlap(this);
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

	if (caller.hasBlob("mat_scrap", 1))
	{
		CButton@ button = caller.CreateGenericButton("$mat_scrap$", Vec2f(0.0f, 10.0f), this, this.getCommandID("add metal"), getTranslatedString("Add scrap"), params);
		if (button !is null)
		{
			button.deleteAfterClick = false;
			button.SetEnabled(caller.hasBlob(metal, 1));
		}
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

	caller.CreateGenericButton(8, Vec2f(10.0f, -10.0f), this, this.getCommandID("switch_mode"), this.get_bool("drop_items") ? "Mode: Put to inventory" : "Mode: Drop items", params);
}

void spawnBlob(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ b = server_CreateBlob(this.get_string("prod_blob"), this.getTeamNum(), this.getPosition());
		b.server_SetQuantity(this.get_u32("prod_amount"));

		if (this.get_bool("drop_items")) b.setPosition(this.getPosition());
		else if (!this.server_PutInInventory(b)) b.setPosition(this.getPosition());
		
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

		int requestedAmount = Maths::Max(0, 20 - this.get_s16(metal_prop));
		if (requestedAmount <= 0) return;

		CBlob@ carried = caller.getCarriedBlob();
		int callerQuantity = caller.getInventory().getCount(metal) + (carried !is null && carried.getName() == metal ? carried.getQuantity() : 0);

		int amountToStore = Maths::Min(Maths::Max(1, this.get_u8("cost")), callerQuantity);
		if (amountToStore > 0)
		{
			caller.TakeBlob(metal, amountToStore);
			this.add_s16(metal_prop, amountToStore);
			
			CRules@ rules = getRules();
			if (isServer() && rules !is null)
			{
				CPlayer@ p = caller.getPlayer();
				
				if (p !is null)
				{
					CBitStream params;
					params.write_string(p.getUsername());
					params.write_u16(amountToStore);
					rules.SendCommand(rules.getCommandID("scrap_used"), params);
				}
			}

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
	else if (cmd == this.getCommandID("switch_mode"))
	{
		this.set_bool("drop_items", !this.get_bool("drop_items"));
		if (isServer()) this.Sync("drop_items", true);
	}
	else if (cmd == this.getCommandID("select"))
	{
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		SelectMenu(this, blob);
	}
	else if (cmd >= this.getCommandID("7mm") && cmd <= this.getCommandID("atgrenade"))
	{
		u8 index = cmd - this.getCommandID("7mm");
		this.set_string("prod_blob", prod_blobs[index]);
		this.set_u32("prod_amount", prod_amounts[index]);
		this.set_u32("prod_time", prod_times[index]);
		this.set_u8("cost", costs[index]);
		this.set_u8("id", index);

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
			CGridButton@ button0 = menu.AddButton("$ammo$", "Ammo (" + costs[0] + " -> " + prod_amounts[0] + " -> " + prod_times[0] + "s)", this.getCommandID("7mm"), Vec2f(1, 1), params);
			CGridButton@ button1 = menu.AddButton("$mat_14mmround$", "14mm Shells (" + costs[1] + " -> " + prod_amounts[1] + " -> " + prod_times[1] + "s)", this.getCommandID("14mm"), Vec2f(1, 1), params);
			CGridButton@ button2 = menu.AddButton("$mat_bolts$", "Tank Shells (" + costs[2] + " -> " + prod_amounts[2] + " -> " + prod_times[2] + "s)", this.getCommandID("tankshell"), Vec2f(1, 1), params);
			CGridButton@ button3 = menu.AddButton("$mat_heatwarhead$", "HEAT Warheads (" + costs[3] + " -> " + prod_amounts[3] + " -> " + prod_times[3] + "s)", this.getCommandID("heats"), Vec2f(1, 1), params);
			CGridButton@ button4 = menu.AddButton("$mat_molotov$", "Molotov (" + costs[4] + " -> " + prod_amounts[4] + " -> " + prod_times[4] + "s)", this.getCommandID("molotov"), Vec2f(1, 1), params);
			CGridButton@ button5 = menu.AddButton("$grenade$", "Grenade (" + costs[5] + " -> " + prod_amounts[5] + " -> " + prod_times[5] + "s)", this.getCommandID("grenade"), Vec2f(1, 1), params);
			CGridButton@ button6 = menu.AddButton("$mine$", "Mine (" + costs[6] + " -> " + prod_amounts[6] + " -> " + prod_times[6] + "s)", this.getCommandID("mine"), Vec2f(1, 1), params);
			CGridButton@ button7 = menu.AddButton("$helmet$", "Helmet (" + costs[7] + " -> " + prod_amounts[7] + " -> " + prod_times[7] + "s)", this.getCommandID("helmet"), Vec2f(1, 1), params);
			CGridButton@ button8 = menu.AddButton("$specammo$", "Special Ammo (" + costs[8] + " -> " + prod_amounts[8] + " -> " + prod_times[8] + "s)", this.getCommandID("specammo"), Vec2f(1, 1), params);
			CGridButton@ button9 = menu.AddButton("$atgrenade$", "Anti-Tank Grenade (" + costs[9] + " -> " + prod_amounts[9] + " -> " + prod_times[9] + "s)", this.getCommandID("atgrenade"), Vec2f(1, 1), params);

			if (button0 !is null && button1 !is null && button2 !is null && button3 !is null
				&& button4 !is null && button5 !is null && button6 !is null && button7 !is null
				&& button8 !is null && button9 !is null)
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
				else if (prod_prop == "mat_atgrenade")
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
	if (hitterBlob.getName() == "balista_bolt" || hitterBlob.hasTag("atgrenade") || hitterBlob.getName() == "c4")
	{
		damage *= 5.0f;
	} 
	return damage;
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
	if (!mouseOnBlob) return;

	// fuel
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

	// working
	{
		Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 40);
		Vec2f dim = Vec2f(24, 8);
		const f32 y = blob.getHeight() * 2.4f;
		const f32 perc = blob.get_u32("timer") / f32(blob.get_u32("prod_time") * getTicksASecond());

		if (blob.get_bool(working_prop))
		{
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(255,255,205,35));
		}
	}
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