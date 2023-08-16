#include "MedicisCommon.as"

void onInit(CBlob@ this)
{
	this.set_bool(medicCallingBoolString, false); // MedicisCommon.as
	this.set_f32(bucketAmountString, 0.0f); // MedicisCommon.as

	//this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";	

	this.addCommandID(bucketSyncIDString); // MedicisCommon.as
	this.addCommandID("heal_sound"); // lol imagine doing that perfect code that changes nothing
	// unless youre working in notepad

	this.set_u16("last_target", this.getNetworkID());
	this.set_f32("target_counter", 0);
}

void onTick(CBlob@ this)
{
	const bool is_client = isClient();
	const bool is_my_player = this.isMyPlayer();

	CBlob@ player_found = HealPlayer(this);
	this.set_u16("heal_target_id", player_found is null ? 0 : player_found.getNetworkID());

	if (this.hasTag(medicTagString))
	{
		if (isServer() && (getGameTime() + this.getNetworkID()) % 30 == 0)
		{
			bucketAdder(this, 0.0625f); // amount of bucket refilled, out of 1.0f
		}

		float bucketAmount = this.get_f32(bucketAmountString); // MedicisCommon.as
		float bucketCost = 1.0f / bucket_Max_Charges; // max bucket is always 1.0f, get cost out of max charges

		if (this.isKeyJustPressed(key_action3) && !this.isAttached()) // 1 frame, when space is pressed
		{
			if (bucketAmount >= bucketCost) // must have enough bucket load
			{
				if (isServer()) // ability is completely handled by server, no chance for true desync
				{
					if (player_found is null) // MedicisCommon.as
					{
						bucketCost = 0.0f;
					}
					else
					{
						RestoreHealth(player_found, player_found is this ? 0.25f : 0.5f);

						CBitStream params;
						params.write_u16(player_found.getNetworkID());
						this.SendCommand(this.getCommandID("heal_sound"), params);
					}
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

void onRender(CSprite@ this)
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

	f32 interfactor = getInterpolationFactor();
	bool draw_call = !thisBlob.hasTag("target_to_heal");

	if (thisBlob.hasTag(medicTagString))
	{
		CBlob@ target_to_heal = getBlobByNetworkID(thisBlob.get_u16("heal_target_id"));
		if (target_to_heal !is null && thisBlob.isMyPlayer())
		{
			if (thisBlob.get_u16("last_target") != target_to_heal.getNetworkID())
			{
				thisBlob.set_f32("target_counter", 0);
				thisBlob.set_u16("last_target", target_to_heal.getNetworkID());
			}
			else thisBlob.add_f32("target_counter", 0.5f);
			f32 counter = thisBlob.get_f32("target_counter");
				
			Vec2f oldpos = getDriver().getScreenPosFromWorldPos(target_to_heal.getOldPosition());
			Vec2f pos = getDriver().getScreenPosFromWorldPos(target_to_heal.getPosition());
			f32 lerp = Maths::Min(1.0f, 0.1f + counter * 0.1f);

			Vec2f last_pos2d = thisBlob.get_Vec2f("last_pos2d");
			Vec2f pos2d = Vec2f_lerp(last_pos2d, Vec2f_lerp(oldpos, pos, interfactor) + Vec2f(-21, -80), lerp);
			thisBlob.set_Vec2f("last_pos2d", pos2d);
			drawTargetIdentifier(pos2d); // MedicisCommon.as

			target_to_heal.Tag("target_to_heal");
		}
		else
		{
			Vec2f oldpos = getDriver().getScreenPosFromWorldPos(thisBlob.getOldPosition());
			Vec2f pos = getDriver().getScreenPosFromWorldPos(thisBlob.getPosition());
			Vec2f pos2d = Vec2f_lerp(oldpos, pos, interfactor) + Vec2f(-21, -80);
			thisBlob.set_Vec2f("last_pos2d", pos2d);
		}
		
		if (thisBlob is renderBlob) // if the blob is YOU, draw the hud. Otherwise fuck off
		{
			float bucketAmount = thisBlob.get_f32(bucketAmountString);
			float bucketCost = 1.0f / bucket_Max_Charges;
			drawBucketHud(bucketAmount, bucketCost); // MedicisCommon.as
		}
		else if (!renderBlob.hasTag(medicTagString)) // only draw medic identifier on people if you yourself are not a medic
		{
			Vec2f oldpos = getDriver().getScreenPosFromWorldPos(thisBlob.getOldPosition());
			Vec2f pos = getDriver().getScreenPosFromWorldPos(thisBlob.getPosition());
			
			Vec2f pos2d = Vec2f_lerp(oldpos, pos, interfactor) + Vec2f(-18, -80);
			drawMedicIdentifier(pos2d); // MedicisCommon.as
		}
	}
	else if (draw_call && renderBlob.hasTag(medicTagString)) // if YOU are a medic, draw the "Help Me" icon on players with the variable set TRUE
	{
		bool medicCalling = thisBlob.get_bool(medicCallingBoolString); // checked in onTick()
		if (medicCalling)
		{
			Vec2f oldpos = getDriver().getScreenPosFromWorldPos(thisBlob.getOldPosition());
			Vec2f pos = getDriver().getScreenPosFromWorldPos(thisBlob.getPosition());
			
			Vec2f pos2d = Vec2f_lerp(oldpos, pos, interfactor) + Vec2f(-14, -75);
			drawMedicCalling(pos2d); // MedicisCommon.as
		}
	}

	if (thisBlob.hasTag("target_to_heal"))
		thisBlob.Untag("target_to_heal");
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
	else if (cmd == this.getCommandID("heal_sound"))
	{
		if (!isClient()) return;

		u16 id = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(id);
		if (blob is null) return;
		
		Sound::Play("Heart.ogg", blob.getPosition(), 1.0f, 1.075f+XORRandom(76)*0.001f);
	}
}