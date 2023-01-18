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
		this.getSprite().PlaySound("Heart.ogg");

		if (isServer())
		{
			u16 blob_id;
			if (!params.saferead_u16(blob_id)) return;

			CBlob@ blob = getBlobByNetworkID(blob_id);
			
			if (blob !is null)
			{
				blob.server_Heal(1.5f);
				
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