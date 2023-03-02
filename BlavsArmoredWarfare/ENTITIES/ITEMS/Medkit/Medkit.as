void onInit(CBlob@ this)
{
	//this.getShape().SetRotationsAllowed(false);
	this.set_u8("medamount", 4);
	this.Tag("trap");

	this.addCommandID("usemed");
	this.Tag("change team on pickup");
}

void onInit(CSprite@ this)
{
	this.ScaleBy(0.75f, 0.75f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (!blob.hasTag("trap") && !blob.hasTag("flesh") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;
	if (caller.exists("next_med") && caller.get_u32("next_med") >= getGameTime()) return;

	if (caller.getHealth() < caller.getInitialHealth()-0.1f)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		u8 med_amount = this.get_u8("medamount");
		CButton@ button = caller.CreateGenericButton(30, Vec2f(0, 0), this, this.getCommandID("usemed"), med_amount + " use" + (med_amount == 1 ? "" : "s") + "      ", params);
		button.enableRadius = 28.0f;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("usemed"))
	{
		u16 blob_id;
		if (!params.saferead_u16(blob_id)) return;

		CBlob@ blob = getBlobByNetworkID(blob_id);

		this.getSprite().PlaySound("Heart.ogg");
		if (blob !is null)
		{
			if (blob.get_u32("next_med") >= getGameTime()) return;
			blob.set_u32("next_med", getGameTime()+15);
		}

		if (isServer())
		{
			if (blob !is null)
			{
				//if (blob.getHealth() > oldHealth)
				{
					if (blob.hasBlob("aceofspades", 1))
					{
						blob.TakeBlob("aceofspades", 1);
						blob.set_u32("aceofspades_timer", getGameTime()+90);
					}
				}

				f32 heal_amount = 1.5f;
				if (blob.getPlayer() !is null && getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Bloodthirsty")
				{
					heal_amount /= 2;
				}
				blob.server_Heal(heal_amount);
				
				if (this.get_u8("medamount") <= 1) 
				{
					this.server_Die();
				}
				else
				{
					this.set_u8("medamount", this.get_u8("medamount") - 1);
					this.Sync("medamount", true);
				}
			}
		}
	}
}