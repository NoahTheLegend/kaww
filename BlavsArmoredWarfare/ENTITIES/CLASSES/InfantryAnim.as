#include "InfantryCommon.as"
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"

const f32 config_offset = -4.0f;

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	ensureCorrectRunnerTexture(this, this.getBlob().getName(), this.getBlob().getName().toUpper());
	string texname = getRunnerTextureName(this);

	this.RemoveSpriteLayer("frontarm");
	CSpriteLayer@ frontarm = this.addTexturedSpriteLayer("frontarm", texname , 32, 16);

	if (frontarm !is null)
	{
		Animation@ animcharge = frontarm.addAnimation("default", 0, false);
		animcharge.AddFrame(40);
		Animation@ animshoot = frontarm.addAnimation("fired", 0, false);
		animshoot.AddFrame(32);
		Animation@ camogun = frontarm.addAnimation("camogun", 0, false);
		camogun.AddFrame(56);
		Animation@ animnoarrow = frontarm.addAnimation("no_arrow", 0, false);
		animnoarrow.AddFrame(33);
		Animation@ camogunnoarrow = frontarm.addAnimation("camogunno_arrow", 0, false);
		camogunnoarrow.AddFrame(57);
		frontarm.SetOffset(Vec2f(-1.0f, 5.0f + config_offset));
		frontarm.SetAnimation("fired");
		frontarm.SetVisible(false);
	}

	this.RemoveSpriteLayer("backarm");
	CSpriteLayer@ backarm = this.addTexturedSpriteLayer("backarm", texname , 32, 16);

	if (backarm !is null)
	{
		Animation@ anim = backarm.addAnimation("default", 0, false);
		anim.AddFrame(0); //131
		backarm.SetOffset(Vec2f(-10.0f, 5.0f + config_offset));
		backarm.SetAnimation("default");
		backarm.SetVisible(false);
	}

	this.RemoveSpriteLayer("camo");
	CSpriteLayer@ camo = this.addSpriteLayer("camo", "Camo.png" , 32, 32, 0, 0);

	if (camo !is null)
	{
		Animation@ anim = camo.addAnimation("movement", 4, true);
		anim.AddFrame(0);
		anim.AddFrame(1);
		anim.AddFrame(2);
		anim.AddFrame(3);
		Animation@ noanim = camo.addAnimation("default", 0, false);
		noanim.AddFrame(0);
		Animation@ dead = camo.addAnimation("death", 0, false);
		dead.AddFrame(4);

		camo.SetOffset(Vec2f(0.0f, 0.0f + config_offset));
		camo.SetAnimation("movement");
		camo.SetVisible(false);
		camo.SetRelativeZ(0.26f);
	}
}

void setArmValues(CSpriteLayer@ arm, bool visible, f32 angle, f32 relativeZ, string anim, Vec2f around, Vec2f offset)
{
	if (arm !is null)
	{
		arm.SetVisible(visible);

		if (visible)
		{
			arm.SetOffset(offset);
			arm.ResetTransform();
			arm.SetRelativeZ(relativeZ);
			arm.RotateBy(angle, around);
		}
	}
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	bool isCamo = false;

	if (blob !is null && blob.hasTag("reload_sprite"))
	{
		CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");

		if (frontarm !is null)
		{
			printf("not null");
			frontarm.SetFrameIndex(0);
			frontarm.SetAnimation("camogun");
			frontarm.SetVisible(true);
		}

		CSpriteLayer@ camo = this.getSpriteLayer("camo");

		if (camo !is null)
		{
			camo.SetFrameIndex(0);
			camo.SetAnimation("movement");
			camo.SetVisible(true);
			camo.SetRelativeZ(0.26f);
		}

		getRules().set_string(blob.getPlayer().getUsername() + "_perk", "Camouflage");
		blob.Untag("reload_sprite");
		return;
	}

	// camo netting
	if (blob.getPlayer() !is null)
	{
		CSpriteLayer@ camo = this.getSpriteLayer("camo");
		CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");

		if (camo !is null && frontarm !is null)
		{
			if (getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Camouflage")
			{
				isCamo = true;

				if (blob.getShape().vellen > 0.1f)
				{
					camo.SetAnimation("movement");
				}
				else if (camo.isAnimationEnded())
				{
					camo.SetAnimation("default");
				}
				
				camo.SetVisible(true);
				if (blob.get_bool("isReloading"))
				{
					camo.SetOffset(this.getOffset());
				}
				else
				{
					camo.SetOffset(this.getOffset() + Vec2f((blob.getShape().vellen > 0.05f) ? -1 : 0, 0));
				}

				frontarm.SetAnimation("camogun");

				if (blob.isAttached()) camo.SetVisible(false);
			}
			else
			{
				camo.SetVisible(false);
				frontarm.SetAnimation("fired");
			}
		}
	}

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
			this.RemoveSpriteLayer("frontarm");
			this.RemoveSpriteLayer("backarm");

			CSpriteLayer@ camo = this.getSpriteLayer("camo");
			camo.SetAnimation("death");
		}

		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(1);
		}
		else
		{
			this.SetFrameIndex(2);
		}

		return;
	}

	printf("camo is "+isCamo);

	ArcherInfo@ archer;
	if (!blob.get("archerInfo", @archer))
	{
		return;
	}

	// animations
	const bool firing = IsFiring(blob);
	bool showgun = true;
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	bool isStabbing = archer.isStabbing;
	bool isReloading = blob.get_bool("isReloading"); // archer.isReloading;
	bool crouch = false;

	if (blob.isOnGround())
	{
		if (blob.getVelocity().x <= 1.0f && blob.getVelocity().x >= -1.0f)
		{
			if (down)
			{
				this.ResetTransform();
				this.SetOffset(Vec2f(0, isCamo ? -1.5 : -2.5));
			}
			else this.SetOffset(Vec2f(0, -4.0));
		}
		else this.SetOffset(Vec2f(0, -4.0));
	}

	bool knocked = isKnocked(blob) && !isReloading;
	Vec2f pos = blob.getPosition();
	Vec2f aimpos = blob.getAimPos();
	// get the angle of aiming with mouse
	Vec2f vec = aimpos - pos;
	f32 angle = vec.Angle();

	if (!blob.hasTag("show_gun") && (isStabbing || isReloading || blob.isAttached()))
	{
		showgun = false;
	}

	if (knocked)
	{
		if (inair)
		{
			this.SetAnimation("knocked_air");
		}
		else
		{
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag("seated"))
	{
		this.SetAnimation("default");
	}
	else if (blob.hasTag("seatez"))
	{
		this.SetAnimation("heavy");
	}
	else if (showgun)
	{
		if (blob.isKeyJustPressed(key_action3) || blob.get_u32("end_stabbing") > getGameTime())
		{
			this.SetAnimation("stab");
		}
		else if (inair)
		{
			this.SetAnimation("shoot_jump");

			if (blob.getVelocity().y > -0.75f)
			{
				this.animation.frame = 1;
			}
			else
			{
				this.animation.frame = 0;
			}
			
		}
		else if ((left || right) ||
		         (blob.isOnLadder() && (up || down)))
		{
			if (blob.hasTag("sprinting"))
			{
				this.SetAnimation("sprint");
			}
			else
			{
				if (blob.isKeyPressed(key_action2))
				{
					this.SetAnimation("shoot_walk");
				}
				else
				{
					this.SetAnimation("shoot_run");
				}
			}
		}
		else
		{
			this.SetAnimation("shoot");
		}
	}
	else if (isStabbing)
	{
		this.SetAnimation("stab");
	}
	else if (isReloading)
	{
		this.SetAnimation("reload");
	}
	else if (inair)
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		Vec2f vel = blob.getVelocity();
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fall");
			this.animation.timer = 0;

			if (vy < -1.5)
			{
				this.animation.frame = 0;
			}
			else if (vy > 1.5)
			{
				this.animation.frame = 2;
			}
			else
			{
				this.animation.frame = 1;
			}
		}
	}
	else if ((left || right) ||
	         (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		if (down && this.isAnimationEnded())
			crouch = true;

		int direction;

		if ((angle > 330 && angle < 361) || (angle > -1 && angle < 30) ||
		        (angle > 150 && angle < 210))
		{
			direction = 0;
		}
		else if (aimpos.y < pos.y)
		{
			direction = -1;
		}
		else
		{
			direction = 1;
		}

		defaultIdleAnim(this, blob, direction);
	}

	// anti tank has 2 different states
	if (blob.getName() == "antitank")
	{
		CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");
		if (frontarm !is null)
		{
			if (blob.get_u32("mag_bullets") == 0)
			{
				Animation@ anim = frontarm.getAnimation(isCamo ? "camogunno_arrow" : "no_arrow");
				if (anim !is null) frontarm.SetAnimation(anim);
			}	
			else if (blob.get_u32("mag_bullets") > 0)
			{
				Animation@ anim = frontarm.getAnimation(isCamo ? "camogun" : "fired");
				if (anim !is null) frontarm.SetAnimation(anim);
			}
		}
	}

	//arm anims
	Vec2f armOffset = Vec2f(-1.0f, 4.0f + config_offset);
	f32 armangle = -angle;
	bool stabbing = blob.get_u32("end_stabbing") > getGameTime();

	if (showgun && !stabbing)
	{
		if (this.isFacingLeft())
		{
			armangle = 180.0f - angle;
		}

		if (blob.getName() == "sniper")
		{
			if (blob.get_s32("my_chargetime")-10 > 0)
			{
				armangle += Maths::Min(Maths::Abs(blob.get_s32("my_chargetime")-10)*0.6, 22) * (this.isFacingLeft() ? 1 : -1);
			}
		}
		else
		{
			if (blob.get_s32("my_chargetime") > 0)
			{
				armangle += Maths::Min(Maths::Abs(blob.get_s32("my_chargetime"))*3, 20) * (this.isFacingLeft() ? 1 : -1);
			}
		}

		while (armangle > 180.0f)
		{
			armangle -= 360.0f;
		}

		while (armangle < -180.0f)
		{
			armangle += 360.0f;
		}

		if (!blob.isKeyPressed(key_action2))
		{
			if (this.isFacingLeft())
			{
				if (armangle > 70)
				{
					armOffset -= Vec2f((armangle - 70)/8, 0);
				}

				if (armangle < -40)
				{
					armOffset -= Vec2f(-(armangle + 40)/7, -(armangle + 40)/14);
				}
			}
			else
			{
				if (armangle < -70)
				{
					armOffset -= Vec2f(-(armangle + 70)/8, 0);
				}

				if (armangle > 40)
				{
					armOffset -= Vec2f((armangle - 40)/7, (armangle - 40)/14);
				}
			}
		}
		else
		{
			if (!blob.isKeyPressed(key_action1) && !blob.isKeyPressed(key_action2)) //running/walking
			{
				armOffset -= Vec2f(0.0f,Maths::Abs(blob.getVelocity().x)*0.5f);

				if (this.isFacingLeft())
				{
					armangle += Maths::Abs(blob.getVelocity().x)*-10.0f;
				}
				else
				{
					armangle += Maths::Abs(blob.getVelocity().x)*10.0f;
				}
			}
		}
		
		if (!blob.isOnGround()) //in air
		{
			armOffset -= Vec2f(0,1);
		}
		else if (blob.isKeyPressed(key_action2)) //ads
		{
			armOffset -= Vec2f(2.5f, 1.0f);
		}
		
		DrawGun(this, blob, archer, armangle, armOffset);
	}
	else
	{
		setArmValues(this.getSpriteLayer("frontarm"), false, 0.0f, 0.1f, "default", Vec2f(0, 0), armOffset);
	}

	//set the head anim
	if (knocked || crouch)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action1) || blob.isKeyPressed(key_action2))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}
}

void DrawGun(CSprite@ this, CBlob@ blob, ArcherInfo@ archer, f32 armangle, Vec2f armOffset)
{
	f32 sign = (this.isFacingLeft() ? 1.0f : -1.0f);
	CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");

	frontarm.animation.frame = 4;
	setArmValues(frontarm, true, armangle, 0.1f, "default", Vec2f(-4.0f * sign, 0.0f), armOffset + Vec2f(0.0f, (Maths::Abs(blob.getVelocity().x) >= 1.0f && blob.isOnGround()) ? ((getGameTime() % 8 < 4) ? -1.0f : 0.0f) : 0.0f));

	if (blob.getCarriedBlob() !is null)
	{
		frontarm.SetVisible(!blob.getCarriedBlob().hasTag("hidesgunonhold"));
	}

	frontarm.SetRelativeZ(1.5f);
	setArmValues(this.getSpriteLayer("backarm"), true, armangle, -0.1f, "default", Vec2f(-4.0f * sign, 0.0f), armOffset + Vec2f(0.0f, (Maths::Abs(blob.getVelocity().x) >= 1.0f && blob.isOnGround()) ? ((getGameTime() % 8 < 4) ? -1.0f : 0.0f) : 0.0f));
}

bool IsFiring(CBlob@ blob)
{
	return blob.isKeyPressed(key_action1);
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("SoldierGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("SoldierGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Flesh   = makeGibParticle("SoldierGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Arm2    = makeGibParticle("SoldierGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}