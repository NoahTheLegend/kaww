// Mechanic animations

#include "MechanicCommon.as"
#include "FireCommon.as"
#include "Requirements.as"
#include "RunnerAnimCommon.as"
#include "RunnerCommon.as"
#include "KnockedCommon.as"
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "Accolades.as"
#include "PerksCommon.as";


void onInit(CSprite@ this)
{
	LoadSprites(this);

	CSpriteLayer@ helmet = this.getSpriteLayer("helmet");
	if (helmet !is null)
	{
		CSpriteLayer@ head = this.getSpriteLayer("head");
        if (head !is null)
        {
            helmet.SetRelativeZ(head.getRelativeZ()+1.0f);
        }
	}

	this.getCurrentScript().runFlags |= Script::tick_not_infire;
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	int armour = PLAYER_ARMOUR_STANDARD;

	CPlayer@ p = this.getBlob().getPlayer();
	if (p !is null)
	{
		armour = p.getArmourSet();
		if (armour == PLAYER_ARMOUR_STANDARD)
		{
			Accolades@ acc = getPlayerAccolades(p.getUsername());
			if (acc.hasCape())
			{
				armour = PLAYER_ARMOUR_CAPE;
			}
		}
	}

	switch (armour)
	{
	case PLAYER_ARMOUR_STANDARD:
		ensureCorrectRunnerTexture(this, "mechanic", "MechanicMale");
		break;
	case PLAYER_ARMOUR_CAPE:
		ensureCorrectRunnerTexture(this, "mechanic", "MechanicMale");
		break;
	case PLAYER_ARMOUR_GOLD:
		ensureCorrectRunnerTexture(this, "mechanic", "MechanicMale");
		break;
	}

	this.RemoveSpriteLayer("camo");
	CSpriteLayer@ camo = this.addSpriteLayer("camo", getBlobByName("info_desert") !is null ? "CamoDesert.png" : "Camo.png" , 32, 32, 0, 0);

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

		camo.SetOffset(Vec2f(0.0f, 0.0f));
		camo.SetAnimation("default");
		camo.SetVisible(false);
		camo.SetRelativeZ(0.31f);
	}
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	bool isCamo = false;

	if (blob !is null && blob.hasTag("reload_sprite"))
	{
		CSpriteLayer@ camo = this.getSpriteLayer("camo");

		if (camo !is null)
		{
			camo.SetFrameIndex(0);
			camo.SetAnimation("movement");
			camo.SetVisible(this.isVisible());
			camo.SetRelativeZ(0.31f);
		}

		blob.Untag("reload_sprite");
		return;
	}

	const bool fl = blob.isFacingLeft();

	const bool exposed = blob.hasTag("machinegunner") || blob.hasTag("collidewithbullets") || blob.hasTag("can_shoot_if_attached");
	const bool sleeping = blob.isAttachedToPoint("BED") || blob.isAttachedToPoint("BED2");
		
	// camo netting
	if (blob.getPlayer() !is null)
	{
		CSpriteLayer@ camo = this.getSpriteLayer("camo");
		CSpriteLayer@ helmet = this.getSpriteLayer("helmet");
		
		if (camo !is null)
		{
			bool stats_loaded = false;
    		PerkStats@ stats = getPerkStats(blob, stats_loaded);

			if (blob.getPlayer() !is null && blob.getPlayer().get("PerkStats", @stats) && stats !is null && stats.ghillie)
			{
				if (helmet !is null) helmet.SetVisible(false);

				if (blob.getShape().vellen > 0.1f)
				{
					camo.SetAnimation("movement");
				}
				else if (camo.isAnimationEnded())
				{
					camo.SetAnimation("default");
				}
				
				camo.SetVisible(this.isVisible());
				if (blob.get_bool("isReloading"))
				{
					camo.SetOffset(this.getOffset());
				}
				else
				{
					camo.SetOffset(this.getOffset() + (blob.isOnGround() && blob.isKeyPressed(key_down) ? Vec2f(0,2) : Vec2f_zero) + Vec2f((blob.getShape().vellen > 0.05f) ? -1 : 0, 0));
				}

				if (blob.isAttached()) camo.SetVisible(false);

				if (blob.isKeyJustPressed(key_down))
				{
					blob.set_u32("become_a_bush", getGameTime()+10);
				}

				if (blob.get_u32("become_a_bush") > 0 && blob.isKeyPressed(key_down)
				&& !blob.isKeyPressed(key_action2)
				&& blob.isOnGround() && blob.getVelocity().Length() <= 2.0f)
				{
					if (getGameTime()>=blob.get_u32("become_a_bush"))
					{
						blob.Tag("bushy");
						if (getGameTime() == blob.get_u32("become_a_bush"))
						{
							this.PlaySound("LeafRustle"+(XORRandom(3)+1)+".ogg", 0.33f, 1.0f);
						}
						
						CSpriteLayer@ bush = this.getSpriteLayer("bush");
						if (bush is null)
							@bush = this.addSpriteLayer("bush", getBlobByName("info_desert") !is null ? "Desert_Bushes.png" : "Bushes.png", 24, 24);

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
							}
						}
					}
					else
					{
						this.RemoveSpriteLayer("bush");
						blob.Untag("bushy");
						this.SetVisible(true);
					}
				}
				else
				{
					this.RemoveSpriteLayer("bush");
					blob.Untag("bushy");
					blob.set_u32("become_a_bush", 0);
					this.SetVisible(true);
					camo.SetVisible(!blob.isAttached() || (exposed && !sleeping));
					this.RemoveSpriteLayer("bush");
				}
			}
			else
			{
				this.SetVisible(true);
				this.RemoveSpriteLayer("bush");
				camo.SetVisible(false);
			}

			if (blob.isAttachedToPoint("BED") || blob.isAttachedToPoint("BED2"))
			{
				this.SetVisible(false);
			}
		}
		else if (helmet !is null) helmet.SetVisible(true);
	}
	
	//this.SetVisible(!blob.isAttached() || (exposed && !sleeping));
	u8 perk_id = 0;

	bool stats_loaded = false;
    PerkStats@ stats = getPerkStats(blob, stats_loaded);

	if (stats_loaded) perk_id = stats.id;

	if (blob.hasTag("dead"))
	{
		{
			CSpriteLayer@ camo = this.getSpriteLayer("camo");
			if (camo !is null) camo.SetAnimation("death");
		}
		
		this.SetAnimation("dead");
		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(2);
		}
		else
		{
			this.SetFrameIndex(1);
		}
		return;
	}
	// animations

	bool knocked = isKnocked(blob);
	const bool action2 = blob.isKeyPressed(key_action2);
	const bool action1 = blob.isKeyPressed(key_action1);

	if (!blob.hasTag(burning_tag)) //give way to burning anim
	{
		const bool left = blob.isKeyPressed(key_left);
		const bool right = blob.isKeyPressed(key_right);
		const bool up = blob.isKeyPressed(key_up);
		const bool down = blob.isKeyPressed(key_down);
		const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
		Vec2f pos = blob.getPosition();

		CBlob@ carriedBlob = blob.getCarriedBlob();

		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
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
		this.SetAnimation("empty");
	}
		else if (blob.hasTag("seatez"))
		{
			this.SetAnimation("heavy");
		}
		else if (action2 || (this.isAnimation("strike") && !this.isAnimationEnded()))
		{
			this.SetAnimation("strike");
		}
		else if ((action1  || (this.isAnimation("build") && !this.isAnimationEnded()))
			&& (carriedBlob is null || !carriedBlob.hasTag("take a1")))
		{
			this.SetAnimation("build");
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
			if ((left && !fl)
				|| (right && fl))
				this.SetAnimation("run_backwards");
			else
				this.SetAnimation("run");
		}
		else
		{
			// get the angle of aiming with mouse
			Vec2f aimpos = blob.getAimPos();
			Vec2f vec = aimpos - pos;
			f32 angle = vec.Angle();
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

			if (blob.hasTag("repairing"))
			{
				this.SetAnimation("repair");
				if (this.animation.frame == 7 && blob.hasTag("wield_lighting"))
				{
					this.animation.frame = 6;

					blob.Untag("wield_lighting");
				}
				else blob.Tag("wield_lighting");
			}
			else defaultIdleAnim(this, blob, direction);
		}
	}

	//set the attack head

	if (knocked)
	{
		blob.Tag("dead head");
	}
	else if (action2 || blob.isInFlames())
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

void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	if (position == Vec2f_zero) return;
	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));
	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

// render cursors

const string cursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (blob.isKeyPressed(key_action1) || this.isAnimation("strike"))
	{

		HitData@ hitdata;
		blob.get("hitdata", @hitdata);
		CBlob@ hitBlob = hitdata.blobID > 0 ? getBlobByNetworkID(hitdata.blobID) : null;

		if (hitBlob !is null) // blob hit
		{
			if (!hitBlob.hasTag("flesh"))
			{
				hitBlob.RenderForHUD(RenderStyle::outline);
			}
		}
		else// map hit
		{
			DrawCursorAt(hitdata.tilepos, cursorTexture);
		}
	}
}

void onGib(CSprite@ this)
{
	if (v_fastrender)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm1     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm2     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}
