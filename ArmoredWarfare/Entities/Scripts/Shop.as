//generic shop menu

// properties:
//      shop offset - Vec2f - used to offset things bought that spawn into the world, like vehicles

#include "ShopCommon.as"
#include "Requirements_Tech.as"
#include "MakeCrate.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "ProgressBar.as";
#include "TeamColorCollections.as";

const u32 construct_endtime = 3*30;

void onInit(CBlob@ this)
{
	this.addCommandID("shop buy");
	this.addCommandID("shop made item");
	this.addCommandID("construct");
	this.addCommandID("constructed");

	this.set_f32("construct_time", 0);
	this.set_u32("construct_endtime", construct_endtime);

	if (!this.exists("shop available"))
		this.set_bool("shop available", true);
	if (!this.exists("shop offset"))
		this.set_Vec2f("shop offset", Vec2f_zero);
	if (!this.exists("shop menu size"))
		this.set_Vec2f("shop menu size", Vec2f(7, 7));
	if (!this.exists("shop description"))
		this.set_string("shop description", "Workbench");
	if (!this.exists("shop icon"))
		this.set_u8("shop icon", 15);
	if (!this.exists("shop offset is buy offset"))
		this.set_bool("shop offset is buy offset", false);

	if (!this.exists("shop button radius"))
	{
		CShape@ shape = this.getShape();
		if (shape !is null)
		{
			this.set_u8("shop button radius", Maths::Max(this.getRadius(), (shape.getWidth() + shape.getHeight()) / 2));
		}
		else
		{
			this.set_u8("shop button radius", 16);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || caller.isAttachedTo(this)) return;

	ShopItem[]@ shop_items;
	if (!this.get(SHOP_ARRAY, @shop_items))
	{
		return;
	}

	if (shop_items.length > 0 && this.get_bool("shop available") && !this.hasTag("shop disabled"))
	{
		CButton@ button = caller.CreateGenericButton(
			this.get_u8("shop icon"),                                // icon token
			this.get_Vec2f("shop offset"),                           // button offset
			this,                                                    // shop blob
			createMenu,                                              // func callback
			getTranslatedString(this.get_string("shop description")) // description
		);

		button.enableRadius = this.get_u8("shop button radius");
	}
}


void createMenu(CBlob@ this, CBlob@ caller)
{
	if (this.hasTag("shop disabled"))
		return;

	BuildShopMenu(this, caller, this.get_string("shop description"), Vec2f(0, 0), this.get_Vec2f("shop menu size"));
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	Vec2f offset = Vec2f_zero;
	if (this.get_bool("shop offset is buy offset"))
	{
		offset = this.get_Vec2f("shop offset");
	}
	return ((this.getPosition() + Vec2f((this.isFacingLeft() ? -2 : 2)*offset.x, offset.y) - caller.getPosition()).Length() < caller.getRadius() / 2 + this.getRadius());
}

void updateShopGUI(CBlob@ shop)
{
	const string caption = getRules().get_string("shop open menu name");
	if (caption == "") { return; }

	const int callerBlobID = getRules().get_netid("shop open menu caller");
	CBlob@ callerBlob = getBlobByNetworkID(callerBlobID);
	if (callerBlob is null) { return; }

	CGridMenu@ menu = getGridMenuByName(caption);
	if (menu is null) { return; }
	
	ShopItem[]@ shop_items;
	if (!shop.get(SHOP_ARRAY, @shop_items) || shop_items is null) { return; }

	if (menu.getButtonsCount() != shop_items.length)
	{
		warn("expected " + menu.getButtonsCount() + " buttons, got " + shop_items.length + " items");
		return;
	}

	for (uint i = 0; i < shop_items.length; ++i)
	{
		ShopItem@ item = @shop_items[i];
		if (item is null) { continue; }

		CGridButton@ button = @menu.getButtonOfIndex(i);
		applyButtonProperties(@shop, @callerBlob, @button, @item);
	}
}

void onTick(CBlob@ shop)
{
	if (isClient() && getRules().exists("shop open menu blob") && getRules().get_netid("shop open menu blob") == shop.getNetworkID())
	{
		updateShopGUI(@shop);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	if (cmd == this.getCommandID("shop buy"))
	{
		if (this.hasTag("shop disabled"))
			return;

		u16 callerID;
		if (!params.saferead_u16(callerID))
			return;
		bool spawnToInventory = params.read_bool();
		bool spawnInCrate = params.read_bool();
		bool instant = params.read_bool();
		bool producing = params.read_bool();
		u8 s_index = params.read_u8();
		bool hotkey = params.read_bool();

		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null) { return; }
		CInventory@ inv = caller.getInventory();

		if (this.getHealth() <= 0)
		{
			caller.ClearMenus();
			return;
		}

		if (hotkey)
		{
			caller.SendCommand(caller.getCommandID("prevent emotes"));
		}

		if (inv !is null && isInRadius(this, caller))
		{
			ShopItem[]@ shop_items;
			if (!this.get(SHOP_ARRAY, @shop_items)) { return; }
			if (s_index >= shop_items.length) { return; }
			ShopItem@ s = shop_items[s_index];

			// production?
			if (s.ticksToMake > 0)
			{
				s.producing = producing;
				return;
			}

			// check spam

			//if (isSpammed( blobName, this.getPosition(), 12 ))
			//{
			//	if (caller.isMyPlayer())
			//	{
			//		client_AddToChat( "There is too many " + blobName + "'s made here sorry." );
			//		this.getSprite().PlaySound("/NoAmmo.ogg" );
			//	}
			//	return;
			//}

			if (!getNet().isServer()) { return; } //only do this on server

			bool tookReqs = false;

			// try taking from the caller + this shop first
			CBitStream missing;
			if (hasRequirements_Tech(inv, this.getInventory(), s.requirements, missing))
			{
				server_TakeRequirements(inv, this.getInventory(), s.requirements);
				tookReqs = true;
			}
			// try taking from caller + storages second
			if (!tookReqs)
			{
				const s32 team = this.getTeamNum();
				CBlob@[] storages;
				if (getBlobsByTag("storage", @storages))
					for (uint step = 0; step < storages.length; ++step)
					{
						CBlob@ storage = storages[step];
						if (storage.getTeamNum() == team)
						{
							CBitStream missing;
							if (hasRequirements_Tech(inv, storage.getInventory(), s.requirements, missing))
							{
								server_TakeRequirements(inv, storage.getInventory(), s.requirements);
								tookReqs = true;
								break;
							}
						}
					}
			}

			if (tookReqs)
			{
				if (s.spawnNothing)
				{
					CBitStream params;
					params.write_netid(caller.getNetworkID());
					params.write_netid(0);
					params.write_string(s.blobName);
					this.SendCommand(this.getCommandID("shop made item"), params);
				}
				else
				{
					//inv.server_TakeRequirements(s.requirements);
					Vec2f spawn_offset = Vec2f();

					if (this.exists("shop offset")) { Vec2f _offset = this.get_Vec2f("shop offset"); spawn_offset = Vec2f(2*_offset.x, _offset.y); }
					if (this.isFacingLeft()) { spawn_offset.x *= -1; }
					CBlob@ newlyMade = null;

					if (spawnInCrate)
					{
						CBlob@ crate = server_MakeCrate(s.blobName, s.name, s.crate_icon, caller.getTeamNum(), caller.getPosition());

						if (crate !is null)
						{
							if (spawnToInventory && caller.canBePutInInventory(crate))
							{
								caller.server_PutInInventory(crate);
							}
							else
							{
								caller.server_Pickup(crate);
							}
							@newlyMade = crate;
						}
					}
					else
					{
						CBlob@ blob = server_CreateBlob(s.blobName, caller.getTeamNum(), this.getPosition() + spawn_offset);
						CInventory@ callerInv = caller.getInventory();
						if (blob !is null)
						{
							bool pickable = blob.getAttachments() !is null && blob.getAttachments().getAttachmentPointByName("PICKUP") !is null;
							if (spawnToInventory)
							{
								if (!blob.canBePutInInventory(caller))
								{
									caller.server_Pickup(blob);
								}
								else if (!callerInv.isFull())
								{
									caller.server_PutInInventory(blob);
								}
								// Hack: Archer Shop can force Archer to drop Arrows.
								else if (this.getName() == "archershop" && caller.getName() == "archer")
								{
									int arrowCount = callerInv.getCount("mat_arrows");
									int stacks = arrowCount / 30;
									// Hack: Depends on Arrow stack size.
									if (stacks > 1)
									{
										CBlob@ arrowStack = caller.server_PutOutInventory("mat_arrows");
										if (arrowStack !is null)
										{
											if (arrowStack.getAttachments() !is null && arrowStack.getAttachments().getAttachmentPointByName("PICKUP") !is null)
											{
												caller.server_Pickup(arrowStack);
											}
											else
											{
												arrowStack.setPosition(caller.getPosition());
											}
										}
										caller.server_PutInInventory(blob);
									}
									else if (pickable)
									{
										caller.server_Pickup(blob);
									}
								}
								else if (pickable)
								{
									caller.server_Pickup(blob);
								}
							}
							else
							{
								CBlob@ carried = caller.getCarriedBlob();
								if (carried is null && pickable)
								{
									caller.server_Pickup(blob);
								}
								else if (blob.canBePutInInventory(caller) && !callerInv.isFull())
								{
									caller.server_PutInInventory(blob);
								}
								else if (pickable)
								{
									caller.server_Pickup(blob);
								}
							}
							@newlyMade = blob;
						}
					}

					if (newlyMade !is null && caller.getPlayer() !is null)
					{
						newlyMade.set_u16("buyer", caller.getPlayer().getNetworkID());

						CBitStream params;
						params.write_netid(caller.getNetworkID());
						params.write_netid(newlyMade.getNetworkID());
						params.write_string(s.blobName);
						this.SendCommand(this.getCommandID("shop made item"), params);
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("construct"))
	{
		this.set_u16("builder_id", 0);
		this.set_f32("construct_time", 0);
		this.set_string("constructing_name", "");
		this.set_s8("constructing_index", 0);
		this.set_bool("constructing", false);
		//printf("construct");

		u16 callerID;
		if (!params.saferead_u16(callerID))
			return;
		bool spawnToInventory = params.read_bool();
		bool spawnInCrate = params.read_bool();
		bool instant = params.read_bool();
		bool producing = params.read_bool();
		u8 s_index = params.read_u8();
		bool hotkey = params.read_bool();

		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null) { return; }
		CInventory@ inv = caller.getInventory();

		if (this.getHealth() <= 0)
		{
			caller.ClearMenus();
			return;
		}

		if (inv !is null && isInRadius(this, caller))
		{
			ShopItem[]@ shop_items;
			if (!this.get(SHOP_ARRAY, @shop_items)) { return; }
			if (s_index >= shop_items.length) { return; }
			ShopItem@ s = shop_items[s_index];

			this.set_u16("builder_id", caller.getNetworkID());
			this.set_f32("construct_time", 1); // gets stuck if caller is too far already and this is set to 0
			this.set_string("constructing_name", s.blobName);
			this.set_s8("constructing_index", s_index);
			this.set_bool("constructing", true);

			u32 endtime = this.get_u32("construct_endtime");
			if (s.blobName == "bunker")
				endtime = 7.5f*30;
			else if (s.blobName == "heavybunker")
				endtime = 10.0f*30;
			else if (s.blobName == "quarters")
			{
				endtime = 1.0f*30;
			}
			else
			{
				endtime = construct_endtime;
			}
			this.set_u32("construct_endtime", endtime);

			Bar@ bars;
			if (!this.get("Bar", @bars))
			{
				Bar setbars;
        		setbars.gap = 20.0f;
        		this.set("Bar", setbars);
			}
			if (this.get("Bar", @bars))
			{
				if (!hasBar(bars, "construct"))
				{
					SColor team_front = getNeonColor(caller.getTeamNum(), 0);
					ProgressBar setbar;
					setbar.Set(this, "construct", Vec2f(64.0f, 16.0f), true, Vec2f(0, 48), Vec2f(2, 2), back, team_front,
						"construct_time", this.get_u32("construct_endtime"), 0.25f, 5, 5, false, "constructed");

    				bars.AddBar(this, setbar, true);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("constructed"))
	{
		if (this.get_f32("construct_time") == 0) return;
		//printf("constructed");
		if (getNet().isServer())
		{
			CBitStream stream;
			stream.write_u16(this.get_u16("builder_id"));
			stream.write_bool(false);
			stream.write_bool(false);
			stream.write_bool(true);
			stream.write_bool(false);
			stream.write_s8(this.get_s8("constructing_index"));
			stream.write_bool(false);
			//printf("sent");
			this.SendCommand(this.getCommandID("shop buy"), stream);
		}

		this.set_u16("builder_id", 0);
		this.set_f32("construct_time", 0);
		this.set_string("constructing_name", "");
		this.set_s8("constructing_index", 0);
		this.set_bool("constructing", false);
	}
}

void applyButtonProperties(CBlob@ shop, CBlob@ caller, CGridButton@ button, ShopItem@ s_item)
{
	if (s_item.producing)		  // !! no click for production items
		button.clickable = false;

	button.selectOnClick = true;

	bool tookReqs = false;
	CBlob@ storageReq = null;
	// try taking from the caller + this shop first
	CBitStream missing;
	if (hasRequirements_Tech(shop.getInventory(), caller.getInventory(), s_item.requirements, missing))
	{
		tookReqs = true;
	}
	// try taking from caller + storages second
	//if (!tookReqs)
	//{
	//	const s32 team = this.getTeamNum();
	//	CBlob@[] storages;
	//	if (getBlobsByTag( "storage", @storages ))
	//		for (uint step = 0; step < storages.length; ++step)
	//		{
	//			CBlob@ storage = storages[step];
	//			if (storage.getTeamNum() == team)
	//			{
	//				CBitStream missing;
	//				if (hasRequirements_Tech( caller.getInventory(), storage.getInventory(), s_item.requirements, missing ))
	//				{
	//					@storageReq = storage;
	//					break;
	//				}
	//			}
	//		}
	//}

	const bool takeReqsFromStorage = (storageReq !is null);

	if (s_item.ticksToMake > 0)		   // production
		SetItemDescription_Tech(button, shop, s_item.requirements, s_item.description, shop.getInventory());
	else
	{
		string desc = s_item.description;
		//if (takeReqsFromStorage)
		//	desc += "\n\n(Using resources from team storage)";

		SetItemDescription_Tech(button, caller, s_item.requirements, getTranslatedString(desc), takeReqsFromStorage ? storageReq.getInventory() : shop.getInventory());
	}

	//if (s_item.producing) {
	//	button.SetSelected( 1 );
	//	menu.deleteAfterClick = false;
	//}
}

//helper for building menus of shopitems

void addShopItemsToMenu(CBlob@ this, CGridMenu@ menu, CBlob@ caller)
{
	ShopItem[]@ shop_items;

	if (this.get(SHOP_ARRAY, @shop_items))
	{
		for (uint i = 0 ; i < shop_items.length; i++)
		{
			ShopItem @s_item = shop_items[i];
			if (s_item is null || caller is null) { continue; }
			CBitStream params;

			params.write_u16(caller.getNetworkID());
			params.write_bool(s_item.spawnToInventory);
			params.write_bool(s_item.spawnInCrate);
			params.write_bool(s_item.instant);
			params.write_bool(s_item.producing);
			params.write_u8(u8(i));
			params.write_bool(false); //used hotkey?

			CGridButton@ button;

			if (s_item.instant)
			{
				if (s_item.customButton)
					@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("shop buy"), Vec2f(s_item.buttonwidth, s_item.buttonheight), params);
				else
					@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("shop buy"), params);
			}
			else
			{
				@button = menu.AddButton(s_item.iconName, getTranslatedString(s_item.name), this.getCommandID("construct"), Vec2f(s_item.buttonwidth, s_item.buttonheight), params);
			}
			
			if (button !is null)
			{
				applyButtonProperties(@this, @caller, @button, @s_item);
			}
		}
	}
}

void BuildShopMenu(CBlob@ this, CBlob @caller, string description, Vec2f offset, Vec2f slotsAdd)
{
	if (caller is null || !caller.isMyPlayer())
		return;

	ShopItem[]@ shopitems;

	if (!this.get(SHOP_ARRAY, @shopitems)) { return; }

	const string caption = getTranslatedString(description);

	CControls@ controls = caller.getControls();
	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + offset, this, Vec2f(slotsAdd.x, slotsAdd.y), caption);

	getRules().set_netid("shop open menu blob", this.getNetworkID());
	getRules().set_string("shop open menu name", caption);
	getRules().set_netid("shop open menu caller", caller.getNetworkID());

	if (menu !is null)
	{
		if (!this.hasTag(SHOP_AUTOCLOSE))
			menu.deleteAfterClick = false;
		addShopItemsToMenu(this, menu, caller);

		//keybinds
		array<EKEY_CODE> numKeys = { KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0 };
		uint keybindCount = Maths::Min(shopitems.length(), numKeys.length());

		for (uint i = 0; i < keybindCount; i++)
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			params.write_bool(shopitems[i].spawnToInventory);
			params.write_bool(shopitems[i].spawnInCrate);
			params.write_bool(shopitems[i].producing);
			params.write_u8(i);
			params.write_bool(true); //used hotkey?

			menu.AddKeyCommand(numKeys[i], this.getCommandID("shop buy"), params);
		}
	}

}

void BuildDefaultShopMenu(CBlob@ this, CBlob @caller)
{
	BuildShopMenu(this, caller, getTranslatedString("Shop"), Vec2f(0, 0), Vec2f(4, 4));
}
