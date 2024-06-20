bool isCrouching(CBlob@ this)
{
	return
		//must be on ground and pressing down
		this.isOnGround()
		&& this.isKeyPressed(key_down)
		//cannot have movement intent
		&& !this.isKeyPressed(key_left)
		&& !this.isKeyPressed(key_right)
		//cannot have banned crouch (done in actor logic scripts)
		&& !this.hasTag("prevent crouch");
}

bool hasJustCrouched(CBlob@ this)
{
	return isCrouching(this) && (this.isKeyJustPressed(key_down) || this.isKeyJustReleased(key_down));
}

// character was placed in crate
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true; // run scripts while in crate
	this.getMovement().server_SetActive(true);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CShape@ shape = this.getShape();
	CShape@ oShape = blob.getShape();
	if (shape is null || oShape is null)
	{
		error("error: missing shape in runner doesCollideWithBlob");
		return false;
	}

	if (blob.isPlatform() && blob.getAngleDegrees() == 0
		&& this.get_u8("crouch_through") > 0
		&& this.getTeamNum() == blob.getTeamNum())
	{
		return false;
	}

	bool colliding_block = (oShape.isStatic() && oShape.getConsts().collidable);

	// when dead, collide only if its moving and some time has passed after death
	if (this.hasTag("dead"))
	{
		bool slow = (this.getShape().vellen < 1.5f);
		//static && collidable should be doors/platform etc             fast vel + static and !player = other entities for a little bit (land on the top of ballistas).
		return colliding_block || (!slow && oShape.isStatic() && !blob.hasTag("player"));
	}
	else // collide only if not a player or other team member, or crouching
	{
		//other team member
		if (blob.hasTag("player") && this.getTeamNum() == blob.getTeamNum())
		{
            Vec2f pos = this.getPosition();
            Vec2f blobpos = blob.getPosition();

            bool platform = this.get_bool("platform");
            bool blobplatform = blob.get_bool("platform");

            Vec2f aimdir = this.getAimPos() - this.getPosition();
            f32 aimangle = aimdir.Angle();

            if (blobplatform && aimangle > 225 && aimangle < 315)
                return !this.isKeyPressed(key_down);
            
			return (platform && blobpos.y < pos.y - this.getRadius()) // we're platform
                    || (blobplatform && pos.y < blobpos.y - blob.getRadius()); // other is platform
		}
    
		//don't collide if crouching (but doesn't apply to blocks)
		if (!shape.isStatic() && !colliding_block && isCrouching(this))
		{
			return false;
		}

	}

	return true;
}

void onTick(CBlob@ this)
{
    bool justcrouched = hasJustCrouched(this);
    bool is_platform = false;

    if (!justcrouched && this.isOnScreen())
    {
        bool a1 = this.isKeyPressed(key_action1);
	    bool a3 = this.isKeyPressed(key_action3);
    
	    Vec2f aimdir = this.getAimPos() - this.getPosition();
	    f32 aimdir_angle = aimdir.Angle();
        
        bool platform = !a1 && !a3 && this.isOnGround() 
            && aimdir_angle >= 45 && aimdir_angle <= 135
            && this.isKeyPressed(key_down) && !this.hasTag("bushy");

        is_platform = platform;
    }
    this.set_bool("platform", is_platform);
        
	if (justcrouched)
	{
        this.getShape().checkCollisionsAgain = true;
		const uint count = this.getTouchingCount();
		for (uint step = 0; step < count; ++step)
		{
			CBlob@ blob = this.getTouchingByIndex(step);
			blob.getShape().checkCollisionsAgain = true;
		}
	}
}
