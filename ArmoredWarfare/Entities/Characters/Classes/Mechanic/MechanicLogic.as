// Mechanic logic

#include "WarfareGlobal.as"
#include "Hitters.as";
#include "HittersAW.as";
#include "MechanicCommon.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "Requirements.as"
#include "BuilderHittable.as";
#include "PlacementCommon.as";
#include "ParticleSparks.as";
#include "MaterialCommon.as";
#include "HoverMessage.as";
#include "PlayerRankInfo.as";
#include "ProgressBar.as";
#include "TeamColorCollections.as";
#include "GlobalInfantryHooks.as";

//can't be <2 - needs one frame less for gathering infos
const s32 hit_frame = 2;
const f32 hit_damage = 0.5f;

void onInit(CBlob@ this)
{
	barInit(this);
	
	this.set_f32("pickaxe_distance", 10.0f);
	this.set_f32("gib health", -1.5f);

	this.set_bool("detaching", false);
	this.set_f32("detach_time", 0);

	this.set_s8(penRatingString, 3);

	this.Tag("player");
	this.Tag("flesh");
	this.Tag("3x2");
	this.set_u32("can_spot", 0);
	this.set_u32("bull_boost", 0);
	this.set_u32("regen", 0);
	this.set_u8("scoreboard_icon", 6);
	this.set_u8("class_icon", 0);

	HitData hitdata;
	this.set("hitdata", hitdata);

	this.addCommandID("pickaxe");
	this.addCommandID("dig_exp");
	this.addCommandID("aos_effects");
	this.addCommandID("levelup_effects");
	this.addCommandID("bootout");
	this.addCommandID("addxp_universal");
	this.addCommandID("attach_parachute");
	this.addCommandID("detach turret");
	this.addCommandID("sync_regen");

	this.set_u32("turret_delay", 0);

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

		if (!player.exists("PerkStats"))
		{
			addPerk(player, 0);
		}

		InitPerk(this, player);
	}
}

void onTick(CBlob@ this)
{
	visualTimerTick(this);

	const bool ismyplayer = this.isMyPlayer();
	CPlayer@ p = this.getPlayer();

	bool stats_loaded = false;
    PerkStats@ stats = getPerkStats(p, stats_loaded);

	ManageParachute(this, stats);

	this.set_bool("has_aos", stats_loaded && this.hasBlob("aceofspades", 1));

	bool lock_stab = false;
	if (this.get_u32("turret_delay") < getGameTime() && this.isKeyPressed(key_action3) && this.isKeyPressed(key_down) && this.isOnGround() && this.getVelocity().Length() <= 1.0f)
	{
		if (this.hasBlob("mat_scrap", 1) && this.getPlayer() !is null && stats.id == Perks::fieldengineer)
		{
			if (getGameTime()%12 == 0 && this.getSprite() !is null)
			{
				this.getSprite().PlaySound("SentryBuild.ogg", 0.33f, 1.05f+0.001f*XORRandom(115));
			}
			lock_stab = true;
			if (this.get_f32("turret_load") < 90)
			{
				this.add_f32("turret_load", 1);
			}
			else
			{
				this.set_f32("turret_load", 0);
				this.set_u32("turret_delay", getGameTime()+150);

				if (isServer())
				{
					this.TakeBlob("mat_scrap", 1);
					CBlob@ turret_exists = getBlobByNetworkID(this.getPlayer().get_u16("turret_netid"));
					if (turret_exists !is null && turret_exists.getName() == "sentrygun")
					{
						this.server_Hit(turret_exists, turret_exists.getPosition(), Vec2f(0,0), 150.0f, HittersAW::bullet, true); 
						//turret_exists.server_Die();
					}
					CBlob@ turret = server_CreateBlob("sentrygun", this.getTeamNum(), this.getPosition());
					if (turret !is null)
					{
						this.getPlayer().set_u16("turret_netid", turret.getNetworkID());
						turret.SetDamageOwnerPlayer(this.getPlayer());
					}
				}
			}
		}
	}
	else if (this.get_f32("turret_load") > 0) this.set_f32("turret_load", 0);

	if (this.get_f32("turret_load") > 0) // build a sentry
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "sentry_build"))
			{
				SColor team_front = getNeonColor(this.getTeamNum(), 0);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "sentry_build", Vec2f(64.0f, 16.0f), false, Vec2f(0, 40), Vec2f(2, 2), back, team_front,
					"turret_load", 90/*sentry buildtime*/, 1.0f, 5, 5, false, "");

    			bars.AddBar(this.getNetworkID(), setbar, true);
			}
		}	
	}
	else if (this.isKeyJustReleased(key_action3) || this.isKeyPressed(key_right) || this.isKeyPressed(key_left) || this.isKeyJustReleased(key_down))
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			bars.RemoveBar("sentry_build", false);
		}
	}

	if (this.get_bool("detaching"))
	{
		this.add_f32("detach_time", 1);

		CBlob@ turret = getBlobByNetworkID(this.get_u16("detaching_id"));
		CBlob@ carry = this.getCarriedBlob();

		if (turret is null || this.getDistanceTo(turret) > 48.0f
			|| carry is null || carry.getName() != "pipewrench")
		{
			this.set_bool("detaching", false);
			this.set_u16("detaching_id", 0);
			this.set_f32("detach_time", 0);
			this.Untag("init_detaching");
			
			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				bars.RemoveBar("detach", false);
			}
		}
	}
	
	// detach secondary weapon from the vehicle
	if (this.hasTag("init_detaching"))
	{
		u16 time = 150;
		if (stats_loaded)
			time = stats.demontage_time;

		this.Untag("init_detaching");
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (!hasBar(bars, "detach"))
			{
				SColor team_front = SColor(255, 133, 133, 160);
				ProgressBar setbar;
				setbar.Set(this.getNetworkID(), "detach", Vec2f(64.0f, 16.0f), false, Vec2f(0, 40), Vec2f(2, 2), back, team_front,
					"detach_time", time, 1.0f, 5, 5, false, "detach turret");

    			bars.AddBar(this.getNetworkID(), setbar, true);
			}
		}	
	}

	if (ismyplayer && getHUD().hasMenus())
	{
		return;
	}

	if (stats_loaded)
	{
		if (!stats.ghillie && this.hasScript("ClimbTree.as")) this.RemoveScript("ClimbTree.as");
		else if (stats.ghillie && !this.hasScript("ClimbTree.as")) this.AddScript("ClimbTree.as");
	}
	
	if (!this.hasTag("set light")
	&& ((this.getTeamNum() == getRules().get_u8("teamleft") && getRules().get_s16("teamLeftTickets") == 0)
	|| (this.getTeamNum() == getRules().get_u8("teamright") && getRules().get_s16("teamRightTickets") == 0)))
	{
		this.Tag("set light");
		this.SetLightRadius(8.0f);
		this.SetLightColor(SColor(255, 255, 255, 255));
		this.SetLight(true);
	}

	// activate/throw
	if (ismyplayer)
	{
		Pickaxe(this);
	}
	
	if (isServer())
	{
		bool stats_loaded = false;
   		PerkStats@ stats = getPerkStats(this, stats_loaded);

		if (stats_loaded)
		{
			if (stats.id == Perks::lucky
			&& this.get_u32("aceofspades_timer") < getGameTime()
			&& !this.get_bool("has_aos"))
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					int xslots = inv.getInventorySlots().x;
					int yslots = inv.getInventorySlots().y;
					CBlob@ item = inv.getItem(xslots * yslots - 1);
					
					//if (item !is null) // theres an item in the last slot
					//{
					//	item.server_RemoveFromInventories();
					//}
					//else //if (!this.hasBlob("aceofspades", 1))  // theres no item in the last slot
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
			if (p !is null)
			{
				float walkStat = 1.1f;
				float airwalkStat = 2.2f;
				float jumpStat = 0.95f;

				bool sprint = (stats_loaded ? stats.sprint : true) && this.getHealth() == this.getInitialHealth() && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);

				// operators move slower than normal
				if (stats_loaded)
				{
					if (stats.id == Perks::bull) sprint = stats.sprint && this.getHealth() >= this.getInitialHealth()*0.5f && this.isOnGround() && !this.isKeyPressed(key_action2) && (this.getVelocity().x > 1.0f || this.getVelocity().x < -1.0f);
					
					walkStat 	*= stats.walk_factor;
					airwalkStat *= stats.walk_factor_air;
					jumpStat 	*= stats.jump_factor;

					if (stats.id == Perks::bull && this.get_u32("bull_boost") != 0 && this.get_u32("bull_boost") > getGameTime())
					{
						walkStat 	*= stats.walk_extra_factor;
						airwalkStat *= stats.walk_extra_factor_air;
						jumpStat 	*= stats.jump_extra_factor;
					}
				}

				if (sprint)
				{
					CBlob@ carried = this.getCarriedBlob();
					if (!this.hasTag("sprinting") && (carried is null || !carried.hasTag("very heavy weight")))
					{
						if (isClient())
						{
							ParticleAnimated("DustSmall.png", this.getPosition()-Vec2f(0, -3.75f), Vec2f(this.isFacingLeft() ? 1.0f : -1.0f, -0.1f), 0.0f, 0.75f, 2, XORRandom(70) * -0.00005f, true);
						}
					}
					this.Tag("sprinting");
				}
				else
				{
					this.Untag("sprinting");
				}

				moveVars.walkFactor *= walkStat;
				moveVars.walkSpeedInAir = airwalkStat;
				moveVars.jumpFactor *= jumpStat;
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

				if ((map.isTileThickStone(type) && XORRandom(6) == 0) || (map.isTileStone(type) && XORRandom(10) == 0)
					|| (map.isTileGold(type) && XORRandom(5) == 0))
				{
					CRules@ rules = getRules();
					CPlayer@ player = this.getPlayer();

					if (player !is null)
					{
						if (isServer())
						{
							// give exp
							int exp_reward = 1;

							CBitStream params;
							params.write_u32(exp_reward);
							this.server_SendCommandToPlayer(this.getCommandID("dig_exp"), params, player);
						}
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
	//else if (cmd == this.getCommandID("attach_parachute"))
	//{
	//	if (isServer())
	//	{
	//		AttachParachute(this);
	//	}
	//}
	else if (cmd == this.getCommandID("addxp_universal"))
	{
		u8 exp_reward;
		if (!params.saferead_u8(exp_reward)) return;
		if (this.getPlayer() !is null)
		{
			add_message(ExpMessage(exp_reward));
			CheckRankUps(getRules(), // do reward coins and sfx
				getRules().get_u32(this.getPlayer().getUsername() + "_exp"), // player new exp
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
	else if (cmd == this.getCommandID("sync_regen")) // Eatable.as, syncs serverside prop to color hp bar in yellow
	{
		if (!isClient()) return;
		u32 regen = params.read_u32();
		this.set_u32("regen", regen);
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
                client_AddToChat("You've been promoted to " + rank + "!", SColor(255, 50, 150, 20));
            }
            else {
                client_AddToChat(player.getCharacterName() + " has been promoted to " + rank + "!", SColor(255, 50, 140, 20));
            }
            
            if (this !is null)
            {
                // create floating rank
                CParticle@ p;
				//printf(""+level);
				@p = ParticleAnimated("Ranks.png", this.getPosition() + Vec2f(0,-14), Vec2f(0,-0.9), 0.0f, 1.0f, 0, level, Vec2f(32, 32), 0, 0, true);
               
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
	else if (cmd == this.getCommandID("detach turret"))
	{
		CBlob@ turret = getBlobByNetworkID(this.get_u16("detaching_id"));
		if (turret is null) return;
		if (this.getDistanceTo(turret) > 48.0f) return;

		if (isServer())
		{
			turret.server_DetachFromAll();
		}

		this.set_bool("detaching", false);
		this.set_u16("detaching_id", 0);
		this.set_f32("detach_time", 0);
		this.Untag("init_detaching");
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

	if (b.isAttached())
	{
		bool exposed = b.hasTag("machinegunner") || b.hasTag("collidewithbullets");
		return exposed;
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
	else if (b.isAttached() && !b.hasTag("player") && !b.hasTag("collidewithbullets") && !b.hasTag("machinegunner"))
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

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("vehicle"))
	{
		this.setVelocity(detached.getVelocity());
	}
	// Deploy parachute!
	if (detached.hasTag("aerial"))
	{
		if (!getMap().rayCastSolid(this.getPosition(), this.getPosition() + Vec2f(0.0f, 150.0f)) && !this.isOnGround() && !this.isInWater() && !this.isAttached())
		{
			bool stats_loaded = false;
    		PerkStats@ stats = getPerkStats(this, stats_loaded);
				
			if (stats_loaded && stats.parachute && (!this.hasTag("parachute") || (isServer() && !isClient())))
			{
				Sound::Play("/ParachuteOpen", detached.getPosition());
				this.Tag("parachute");

				//AttachParachute(this);
			}
		}
	}
	if (detached !is null && getLocalPlayer() !is null && getLocalPlayer().getBlob() is this && (detached.getName() == "binoculars" || detached.getName() == "launcher_javelin"))
	{
		if (!g_fixedcamera && this.get_bool("disable_fixedcamera"))
		{
			this.set_bool("disable_fixedcamera", false);
			g_fixedcamera = true;
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

void onRender(CSprite@ this)
{
	visualTimerRender(this);
}