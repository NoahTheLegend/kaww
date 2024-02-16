// a script to combine builder's and infantry's logic files in here (where possible)
#include "InfantryCommon.as";
#include "WarfareGlobal.as";
#include "AllHashCodes.as";
#include "KnockedCommon.as";
#include "PerksCommon.as";

const f32 shield_angle = 60;
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible") && customData != Hitters::suicide) return 0; // spawn immunity, doesnt work against suicide hitter

	if (this.exists("ignore_damage") && this.get_u32("ignore_damage") > getGameTime()) return 0;
	CPlayer@ p = this.getPlayer();

	bool coalition_power = this.getTeamNum() == 6 && getRules().get_bool("enable_powers"); // team 6 buff
	f32 extra_amount = 0.95f;
	if (coalition_power)
	{
		damage *= extra_amount;
	}

	bool exposed = this.hasTag("machinegunner") || this.hasTag("collidewithbullets");
	bool mg_attached = false;
	if (exposed)
	{
		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
		mg_attached = ap !is null && ap.getOccupied() !is null && ap.getOccupied().isAttached();
	}
	bool hiding = this.get_u8("mg_hidelevel") > getGameTime();

	s8 pen = hitterBlob.get_s8("pen_level");

	bool stats_loaded = false;
    PerkStats@ stats = getPerkStats(this, stats_loaded);

	const bool explosion_damage = customData == Hitters::explosion || customData == Hitters::keg || customData == Hitters::mine;
	const bool fire_damage = customData == Hitters::fire || customData == Hitters::burn;

	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet);
	
	{
		InfantryInfo@ infantry;
		if (this.get("infantryInfo", @infantry))
		{
			this.set_u32("accuracy_delay", getGameTime()+ACCURACY_HIT_DELAY);
			f32 cap = this.get_u8("inaccuracy")+infantry.inaccuracy_hit;
			if (cap < infantry.inaccuracy_cap) this.add_u8("inaccuracy", infantry.inaccuracy_hit);
			else this.set_u8("inaccuracy", infantry.inaccuracy_cap);
		}
	}

	if (this.hasTag("is_shielder")
		&& (is_bullet || explosion_damage || customData == Hitters::sword))
	{
		bool isReloading = this.get_bool("isReloading") || this.get_s32("my_reloadtime") > 0;

		if (!isReloading && this.isKeyPressed(key_action3))
		{
			Vec2f mpos = this.getAimPos();
			f32 angle = (this.isFacingLeft()?-(mpos-this.getPosition()).Angle()+180:(mpos-this.getPosition()).Angle());
			f32 hit_angle = (this.isFacingLeft()?-(worldPoint-this.getPosition()).Angle()+180:(worldPoint-this.getPosition()).Angle());

			f32 diff = angle - hit_angle;
			diff += diff > 180 ? -360 : diff < -180 ? 360 : 0;

			bool block = Maths::Abs(diff) < shield_angle;
			//printf("angle "+angle+" hit angle "+hit_angle+" diff "+diff);
			if (block)
			{
				if (explosion_damage ? hitterBlob.getDistanceTo(this) < 32.0f+XORRandom(81)*0.1f : damage >= 1.5f)
				{
					setKnocked(this, 15);
					damage /= (1.75f + XORRandom(21)*0.1f);
				}
				else if (isServer())
				{
					CBitStream params;
					bool has_hit = (is_bullet || customData == Hitters::sword);
					params.write_bool(has_hit);
					this.SendCommand(this.getCommandID("shield_effects"), params);

					damage /= (1.75f + XORRandom(21)*0.1f);
				}
			}
		}
	}

	if (this.isAttached())
	{
		if (fire_damage)
		{
			damage *= (exposed ? 0.5f : 0.0f);
		}
		else if (explosion_damage || hitterBlob.getName() == "ballistabolt")
		{
			//printf("explosion");
			//printf(""+damage * (exposed && !mg_attached ? 0.2f : hiding ? 0.01f : 0.025f));
			damage *= ((exposed && !mg_attached) ? 0.25f : ((!exposed || hiding) ? 0.01f : 0.0175f));
		}
		else if (is_bullet)
		{
			//printf("bullet");
			damage *= 0.5f;
		}
		else if (customData == Hitters::sword)
		{
			//printf("sword");
			damage *= (exposed ? 0.5f : 0);
		}
	}

	if (stats_loaded)
	{
		if (this.getPlayer() !is null)
		{
			if (fire_damage)
			{
				damage *= stats.fire_in_damage;
			}

			if (stats.id == Perks::paratrooper
			&& this.getVelocity().y > 0.0f && !this.isOnGround() && !this.isOnLadder()
			&& !this.isInWater() && !this.isAttached())
			{
				damage *= stats.para_damage_take_mod;
			}
		}

		if (stats.id == Perks::paratrooper
			this.getHealth() - damage/2 <= 0 && this.getHealth() > 0.01f)
		{
			CPlayer@ p = this.getPlayer();
			PerkStats@ stats;
			if (p !is null && p.get("PerkStats", @stats) && stats.id == Perks::lucky && this.get_bool("has_aos"))
			{
				this.TakeBlob("aceofspades", 1);
				this.set_u32("aceofspades_timer", getGameTime()+stats.aos_taken_time);
				this.set_u32("ignore_damage", getGameTime()+stats.aos_invulnerability_time);

				this.server_SetHealth(0.01f);

				if (this.getPlayer() !is null)
				{
					CBitStream params;
					this.SendCommand(this.getCommandID("aos_effects"), params);
				}

				return 0;
			}
		}

		if (stats.id == Perks::bull && !is_bullet)
		{
			damage *= stats.damage_take_mod;
		}
		else if (stats.id == Perks::deathincarnate)
		{
			damage *= stats.damage_take_mod;
		}
	}
	if (!this.isAttached() && customData == Hitters::ballista) // shell damage
	{
		damage *= 2;
	}
	if ((!this.isAttached() || exposed) && (explosion_damage || hitterBlob.getName() == "ballista_bolt") // common explosion checks & bunker protection
		|| hitterBlob.hasTag("grenade") || hitterBlob.getName() == "c4")
	{
		if (hitterBlob.hasTag("grenade")) damage *= 5.0f+(XORRandom(301)*0.01f);
		if (hitterBlob.getName() == "c4") damage *= 10;
		if (hitterBlob.get_u16("follow_id") == this.getNetworkID()) damage *= 5.0f;
		if (damage == 0.005f || damage == 0.01f) damage = 1.75f+(XORRandom(25)*0.01f); // someone broke damage
		if (hitterBlob.exists("explosion_damage_scale")) damage *= hitterBlob.get_f32("explosion_damage_scale");
		
		if (hitterBlob.getName() == "mat_smallbomb")
		{
			damage *= 10;
		}

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
					if (hi.getTeamNum() != this.getTeamNum()) continue;
					if (hi.hasTag("bunker") || hi.hasTag("tank")) 
					{
						at_bunker = true;
						break;
					}
				}
			}
			if (at_bunker) return 0;
		}

		u16 dist_blocks = Maths::Floor((pos-hitterBlob.get_Vec2f("from_pos")).Length()/8);
		// printf(""+dist_blocks);
		f32 mod = 0.5f;
		damage = damage * Maths::Min(mod, Maths::Max(0.05f, mod - (0.025f * (dist_blocks))));
		//printf(""+damage+" dist "+dist_blocks);
	}

	return damage;
}

//void AttachParachute(CBlob@ this)
//{
//	if (isServer() && this.getTickSinceCreated() > 5)
//	{
//		CAttachment@ aps = this.getAttachments();
//		if (aps !is null)
//		{			
//			AttachmentPoint@ att = aps.getAttachmentPointByName("PARACHUTE");
//			CBlob@ para = server_CreateBlob("parachuteblob", this.getTeamNum(), this.getPosition());
//			if (para !is null)
//			{
//				this.server_AttachTo(para, att);
//			}
//		}
//	}
//}


void ManageParachute(CBlob@ this, PerkStats@ stats)
{
	if (this.isOnGround() || this.isInWater() || this.isAttached() || this.isOnLadder() || this.hasTag("dead"))
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
		// disable parachute
		//if (isServer())
		//{
		//	CAttachment@ aps = this.getAttachments();
		//	if (aps !is null)
		//	{
		//		AttachmentPoint@ ap = aps.getAttachmentPointByName("PARACHUTE");
		//		if (ap !is null && ap.getOccupied() !is null)
		//		{
		//			CBlob@ para = ap.getOccupied();
		//			para.server_Die();
		//		}
		//	}
		//}
	if (this.hasTag("parachute")) // parachute logic
	{
		bool is_infantry = this.hasTag("infantry");
		CBlob@ carry = this.getCarriedBlob();
		bool has_heavy = carry !is null && (carry.hasTag("weapon") || carry.hasTag("heal"));
		
		if (this.isMyPlayer() && getGameTime()%30==0)
		{
			CAttachment@ aps = this.getAttachments();
			if (aps !is null)
			{
				AttachmentPoint@ ap = aps.getAttachmentPointByName("PARACHUTE");
				if (ap !is null && ap.getOccupied() is null)
				{
					CBitStream params;
					this.SendCommand(this.getCommandID("attach_parachute"), params);
				}
			}
		}

		f32 mod = is_infantry ? 4.0f : 1.0f;
		bool is_paratrooper = false;
		if (this.getPlayer() !is null)
		{
			if (this.hasTag("parachute") && stats !is null && stats.id == Perks::paratrooper)
			{
				mod *= 10.0f;
				is_paratrooper = true;
			}
		}

		this.AddForce(Vec2f(Maths::Sin(f32(getGameTime()) / 9.5f) * 13.0f,
			(Maths::Sin(f32(getGameTime() / 4.2f)) * 8.0f)));

		Vec2f vel = this.getVelocity();
		if (is_paratrooper)
		{
			if (this.isKeyPressed(key_left))
				this.AddForce(Vec2f(-1.0f, 0));
			else if (this.isKeyPressed(key_right))
				this.AddForce(Vec2f(1.0f, 0));
		}

		f32 mod_y = (has_heavy ? 0.85f : (this.isKeyPressed(key_down) ? 0.83f : this.isKeyPressed(key_up) ? 0.25f / mod : 0.5f/*default fall speed*/));

		this.setVelocity(Vec2f(vel.x + (is_infantry ? (this.isKeyPressed(key_left) ? -0.25f : this.isKeyPressed(key_right) ?
			0.25f : 0) : 0), vel.y * mod_y));
	}
	// make a parachute
	else
	{
		if (this.getPlayer() !is null && this.get_u32("last_parachute") < getGameTime())
		{
			if (stats !is null && stats.id == Perks::paratrooper)
			{
				if (this.isKeyPressed(key_up) && this.getVelocity().y > 5.0f)
				{
					if (isClient())
					{
						Sound::Play("/ParachuteOpen", this.getPosition());
						this.set_u32("last_parachute", getGameTime()+60);
						this.Tag("parachute");

						//CBitStream params;
						//this.SendCommand(this.getCommandID("attach_parachute"), params);
					}
				}
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (isServer())
	{
		if (attached !is null && attached.hasTag("change team on pickup"))
		{
			attached.server_setTeamNum(this.getTeamNum());
		}
	}
	if (attached !is null && getLocalPlayer() !is null && getLocalPlayer().getBlob() is this && (attached.getName() == "binoculars" || attached.getName() == "launcher_javelin"))
	{
		if (g_fixedcamera)
		{
			this.set_bool("disable_fixedcamera", true);
			g_fixedcamera = false;
		}
	}
}

bool canStab(CBlob@ this)
{
	return (!this.hasTag("is_shielder") && !this.hasTag("is_mp5"));
}

void InitPerk(CBlob@ this, CPlayer@ player)
{
	// perk commands
	// initialize for everyone to prevent unexpected behavior
	this.addCommandID("mason_open_menu");
	this.addCommandID("mason_select");
	this.addCommandID("mason_place_structure");
	this.addCommandID("mason_place_block");
	this.addCommandID("mason_place_block_client");

	this.set_s32("selected_structure", -1);

   	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	
	PerkStats@ stats;
	if (player !is null && player.get("PerkStats", @stats) && stats.id == Perks::mason)
	{
   		if (player.isMyPlayer() || isServer())
   		{
   		    this.AddScript("MasonPerkLogic.as");
   		    sprite.AddScript("MasonPerkGUI.as");

			this.set_u32("place_structure_delay", 0);
            this.set_s32("selected_structure", -1);
            this.set_u32("selected_structure_time", 0);
            this.set_Vec2f("building_structure_pos", Vec2f(-1,-1));
            this.set_f32("build_pitch", 0);
   		}
	}
}