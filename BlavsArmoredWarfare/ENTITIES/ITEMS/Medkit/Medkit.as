void onInit(CBlob@ this)
{
	//this.getShape().SetRotationsAllowed(false);
	this.set_u8("medamount", 6);
	this.Tag("trap");

	this.addCommandID("usemed");
}

void onInit(CSprite@ this)
{
	this.ScaleBy(0.75f, 0.75f);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;

	if (caller.getHealth() < caller.getInitialHealth())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		CButton@ button = caller.CreateGenericButton(30, Vec2f(0, 0), this, this.getCommandID("usemed"), this.get_u8("medamount") + " uses      ", params);
		button.enableRadius = 28.0f;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (this is null) return;
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