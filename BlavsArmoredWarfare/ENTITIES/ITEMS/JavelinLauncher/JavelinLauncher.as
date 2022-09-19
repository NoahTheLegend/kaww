#include "ComputerCommon.as"

const string launchJavelinIDString = "launch_javelin_command";

const u8 searchRadius = 32.0f;

void onInit(CBlob@ this)
{
	this.set_u16(curTargetNetIDString, 0);
	this.set_f32(targetingProgressString, 0.0f); // out of 1.0f
	this.set_f32(robotechHeightString, 68.0f); //pixels

	this.Tag("medium weight");
	this.Tag("trap"); // so bullets pass

	this.addCommandID(launchJavelinIDString);
}

void onTick(CBlob@ this)
{
	if (!this.isAttached())
	{
		this.set_f32(robotechHeightString, 68.0f); //resets robotech height
		return;
	}

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point is null) return;

	CBlob@ ownerBlob = point.getOccupied();
	if (ownerBlob is null) return;

	float angle = ownerBlob.isFacingLeft() ? 30.0f : -30.0f;
	this.setAngleDegrees(angle);

	if (!ownerBlob.isMyPlayer()) return; // only player holding this

	Vec2f ownerPos = ownerBlob.getPosition();
	Vec2f ownerAimpos = ownerBlob.getAimPos() + Vec2f(2.0f, 2.0f);

	u16 curTargetNetID = this.get_u16(curTargetNetIDString);
	float targetingProgress = this.get_f32(targetingProgressString);

	CMap@ map = getMap();
	if (map == null) return;

	if (ownerBlob.isAttached()) return;

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

		if (!b.hasTag("vehicle")) //vehicles only
		{ continue; }

		if (b.isAttached()) // non attached blobs
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
			
			f32 squareAngle = 45.0f * (1.0f - targetingProgress) * 3;
			Vec2f squareScale = Vec2f(36.0f, 36.0f) * (2.0f - targetingProgress*1.5);
			f32 squareCornerSeparation = 4.0f;
			makeTargetSquare(targetPos, squareAngle, squareScale, squareCornerSeparation, 1.0f, targetingProgress == 1.0f ? redConsoleColor : yellowConsoleColor); //target detected rhombus
			this.set_f32(targetingProgressString, Maths::Min(targetingProgress+0.01f, 1.0f));
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

	CControls@ controls = getControls();
	float robotechHeight = this.get_f32(robotechHeightString);
	if (controls.isKeyJustPressed(KEY_UP))
	{
		robotechHeight += 10.0f;
	}
	else if (controls.isKeyJustPressed(KEY_DOWN))
	{
		robotechHeight -= 10.0f;
	}

	robotechHeight = Maths::Clamp(robotechHeight, 18.0f, 128.0f);
	this.set_f32(robotechHeightString, robotechHeight);

	Vec2f robotechPos = Vec2f(0, -robotechHeight * 2.0f);
	robotechPos.RotateByDegrees(ownerBlob.isFacingLeft() ? -45.0f : 45.0f); 
	robotechPos += ownerPos; // join with thispos

	makeTargetSquare(robotechPos, 0, Vec2f(4.0f, 4.0f), 3.0f, 1.0f, greenConsoleColor); // turnpoint
	drawParticleLine( ownerPos, robotechPos, Vec2f_zero, greenConsoleColor, 0, 4.0f); // trajectory

	CBlob@ targetBlob = getBlobByNetworkID(curTargetNetID);
	if (curTargetNetID == 0 || targetBlob == null)
	{
		makeTargetSquare(ownerAimpos, 0, Vec2f(32.0f, 20.0f), 2.0f, 1.0f, greenConsoleColor);
	}
	else
	{
		drawParticleLine( robotechPos, targetBlob.getPosition(), Vec2f_zero, greenConsoleColor, 0, 4.0f); // trajectory
	}

	if (targetingProgress == 1.0f && ownerBlob.isKeyJustPressed(key_action3))
	{
		CInventory@ inv = ownerBlob.getInventory();
		if (inv !is null && inv.getItem("mat_heatwarhead") !is null)
		{
			CBlob@ mag;
			for (u8 i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ b = inv.getItem(i);
				if (b is null || b.getName() != "mat_heatwarhead" || b.hasTag("dead")) continue;
				@mag = @b;
				break;
			}
			if (mag !is null)
			{
				u16 quantity = mag.getQuantity();

				if (quantity <= 1)
				{
					this.add_u32("mag_bullets", quantity);
					mag.Tag("dead");
					if (isServer()) mag.server_Die();
					CBitStream params;
					params.write_u16(curTargetNetID);
					params.write_f32(robotechHeight);
					this.SendCommandOnlyServer(this.getCommandID(launchJavelinIDString), params);
					this.set_f32(targetingProgressString, 0);
					this.set_u16(curTargetNetIDString, 0);
				}
				else
				{
					this.set_u32("mag_bullets", 1);
					if (isServer()) mag.server_SetQuantity(quantity - 1);
					CBitStream params;
					params.write_u16(curTargetNetID);
					params.write_f32(robotechHeight);
					this.SendCommandOnlyServer(this.getCommandID(launchJavelinIDString), params);
					this.set_f32(targetingProgressString, 0);
					this.set_u16(curTargetNetIDString, 0);
				}
			}
		}
		else if (this.isMyPlayer())
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 0.85);
		}

		
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null) return;
	if (!isServer()) return;

	if (cmd == this.getCommandID(launchJavelinIDString))
	{
		u16 curTargetNetID = 0;
		float robotechHeight = 64.0f;

		if (!params.saferead_u16(curTargetNetID)) return;
		if (!params.saferead_f32(robotechHeight)) return;

		CBlob@ targetBlob = getBlobByNetworkID(curTargetNetID);
		if (curTargetNetID == 0 || targetBlob == null) return;
		
		if (!this.isAttached()) return;

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point is null) return;

		CBlob@ ownerBlob = point.getOccupied();
		if (ownerBlob is null) return;

		Vec2f launchVec = Vec2f(ownerBlob.isFacingLeft() ? -1 : 1, -1.05f);
		Vec2f thisPos = this.getPosition();

		CBlob@ blob = server_CreateBlob("missile_javelin", ownerBlob.getTeamNum(), thisPos - Vec2f(0,3));
		if (blob != null)
		{
			blob.setVelocity(launchVec * 3.0f);
			blob.IgnoreCollisionWhileOverlapped(this, 20);

			blob.SetDamageOwnerPlayer(ownerBlob.getPlayer()); 
			blob.set_u16(curTargetNetIDString, curTargetNetID);
			blob.set_f32(robotechHeightString, thisPos.y - robotechHeight);
		}
	}
}