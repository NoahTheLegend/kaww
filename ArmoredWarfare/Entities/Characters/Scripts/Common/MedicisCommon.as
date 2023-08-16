const string medicCallingBoolString = "is_calling_medic";
const string medicTagString = "medic_tag"; // add this tag per-basis, in the character logic onInit()

const string bucketAmountString = "medic_ability_bucket";
const u8 bucket_Max_Charges = 5; // MUST be in line with the hud sprite. If you change this, also change the sprite.

const string bucketSyncIDString = "bucket_sync_ID";
const f32 max_heal_radius = 96.0f; // 12 blocks

void drawBucketHud(float bucketAmount, float bucketCost)
{
	u8 frame = bucketAmount / bucketCost;

	Vec2f HUDpos = Vec2f(200, getScreenHeight() - 100.0f);
	GUI::DrawIcon("MedicHUD.png", frame, Vec2f(50, 10), HUDpos);
}

void drawMedicCalling(Vec2f HUDpos)
{
	//u8 frame = (getGameTime() % 180) / 20;
	//if (frame > 4) frame = 9 - frame;
	u8 frame = 0;
	GUI::DrawIcon("CallMedic.png", frame, Vec2f(16, 16), HUDpos);
}

void drawMedicIdentifier(Vec2f HUDpos)
{
	GUI::DrawIcon("MedicIdentifier.png", 0, Vec2f(16, 16), HUDpos);
}

void drawTargetIdentifier(Vec2f HUDpos)
{
	u8 frame = (getGameTime() % 20 < 10 ? 0 : 4);
	GUI::DrawIcon("CallMedic.png", frame, Vec2f(16, 16), HUDpos, 1.33f, 1.33f);
}

void updateBucket(CBlob@ this, float newBucketAmount) // this is the sync method
{
	CPlayer@ player = this.getPlayer();
	if (player == null) return;
	
	CBitStream params;
	params.write_f32(newBucketAmount);
	
	this.server_SendCommandToPlayer(this.getCommandID(bucketSyncIDString), params, player); // intended for client only
	this.set_f32(bucketAmountString, newBucketAmount); // intended for server only
	// Note: Due to "server_SendCommandToPlayer" also sending to Server, in LocalHost the variable is set twice,
	// however, it doesn't matter due to it being instant and in the same tick. It works fine in both localhost and dedicated.
}

void bucketAdder(CBlob@ this, float bucketChange) // always calls updateBucket()
{
	float bucketAmount = this.get_f32(bucketAmountString);

	float newBucketAmount = Maths::Clamp(bucketAmount + bucketChange, 0.0f, 1.0f); // bucket overflow prevention
	
	updateBucket(this, newBucketAmount); // bucket changes end here
}

void RestoreHealth(CBlob@ blob, f32 amount)
{
	blob.server_SetHealth(Maths::Min(blob.getInitialHealth(), blob.getHealth()+amount));
}

CBlob@ HealPlayer(CBlob@ this)
{
	if (getMap() is null) return null;

	CBlob@[] heal_list;
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p is null) continue;
		CBlob@ b = p.getBlob();

		if (b is null || b.getTeamNum() != this.getTeamNum()
			|| b.getDistanceTo(this) > max_heal_radius || b is this)
				continue;

		if (getMap().rayCastSolidNoBlobs(b.getPosition(), this.getPosition()))
			continue;

		heal_list.push_back(@b);
	}

	u16 id_to_heal = 0;
	f32 temp_health_ratio = 1.0f;
	for (u8 i = 0; i < heal_list.length; i++)
	{
		CBlob@ b = heal_list[i];
		f32 current_ratio = b.getHealth()/b.getInitialHealth();

		if (current_ratio < temp_health_ratio)
		{
			temp_health_ratio = current_ratio;
			id_to_heal = b.getNetworkID();
		}
	}

	if (id_to_heal != 0)
	{
		CBlob@ b = getBlobByNetworkID(id_to_heal);
		if (b !is null)
		{
			return b;
		}
	}
	else if (this.getHealth()/this.getInitialHealth() < 1.0f)
	{
		return this;
	}

	return null;
}