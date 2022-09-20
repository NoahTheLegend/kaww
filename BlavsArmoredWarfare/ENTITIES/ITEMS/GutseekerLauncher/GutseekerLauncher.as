#include "ComputerCommon.as"
#include "OrdnanceCommon.as"

const string ammoBlobName = "mat_heatwarhead";

const u8 searchRadius = 32.0f;

void onInit(CBlob@ this)
{
	LauncherInfo launcher;
	launcher.progress_speed = 0.04f;
	this.set("launcherInfo", @launcher);

	this.set_u16(targetNetIDString, 0);
	this.set_f32(targetingProgressString, 0.0f); // out of 1.0f
	this.set_f32(robotechHeightString, 168.0f); //pixels

	this.Tag("medium weight");
	this.Tag("trap"); // so bullets pass
	this.Tag("hidesgunonhold"); // is it's own weapon

	this.getSprite().SetFrame(4); // no hand

	this.addCommandID(launchOrdnanceIDString);
}

void onTick(CBlob@ this)
{
	if (!this.isAttached())
	{
		this.set_f32(robotechHeightString, 68.0f); //resets robotech height
		this.getSprite().SetFrame(4);
		return;
	}
	
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point is null) return;

	CBlob@ ownerBlob = point.getOccupied();
	if (ownerBlob is null) return;

	float angle = ownerBlob.isFacingLeft() ? 30.0f : -30.0f;

	if (!ownerBlob.isMyPlayer() || ownerBlob.isAttached()) return; // only player holding this
	
	LauncherInfo@ launcher;
	if (!this.get("launcherInfo", @launcher))
	{ return; }
	
	// binoculars effect
	ownerBlob.set_u32("dont_change_zoom", getGameTime()+3);
	CCamera@ camera = getCamera();
	if (camera !is null)
	{
		camera.mouseFactor = 0.7f;
	}
	
	Vec2f ownerPos = ownerBlob.getPosition();
	Vec2f ownerAimpos = ownerBlob.getAimPos() + Vec2f(2.0f, 2.0f);

	u16 curTargetNetID = this.get_u16(targetNetIDString);
	float targetingProgress = this.get_f32(targetingProgressString);

	const bool isSearching = ownerBlob.isKeyPressed(key_action2);
	if (!isSearching)
	{
		if (launcher.found_targets_id.length > 0)
		{
			launcher.found_targets_id.clear();
		}
		if (curTargetNetID != 0)
		{
			ownerBlob.set_u16(targetNetIDString, 0);
		}
		makeTargetSquare(ownerAimpos, 0, Vec2f(3.0f, 3.0f), 3.0f, 1.0f, greenConsoleColor);
		return;
	}

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

		if (!b.hasTag("vehicle") && !b.hasTag("flesh") && !b.hasTag("structure") && !b.hasTag("bunker")) // important things
		{ continue; }

		if (b.hasTag("dead") || b.isAttached()) // living things
		{ continue; }

		if (b.isAttached()) // non attached blobs
		{ continue; }

		u16 bNetID = b.getNetworkID();
		int index = launcher.found_targets_id.find(bNetID);
		if (index >= 0 && index < launcher.found_targets_id.length) //skip if ID already in array
		{ continue; }
		
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

		if (validNetID == curTargetNetID) 
		{
			bestBlobNetID = validNetID;
			break;
		}
		else if (targetDist < bestDist)
		{
			bestDist = targetDist;
			bestBlobNetID = validNetID;
		}
	}

	this.getSprite().SetFrame(0); // reset

	if (bestBlobNetID != 0) //start locking onto valid target
	{
		CBlob@ bestBlob = getBlobByNetworkID(bestBlobNetID);
		if (bestBlob != null)
		{
			Vec2f targetPos = bestBlob.getPosition();

			if (bestBlobNetID != curTargetNetID)
			{
				curTargetNetID = bestBlobNetID;
				this.set_u16(targetNetIDString, bestBlobNetID);
				targetingProgress = 0.0f;
			}
			
			this.getSprite().SetFrame(2); // green ping
			angle *= 1.55f;
			if (getGameTime() % 11 == 0)
			{
				this.getSprite().PlaySound("collect.ogg", 0.8, Maths::Clamp(1.5*targetingProgress, 0.7f, 2.0f));
			}

			if (targetingProgress >= 1.0f)
			{
				launcher.found_targets_id.push_back(bestBlobNetID); //place ID in array
			}
			else
			{
				f32 squareAngle = 45.0f * (1.0f-targetingProgress);
				Vec2f squareScale = Vec2f(8.0f, 8.0f)*targetingProgress;
				f32 squareCornerSeparation = 4.0f * targetingProgress;
				makeTargetSquare(targetPos, squareAngle, squareScale, squareCornerSeparation, 1.0f); //target detected rhombus
				this.set_f32(targetingProgressString, Maths::Min(targetingProgress+launcher.progress_speed, 1.0f));
			}
		}
	}
	else //resets if no valid targets in range
	{
		if (curTargetNetID != 0)
		{
			curTargetNetID = 0;
			this.set_u16(targetNetIDString, 0);
		}
	}

	//draw square for all saved targets
	int savedTargetCount = launcher.found_targets_id.length;
	for (uint i = 0; i < savedTargetCount; i++)
	{
		u16 netID = launcher.found_targets_id[i];
		CBlob@ targetBlob = getBlobByNetworkID(netID);
		if (targetBlob == null)
		{ continue; }

		Vec2f targetPos = targetBlob.getPosition();

		makeTargetSquare(targetPos, 0.0f, Vec2f(8.0f, 8.0f), 4.0f, 1.0f); //target acquired square
	}

	if (savedTargetCount > 0 && ownerBlob.isKeyJustPressed(key_action3))
	{
		bool existingTargets = false;
		CBitStream params;
		for (uint i = 0; i < savedTargetCount; i++)
		{
			u16 netID = launcher.found_targets_id[i];
			CBlob@ targetBlob = getBlobByNetworkID(netID);
			if (targetBlob != null)
			{
				params.write_u16(netID);
				existingTargets = true;
			}
		}

		CInventory@ inv = ownerBlob.getInventory();
		if (inv !is null && inv.getItem(ammoBlobName) !is null && existingTargets)
		{
			this.SendCommandOnlyServer(this.getCommandID(launchOrdnanceIDString), params);
			this.set_f32(targetingProgressString, 0);
			this.set_u16(targetNetIDString, 0);
			launcher.found_targets_id.clear();
		}
		else
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 0.55);
		}
	}

	this.setAngleDegrees(angle);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null) return;
	if (!isServer()) return;

	if (cmd == this.getCommandID(launchOrdnanceIDString))
	{
		if (this.hasTag("dead")) return;

		u16 targetNetID = 0;

		float disperseXpos = 0.0f;

		bool existingTargets = false;
		u16[] targetNetIDList;
		while (params.saferead_u16(targetNetID))
		{
			CBlob@ targetBlob = getBlobByNetworkID(targetNetID);
			if (targetNetID != 0 && targetBlob != null)
			{
				targetNetIDList.push_back(targetNetID); //place ID in array
				disperseXpos += targetBlob.getPosition().x;
				existingTargets = true;
			}
		}

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (!existingTargets || !this.isAttached() || point is null) return;

		CBlob@ ownerBlob = point.getOccupied();
		if (ownerBlob is null) return;

		Vec2f launchVec = Vec2f(ownerBlob.isFacingLeft() ? -1 : 1, -1.05f);
		Vec2f thisPos = this.getPosition();
		disperseXpos += thisPos.x;

		CInventory@ inv = ownerBlob.getInventory();
		if (inv is null || inv.getItem(ammoBlobName) is null) return;
		inv.server_RemoveItems(ammoBlobName, 1);

		CBlob@ blob = server_CreateBlob("missile_gutseekerbig", ownerBlob.getTeamNum(), thisPos - Vec2f(0,3));
		if (blob != null)
		{
			blob.setVelocity(launchVec * 3.0f);
			blob.IgnoreCollisionWhileOverlapped(this, 20);

			blob.SetDamageOwnerPlayer(ownerBlob.getPlayer()); 
			
			MissileInfo@ missile;
			if (!blob.get("missileInfo", @missile))
			{ return; }

			int targetAmount = targetNetIDList.length;
			disperseXpos /= targetAmount+1; // average all horizontal positions
			Vec2f dispersePos = Vec2f(disperseXpos, thisPos.y - 200.0f); // disperse position
			blob.set_Vec2f("disperse_pos", dispersePos);

			for (uint i = 0; i < targetAmount; i++)
			{
				missile.target_netid_list.push_back(targetNetIDList[i]);
			}
		}
		//this.Tag("dead");
		//this.server_Die();
	}
}