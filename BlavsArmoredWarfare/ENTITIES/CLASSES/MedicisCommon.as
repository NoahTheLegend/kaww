const string medicCallingBoolString = "is_calling_medic";
const string medicTagString = "medic_tag";

const string bucketAmountString = "medic_ability_bucket";
const u8 bucket_Max_Charges = 4;

const string bucketSyncIDString = "bucket_sync_ID";

void drawBucketHud( float bucketAmount, float bucketCost )
{
	u8 frame = bucketAmount / bucketCost;

	Vec2f HUDpos = Vec2f(150, getScreenHeight() - 80.0f);
	GUI::DrawIcon("MedicHUD.png", frame, Vec2f(50, 10), HUDpos);
}

void drawMedicCalling( Vec2f HUDpos )
{
	u8 frame = (getGameTime() * 0.5f) % 9;
	if (frame > 4) frame = 9 - frame;
	GUI::DrawIcon("CallMedic.png", frame, Vec2f(16, 16), HUDpos);
}

void drawMedicIdentifier( Vec2f HUDpos )
{
	GUI::DrawIcon("MedicIdentifier.png", 0, Vec2f(16, 16), HUDpos);
}

void updateBucket( CBlob@ this, float newBucketAmount )
{
	CPlayer@ player = this.getPlayer();
	if (player == null) return;
	
	CBitStream params;
	params.write_f32(newBucketAmount);
	
	this.server_SendCommandToPlayer(this.getCommandID(bucketSyncIDString), params, player);
	this.set_f32(bucketAmountString, newBucketAmount);
}

void bucketAdder( CBlob@ this, float bucketChange )
{
	float bucketAmount = this.get_f32(bucketAmountString);

	float newBucketAmount = bucketAmount + bucketChange;
	
	if (newBucketAmount > 1.0f)
	{
		newBucketAmount = 1.0f;
	}
	else if (newBucketAmount < 0.0f)
	{
		newBucketAmount = 0.0f;
	}

	updateBucket(this, newBucketAmount);
}