#include "ComputerCommon.as"
#include "OrdnanceCommon.as"

const u8 searchRadius = 32.0f;

void onInit(CBlob@ this)
{
	LauncherInfo launcher;
	launcher.progress_speed = 0.04f;
	this.set("launcherInfo", @launcher);
	
	this.set_f32(robotechHeightString, 168.0f); //pixels

	this.getSprite().SetFrame(2); // no hand
}

void onTick(CBlob@ this)
{
	bool heli_launcher = this.isAttachedToPoint("JAVLAUNCHER");
	this.set_bool("is_heli_launcher", heli_launcher);
	if (heli_launcher) // heli's launcher
	{
		this.getSprite().SetVisible(false);
	}

	const bool is_client = isClient();
	const bool is_dead = this.hasTag("dead");
	s8 launcherFrame = this.get_s8("launcher_frame");
	float launcherAngle = this.get_f32("launcher_angle");

	this.setAngleDegrees(launcherAngle);
	if (is_client) this.getSprite().SetFrame(launcherFrame);

	if (is_dead)
	{
		this.set_s8("launcher_frame", 3); // no ammo
		this.set_f32("launcher_angle", 0);
	}

	if (!this.isAttached())
	{
		this.set_f32(robotechHeightString, 68.0f); //resets robotech height
		if (!is_dead)
		{
			this.set_s8("launcher_frame", 2); // not held
			this.set_f32("launcher_angle", 0);
		}
		return;
	}
	
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName((!heli_launcher ? "PICKUP" : "JAVLAUNCHER"));
	if (point is null) return;

	CBlob@ ownerBlob = point.getOccupied();
	if (ownerBlob is null) return;
	
	Vec2f ownerPos = ownerBlob.getPosition();
	Vec2f ownerAimpos = ownerBlob.getAimPos() + Vec2f(2.0f, 2.0f);

	bool launch = false;

	if (heli_launcher) // move controls to pilot of helicopter
	{
		AttachmentPoint@ appilot = ownerBlob.getAttachments().getAttachmentPointByName("DRIVER");
		if (appilot is null) return;
		
		CBlob@ pilot = appilot.getOccupied();
		if (pilot is null) return;

		ownerAimpos = appilot.getAimPos(); // set aimpos to attachment point because kag
		if (appilot.isKeyJustPressed(key_action3)) launch = true;
		@ownerBlob = @pilot;
	}
	else if (!ownerBlob.isMyPlayer() || ownerBlob.isAttached()) return; // only player holding this
	CControls@ controls = getControls();
	
	// binoculars effect
	ownerBlob.set_u32("dont_change_zoom", getGameTime()+3);
	ownerBlob.Tag("binoculars");
	const bool draw_robotech = !heli_launcher && ownerBlob.isMyPlayer();

	if (is_dead)
	{
		if (controls.isKeyJustPressed(KEY_KEY_R))
		{
			launcherSetDeath( this, false );
		}
		return;
	}

	launcherFrame = 2;
	launcherAngle = ownerBlob.isFacingLeft() ? 30.0f : -30.0f;

	u16 curTargetNetID = this.get_u16(targetNetIDString);
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

	launcherFrame = 0; // grabbed, no green ping

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
			
			f32 squareAngle = 45.0f * (1.0f - targetingProgress) * 3;
			if (heli_launcher) squareAngle = 90.0f;
			Vec2f squareScale = Vec2f(36.0f, 36.0f) * (2.0f - targetingProgress*1.5);
			f32 squareCornerSeparation = 4.0f;
			makeTargetSquare(targetPos, squareAngle, squareScale, squareCornerSeparation, 1.0f, targetingProgress == 1.0f ? redConsoleColor : yellowConsoleColor); //target detected rhombus
			this.set_f32(targetingProgressString, Maths::Min(targetingProgress+0.01f, 1.0f));

			launcherFrame = 1; // green ping
			launcherAngle *= 1.55f;

			if (getGameTime() % 11 == 0)
			{
				this.getSprite().PlaySound("collect.ogg", 0.8, Maths::Clamp(1.5*targetingProgress, 0.7f, 2.0f));
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

	float robotechHeight = this.get_f32(robotechHeightString);
	if (draw_robotech)
	{
		if (controls.isKeyJustPressed(MOUSE_SCROLL_DOWN))
		{
			robotechHeight += 10.0f;

			this.getSprite().PlaySound("techsound3.ogg", 0.65);
		}
		else if (controls.isKeyJustPressed(MOUSE_SCROLL_UP))
		{
			robotechHeight -= 10.0f;

			this.getSprite().PlaySound("techsound3.ogg", 0.65, 0.75);
		}
	}

	robotechHeight = Maths::Clamp(robotechHeight, 18.0f, 118.0f);
	this.set_f32(robotechHeightString, robotechHeight);

	Vec2f robotechPos = Vec2f(0, -robotechHeight * 2.0f);
	robotechPos.RotateByDegrees(ownerBlob.isFacingLeft() ? -45.0f : 45.0f); 
	robotechPos += ownerPos; // join with thispos

	if (draw_robotech) makeTargetSquare(robotechPos, 0, Vec2f(3.0f, 3.0f), 3.0f, 1.0f, greenConsoleColor); // turnpoint
	
	CBlob@ targetBlob = getBlobByNetworkID(curTargetNetID);
	if (curTargetNetID == 0 || targetBlob == null)
	{
		makeTargetSquare(ownerAimpos, 0, Vec2f(32.0f, 20.0f), 2.0f, 1.0f, greenConsoleColor);
	}
	else if (draw_robotech)
	{
		drawParticleLine( ownerPos - Vec2f(0,2), robotechPos, Vec2f_zero, greenConsoleColor, 0, 5.0f); // trajectory
		drawParticleLine( robotechPos, targetBlob.getPosition(), Vec2f_zero, greenConsoleColor, 0, 5.0f); // trajectory
	}

	if (ownerBlob.isKeyJustPressed(key_action1) || launch)
	{
		if (targetingProgress == 1.0f)
		{
			CBitStream params;
			params.write_u16(curTargetNetID);
			params.write_f32(robotechHeight);
			this.SendCommandOnlyServer(this.getCommandID(launchOrdnanceIDString), params);

			if (!heli_launcher)
			{
				this.set_f32(targetingProgressString, 0);
				this.set_u16(targetNetIDString, 0);
			}
		}
		else
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 0.55);
		}
	}

	/*
	if (targetingProgress == 1.0f && ownerBlob.isKeyJustPressed(key_action3))
	{
		CInventory@ inv = ownerBlob.getInventory();
		if (inv !is null && inv.getItem(ammoBlobName) !is null)
		{
			CBitStream params;
			params.write_u16(curTargetNetID);
			params.write_f32(robotechHeight);
			this.SendCommandOnlyServer(this.getCommandID(launchOrdnanceIDString), params);
			this.set_f32(targetingProgressString, 0);
			this.set_u16(targetNetIDString, 0);
		}
		else
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 0.55);
		}
	}
	*/

	bool differentAngle = launcherAngle != this.getAngleDegrees();
	bool differentFrame = launcherFrame != this.get_s8("launcher_frame");
	
	if (differentAngle || differentFrame)
	{
		CBitStream params;
		params.write_s8(launcherFrame);
		params.write_f32(launcherAngle);
		this.SendCommand(this.getCommandID(launcherUpdateStateIDString), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null) return;
	if (!isServer()) return;

	if (cmd == this.getCommandID(launchOrdnanceIDString))
	{
		if (this.hasTag("dead")) return;

		u16 curTargetNetID = 0;
		float robotechHeight = 64.0f;

		if (!params.saferead_u16(curTargetNetID)) return;
		if (!params.saferead_f32(robotechHeight)) return;

		CBlob@ targetBlob = getBlobByNetworkID(curTargetNetID);
		if (curTargetNetID == 0 || targetBlob == null) return;
		
		if (!this.isAttached()) return;

		bool heli_launcher = this.get_bool("is_heli_launcher");

		if (heli_launcher) robotechHeight = 0.0f;

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName(!heli_launcher ? "PICKUP" : "JAVLAUNCHER");
		if (point is null) return;

		CBlob@ ownerBlob = point.getOccupied();
		if (ownerBlob is null) return;

		if (heli_launcher && ownerBlob.get_u32("next_shoot") >= getGameTime()) return;

		Vec2f launchVec = Vec2f(ownerBlob.isFacingLeft() ? -1 : 1, -1.05f);
		Vec2f thisPos = this.getPosition();

		CBlob@ blob = server_CreateBlob("missile_javelin", ownerBlob.getTeamNum(), thisPos - Vec2f(0,3));
		if (blob != null)
		{
			blob.setVelocity(launchVec * 3.0f);
			blob.IgnoreCollisionWhileOverlapped(this, 20);

			blob.SetDamageOwnerPlayer(ownerBlob.getPlayer()); 
			blob.set_u16(targetNetIDString, curTargetNetID);
			blob.set_f32(robotechHeightString, thisPos.y - robotechHeight);
		}

		launcherSetDeath( this, true); // set dead
	}
}