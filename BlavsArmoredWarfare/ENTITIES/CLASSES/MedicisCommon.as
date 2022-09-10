const string medicCallingBoolString = "is_calling_medic";
const string medicTagString = "medic_tag"; // add this tag per-basis, in the character logic onInit()

const string bucketAmountString = "medic_ability_bucket";
const u8 bucket_Max_Charges = 4; // MUST be in line with the hud sprite. If you change this, also change the sprite.

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

void updateBucket( CBlob@ this, float newBucketAmount ) // this is the sync method
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

void bucketAdder( CBlob@ this, float bucketChange ) // always calls updateBucket()
{
	float bucketAmount = this.get_f32(bucketAmountString);

	float newBucketAmount = Maths::Clamp(bucketAmount + bucketChange, 0.0f, 1.0f); // bucket overflow prevention
	
	updateBucket(this, newBucketAmount); // bucket changes end here
}

void spawnMedicisHeart( CBlob@ this )
{
	CBlob@ blob = server_CreateBlob("heart", -1, this.getPosition());
	if (blob != null)
	{
		Vec2f thisPos = this.getPosition();
		Vec2f thisVel = this.getVelocity();
		Vec2f thisAimPos = this.getAimPos();
		Vec2f thisAimVec = thisAimPos - thisPos;
		Vec2f thisAimVecNorm = thisAimVec;
		thisAimVecNorm.Normalize();
		thisAimVecNorm *= 4.0f;

		Vec2f blobVel = thisAimVecNorm + Vec2f(0.0f, -1.0f);
		blobVel += thisVel*0.8f; // add a bit of owner's velocity

		blob.setVelocity(blobVel);
		blob.server_SetTimeToDie(10);
	}
}