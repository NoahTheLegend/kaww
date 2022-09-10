#include "MedicisCommon.as"

void onInit( CBlob@ this )
{
	this.set_bool(medicCallingBoolString, false);
	this.set_f32(bucketAmountString, 0.0f);

	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";	

	this.addCommandID(bucketSyncIDString);
}

void onTick( CBlob@ this )
{
	const bool is_client = isClient();
	const bool is_my_player = this.isMyPlayer();

	if (this.hasTag(medicTagString))
	{
		if (isServer() && (getGameTime() + this.getNetworkID()) % 30 == 0) // bucket increase every second
		{
			bucketAdder(this, 0.05f);
		}

		float bucketAmount = this.get_f32(bucketAmountString);
		float bucketCost = 1.0f / bucket_Max_Charges;

		if (this.isKeyJustPressed(key_action3))
		{
			if (bucketAmount >= bucketCost)
			{
				if (isServer())
				{
					CBlob@ blob = server_CreateBlob("heart", -1, this.getPosition());
					if (blob != null)
					{
						blob.setVelocity(Vec2f(this.isFacingLeft() ? -4.0f : 4.0f, -5.0f+XORRandom(3)));
						blob.server_SetTimeToDie(10);
					}
					
					bucketAdder(this, -bucketCost);
				}
			}
			else if (is_my_player) this.getSprite().PlaySound("NoAmmo.ogg", 1.0f);
		}
	}

	if (is_client)
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
		if (thisBlob is renderBlob)
		{
			float bucketAmount = thisBlob.get_f32(bucketAmountString);
			float bucketCost = 1.0f / bucket_Max_Charges;
			drawBucketHud(bucketAmount, bucketCost);
		}
		else if (!renderBlob.hasTag(medicTagString))
		{
			Vec2f pos2d = thisBlob.getScreenPos() + Vec2f(-16, -60);
			drawMedicIdentifier(pos2d);
		}
	}
	else if (renderBlob.hasTag(medicTagString))
	{
		bool medicCalling = thisBlob.get_bool(medicCallingBoolString);
		if (medicCalling)
		{
			Vec2f pos2d = thisBlob.getScreenPos() + Vec2f(-16, -60);
			drawMedicCalling(pos2d);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null) return;

	if (this.isMyPlayer() && cmd == this.getCommandID(bucketSyncIDString))
	{
		float newBucketAmount = 0.0f;

		if (params.saferead_f32(newBucketAmount))
		{
			this.set_f32(bucketAmountString, newBucketAmount);
		}
	}
}