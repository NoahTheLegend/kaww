#include "RunnerCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("equip_head");
	this.addCommandID("force_equip_head");
}

void onTick(CBlob@ this)
{
	if (this.getSprite() is null) return;

	const bool exposed = this.hasTag("machinegunner") || this.hasTag("collidewithbullets") || this.hasTag("can_shoot_if_attached");
	const bool sleeping = this.isAttachedToPoint("BED") || this.isAttachedToPoint("BED2");
	const bool repairing = this.hasTag("repairing");
	
	CSpriteLayer@ helmet = this.getSprite().getSpriteLayer("helmet");
	if (helmet !is null)
	{
		if ((repairing && WeldCondition(this)) || (this.isAttached() && (!exposed || sleeping)))
		{
			helmet.SetVisible(false);
		}
		else
		{
			helmet.SetVisible(true);
		}
	}
}

bool WeldCondition(CBlob@ this)
{
	return this.getVelocity().Length() < 0.05f && !this.isAttached()
		&& this.getCarriedBlob() !is null && this.getCarriedBlob().getName() == "weldingtool";
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	const string name = this.getName();

	CGridMenu@ equipments = CreateGridMenu(Vec2f(gridmenu.getUpperLeftPosition() + Vec2f(this.hasTag("3x2") ? 168 : 120, 24)), this, Vec2f(1, 1), "equipment");

	string HeadImage = "Equipment.png";

	int HeadFrame = 0;

	if(this.get_string("equipment_head") != "")
	{
		HeadImage = this.get_string("equipment_head")+"_icon.png";
		HeadFrame = 0;
	}

	if(equipments !is null)
	{
		equipments.SetCaptionEnabled(false);
		equipments.deleteAfterClick = false;

		if (this !is null)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID());

			int teamnum = this.getTeamNum();
			if (teamnum > 6) teamnum = 7;
			AddIconToken("$headimage$", HeadImage, Vec2f(24, 24), HeadFrame, teamnum);

			CGridButton@ head = equipments.AddButton("$headimage$", "", this.getCommandID("equip_head"), Vec2f(1, 1), params);
			if(head !is null)
			{
				if (this.get_string("equipment_head") != "")
					head.SetHoverText("Unequip helmet\n");
				else
					head.SetHoverText("Equip helmet\n");
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || !isServer()) return;
	if (this.get_u32("helmet_pick_delay") > getGameTime()) return;
	if (blob.getName() == "helmet" && this.get_string("equipment_head") == ""
		&& !blob.isAttached() && !blob.isInInventory())
	{
		CBitStream params;
		params.write_u16(this.getNetworkID());
		params.write_u16(blob.getNetworkID());
		this.SendCommand(this.getCommandID("force_equip_head"), params);

		this.set_u32("helmet_pick_delay", getGameTime()+45);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("equip_head"))
	{
		u16 callerID;
		if (!params.saferead_u16(callerID))
			return;
		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null)
			return;

		caller.getSprite().PlaySound("Pickup.ogg");

		bool holdingequipment = false;
		CBlob@ item = caller.getCarriedBlob();
		if(item !is null) {holdingequipment = true;}

		if(caller.get_string("equipment_head") != "")
		{
			removeHead(caller, caller.get_string("equipment_head"));
			if(holdingequipment && (item.getName() == "helmet" || item.getName() == "goldenhelmet"))
			{
				addHead(caller, item.getName());
				item.server_Die();
			}
		}
		else
		{
			if(holdingequipment && (item.getName() == "helmet" || item.getName() == "goldenhelmet"))
			{
				addHead(caller, item.getName());
				item.server_Die();
			}
		}
		caller.ClearMenus();
	}
	else if (cmd == this.getCommandID("force_equip_head"))
	{
		u16 callerID;
		if (!params.saferead_u16(callerID))
			return;
		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null)
			return;

		u16 itemID;
		if (!params.saferead_u16(itemID))
			return;
		CBlob@ item = getBlobByNetworkID(itemID);
		if (item is null || item.isAttached() || item.isInInventory())
			return;

		caller.getSprite().PlaySound("Pickup.ogg");

		bool holdingequipment = false;
		if(item !is null) {holdingequipment = true;}

		if(caller.get_string("equipment_head") != "")
		{
			removeHead(caller, caller.get_string("equipment_head"));
			if(holdingequipment && (item.getName() == "helmet" || item.getName() == "goldenhelmet"))
			{
				addHead(caller, item.getName());
				item.server_Die();
			}
		}
		else
		{
			if(holdingequipment && (item.getName() == "helmet" || item.getName() == "goldenhelmet"))
			{
				addHead(caller, item.getName());
				item.server_Die();
			}
		}

	}
}

void addHead(CBlob@ playerblob, string headname)
{
	if (playerblob.get_string("equipment_head") == "")
	{
		if(playerblob.get_u8("override head") != 0)
			playerblob.set_u8("last head", playerblob.get_u8("override head"));
		else	
			playerblob.set_u8("last head", playerblob.getHeadNum());
	}

	{
		playerblob.Tag(headname);
		playerblob.set_string("reload_script", headname);
		playerblob.AddScript(headname+"_effect.as");
		playerblob.set_string("equipment_head", headname);
		playerblob.Tag("update head");
	}
}

void removeHead(CBlob@ playerblob, string headname)
{
	if(headname == "helmet")
	{
		CSpriteLayer@ helmet = playerblob.getSprite().getSpriteLayer("helmet");
		if (helmet !is null)
		{
			playerblob.getSprite().RemoveSpriteLayer("helmet");
		}
	}
	playerblob.Untag(headname);
	if(isServer())
	{
		if(headname == "helmet")
		{
			CBlob@ oldeq = server_CreateBlob(headname, playerblob.getTeamNum(), playerblob.getPosition());
			playerblob.server_PutInInventory(oldeq);
		}
	}

	if(headname == "goldenhelmet")
	{
		CSpriteLayer@ helmet = playerblob.getSprite().getSpriteLayer("goldenhelmet");
		if (helmet !is null)
		{
			playerblob.getSprite().RemoveSpriteLayer("goldenhelmet");
		}
	}
	playerblob.Untag(headname);
	if(isServer())
	{
		if(headname == "goldenhelmet")
		{
			CBlob@ oldeq = server_CreateBlob(headname, playerblob.getTeamNum(), playerblob.getPosition());
			playerblob.server_PutInInventory(oldeq);
		}
	}

	{
		playerblob.set_u8("override head", playerblob.get_u8("last head"));
		playerblob.set_string("equipment_head", "");
		playerblob.RemoveScript(headname+"_effect.as");
		playerblob.Tag("update head");
	}
}

void onDie(CBlob@ this)
{
    /*if (isServer())
	{
		if(this.get_string("equipment_head") == "helmet")
		{
			server_CreateBlob("helmet", this.getTeamNum(), this.getPosition());
		}
		if(this.get_string("equipment_head") == "goldenhelmet")
		{
			server_CreateBlob("goldenhelmet", this.getTeamNum(), this.getPosition());
		}
	}*/
}