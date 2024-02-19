#include "Hitters.as";
#include "MaterialCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("grab");
	this.addCommandID("ungrab");

	this.Tag("rotary_joint");
	this.set_u32("grab_delay", 0);
}

const u8 grab_delay = 10;
f32 max_tension = 32.0f;

void onTick(CBlob@ this)
{
	bool active = this.hasTag("active");
	bool attached = this.hasTag("attached");
	bool crane_was_hit = this.hasTag("crane_was_hit");

	if (!attached) return;

	Vec2f pos = this.getPosition();
	Vec2f oldpos = this.get_Vec2f("oldpos");
	Vec2f vel = pos-oldpos;
	this.set_Vec2f("oldpos", pos);

	if (this.get_u16("grabbed_id") != 0)
	{
		CBlob@ blob = getBlobByNetworkID(this.get_u16("grabbed_id"));
		if (blob is null || blob.getDistanceTo(this) > max_tension)
		{
			this.set_u16("grabbed_id", 0);
		}

		if (blob !is null)
		{
			Vec2f dir = blob.getPosition() - pos;
			Vec2f normDir = dir;
			normDir.Normalize();
			
			f32 mass = blob.getMass();
			f32 heavymass_factor = mass / 1000 * 0.2f;
			f32 pull_force = (mass * Maths::Max(0.1f, (1.0f-heavymass_factor)));

			if (mass < 1000 && !blob.hasTag("aerial"))
			{
				blob.setPosition(pos);
				blob.setVelocity(vel);
				blob.AddForce(-normDir * pull_force);
			}
			else
			{
				blob.setVelocity(blob.getVelocity() * (dir.Length() > max_tension/4 ? 1.0f : dir.Length()/max_tension));
				blob.AddForce(-normDir * pull_force);
			}
		}
	}

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		
		if (sprite.animation !is null)
			sprite.animation.frame = this.get_u16("grabbed_id") != 0 ? 1 : 0;

		sprite.SetRelativeZ(attached ? -55.0f : 0.0f);
	}

	if (!isServer()) return;
	if (crane_was_hit || (!attached && this.get_u16("grabbed_id") != 0))
	{
		this.Untag("crane_was_hit");
		this.set_u16("grabbed_id", 0);
		this.SendCommand(this.getCommandID("ungrab"));
	}
	if (active && this.get_u32("grab_delay") < getGameTime())
	{
		CBlob@[] bs;
		getMap().getBlobsAtPosition(pos+Vec2f(-6,0).RotateBy(this.getAngleDegrees()), @bs);
		bool ungrab = true;

		if (this.get_u16("grabbed_id") == 0)
		{
			for (u8 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null || b is this) continue;
				if (canGrab(this, b))
				{
					CBitStream params;
					params.write_u16(b.getNetworkID());
					this.SendCommand(this.getCommandID("grab"), params);

					this.set_u32("grab_delay", getGameTime()+grab_delay);
					ungrab = false;

					break;
				}
			}
		}

		if (ungrab)
		{
			this.set_u16("grabbed_id", 0);
			this.set_u32("grab_delay", getGameTime()+grab_delay);
			this.SendCommand(this.getCommandID("ungrab"));
		}
	}
	//this.setAngleDegrees(this.get_f32("angle"));
}

bool canGrab(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("structure") // dont grab strucute/aerial blobs
		|| (blob.getShape() !is null && blob.getShape().isStatic()) || blob.hasTag("projectile") // dont grab static or projectiles
		|| blob.isAttached() || blob.isInInventory() || blob.hasTag("attached")) // dont grab attached or from inventories
	{
		return false;
	}

	if (blob.hasTag("flesh") || blob.hasTag("vehicle")
		|| blob.hasTag("material") || blob.hasTag("trap")
		|| blob.hasTag("vehicle")  || blob.hasTag("machinegun") || blob.hasTag("weapon")
		|| blob.hasTag("material") || blob.hasTag("trap") 		|| blob.hasTag("flesh"))
	{
		return true;
	}

	return false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("grab"))
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ b = getBlobByNetworkID(id);
		if (b is null) return;

		if (isClient())
		{
			this.getSprite().PlaySound("throw.ogg", 1.5f, 0.6f + XORRandom(31)*0.01f);
		}

		this.set_u16("grabbed_id", id);
	}
	else if (cmd == this.getCommandID("ungrab"))
	{
		if (!isClient()) return;
		this.set_u16("grabbed_id", 0);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isServer())
	{
		if (hitterBlob !is null && hitterBlob.getTeamNum() != this.getTeamNum())
		{
			this.set_u16("grabbed_id", 0);
			this.SendCommand(this.getCommandID("ungrab"));
		}
	}
	return damage;
}