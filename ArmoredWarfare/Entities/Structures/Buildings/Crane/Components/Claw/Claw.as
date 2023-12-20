#include "Hitters.as";
#include "MaterialCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("grab");
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

	if (this.get_u16("grabbed_id") != 0)
	{
		CBlob@ blob = getBlobByNetworkID(this.get_u16("grabbed_id"));
		if (blob is null || blob.getDistanceTo(this) > max_tension)
		{
			this.set_u16("grabbed_id", 0);
		}

		if (blob !is null)
		{
			Vec2f dir = blob.getPosition() - this.getPosition();
			Vec2f normDir = dir;
			normDir.Normalize();

			blob.setVelocity(blob.getVelocity() * (dir.Length() > max_tension/4 ? 1.0f : dir.Length()/max_tension));
			
			f32 mass = blob.getMass();
			f32 heavymass_factor = mass / 1000 * 0.2f;
			blob.AddForce(-normDir * (mass * Maths::Max(0.1f, (1.0f-heavymass_factor))));
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
	if (crane_was_hit)
	{
		this.Untag("crane_was_hit");
		this.set_u16("grabbed_id", 0);
	}
	if (active && this.get_u32("grab_delay") < getGameTime())
	{
		CBlob@[] bs;
		getMap().getBlobsInRadius(this.getPosition(), 8.0f, @bs);
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
		}
	}
	//this.setAngleDegrees(this.get_f32("angle"));
}

bool canGrab(CBlob@ this, CBlob@ blob)
{
	if ((blob.getTeamNum() != this.getTeamNum() && !blob.hasTag("material")) || blob.hasTag("aerial") || blob.hasTag("structure")
		|| (blob.getShape() !is null && blob.getShape().isStatic()) || blob.hasTag("projectile")
		|| blob.isAttached() || blob.isInInventory())
	{
		return false;
	}

	if (blob.hasTag("flesh") || blob.hasTag("vehicle")
		|| blob.hasTag("material") || blob.hasTag("trap"))
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
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isServer())
	{
		if (hitterBlob !is null && hitterBlob.getTeamNum() != this.getTeamNum())
		{
			this.set_u16("grabbed_id", 0);
		}
	}
	return damage;
}