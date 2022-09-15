#include "ComputerCommon.as"

const string targetingProgressString = "targeting_progress";

const string launchJavelinIDString = "launch_javelin_command";

const u8 searchRadius = 32.0f;

void onInit(CBlob@ this)
{
	this.set_u16(curTargetNetIDString, 0);
	this.set_f32(targetingProgressString, 0.0f); // out of 1.0f

	this.Tag("medium weight");
	this.Tag("trap"); // so bullets pass

	this.addCommandID(launchJavelinIDString);
}

void onTick(CBlob@ this)
{
	if (!this.isAttached()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point is null) return;

	CBlob@ ownerBlob = point.getOccupied();
	if (ownerBlob is null) return;

	float angle = ownerBlob.isFacingLeft() ? 45.0f : -45.0f;
	this.setAngleDegrees(angle);

	if (!ownerBlob.isMyPlayer()) return; // only player holding this

	Vec2f ownerPos = ownerBlob.getPosition();
	Vec2f ownerAimpos = ownerBlob.getAimPos() + Vec2f(2.0f, 2.0f);

	u16 curTargetNetID = this.get_u16(curTargetNetIDString);
	float targetingProgress = this.get_f32(targetingProgressString);

	CMap@ map = getMap();
	if (map == null) return;

	u16[] validBlobIDs; //detectable enemies go here
	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(ownerAimpos, searchRadius, @blobsInRadius); //possible enemies in radius
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b is null)
		{ continue; }

		if (b.getTeamNum() == ownerBlob.getTeamNum()) //enemy only
		{ continue; }

		if (!b.hasTag("vehicle") || b.isAttached()) //vehicles only
		{ continue; }

		u16 bNetID = b.getNetworkID();
		validBlobIDs.push_back(bNetID); //to the pile
	}

	//get closest to mouse
	f32 bestDist = 99999.0f;
	u16 bestBlobNetID = 0;
	for (uint i = 0; i < validBlobIDs.length; i++)
	{
		u16 validNetID = validBlobIDs[i];
		CBlob@ b = getBlobByNetworkID(validNetID);
		if (b is null)
		{ continue; }

		Vec2f targetPos = b.getPosition();
		Vec2f targetVec = targetPos - ownerAimpos;
		f32 targetDist = targetVec.getLength();

		if (targetDist < bestDist)
		{
			bestDist = targetDist;
			bestBlobNetID = validNetID;
		}
	}

	if (bestBlobNetID != 0) //start locking onto valid target
	{
		CBlob@ bestBlob = getBlobByNetworkID(bestBlobNetID);
		if (bestBlob != null)
		{
			Vec2f targetPos = bestBlob.getPosition();

			if (bestBlobNetID != curTargetNetID)
			{
				curTargetNetID = bestBlobNetID;
				this.set_u16(curTargetNetIDString, bestBlobNetID);
				targetingProgress = 0.0f;
			}
			
			f32 squareAngle = 45.0f * (1.0f - targetingProgress);
			Vec2f squareScale = Vec2f(32.0f, 32.0f) * (2.0f - targetingProgress);
			f32 squareCornerSeparation = 4.0f;
			makeTargetSquare(targetPos, squareAngle, squareScale, squareCornerSeparation, 1.0f, targetingProgress == 1.0f ? redConsoleColor : yellowConsoleColor); //target detected rhombus
			this.set_f32(targetingProgressString, Maths::Min(targetingProgress+0.02f, 1.0f));
		}
	}
	else //resets if no valid targets in range
	{
		if (curTargetNetID != 0)
		{
			curTargetNetID = 0;
			this.set_u16(curTargetNetIDString, 0);
		}
	}
	
	CBlob@ targetBlob = getBlobByNetworkID(curTargetNetID);
	if (curTargetNetID == 0 || targetBlob == null)
	{
		makeTargetSquare(ownerAimpos, 0, Vec2f(32.0f, 20.0f), 2.0f, 1.0f, greenConsoleColor);
	}
	else if (targetingProgress == 1.0f && ownerBlob.isKeyJustPressed(key_action3))
	{
		CBitStream params;
		params.write_u16(curTargetNetID);
		this.SendCommandOnlyServer(this.getCommandID(launchJavelinIDString), params);
		this.set_f32(targetingProgressString, 0);
		this.set_u16(curTargetNetIDString, 0);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null) return;
	if (!isServer()) return;

	if (cmd == this.getCommandID(launchJavelinIDString))
	{
		u16 curTargetNetID = 0;

		if (!params.saferead_u16(curTargetNetID)) return;

		CBlob@ targetBlob = getBlobByNetworkID(curTargetNetID);
		if (curTargetNetID == 0 || targetBlob == null) return;
		
		if (!this.isAttached()) return;

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point is null) return;

		CBlob@ ownerBlob = point.getOccupied();
		if (ownerBlob is null) return;

		Vec2f launchVec = Vec2f(1.0f, 0.0f);
		launchVec.RotateByDegrees(ownerBlob.isFacingLeft() ? -130.0f : -50.0f);

		CBlob@ blob = server_CreateBlob("missile_javelin", ownerBlob.getTeamNum(), this.getPosition());
		if (blob != null)
		{
			blob.setVelocity(launchVec * 3.0f);
			blob.IgnoreCollisionWhileOverlapped(this, 20);

			blob.SetDamageOwnerPlayer(ownerBlob.getPlayer()); 
			blob.set_u16(curTargetNetIDString, curTargetNetID);
		}
	}
}