// Medic logic

#include "InfantryCommon.as"
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "RunnerCommon.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";
#include "Recoil.as";

void onInit(CBlob@ this)
{
	ArcherInfo archer;
	this.set("archerInfo", @archer);

	this.set_s8("charge_time", 0);
	this.set_u8("charge_state", ArcherParams::not_aiming);
	this.set_bool("has_arrow", false);
	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("flesh");

	this.push("names to activate", "keg");

	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("shoot arrow");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
	if (!getNet().isServer())
	{
		return;
	}

	if (aimangle < 0.0f)
	{
		aimangle += 360.0f;
	}

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateBy(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 attack_distance = 22.0f;

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null && !dontHitMore) // blob
			{
				if (b.hasTag("ignore sword")) continue;

				//big things block attacks
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

				if (!canHit(this, b))
				{
					// no TK
					if (large)
						dontHitMore = true;

					continue;
				}

				if (!dontHitMore)
				{
					Vec2f velocity = b.getPosition() - pos;
					this.server_Hit(b, hi.hitpos, velocity, damage, type, true);  // server_Hit() is server-side only

					// end hitting if we hit something solid, don't if its flesh
					if (large)
					{
						dontHitMore = true;
					}
				}
			}
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16, 16));
	}
}

void ManageBow(CBlob@ this, ArcherInfo@ archer, RunnerMoveVars@ moveVars)
{
	//are we responsible for this actor?
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer() && !ismyplayer)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			responsible = p.isBot();
		}
	}

	CSprite@ sprite = this.getSprite();
	bool hasarrow = archer.has_arrow;
	bool hasnormal = hasArrows(this, ArrowType::normal);
	s8 charge_time = archer.charge_time;
	bool isStabbing = archer.isStabbing;
	u8 charge_state = archer.charge_state;
	const bool pressed_action2 = this.isKeyPressed(key_action2);
	Vec2f pos = this.getPosition();

	if (responsible)
	{
		if ((getGameTime() + this.getNetworkID()) % 10 == 0)
		{
			hasarrow = hasArrows(this);

			if (!hasarrow && hasnormal)
			{
				// set back to default
				hasarrow = hasnormal;
			}
		}

		if (hasarrow != this.get_bool("has_arrow"))
		{
			this.set_bool("has_arrow", hasarrow);
			this.Sync("has_arrow", isServer());
		}
	}

	// Do the stab
	if (charge_time == 13 && archer.isStabbing)
	{
		f32 attackarc = 95.0f;

		DoAttack(this, 1.5f, (this.isFacingLeft() ? 180.0f : 0.0f), attackarc, Hitters::sword);

		Sound::Play("/SwordSlash", this.getPosition());
	}

	// Start the stab
	if (this.isKeyJustPressed(key_action2) && !this.isKeyPressed(key_action1))
	{
		moveVars.walkFactor *= 0.8f;

		if (archer.charge_time == 0)
		{
			charge_time = 18;

			archer.isStabbing = true;
		}
	}
	else if (this.isKeyPressed(key_action1))
	{
		moveVars.walkFactor *= 0.8f;
		moveVars.jumpFactor *= 0.0f;
		moveVars.canVault = true;

		const bool just_action1 = this.isKeyJustPressed(key_action1);

		if (charge_time == 0 && isStabbing == false && (this.isOnGround() || this.wasOnGround() || this.isOnLadder() || this.wasOnLadder()))
		{
			charge_state = ArcherParams::readying;
			hasarrow = hasArrows(this);

			if (!hasarrow && hasnormal)
			{
				hasarrow = hasnormal;
			}

			if (responsible)
			{
				this.set_bool("has_arrow", hasarrow);
				this.Sync("has_arrow", isServer());
			}

			if (!hasarrow)
			{
				charge_state = ArcherParams::no_arrows;

				if (ismyplayer && !this.wasKeyPressed(key_action1))   // playing annoying no ammo sound
				{
					this.getSprite().PlaySound("Entities/Characters/Sounds/NoAmmo.ogg", 0.5);
				}
			}
			else
			{
				if (ismyplayer)
				{
					ClientFire(this, charge_time, hasarrow, archer.arrow_type, false);

					charge_time = 7;
					charge_state = ArcherParams::fired;
				}

				if (!ismyplayer)   // lower the volume of other players charging  - ooo good idea
				{
					sprite.SetEmitSoundVolume(0.5f);
				}
			}
		}
		else
		{
			charge_time--;

			if (charge_time <= 0)
			{
				charge_time = 0;

				archer.isStabbing = false;
			}
		}
	}
	else
	{
		if (this.getPlayer() !is null)
		{
			moveVars.walkFactor *= this.getPlayer().hasTag("Conditioning") ? 1.0f : 0.9f;
			moveVars.jumpFactor *= this.getPlayer().hasTag("Conditioning") ? 1.1f : 1.0f;
		}

		charge_time--;

		if (charge_time <= 0)
		{
			charge_time = 0;

			archer.isStabbing = false;
		}
	}

	// Inhibit movement when stabbing
	if (charge_time > 0 && isStabbing == true)
	{
		moveVars.walkFactor *= 0.7f;
		moveVars.jumpFactor *= 0.8f;
	}

	// my player!

	if (responsible)
	{
		// set cursor

		if (ismyplayer && !getHUD().hasButtons())
		{
			int frame = 0;
			if (charge_time < 4)
			{
				frame = charge_time;
			}
			else
			{
				frame = 3;
			}
			getHUD().SetCursorFrame(frame);
		}

		// activate/throw

		//if (this.isKeyJustPressed(key_action3))
		//{
		//	client_SendThrowOrActivateCommand(this);
		//}
	}

	archer.charge_time = charge_time;
	archer.charge_state = charge_state;
	archer.has_arrow = hasarrow;
}

void onTick(CBlob@ this)
{
	ArcherInfo@ archer;
	if (!this.get("archerInfo", @archer))
	{
		return;
	}

	if (isKnocked(this) || this.isInInventory())
	{
		archer.charge_state = 0;
		archer.charge_time = 0;
		getHUD().SetCursorFrame(0);
		return;
	}

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	ManageBow(this, archer, moveVars);


	if (getGameTime() % 13 == 0)
	{
		//     Heal system
	    float heal_amount = 0.125f;   //Amount the blob is repaired every 15 ticks

	    array<CBlob@> blobs;//Blob array full of blobs
	    CMap@ map = getMap();
	    map.getBlobsInRadius(this.getPosition(), 64.0f, blobs);//Put the blobs within the repair distance into the "blobs" array

	    for (u16 i = 0; i < blobs.size(); i++)//For every blob in this array
	    {
	        if (blobs[i].hasTag("player") && this.getTeamNum() == blobs[i].getTeamNum() && this !is blobs[i] && !blobs[i].hasTag("dead"))//If they have the repair tag
	        {
	            if (blobs[i].getHealth() + heal_amount <= blobs[i].getInitialHealth())//This will only happen if the health does not go above the inital (max health) when heal_amount is added. 
	            {
	                blobs[i].server_SetHealth(blobs[i].getHealth() + heal_amount);//Add the repair amount.

	                const Vec2f pos = blobs[i].getPosition() + Vec2f(0.0f, -15.0f);
					CParticle@ p = ParticleAnimated("HealingParticle.png", pos, Vec2f(0,0), -0.5f, 1.0f, 3.0f, 0.0f, false);
					if (p !is null) { p.diesoncollide = false; p.fastcollision = true; p.lighting = false; }

	                this.getSprite().PlaySound("Heart.ogg");
	            }
	            else //Repair amount would go above the inital health (max health). 
	            {
	                blobs[i].server_SetHealth(blobs[i].getInitialHealth());//Set health to the inital health (max health)
	            }
	        }
	    }
	}
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ClientFire(CBlob@ this, const s8 charge_time, const bool hasarrow, const u8 arrow_type, const bool legolas)
{
	// FIRE!
	if (hasarrow && canSend(this))  // client-logic
	{
		if (this.getPlayer().hasTag("Sharpshooter") && Maths::Abs(this.getVelocity().x) < 0.02f)
		{
			ShootArrow(this, this.getPosition(), this.getAimPos() + Vec2f(-9.0f + XORRandom(18), -9.0f + XORRandom(18)), ArcherParams::shoot_max_vel*2.1f, ArrowType::normal, legolas);
		}
		else
		{
			ShootArrow(this, this.getPosition(), this.getAimPos() + Vec2f(-17.0f + XORRandom(34), -17.0f + XORRandom(34)), ArcherParams::shoot_max_vel*2.1f, ArrowType::normal, legolas);
		}

		
		
		CMap@ map = getMap();
		ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -8.0f : 8.0f, -0.0f), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
		
		CPlayer@ p = getLocalPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				CPlayer@ ply = local.getPlayer();
			
				if (ply !is null && ply.isMyPlayer())
				{
					Recoil(this, local, 3.2f, 1);

					ShakeScreen(28, 8, this.getPosition());

					makeGibParticle(
					"EmptyShellSmall",               // file name
					this.getPosition(),                 // position
					Vec2f(this.isFacingLeft() ? 2.0f : -2.0f, 0.0f),                           // velocity
					0,                                  // column
					0,                                  // row
					Vec2f(16, 16),                      // frame size
					0.2f,                               // scale?
					0,                                  // ?
					"ShellCasing",                      // sound
					this.get_u8("team_color"));         // team number
				}
			}
		}
	}
}

void ShootArrow(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed, const u8 arrow_type, const bool legolas = true)
{
	if (canSend(this))
	{
		// player or bot
		Vec2f arrowVel = (aimpos - arrowPos);
		arrowVel.Normalize();
		arrowVel *= arrowspeed;
		CBitStream params;
		params.write_Vec2f(arrowPos);
		params.write_Vec2f(arrowVel);

		this.SendCommand(this.getCommandID("shoot arrow"), params);
	}
}

CBlob@ CreateArrow(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel, u8 arrowType)
{
	CBlob@ arrow = server_CreateBlobNoInit("bullet");
	if (arrow !is null)
	{
		// fire arrow?
		arrow.set_u8("arrow type", arrowType);
		arrow.SetDamageOwnerPlayer(this.getPlayer());
		arrow.Init();

		arrow.IgnoreCollisionWhileOverlapped(this);
		arrow.server_setTeamNum(this.getTeamNum());
		arrow.setPosition(arrowPos);
		arrow.setVelocity(arrowVel);
		arrow.getShape().setDrag(arrow.getShape().getDrag() * 0.3f);
		arrow.server_SetTimeToDie(-1);   // override lock
		arrow.server_SetTimeToDie(1.5f);
	}
	return arrow;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot arrow"))
	{
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;

		ArcherInfo@ archer;
		if (!this.get("archerInfo", @archer))
		{
			return;
		}

		if (getNet().isServer())
		{
			CreateArrow(this, arrowPos, arrowVel, ArrowType::normal);
		}

		this.getSprite().PlaySound("Mp5Fire.ogg");
		this.TakeBlob(arrowTypeNames[ ArrowType::normal ], 1);
	}
}

bool canHit(CBlob@ this, CBlob@ b)
{
	if (b.hasTag("invincible"))
		return false;

	// Don't hit temp blobs and items carried by teammates.
	if (b.isAttached())
	{

		CBlob@ carrier = b.getCarriedBlob();

		if (carrier !is null)
			if (carrier.hasTag("player")
			        && (this.getTeamNum() == carrier.getTeamNum() || b.hasTag("temp blob")))
				return false;

	}

	if (b.hasTag("dead"))
		return true;

	return b.getTeamNum() != this.getTeamNum();
}