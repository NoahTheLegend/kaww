#include "Hitters.as";
#include "MaterialCommon.as";

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	this.set_s8("dir", this.getNetworkID()%2==0?-1:1);

	sprite.SetEmitSound("buzzsaw_loop.ogg");
	sprite.SetEmitSoundVolume(2.0f);
	sprite.SetEmitSoundSpeed(1.0f);

	this.set_bool("was_active", false);
	this.set_u32("delay_startsound", 0);
	this.set_u16("speed", 0);
}

const u8 hit_rate = 5;
const u16 max_speed = 100;

void onTick(CBlob@ this)
{
	bool active = this.hasTag("active");
	bool attached = this.hasTag("attached");

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		sprite.SetRelativeZ(attached ? -55.0f : 0.0f);

		if (!this.get_bool("was_active") && active && this.get_u32("delay_startsound") < getGameTime())
		{
			sprite.PlaySound(this.getName()+"_start.ogg", 5.0f, 1.25f);
			this.set_u32("delay_startsound", getGameTime()+30);
		}
		this.set_bool("was_active", active);

		u16 speed = this.get_u16("speed");

		if (active)
		{
			if (speed < max_speed) speed += 5;
		}
		else
		{
			if (speed > 2) speed -= 2;
			else speed = 0;
		}

		sprite.RotateBy(this.get_s8("dir") * speed/3, Vec2f(0,0));
		sprite.SetEmitSoundPaused(speed == 0);
		sprite.SetEmitSoundSpeed(2.0f*((f32(speed)+Maths::Sin(getGameTime()*0.5f)*4)/max_speed));
		sprite.SetEmitSoundVolume(2.0f*(f32(speed)/max_speed));

		this.set_u16("speed", speed);
	}

	if (!isServer()) return;
	if (active && (getGameTime()+this.getNetworkID())%hit_rate==0)
	{
		CBlob@[] hit;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @hit);

		for (u16 i = 0; i < hit.size(); i++)
		{
			CBlob@ blob = hit[i];
			if (blob is null || blob.getTeamNum() == this.getTeamNum()) continue;

			if (blob.hasTag("wooden"))
			{
				this.server_Hit(blob, this.getPosition(), Vec2f(0, 0.01f), 0.5f, Hitters::builder, true);
				Material::fromBlob(this, blob, 0.5f);
			}
			else if (blob.hasTag("flesh"))
			{
				this.server_Hit(blob, this.getPosition(), Vec2f(0, 0.01f), 0.5f, Hitters::sword, true);
			}
			else if (blob.hasTag("weak vehicle") || blob.hasTag("truck"))
			{
				this.server_Hit(blob, this.getPosition(), Vec2f(0, 0.01f), 1.0f, Hitters::builder, true);
			}
		}
	}
}