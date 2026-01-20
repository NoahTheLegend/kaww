#include "ParticleSparks.as";
#include "UtilityChecks.as";

const u16 duration = 10 * 30;
const f32 radius = 128.0f;

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.getShape().SetRotationsAllowed(true);

	this.addCommandID("sync");
	this.set_u8("bombs_remaining", 7 + XORRandom(3));
	this.set_u8("max_bombs", this.get_u8("bombs_remaining"));

	if (isClient())
	{
		CBitStream params;
		params.write_bool(false);
		params.write_u16(getLocalPlayer().getNetworkID());
		this.SendCommand(this.getCommandID("sync"), params);
	}

	this.getCurrentScript().tickFrequency = 1;
	this.getAttachments().getAttachmentPointByName("PICKUP").SetKeysToTake(key_action3);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.hasTag("activated")) return;

	s32 timer = blob.get_s32("timer") - getGameTime();
	if (!blob.hasTag("extinguished"))
	{
		blob.SetLight(true);
		blob.SetLightRadius((radius+XORRandom(16)) * (Maths::Max(0,timer)/(getGameTime()+duration))+16.0f);
		blob.SetLightColor(SColor(255, 200+XORRandom(55), 25, 25));
	}
	else blob.SetLight(false);

	if (timer < 0)
	{
		if (this.animation.name != "end")
		{
			this.PlaySound("ExtinguishFire.ogg", 1.0f, 0.85f);
		}
		
		this.SetAnimation("end");
		this.SetEmitSoundPaused(true);
		
		return;
	}
	else
	{
		this.SetEmitSoundSpeed(1.0f+XORRandom(51)*0.001f);
		this.SetAnimation("activate");
	}
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (isServer() && ap !is null && ap.isKeyJustPressed(key_action3) && !this.hasTag("activated"))
	{
		// send activated
		CBitStream params;
		this.SendCommand(this.getCommandID("activate"), params);
	}

	if (!this.hasTag("activated") || this.hasTag("extinguished")) return;

	s32 timer = this.get_s32("timer") - getGameTime();
	if (timer < 0)
	{
		this.server_SetTimeToDie(15.0f);
		this.setInventoryName("Red Flare (extinguished)");
		this.Tag("extinguished");
	}

	f32 vel = this.getVelocity().x;
	if (vel > 1.0f)
	{
		this.set_bool("left_to_right", true);
	}
	else if (vel < -1.0f)
	{
		this.set_bool("left_to_right", false);
	}

	u8 bombs_remaining = this.get_u8("bombs_remaining");
	if (isServer() && bombs_remaining > 0 && timer <= 90 + this.getNetworkID() % 90 && getGameTime() % 5 == 0)
	{
		this.add_u8("bombs_remaining", -1);
		u8 max = this.get_u8("max_bombs");

		f32 factor = 1.0f - f32(bombs_remaining) / f32(max);
		f32 space = 48.0f;
		
		f32 y = -128.0f;
		f32 height = this.getPosition().y - y;

		s8 fl = this.get_bool("left_to_right") ? 1 : -1;
		f32 center = this.getPosition().x + (fl == 1 ? -max / 2 * space - space * 2 : max / 2 * space + space * 2);

		Vec2f vel = Vec2f(fl * 2.0f, 0);
		f32 vel_offset = -vel.x * 2;

		f32 x = center + bombs_remaining * space * fl + vel_offset;
		Vec2f spawn_pos = Vec2f(x, y);

		CBlob@ bomb = server_CreateBlob("mat_smallbomb", this.getTeamNum(), spawn_pos);
		if (bomb !is null)
		{
			bomb.setVelocity(vel);
			bomb.setAngleDegrees(0);
			bomb.server_SetQuantity(1);
			bomb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

			bomb.Tag("change rotation");
			bomb.Tag("remove_shrapnel");
		}
	}

	if (isClient())
	{
		this.getSprite().SetEmitSoundVolume(0.75f);

		bool has_gravity = false; // todo
		MakeParticle(this, Vec2f(0, !has_gravity ? 0.0f - (XORRandom(11) + 10) * 0.1f : 0), "RedFlareFire"+XORRandom(2));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		this.Tag("activated");
		this.set_s32("timer", getGameTime() + duration);

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.SetEmitSound("FlareLoop.ogg");
				sprite.SetEmitSoundVolume(1.25f);
				sprite.SetEmitSoundPaused(false);

				sprite.PlaySound("FlareStart.ogg", 3.0f, 0.9f);
			}
		}
	}
	else if (cmd == this.getCommandID("sync"))
	{
		bool truesync = params.read_bool();
		u16 ply_id = params.read_u16();
		
		CPlayer@ ply = getPlayerByNetworkId(ply_id);
		if (!truesync && isServer() && ply !is null) // init
		{
			if (this.hasTag("activated"))
			{
				CBitStream nextparams;
				nextparams.write_bool(true);
				nextparams.write_u16(ply_id);
				nextparams.write_s32(this.get_s32("timer"));
				this.server_SendCommandToPlayer(this.getCommandID("sync"), nextparams, ply);
			}
		}
		if (truesync && isClient())
		{
			s32 timer = params.read_s32();
			this.set_s32("timer", timer);

			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.SetEmitSound("FlareLoop.ogg");
				sprite.SetEmitSoundVolume(0.5f);
				sprite.SetEmitSoundPaused(false);
			}
		}
	}
}

void MakeParticle(CBlob@ this, Vec2f vel, string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(0, -4).RotateBy(this.getAngleDegrees());
	CParticle@ p = ParticleAnimated("LargeSmoke", this.getPosition(), vel + Vec2f(this.getNetworkID() % 10, 0) * 0.1f, float(XORRandom(360)), 1.0f, 3 + XORRandom(3), 0, false);
	if (p !is null)
	{
		p.deadeffect = -1;
		p.timeout = XORRandom(30) + 30;
		p.collides = true;
		p.diesoncollide = false;
		p.diesonanimate = false;
		p.setRenderStyle(RenderStyle::additive);

		SColor col = SColor(255, 200+XORRandom(55), 25, 25);
		p.colour = col;
		p.forcecolor = col;
	}
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return !this.hasTag("activated");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ ap)
{
	this.setAngleDegrees(0);
	this.getShape().SetRotationsAllowed(false);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ ap)
{
	this.getShape().SetRotationsAllowed(true);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("trap")) return false;
	if (blob.hasTag("destructable"))
	{
		return true;
	}
	if (blob.hasTag("structure") && (!blob.hasTag("bunker") || blob.getName() == "sandbags" || blob.getTeamNum() == this.getTeamNum()))
	{
		return false;
	}
	if (blob.hasTag("flesh"))
	{
		return false;
	}
	return (!blob.hasTag("vehicle") && blob.isCollidable());
}