// Slave logic

#include "WarfareGlobal.as"
#include "Hitters.as";
#include "SlaveCommon.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "Requirements.as"
#include "BuilderHittable.as";
#include "PlacementCommon.as";
#include "ParticleSparks.as";
#include "MaterialCommon.as";
#include "HoverMessage.as";
#include "PlayerRankInfo.as";

//can't be <2 - needs one frame less for gathering infos
const s32 hit_frame = 2;
const f32 hit_damage = 0.5f;

void onInit(CBlob@ this)
{
	this.set_f32("pickaxe_distance", 10.0f);
	this.set_f32("gib health", -1.5f);

	this.set_s8(penRatingString, 3);

	this.Tag("player");
	this.Tag("flesh");
	this.Tag("3x2");
	this.set_u32("can_spot", 0);

	HitData hitdata;
	this.set("hitdata", hitdata);

	this.addCommandID("pickaxe");
	this.addCommandID("dig_exp");
	this.addCommandID("aos_effects");
	this.addCommandID("levelup_effects");
	this.addCommandID("bootout");

	CShape@ shape = this.getShape();
	shape.SetRotationsAllowed(false);
	shape.getConsts().net_threshold_multiplier = 0.5f;

	this.set_Vec2f("inventory offset", Vec2f(0.0f, 160.0f));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 1, Vec2f(16, 16));
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CPlayer@ p = this.getPlayer();
	if (p !is null)
	{
		if (getRules().get_string(p.getUsername() + "_perk") == "Lucky" && this.getHealth() <= 0.01f && !this.hasBlob("aceofspades", 1)) return 0;
	}
	if (isServer()) //update bots' logic
	{
		if (this.hasTag("disguised"))
		{
			this.set_u32("can_spot", getGameTime()+150); // reveal us for some time
		}
	}
	if (hitterBlob.getName() == "mat_smallbomb")
	{
		damage *= 4;
	}
	if (this.isAttached())
	{
		if (customData == Hitters::explosion)
			return damage*0.04f;
		else if (customData == Hitters::arrow)
			return damage*0.5f;
		else return 0;
	}
	if (this.getPlayer() !is null && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Camouflage")
	{
		if (customData == Hitters::fire)
		{
			return damage * 2;
		}
	}
	if (damage > 0.15f && this.getHealth() - damage/2 <= 0 && this.getHealth() > 0.01f)
	{
		if (this.hasBlob("aceofspades", 1))
		{
			this.TakeBlob("aceofspades", 1);
			this.set_u32("aceofspades_timer", getGameTime()+30);

			this.server_SetHealth(0.01f);

			if (this.getPlayer() !is null)
			{
				CBitStream params;
				this.SendCommand(this.getCommandID("aos_effects"), params);
			}

			return damage = 0;
		}
	}
	if (this.getPlayer() !is null)
	{
		if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Death Incarnate")
		{
			damage *= 2.0f; // take double damage
		}
	}
	if ((customData == Hitters::explosion || hitterBlob.getName() == "ballista_bolt") && hitterBlob.getName() != "grenade")
	{
		bool at_bunker = false;
		Vec2f pos = this.getPosition();
		Vec2f hit_pos = hitterBlob.getPosition();

		CBlob@[] bunkers;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @bunkers);

		if (!getMap().rayCastSolidNoBlobs(pos, hit_pos))
		{
			HitInfo@[] infos;
			Vec2f hitvec = hit_pos - pos;

			if (getMap().getHitInfosFromRay(pos, -hitvec.Angle(), hitvec.getLength(), this, @infos))
			{
				for (u16 i = 0; i < infos.length; i++)
				{
					CBlob@ hi = infos[i].blob;
					if (hi is null) continue;
					if (hi.hasTag("bunker") || hi.hasTag("tank")) 
					{
						at_bunker = true;
						break;
					}
				}
			}
			if (at_bunker) return 0;
			return damage * 0.1f;
		}
	}

	return damage;
}

void onTick(CBlob@ this)
{
	if (this.isInInventory())
		return;

	const bool ismyplayer = this.isMyPlayer();
	ManageParachute(this);

	if (ismyplayer && getHUD().hasMenus())
	{
		return;
	}
	
	if ((this.getTeamNum() == 0 && getRules().get_s16("blueTickets") == 0)
	|| (this.getTeamNum() == 1 && getRules().get_s16("redTickets") == 0))
	{
		this.SetLightRadius(8.0f);
		this.SetLightColor(SColor(255, 255, 255, 255));
		this.SetLight(true);
	}

	// activate/throw
	if (ismyplayer)
	{
		Pickaxe(this);
	}

	CPlayer@ p = this.getPlayer();
	if (isServer())
	{
		if (p !is null)
		{
			if (!this.hasBlob("aceofspades", 1)
			&& this.get_u32("aceofspades_timer") < getGameTime()
			&& getRules().get_string(p.getUsername() + "_perk") == "Lucky")
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					int xslots = inv.getInventorySlots().x;
					int yslots = inv.getInventorySlots().y;
					CBlob@ item = inv.getItem(xslots * yslots - 1);
					
					if (item !is null) // theres an item in the last slot
					{
						item.server_RemoveFromInventories();
					}
					else //if (!this.hasBlob("aceofspades", 1))  // theres no item in the last slot
					{
						// give ace
						CBlob@ b = server_CreateBlob("aceofspades", -1, this.getPosition());
						if (b !is null) this.server_PutInInventory(b);
					}
				}
			}
		}
	}

	// slow down walking
	if (this.isKeyPressed(key_action2))
	{
		RunnerMoveVars@ moveVars;
		if (this.get("moveVars", @moveVars))
		{
			moveVars.walkFactor = 0.5f;
			moveVars.jumpFactor = 0.5f;
		}
		this.Tag("prevent crouch");
	}
	else
	{
		RunnerMoveVars@ moveVars;
		if (this.get("moveVars", @moveVars))
		{
			if (this.getPlayer() !is null && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Bull")
			{
				bool sprint = this.getHealth() >= this.getInitialHealth()/2 && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
				
				if (sprint) moveVars.walkFactor *= 1.1f;
				moveVars.walkFactor *= 1.1f;
				moveVars.walkSpeedInAir = 2.0f;
				moveVars.jumpFactor *= 1.2f;
			}
			else  if (this.getPlayer() !is null)
			{
				moveVars.walkFactor *= this.getPlayer().hasTag("Conditioning") ? 1.1f : 1.0f;
				moveVars.jumpFactor *= this.getPlayer().hasTag("Conditioning") ? 1.1f : 1.0f;
			}
		}
	}

	if (ismyplayer && this.isKeyPressed(key_action1) && !this.isKeyPressed(key_inventory)) //Don't let the builder place blocks if he/she is selecting which one to place
	{
		BlockCursor @bc;
		this.get("blockCursor", @bc);

		HitData@ hitdata;
		this.get("hitdata", @hitdata);
		hitdata.blobID = 0;
		hitdata.tilepos = bc.buildable ? bc.tileAimPos : Vec2f(-8, -8);
	}

	// get rid of the built item
	if (this.isKeyJustPressed(key_inventory) || this.isKeyJustPressed(key_pickup))
	{
		this.set_u8("buildblob", 255);
		this.set_TileType("buildtile", 0);

		CBlob@ blob = this.getCarriedBlob();
		if (blob !is null && blob.hasTag("temp blob"))
		{
			blob.Untag("temp blob");
			blob.server_Die();
		}
	}
}

void SendHitCommand(CBlob@ this, CBlob@ blob, const Vec2f tilepos, const Vec2f attackVel, const f32 attack_power)
{
	CBitStream params;
	params.write_netid(blob is null? 0 : blob.getNetworkID());
	params.write_Vec2f(tilepos);
	params.write_Vec2f(attackVel);
	params.write_f32(attack_power);

	this.SendCommand(this.getCommandID("pickaxe"), params);
}

bool RecdHitCommand(CBlob@ this, CBitStream@ params)
{
	u16 blobID;
	Vec2f tilepos, attackVel;
	f32 attack_power;

	if (!params.saferead_netid(blobID))
		return false;
	if (!params.saferead_Vec2f(tilepos))
		return false;
	if (!params.saferead_Vec2f(attackVel))
		return false;
	if (!params.saferead_f32(attack_power))
		return false;

	if (blobID == 0)
	{
		CMap@ map = getMap();
		if (map !is null)
		{
			if (map.getSectorAtPosition(tilepos, "no build") is null)
			{
				uint16 type = map.getTile(tilepos).type;

				if (getNet().isServer())
				{
					map.server_DestroyTile(tilepos, 1.0f, this);

					Material::fromTile(this, type, 1.0f);
				}

				if (getNet().isClient())
				{
					if (map.isTileBedrock(type))
					{
						this.getSprite().PlaySound("/metal_stone.ogg");
						sparks(tilepos, attackVel.Angle(), 1.0f);
					}
				}

				if ((map.isTileThickStone(type) && XORRandom(6) == 0) or (map.isTileStone(type) && XORRandom(10) == 0) or (map.isTileGold(type) && XORRandom(5) == 0))
				{
					CRules@ rules = getRules();
					CPlayer@ player = this.getPlayer();

					if (player !is null)
					{
						if (isServer())
						{
							// give exp
							int exp_reward = 1;
							//if (rules.get_string(player.getUsername() + "_perk") == "Death Incarnate")
							//{
							//	exp_reward *= 3;
							//}
							CBitStream params;
							params.write_u32(exp_reward);
							this.server_SendCommandToPlayer(this.getCommandID("dig_exp"), params, player);
							//rules.add_u32(player.getUsername() + "_exp", exp_reward);
							//rules.Sync(player.getUsername() + "_exp", true);
						}
									// sometimes makes a null blob not found error! test this future me
					}
				}
			}
		}
	}
	else
	{
		CBlob@ blob = getBlobByNetworkID(blobID);
		if (blob !is null)
		{
			bool isdead = blob.hasTag("dead");

			if (isdead) //double damage to corpses
			{
				attack_power *= 2.0f;
			}

			const bool teamHurt = !blob.hasTag("flesh") || isdead;

			if (getNet().isServer())
			{
				this.server_Hit(blob, tilepos, attackVel, attack_power, Hitters::builder, teamHurt);

				Material::fromBlob(this, blob, attack_power);
			}
		}
	}

	return true;
}

CBlob@ CreateProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	CBlob@ proj = server_CreateBlobNoInit("bullet");
	if (proj !is null)
	{
		proj.SetDamageOwnerPlayer(this.getPlayer());
		proj.Init();

		proj.set_f32("bullet_damage_body", damage_body);
		proj.set_f32("bullet_damage_head", damage_head);
		proj.IgnoreCollisionWhileOverlapped(this);
		proj.server_setTeamNum(this.getTeamNum());
		proj.setPosition(arrowPos);
		proj.setVelocity(arrowVel);
		proj.setPosition(arrowPos);
	}
	return proj;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pickaxe"))
	{
		if (!RecdHitCommand(this, params))
		{
			warn("error when recieving pickaxe command");
		}
	}
	else if (cmd == this.getCommandID("dig_exp"))
	{
		CRules@ rules = getRules();
		u32 exp_reward;
		if (!params.saferead_u32(exp_reward)) return;

		add_message(ExpMessage(exp_reward));

		if (this.getPlayer() !is null)
		{
			rules.add_u32(this.getPlayer().getUsername() + "_exp", exp_reward);
			CheckRankUps(rules, // do reward coins and sfx
				rules.get_u32(this.getPlayer().getUsername() + "_exp"), // player new exp
				this);	
		}
	}
	else if (cmd == this.getCommandID("aos_effects"))
	{
		if (this.isMyPlayer()) // are we on server?
		{
			this.getSprite().PlaySound("FatesFriend.ogg", 1.2);
			SetScreenFlash(42,   255,   150,   150,   0.28);
		}
		else
		{
			this.getSprite().PlaySound("FatesFriend.ogg", 2.0);
		}
	}
	else if (cmd == this.getCommandID("levelup_effects"))
	{
		u8 level;
		if (!params.saferead_u8(level)) return;
		string rank;
		if (!params.saferead_string(rank)) return;

		CRules@ rules = getRules();
		CPlayer@ player = this.getPlayer();
		if (player is null) return;
		// flash screen
        if (player.isMyPlayer())
        {
            SetScreenFlash(30,   255,   255,   255,   2.3);
        }
        
        // play sound
        if (isClient()) this.getSprite().PlaySound("LevelUp", 1.6f, 1.0f);
        if (isServer())
        {
            // coins
            server_DropCoins(this.getPosition(), 50);
        }

        //if (isServer()) //client
        {
            // chat message
            if (player.isMyPlayer()) {
                client_AddToChat("You've been promoted to " + rank.toLower() + "!", SColor(255, 50, 150, 20));
            }
            else {
                client_AddToChat(player.getCharacterName() + " has been promoted to " + rank.toLower() + "!", SColor(255, 50, 140, 20));
            }
            
            if (this !is null)
            {
                // create floating rank
                CParticle@ p = ParticleAnimated("Ranks", this.getPosition() + Vec2f(8.5f,-14), Vec2f(0,-0.9), 0.0f, 1.0f, 0, level - 1, Vec2f(32, 32), 0, 0, true);
                if(p !is null)
                {
                    p.collides = false;
                    p.Z = 1000;
                    p.timeout = 2; // this shit doesnt work
                }

                // create particle
                ParticleAnimated("LevelUpParticle", this.getPosition(), this.getVelocity() - Vec2f(0,1.2), 0.0f, 1.0f, 3, 0.2f, true);
            }
        }
        
        // adjust to the current level
        rules.set_string(player.getUsername() + "_last_lvlup", rank);
	}
	else if (cmd == this.getCommandID("bootout"))
	{
		if (isClient()) this.getSprite().PlaySound("bridge_open", 1.0f, 1.25f);
		if (isServer()) this.server_DetachFromAll();
	}
}

//helper class to reduce function definition cancer
//and allow passing primitives &inout
class SortHitsParams
{
	Vec2f aimPos;
	Vec2f tilepos;
	Vec2f pos;
	bool justCheck;
	bool extra;
	bool hasHit;
	HitInfo@ bestinfo;
	f32 bestDistance;
};

void Pickaxe(CBlob@ this)
{
	HitData@ hitdata;
	CSprite @sprite = this.getSprite();
	bool strikeAnim = sprite.isAnimation("strike");

	if (!strikeAnim)
	{
		this.get("hitdata", @hitdata);
		hitdata.blobID = 0;
		hitdata.tilepos = Vec2f_zero;
		return;
	}

	// no damage cause we just check hit for cursor display
	bool justCheck = !sprite.isFrameIndex(hit_frame);
	bool adjusttime = sprite.getFrameIndex() < hit_frame - 1;

	// pickaxe!

	this.get("hitdata", @hitdata);

	if (hitdata is null) return;

	Vec2f blobPos = this.getPosition();
	Vec2f aimPos = this.getAimPos();
	Vec2f aimDir = aimPos - blobPos;

	// get tile surface for aiming at little static blobs
	Vec2f normal = aimDir;
	normal.Normalize();

	Vec2f attackVel = normal;

	if (!adjusttime)
	{
		if (!justCheck)
		{
			if (hitdata.blobID == 0)
			{
				SendHitCommand(this, null, hitdata.tilepos, attackVel, hit_damage);
			}
			else
			{
				CBlob@ b = getBlobByNetworkID(hitdata.blobID);
				if (b !is null)
				{
					SendHitCommand(this, b, (b.getPosition() + this.getPosition()) * 0.5f, attackVel, hit_damage);
				}
			}
		}
		return;
	}

	hitdata.blobID = 0;
	hitdata.tilepos = Vec2f_zero;

	f32 arcdegrees = 90.0f;

	f32 aimangle = aimDir.Angle();
	Vec2f pos = blobPos - Vec2f(2, 0).RotateBy(-aimangle);
	f32 attack_distance = this.getRadius() + this.get_f32("pickaxe_distance");
	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;

	bool hasHit = false;

	const f32 tile_attack_distance = attack_distance * 1.5f;
	Vec2f tilepos = blobPos + normal * Maths::Min(aimDir.Length() - 1, tile_attack_distance);
	Vec2f surfacepos;
	map.rayCastSolid(blobPos, tilepos, surfacepos);

	Vec2f surfaceoff = (tilepos - surfacepos);
	f32 surfacedist = surfaceoff.Normalize();
	tilepos = (surfacepos + (surfaceoff * (map.tilesize * 0.5f)));

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@ bestinfo = null;
	f32 bestDistance = 100000.0f;

	HitInfo@[] hitInfos;

	//setup params for ferrying data in/out
	SortHitsParams@ hit_p = SortHitsParams();

	//copy in
	hit_p.aimPos = aimPos;
	hit_p.tilepos = tilepos;
	hit_p.pos = pos;
	hit_p.justCheck = justCheck;
	hit_p.extra = true;
	hit_p.hasHit = hasHit;
	@(hit_p.bestinfo) = bestinfo;
	hit_p.bestDistance = bestDistance;

	if (map.getHitInfosFromArc(pos, -aimangle, arcdegrees, attack_distance, this, @hitInfos))
	{
		SortHits(this, hitInfos, hit_damage, hit_p);
	}

	aimPos = hit_p.aimPos;
	tilepos = hit_p.tilepos;
	pos = hit_p.pos;
	justCheck = hit_p.justCheck;
	hasHit = hit_p.hasHit;
	@bestinfo = hit_p.bestinfo;
	bestDistance = hit_p.bestDistance;

	bool noBuildZone = map.getSectorAtPosition(tilepos, "no build") !is null;
	bool isgrass = false;

	if ((tilepos - aimPos).Length() < bestDistance - 4.0f && map.getBlobAtPosition(tilepos) is null)
	{
		Tile tile = map.getTile(surfacepos);

		if (!noBuildZone && !map.isTileGroundBack(tile.type))
		{
			//normal, honest to god tile
			if (map.isTileBackgroundNonEmpty(tile) || map.isTileSolid(tile))
			{
				hasHit = true;
				hitdata.tilepos = tilepos;
			}
			else if (map.isTileGrass(tile.type))
			{
				//NOT hashit - check last for grass
				isgrass = true;
			}
		}
	}

	if (!hasHit)
	{
		//copy in
		hit_p.aimPos = aimPos;
		hit_p.tilepos = tilepos;
		hit_p.pos = pos;
		hit_p.justCheck = justCheck;
		hit_p.extra = false;
		hit_p.hasHit = hasHit;
		@(hit_p.bestinfo) = bestinfo;
		hit_p.bestDistance = bestDistance;

		//try to find another possible one
		if (bestinfo is null)
		{
			SortHits(this, hitInfos, hit_damage, hit_p);
		}

		//copy out
		aimPos = hit_p.aimPos;
		tilepos = hit_p.tilepos;
		pos = hit_p.pos;
		justCheck = hit_p.justCheck;
		hasHit = hit_p.hasHit;
		@bestinfo = hit_p.bestinfo;
		bestDistance = hit_p.bestDistance;

		//did we find one (or have one from before?)
		if (bestinfo !is null)
		{
			hitdata.blobID = bestinfo.blob.getNetworkID();
		}
	}

	if (isgrass && bestinfo is null)
	{
		hitdata.tilepos = tilepos;
	}
}

void SortHits(CBlob@ this, HitInfo@[]@ hitInfos, f32 damage, SortHitsParams@ p)
{
	//HitInfo objects are sorted, first come closest hits
	for (uint i = 0; i < hitInfos.length; i++)
	{
		HitInfo@ hi = hitInfos[i];

		CBlob@ b = hi.blob;
		if (b !is null) // blob
		{
			if (!canHit(this, b, p.tilepos, p.extra))
			{
				continue;
			}

			if (!p.justCheck && isUrgent(this, b))
			{
				p.hasHit = true;
				SendHitCommand(this, hi.blob, hi.hitpos, hi.blob.getPosition() - p.pos, damage);
			}
			else
			{
				bool never_ambig = neverHitAmbiguous(b);
				f32 len = never_ambig ? 1000.0f : (p.aimPos - b.getPosition()).Length();
				if (len < p.bestDistance)
				{
					if (!never_ambig)
						p.bestDistance = len;

					@(p.bestinfo) = hi;
				}
			}
		}
	}
}

bool ExtraQualifiers(CBlob@ this, CBlob@ b, Vec2f tpos)
{
	//urgent stuff gets a pass here
	if (isUrgent(this, b))
		return true;

	//check facing - can't hit stuff we're facing away from
	f32 dx = (this.getPosition().x - b.getPosition().x) * (this.isFacingLeft() ? 1 : -1);
	if (dx < 0)
		return false;

	//only hit static blobs if aiming directly at them
	CShape@ bshape = b.getShape();
	if (bshape.isStatic())
	{
		bool bigenough = bshape.getWidth() >= 8 &&
		                 bshape.getHeight() >= 8;

		if (bigenough)
		{
			if (!b.isPointInside(this.getAimPos()) && !b.isPointInside(tpos))
				return false;
		}
		else
		{
			Vec2f bpos = b.getPosition();
			//get centered on the tile it's positioned on (for offset blobs like spikes)
			Vec2f tileCenterPos = Vec2f(s32(bpos.x / 8), s32(bpos.y / 8)) * 8 + Vec2f(4, 4);
			f32 dist = Maths::Min((tileCenterPos - this.getAimPos()).LengthSquared(),
			                      (tileCenterPos - tpos).LengthSquared());
			if (dist > 25) //>5*5
				return false;
		}
	}

	return true;
}

bool neverHitAmbiguous(CBlob@ b)
{
	string name = b.getName();
	return name == "saw";
}

bool canHit(CBlob@ this, CBlob@ b, Vec2f tpos, bool extra = true)
{
	if (extra && !ExtraQualifiers(this, b, tpos))
	{
		return false;
	}

	if (b.hasTag("invincible"))
	{
		return false;
	}

	if (b.getTeamNum() == this.getTeamNum())
	{
		//no hitting friendly carried stuff
		if (b.isAttached())
			return false;

		//yes hitting corpses
		if (b.hasTag("dead"))
			return true;

		//no hitting friendly mines (grif)
		if (b.getName() == "mine")
			return false;

		//no hitting friendly living stuff
		if (b.hasTag("flesh") || b.hasTag("player"))
			return false;
	}
	//no hitting stuff in hands
	else if (b.isAttached() && !b.hasTag("player"))
	{
		return false;
	}

	//static/background stuff
	CShape@ b_shape = b.getShape();
	if (!b.isCollidable() || (b_shape !is null && b_shape.isStatic()))
	{
		//maybe we shouldn't hit this..
		//check if we should always hit
		if (BuilderAlwaysHit(b))
		{
			if (!b.isCollidable() && !isUrgent(this, b))
			{
				//TODO: use a better overlap check here
				//this causes issues with quarters and
				//any other case where you "stop overlapping"
				if (!this.isOverlapping(b))
					return false;
			}
			return true;
		}
		//otherwise no hit
		return false;
	}

	return true;
}

void ManageParachute( CBlob@ this )
{
	if (this.isOnGround() || this.isInWater() || this.isAttached() || this.isOnLadder())
	{
		if (this.hasTag("parachute"))
		{
			for (uint i = 0; i < 50; i ++)
			{
				Vec2f vel = getRandomVelocity(90.0f, 3.5f + (XORRandom(10) / 10.0f), 25.0f) + Vec2f(0, 2);
				ParticlePixel(this.getPosition() - Vec2f(0, 30) + getRandomVelocity(90.0f, 10 + (XORRandom(20) / 10.0f), 25.0f), vel, getTeamColor(this.getTeamNum()), true, 119);
			}
		}
		this.Untag("parachute");
	}
	else if (!this.hasTag("parachute"))
	{
		if (this.getPlayer() !is null && this.get_u32("last_parachute") < getGameTime())
		{
			if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
			{
				if (this.isKeyPressed(key_up) && this.getVelocity().y > 8.0f)
				{
					Sound::Play("/ParachuteOpen", this.getPosition());
					this.set_u32("last_parachute", getGameTime()+45);
					this.Tag("parachute");
				}
			}
		}
	}
	
	if (this.hasTag("parachute"))
	{
		this.set_u32("no_climb", getGameTime()+2);
		this.AddForce(Vec2f(Maths::Sin(getGameTime() / 9.5f) * 13, (Maths::Sin(getGameTime() / 4.2f) * 8)));
		this.setVelocity(Vec2f(this.getVelocity().x, this.getVelocity().y * (this.isKeyPressed(key_down) ? 0.83f : this.isKeyPressed(key_up) ? 0.55f : 0.73)));
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	// Deploy parachute!
	if (detached.hasTag("aerial"))
	{
		if (!getMap().rayCastSolid(this.getPosition(), this.getPosition() + Vec2f(0.0f, 150.0f)) && !this.isOnGround() && !this.isInWater() && !this.isAttached())
		{
			if (!this.hasTag("parachute"))
			{
				Sound::Play("/ParachuteOpen", detached.getPosition());
				this.Tag("parachute");
			}
		}
	}
	// ignore collision for built blob
	BuildBlock[][]@ blocks;
	if (!this.get("blocks", @blocks))
	{
		return;
	}

	const u8 PAGE = this.get_u8("build page");
	for(u8 i = 0; i < blocks[PAGE].length; i++)
	{
		BuildBlock@ block = blocks[PAGE][i];
		if (block !is null && block.name == detached.getName())
		{
			this.IgnoreCollisionWhileOverlapped(null);
			detached.IgnoreCollisionWhileOverlapped(null);
		}
	}

	// BUILD BLOB
	// take requirements from blob that is built and play sound
	// put out another one of the same
	if (detached.hasTag("temp blob"))
	{
		if (!detached.hasTag("temp blob placed"))
		{
			detached.server_Die();
			return;
		}

		uint i = this.get_u8("buildblob");
		if (i >= 0 && i < blocks[PAGE].length)
		{
			BuildBlock@ b = blocks[PAGE][i];
			if (b.name == detached.getName())
			{
				this.set_u8("buildblob", 255);
				this.set_TileType("buildtile", 0);

				CInventory@ inv = this.getInventory();

				CBitStream missing;
				if (hasRequirements(inv, b.reqs, missing, not b.buildOnGround))
				{
					server_TakeRequirements(inv, b.reqs);
				}
				// take out another one if in inventory
				server_BuildBlob(this, blocks[PAGE], i);
			}
		}
	}
	else if (detached.getName() == "seed")
	{
		if (not detached.hasTag('temp blob placed')) return;

		CBlob@ anotherBlob = this.getInventory().getItem(detached.getName());
		if (anotherBlob !is null)
		{
			this.server_Pickup(anotherBlob);
		}
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	// destroy built blob if somehow they got into inventory
	if (blob.hasTag("temp blob"))
	{
		blob.server_Die();
		blob.Untag("temp blob");
	}
}