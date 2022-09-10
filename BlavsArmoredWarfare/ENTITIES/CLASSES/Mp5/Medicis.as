#include "MedicisCommon.as"

void onInit( CBlob@ this )
{
	this.set_bool(medicCallingBoolString, false); // MedicisCommon.as
	this.set_f32(bucketAmountString, 0.0f); // MedicisCommon.as

	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";	

	this.addCommandID(bucketSyncIDString); // MedicisCommon.as
}

void onTick( CBlob@ this )
{
	const bool is_client = isClient();
	const bool is_my_player = this.isMyPlayer();

	if (this.hasTag(medicTagString))
	{
		if (isServer() && (getGameTime() + this.getNetworkID()) % (this.hasBlob("medkit", 1) ? 15 : 30) == 0) // bucket increase every second, bonus if holding a medkit
		{
			bucketAdder(this, 0.03f); // amount of bucket refilled, out of 1.0f
		}

		float bucketAmount = this.get_f32(bucketAmountString); // MedicisCommon.as
		float bucketCost = 1.0f / bucket_Max_Charges; // max bucket is always 1.0f, get cost out of max charges

		if (this.isKeyJustPressed(key_action3)) // 1 frame, when space is pressed
		{
			if (bucketAmount >= bucketCost) // must have enough bucket load
			{
				if (isServer()) // ability is completely handled by server, no chance for true desync
				{
					spawnMedicisHeart(this); // MedicisCommon.as
					bucketAdder(this, -bucketCost); // instead of refill, drain by using negative
				}
			}
			else if (is_my_player) this.getSprite().PlaySound("NoAmmo.ogg", 1.0f); // only happens client side, no effect on bucket or sync
		}
	}

	if (is_client) // "Help Me" sign check, if character is below 50% health. Only a variable, does not render here.
	{
		if ((getGameTime() + this.getNetworkID()) % 30 == 0) // once a second
		{
			float health = this.getHealth();
			float maxHealth = this.getInitialHealth();
			float healthPercentage = health/maxHealth;

			this.set_bool(medicCallingBoolString, healthPercentage < 0.5f);
		}
	}
	
}

void onRender( CSprite@ this )
{
	if (g_videorecording) return;

	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;

	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null) return;

	if (thisBlob.getPlayer() == null) return;

	CBlob@ renderBlob = p.getBlob();
	if (renderBlob == null) return;
	
	if (renderBlob.getTeamNum() != thisBlob.getTeamNum()) return;

	if (thisBlob.hasTag(medicTagString))
	{
		if (thisBlob is renderBlob) // if the blob is YOU, draw the hud. Otherwise fuck off
		{
			float bucketAmount = thisBlob.get_f32(bucketAmountString);
			float bucketCost = 1.0f / bucket_Max_Charges;
			drawBucketHud(bucketAmount, bucketCost); // MedicisCommon.as
		}
		else if (!renderBlob.hasTag(medicTagString)) // only draw medic identifier on people if you yourself are not a medic
		{
			Vec2f pos2d = thisBlob.getScreenPos() + Vec2f(-16, -60);
			drawMedicIdentifier(pos2d); // MedicisCommon.as
		}
	}
	else if (renderBlob.hasTag(medicTagString)) // if YOU are a medic, draw the "Help Me" icon on players with the variable set TRUE
	{
		bool medicCalling = thisBlob.get_bool(medicCallingBoolString); // checked in onTick()
		if (medicCalling)
		{
			Vec2f pos2d = thisBlob.getScreenPos() + Vec2f(-16, -60);
			drawMedicCalling(pos2d); // MedicisCommon.as
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null) return;

	// this is called from MedicisCommon.as - updateBucket(). Should only run on clients.
	if (this.isMyPlayer() && cmd == this.getCommandID(bucketSyncIDString))
	{
		float newBucketAmount = 0.0f;

		if (params.saferead_f32(newBucketAmount))
		{
			this.set_f32(bucketAmountString, newBucketAmount);
		}
	}
}