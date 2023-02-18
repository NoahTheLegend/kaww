#include "Hitters.as"
#include "GenericButtonCommon.as"

const u32 VANISH_BODY_SECS = 45;
const f32 CARRIED_BLOB_VEL_SCALE = 1.0;
const f32 MEDIUM_CARRIED_BLOB_VEL_SCALE = 0.8;
const f32 HEAVY_CARRIED_BLOB_VEL_SCALE = 0.6;

void onInit(CBlob@ this)
{
	this.push("names to activate", "grenade");

	this.set_f32("hit dmg modifier", 0.0f);
	this.getCurrentScript().tickFrequency = 0; // make it not run ticks until dead
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// hitmarker sfx & sending hitmarker to cursor
	if (hitterBlob is null) return damage;

	if (hitterBlob.getDamageOwnerPlayer() !is null)
	{
		CBlob@ damageowner = hitterBlob.getDamageOwnerPlayer().getBlob();
		if (damageowner !is null && damageowner.getPlayer() !is null)
		{
			if (damageowner.getSprite() !is null && !this.hasTag("dead") && customData != Hitters::spikes && this !is hitterBlob && getLocalPlayer() !is null && getLocalPlayer().getTeamNum() != this.getTeamNum())
			{ 
				if (hitterBlob.getPosition().y < this.getPosition().y - 3.2f && !hitterBlob.hasTag("flesh"))
				{
					Sound::Play("HitmarkerHeadshot.ogg", damageowner.getPosition(), 0.8f, 0.75f + (20 - (this.getHealth()/this.getInitialHealth())*20) * 0.01f);
					//damageowner.set_u8("hitmarker", 30); // is actually 10
				}
				else
				{
					Sound::Play("Hitmarker.ogg", damageowner.getPosition(), 0.8f, 0.75f + ((60 - (this.getHealth()/this.getInitialHealth())*60) * 0.01f) + XORRandom(5)*0.01f);
					//damageowner.set_u8("hitmarker", 7); // is actually 7
				}
			}

			// player is using bloodthirsty, heal him/her  (this is a commentary on how the gender spectrum is nonexistent)
			if (getRules().get_string(damageowner.getPlayer().getUsername() + "_perk") == "Bloodthirsty")
			{
				damageowner.server_Heal(0.03f); //microscopic amount
			}
			//damage is always 0 here idk why
		}
	}

	if (damage > 0.05f)
	{
		makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                0, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}
	if (damage > 0.05f)
	{
		makeGibParticle("GenericGibs", worldPoint, getRandomVelocity((this.getPosition() - worldPoint).getAngle(), 1.0f + damage, 90.0f) + Vec2f(0.0f, -2.0f),
		                0, 4 + XORRandom(4), Vec2f(8, 8), 2.0f, 0, "", 0);
	}

	// make dead state
	// make sure this script is at the end of onHit scripts for it gets the final health
	if (this.getHealth() <= 0.0f && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.set_u32("death time", getGameTime());

		this.UnsetMinimapVars(); //remove minimap icon

		// we want the corpse to stay but player to respawn so we force a die event in rules
		if (getNet().isServer())
		{
			if (this.getPlayer() !is null)
			{
				getRules().server_PlayerDie(this.getPlayer());
				this.server_SetPlayer(null);
			}
			else
			{
				getRules().server_BlobDie(this);
			}
		}

		// add pickup attachment so we can pickup body
		CAttachment@ a = this.getAttachments();

		if (a !is null)
		{
			AttachmentPoint@ ap = a.AddAttachmentPoint("PICKUP", false);
		}

		// sound
		if (this.getSprite() !is null) //moved here to prevent other logic potentially not getting run
		{
			f32 gibHealth = this.get_f32("gib health");

			if (this !is hitterBlob || customData == Hitters::fall)
			{
				if (this.isInWater())
				{
					if (this.getHealth() > gibHealth)
					{
						this.getSprite().PlaySound("Gurgle");
					}
				}
				else
				{
					Sound::Play("PlayerDie.ogg", this.getPosition());

					if (XORRandom(100) < 30)
					{
						this.getSprite().PlaySound("WilhelmYell.ogg", this.getSexNum() == 0 ? 1.0f : 1.5f);
					}
					else if (this.getHealth() > gibHealth / 2.0f)
					{
						this.getSprite().PlaySound("WilhelmShort.ogg", this.getSexNum() == 0 ? 1.0f : 1.5f);
					}
					else if (this.getHealth() > gibHealth)
					{
						this.getSprite().PlaySound("Wilhelm.ogg", 1.0f, this.getSexNum() == 0 ? 1.0f : 1.5f);
					}

					for (uint i = 0; i < 3; ++i)
					{
						ParticleBloodSplat(worldPoint + getRandomVelocity(0, 0.75f + i * 1.0f * XORRandom(5), 360.0f), true);
					}

				}
			}

			// turn off bow sound (emit sound)
			this.getSprite().SetEmitSoundPaused(true);
		}

		this.getCurrentScript().tickFrequency = 30;

		this.set_f32("hit dmg modifier", 0.5f);

		// new physics vars so bodies don't slide
		this.getShape().setFriction(0.75f);
		this.getShape().setElasticity(0.2f);

		// disable tags
		this.Untag("player");
		this.getShape().getVars().isladder = false;
		this.getShape().getVars().onladder = false;
		this.getShape().checkCollisionsAgain = true;
		this.getShape().SetGravityScale(1.0f);
		//set velocity to blob in hand
        CBlob@ carried = this.getCarriedBlob();
        if (carried !is null)
        {
            Vec2f current_vel = this.getVelocity() * CARRIED_BLOB_VEL_SCALE;
            if (carried.hasTag("medium weight"))
                current_vel = current_vel * MEDIUM_CARRIED_BLOB_VEL_SCALE;
            else if (carried.hasTag("heavy weight"))
                current_vel = current_vel * HEAVY_CARRIED_BLOB_VEL_SCALE;
            //the item is detatched from the player before setting the velocity
            //otherwise it wont go anywhere
            this.server_DetachFrom(carried);
            carried.setVelocity(current_vel);
        }
        // fall out of attachments/seats // drop all held things
		this.server_DetachAll();

		StuffFallsOut(this);
	}
	else
	{
		this.set_u32("death time", getGameTime());
	}

	return damage;
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	// can't be put in player inventory.
	return inventoryBlob.getPlayer() is null;
}

void onDie(CBlob@ this)
{
	if (this.getPlayer() !is null) this.getPlayer().set_string("last_class", this.getName());
	if (isServer() && XORRandom(4)==0 && this.get_string("equipment_head") != "" && !this.hasTag("switch class"))
	{
		CBlob@ helmet = server_CreateBlob(this.get_string("equipment_head"), 2, this.getPosition());	
	}
}

void onTick(CBlob@ this)
{
	if (this.getSprite() is null) return;
	if (this.getName() != "sniper")
	{
		CSpriteLayer@ camo = this.getSprite().getSpriteLayer("camo");
		if (camo is null)
		{
			if (this.hasScript("ClimbTree.as")) this.RemoveScript("ClimbTree.as");
		}
		else if (!this.hasScript("ClimbTree.as")) this.AddScript("ClimbTree.as");
	}

	// (drop anything attached)
	CBlob @carried = this.getCarriedBlob();
	if (carried !is null)
	{
		carried.server_DetachFromAll();
	}

	//die if we've "expired"
	if (this.get_u32("death time") + VANISH_BODY_SECS * getTicksASecond() < getGameTime())
	{
		this.server_Die();
	}
}

// reset vanish counter on pickup
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (this.hasTag("dead"))
	{
		this.set_u32("death time", getGameTime());
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (this.hasTag("dead") && this.getInventory().getItemsCount() > 0 && canSeeButtons(this, forBlob));
}

void StuffFallsOut(CBlob@ this)
{
	if (!getNet().isServer())
		return;

	CInventory@ inv = this.getInventory();
	while (inv !is null && inv.getItemsCount() > 0)
	{
		CBlob @blob = inv.getItem(0);
		this.server_PutOutInventory(blob);
		blob.setVelocity(this.getVelocity() + getRandomVelocity(90, 4.0f, 40));
	}
}