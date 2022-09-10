const string medicCallingBoolString = "is_calling_medic";
const string medicTagString = "medic_tag";

const string bucketAmountString = "medic_ability_bucket";
const string bucketAmountMaxString = "medic_ability_bucket_max";
const string bucketCostString = "medic_ability_bucket_cost";

const string bucketSyncIDString = "bucket_sync_ID";

void drawBucketHud( u32 bucketAmount, u32 bucketCost )
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

void updateBucket( CBlob@ this, u32 bucketChange )
{
	CPlayer@ player = this.getPlayer();
	if (player == null) return;
	
	CBitStream params;
	params.write_u32(bucketChange);
	
	this.server_SendCommandToPlayer(this.getCommandID(bucketSyncIDString), params, player);
	bucketAdder(this, bucketChange);
}

void bucketAdder( CBlob@ this, u32 bucketChange )
{
	u32 bucketAmount = this.get_u32(bucketAmountString);
	u32 bucketAmountMax = this.get_u32(bucketAmountMaxString);

	u32 newBucketAmount = bucketAmount + bucketChange;
	
	if (newBucketAmount > bucketAmountMax)
	{
		newBucketAmount = bucketAmountMax;
	}
	else if (newBucketAmount < 0)
	{
		newBucketAmount = 0;
	}

	this.set_u32(bucketAmountString, newBucketAmount);
}