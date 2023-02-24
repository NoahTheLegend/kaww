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
		camo.SetAnimation("default");
		camo.SetVisible(false);
		camo.SetRelativeZ(0.31f);
	}

	CSpriteLayer@ skull = this.addSpriteLayer("skull", "DeathIncarnate.png", 16, 16, 0, 0);
	if (skull !is null)
	{
		skull.SetFrameIndex(0);
		skull.SetOffset(Vec2f(0.0f, -15.0f));
		skull.ScaleBy(Vec2f(0.75f,0.75f));
		skull.SetRelativeZ(-5.0f);
		skull.SetVisible(false);
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
	bool hide_frontarm = false;

	if (blob !is null && blob.hasTag("reload_sprite"))
	{
		CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");

		if (frontarm !is null)
		{
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
			camo.SetRelativeZ(0.31f);
		}

		if (blob.getPlayer() !is null) getRules().set_string(blob.getPlayer().getUsername() + "_perk", "Camouflage");
		blob.Untag("reload_sprite");
		return;
	}

	if (blob.getPlayer() !is null)
	{
		CSpriteLayer@ camo = this.getSpriteLayer("camo");
		CSpriteLayer@ frontarm = this.getSpriteLayer("frontarm");
		CSpriteLayer@ helmet = this.getSpriteLayer("helmet");

		if (camo !is null && frontarm !is null)
		{
			if (blob.getPlayer() !is null && getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Camouflage")
			{
				isCamo = true;

				if (helmet !is null) helmet.SetVisible(false);

				if (blob.getShape().vellen > 0.1f)
				{
					camo.SetAnimation("movement");
				}
				else if (blob.hasTag("dead"))
				{
					camo.SetAnimation("death");
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
					camo.SetOffset(this.getOffset() + (blob.isOnGround() && blob.isKeyJustPressed(key_down) ? Vec2f(0,2) : Vec2f_zero) + Vec2f((blob.getShape().vellen > 0.05f) ? -1 : 0, 0));
				}

				frontarm.SetAnimation("camogun");

				if (blob.isAttached()) camo.SetVisible(false);

				if (blob.isKeyJustPressed(key_down))
				{
					blob.set_u32("become_a_bush", getGameTime()+20);
				}

				if (blob.get_u32("become_a_bush") > 0 && blob.isKeyPressed(key_down)
				&& !blob.isKeyPressed(key_action1)
				&& blob.isOnGround() && blob.getVelocity().Length() <= 2.0f)
				{
					if (getGameTime()>=blob.get_u32("become_a_bush"))
					{
						if (getGameTime() == blob.get_u32("become_a_bush"))
						{
							this.PlaySound("LeafRustle"+(XORRandom(3)+1)+".ogg", 0.33f, 1.0f);
						}
						CSpriteLayer@ bush = this.getSpriteLayer("bush");
						if (bush is null)
							@bush = this.addSpriteLayer("bush", "Bushes.png", 24, 24);

						if (bush !is null)
						{
							Animation@ rand = bush.getAnimation("rand");
							if (rand is null)
							{
								@rand = bush.addAnimation("rand", 0, false);
								if (rand !is null)
								{
									bush.SetVisible(false);
									bush.SetOffset(Vec2f(0,4));
									bush.SetRelativeZ(10.0f);
									int[] frames = {0,1,2,3,5,6,7};
									rand.AddFrames(frames);
									bush.SetAnimation(rand);
									blob.set_u8("bush_icon", XORRandom(frames.length));
									blob.set_bool("bush_faceleft", XORRandom(2)==0);
									bush.SetFrameIndex(blob.get_u8("bush_icon"));
								}
							}
							else
							{
								bush.SetVisible(true);
								bush.SetFrameIndex(blob.get_u8("bush_icon"));
								bush.SetFacingLeft(blob.get_bool("bush_faceleft"));

								this.SetVisible(false);
								camo.SetVisible(false);
								frontarm.SetVisible(false);
								hide_frontarm = true;
								if (helmet !is null) helmet.SetVisible(false);
							}
						}
					}
				}
				else
				{
					blob.set_u32("become_a_bush", 0);
					this.SetVisible(true);
					camo.SetVisible(!blob.isAttached());
					frontarm.SetVisible(true);
					this.RemoveSpriteLayer("bush");
				}
			}
			else
			{
				camo.SetVisible(false);
				frontarm.SetAnimation("fired");
				{
					CSpriteLayer@ bush = this.getSpriteLayer("bush");
					if (bush !is null) bush.SetVisible(false);

					blob.set_u32("become_a_bush", 0);
					this.SetVisible(true);
					frontarm.SetVisible(true);
					this.RemoveSpriteLayer("bush");
					if (helmet !is null && !blob.isAttached()) helmet.SetVisible(true);
				}
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
		}

		//if (blob.getPlayer() !is null && getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Camouflage")
		{
			CSpriteLayer@ camo = this.getSpriteLayer("camo");
			if (camo !is null) camo.SetAnimation("death");
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

	CSpriteLayer@ skull = this.getSpriteLayer("skull");
	if (skull !is null)
	{
		skull.SetFacingLeft(false);
		if ((showgun || isReloading)
		&& blob.getPlayer() !is null && getRules().get_string(blob.getPlayer().getUsername() + "_perk") == "Death Incarnate")
		{
			skull.SetVisible(true);
		}
		else skull.SetVisible(false);	
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
		if ((blob.isKeyJustPressed(key_action3) && blob.getName() != "mp5") || blob.get_u32("end_stabbing") > getGameTime())
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

	if (blob.isAttachedToPoint("BED") || blob.isAttachedToPoint("BED2"))
	{
		this.SetVisible(false);
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

		if (!blob.hasTag("armangle_lock"))
		{
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
		}

		if (armangle > 180.0f)
		{
			armangle -= 360.0f;
		}

		if (armangle < -180.0f)
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
		
		if (!hide_frontarm) DrawGun(this, blob, archer, armangle, armOffset);
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
	if (v_fastrender) return;
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