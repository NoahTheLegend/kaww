// a script to combine builder's and infantry's logic files in here (where possible)
#include "InfantryCommon.as";
#include "WarfareGlobal.as";
#include "AllHashCodes.as";
#include "KnockedCommon.as";

const f32 shield_angle = 60;
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	bool coalition_power = this.getTeamNum() == 6 && getRules().get_bool("enable_powers"); // team 6 buff
	f32 extra_amount = 0.95f;
	if (coalition_power)
	{
		damage *= extra_amount;
	}

	s8 pen = hitterBlob.get_s8("pen_level");

	bool is_bullet = (customData == HittersAW::bullet || customData == HittersAW::heavybullet
		|| customData == HittersAW::machinegunbullet || customData == HittersAW::aircraftbullet);
	
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

	if (this.getName() == "shielder"
		&& (is_bullet || customData == Hitters::explosion
			|| customData == Hitters::keg || customData == Hitters::sword))
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
				if ((customData == Hitters::explosion || customData == Hitters::keg) ? hitterBlob.getDistanceTo(this) < 32.0f+XORRandom(81)*0.1f : damage >= 1.5f)
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

	CPlayer@ p = this.getPlayer();
	if (p !is null)
	{
		if (getRules().get_string(p.getUsername() + "_perk") == "Lucky" && this.getHealth() <= 0.01f && !this.hasBlob("aceofspades", 1)) return 0;
	}
	if (hitterBlob.getName() == "mat_smallbomb")
	{
		damage *= 4;
	}
	if (this.isAttached())
	{
		if (customData == Hitters::explosion)
			return damage*0.04f;
		else if (is_bullet)
			return damage*0.5f;
		else return (customData == Hitters::sword && (this.hasTag("mgunner") || this.hasTag("collidewithbullets"))
			? damage*0.5f : 0);
	}
	if (this.getPlayer() !is null)
	{
		if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Camouflage")
		{
			if (customData == Hitters::fire)
			{
				return damage * 2;
			}
		}
		else if (this.getVelocity().y > 0.0f && !this.isOnGround() && !this.isOnLadder()
		&& !this.isInWater() && !this.isAttached()
		&& getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
		{
			damage *= 0.5f;
		}
		else if (!is_bullet && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Bull")
		{
			damage *= 0.66f;
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
	if (customData != Hitters::explosion && hitterBlob.getName() == "ballista_bolt")
	{
		return (pen > 2 ? damage*2 : damage/2);
	}
	if ((customData == Hitters::explosion || hitterBlob.getName() == "ballista_bolt") || hitterBlob.hasTag("grenade"))
	{
		if (hitterBlob.hasTag("grenade")) damage *= 5.0f+(XORRandom(301)*0.01f);
		if (hitterBlob.get_u16("follow_id") == this.getNetworkID()) return damage*5.0f;
		if (damage == 0.005f || damage == 0.01f) damage = 1.75f+(XORRandom(25)*0.01f); // someone broke damage
		if (hitterBlob.exists("explosion_damage_scale")) damage *= hitterBlob.get_f32("explosion_damage_scale");
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

void AttachParachute(CBlob@ this)
{
	if (isServer() && this.getTickSinceCreated() > 5)
	{
		CAttachment@ aps = this.getAttachments();
		if (aps !is null)
		{			
			AttachmentPoint@ att = aps.getAttachmentPointByName("PARACHUTE");
			CBlob@ para = server_CreateBlob("parachuteblob", this.getTeamNum(), this.getPosition());
			if (para !is null)
			{
				this.server_AttachTo(para, att);
			}
		}
	}
}


void ManageParachute(CBlob@ this)
{
	if (this.hasTag("parachute"))
	{
		// disable parachute
		if (this.isOnGround() || this.isInWater() || this.isAttached() || this.isOnLadder() || this.hasTag("dead"))
		{
			for (uint i = 0; i < 50; i ++)
			{
				Vec2f vel = getRandomVelocity(90.0f, 3.5f + (XORRandom(10) / 10.0f), 25.0f) + Vec2f(0, 2);
				ParticlePixel(this.getPosition() - Vec2f(0, 30) + getRandomVelocity(90.0f, 10 + (XORRandom(20) / 10.0f), 25.0f), vel, getTeamColor(this.getTeamNum()), true, 119);
			}
			this.Untag("parachute");

			if (isServer())
			{
				CAttachment@ aps = this.getAttachments();
				if (aps !is null)
				{
					AttachmentPoint@ ap = aps.getAttachmentPointByName("PARACHUTE");
					if (ap !is null && ap.getOccupied() !is null)
					{
						CBlob@ para = ap.getOccupied();
						para.server_Die();
					}
				}
			}
		}
		else // parachute logic
		{
			// hack, builder blob acts different under player controls
			// current case is that parachute floats slower to left or right for infantry
			// offtop: also builder saves momentum onDetach()
			// if you know how to fix pls help
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
				if (this.hasTag("parachute") && getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
				{
					mod *= 10.0f;
					is_paratrooper = true;
				}
			}
			// huge hack =(
			if (is_infantry) this.AddForce(Vec2f(Maths::Sin(f32(getGameTime()) / 13.0f) * 30.0f,
				(Maths::Sin(f32(getGameTime() / 4.2f)) * 8.0f)));
			else  this.AddForce(Vec2f(Maths::Sin(f32(getGameTime()) / 9.5f) * 13.0f,
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
	} // make a parachute
	else if (!this.hasTag("parachute"))
	{
		if (this.getPlayer() !is null && this.get_u32("last_parachute") < getGameTime())
		{
			if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Paratrooper")
			{
				if (this.isKeyPressed(key_up) && this.getVelocity().y > 5.0f)
				{
					if (isClient())
					{
						Sound::Play("/ParachuteOpen", this.getPosition());
						this.set_u32("last_parachute", getGameTime()+60);
						this.Tag("parachute");

						CBitStream params;
						this.SendCommand(this.getCommandID("attach_parachute"), params);
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
