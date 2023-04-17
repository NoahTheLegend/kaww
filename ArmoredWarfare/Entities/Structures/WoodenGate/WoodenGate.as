// Swing Door logic

#include "Hitters.as"
#include "FireCommon.as"
#include "DoorCommon.as"
#include "CustomBlocks.as";
#include "AllHashCodes.as"

void onInit(CBlob@ this)
{
	this.addCommandID("static on");
	this.addCommandID("static off");

	this.getShape().SetRotationsAllowed(false);
	this.getSprite().getConsts().accurateLighting = true;
	
	this.Tag("place norotate");
	this.Tag("door");
	this.Tag("blocks water");
	this.Tag("builder always hit");
	this.Tag("friendly_collide");
	this.set_bool("state", true);
	
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ lever = sprite.addSpriteLayer("lever", "WoodenGate.png", 16, 16);
	if (lever !is null)
	{
		sprite.SetRelativeZ(-100.0f);
		lever.SetRelativeZ(-99.0f);
		lever.SetOffset(this.isFacingLeft() ? Vec2f(-12.0f, 12.0f) : Vec2f(12.0f, 12.0f));
		//lever.SetVisible(false);
		Animation@ anim = lever.addAnimation("active", 3, false);
		if (anim !is null)
		{
			anim.AddFrame(3);
			anim.AddFrame(7);
			anim.AddFrame(11);
			anim.AddFrame(7);
			anim.AddFrame(3);
			lever.SetAnimation(anim);
		}
		lever.SetFrameIndex(0);
	}

	bool ss = this.get_bool("state");
	if (ss)
	{
		sprite.SetZ(-100.0f);
		sprite.SetAnimation("open");
		this.getShape().getConsts().collidable = false;
		this.getCurrentScript().tickFrequency = 3;
	}

	this.addCommandID("set_state");
	this.addCommandID("sync_state");
	server_Sync(this);
}

void server_Sync(CBlob@ this)
{
	if (isServer())
	{
		CBitStream stream;
		stream.write_bool(this.get_bool("state"));
		
		this.SendCommand(this.getCommandID("sync_state"), stream);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("set_state"))
	{
		bool state = params.read_bool();
		this.set_bool("state", !state);
		this.getSprite().PlaySound(state ? "DoorOpen.ogg" : "DoorClose.ogg", 1.5f, 0.85f);
		setOpen(this, !state);

		this.set_u8("delay", 10);

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				CSpriteLayer@ lever = sprite.getSpriteLayer("lever");
				if (lever !is null)
				{
					lever.SetFrameIndex(0); // activates the animation i guess
					lever.SetAnimation("active");
				}
			}
		}
	}
	else if (cmd == this.getCommandID("sync_state"))
	{
		if (isClient())
		{
			bool ss = params.read_bool();
			
			this.set_bool("state", ss);
		}
	}
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;
	
	Vec2f pos = this.getPosition();
	u32 ang = u32(this.getAngleDegrees() / 90.00f) % 2;
	
	CMap@ map = this.getMap();

	for (int i = 0; i < 5; i++)
	{
		if (ang == 0) map.server_SetTile(Vec2f(pos.x, (pos.y - 16) + i * 8), CMap::tile_wood_back);
		else map.server_SetTile(Vec2f((pos.x - 16) + i * 8, pos.y), CMap::tile_wood_back);
	}
	
	this.getSprite().PlaySound("/build_door.ogg");
}

bool isOpen(CBlob@ this)
{
	return !this.getShape().getConsts().collidable;
}

void setOpen(CBlob@ this, bool open)
{
	CSprite@ sprite = this.getSprite();
	if (open)
	{
		sprite.SetZ(-100.0f);
		sprite.SetAnimation("open");
		this.getShape().getConsts().collidable = false;
		
		this.getSprite().PlaySound("/DoorOpen.ogg", 1.00f, 1.00f);
		// this.getSprite().PlaySound("/Blastdoor_Open.ogg", 1.00f, 1.00f);
	}
	else
	{
		sprite.SetZ(100.0f);
		sprite.SetAnimation("close");
		this.getShape().getConsts().collidable = true;
		Sound::Play("/DoorClose.ogg", this.getPosition(), 1.00f, 0.80f);
	}
	
	const uint count = this.getTouchingCount();
	uint collided = 0;
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.isCollidable())
		{
			blob.AddForce(Vec2f(0, 0)); // Hack to awake sleeping blobs' physics
		}
	}
}
/*
void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_bool(this.get_bool("state"));

	if (this is null || caller is null) return;
	if (this.getDistanceTo(caller) > 96.0f
	|| (this.isFacingLeft() ? this.getPosition().x > caller.getPosition().x : this.getPosition().x < caller.getPosition().x)) return;

	CButton@ button = caller.CreateGenericButton(8, Vec2f(-4, 0), this, this.getCommandID("set_state"), !this.get_bool("state") ? "Open gate" : "Close gate", params);
	if (button !is null)
	{
		button.SetEnabled(this.getDistanceTo(caller) < 48.0f);
	}
}
*/
bool canClose(CBlob@ this)
{
	const uint count = this.getTouchingCount();
	uint collided = 0;
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.isCollidable())
		{
			collided++;
		}
	}
	return collided == 0;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onTick(CBlob@ this)
{
	CBlob@[] overlapping;
	this.getOverlapping(@overlapping);

	bool has_overlapping = false;
	for (u16 i = 0; i < overlapping.length; i++)
	{
		CBlob@ b = overlapping[i];
		if (b is null) continue;
		if (b.getTeamNum() != this.getTeamNum()) continue;
		if (b.hasTag("player") || b.hasTag("vehicle"))
		{
			has_overlapping = true;
		}
	}
	if (this.get_bool("state") != has_overlapping)
	{
		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.PlaySound(has_overlapping ? "DoorOpen.ogg" : "DoorClose.ogg", 1.5f, 0.85f);
				sprite.SetFrameIndex(0);
				sprite.SetAnimation(has_overlapping ? "open" : "close");
				
				CSpriteLayer@ lever = sprite.getSpriteLayer("lever");
				if (lever !is null)
				{
					lever.SetFrameIndex(0); // activates the animation i guess
					lever.SetAnimation("active");
				}
			}
		}
	}
	this.set_bool("state", has_overlapping);
	this.getShape().getConsts().collidable = !has_overlapping;
}

void onTick(CSprite@ this)
{
	if (isClient())
	{
		CBlob@ blob = this.getBlob();
		if (blob !is null)
		{
			if (blob.get_u8("delay") > 0) blob.add_u8("delay", -1);
			if (!blob.get_bool("state") && blob.get_u8("delay") == 0)
			{
				if (blob.getHealth() < blob.getInitialHealth() * 0.75f)
				{
					this.SetAnimation("destruction");
					if (blob.getHealth() < blob.getInitialHealth() * 0.25f)
					{
						this.SetFrameIndex(2);
					}
					else if (blob.getHealth() < blob.getInitialHealth() * 0.5f)
					{
						this.SetFrameIndex(1);
					}
					else this.SetFrameIndex(0);
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.PlaySound("WoodHit", 1.0f);
		u8 frame = 0;

		Animation @destruction_anim = sprite.getAnimation("destruction");
		if (destruction_anim !is null)
		{
			if (this.getHealth() < this.getInitialHealth())
			{
				f32 ratio = (this.getHealth() - damage * getRules().attackdamage_modifier) / this.getInitialHealth();

				if (ratio <= 0.0f)
				{
					frame = destruction_anim.getFramesCount() - 1;
				}
				else
				{
					frame = (1.0f - ratio) * (destruction_anim.getFramesCount());
				}

				frame = destruction_anim.getFrame(frame);
			}
		}

		Animation @close_anim = sprite.getAnimation("close");
		u8 lastframe = close_anim.getFrame(close_anim.getFramesCount() - 1);
		if (lastframe < frame)
		{
			close_anim.AddFrame(frame);
		}
	}

	// add 'return' only after animation code

	if (customData == Hitters::builder)
	{
		return damage * 3;
	}
	if (hitterBlob.hasTag("grenade"))
	{
		return damage * Maths::Max(0.0f, damage*10 / (hitterBlob.getPosition() - this.getPosition()).Length()*0.25f);
	}
	if (hitterBlob.hasTag("bullet"))
	{
		if (hitterBlob.hasTag("aircraft_bullet")) return damage * 0.25f;
		else if (hitterBlob.hasTag("heavy") || hitterBlob.getName() == "bulletheavy") return damage * 0.33f;
		else if (hitterBlob.hasTag("shrapnel")) return damage * 2.0f;
	}


	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getTeamNum() == this.getTeamNum())
	{
		if (blob.hasTag("vehicle") || blob.hasTag("player"))
		{
			return false;
		}
	}
	return !this.get_bool("state");
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f collisionPos )
{
	if (blob !is null && blob.hasTag("vehicle") && !this.get_bool("state") && blob.getTeamNum() != this.getTeamNum())
	{
		f32 damage = 0.0f;
		damage = (blob.getOldPosition()-blob.getPosition()).Length();

		if (blob.hasTag("truck")) damage *= 1.1f;
		else if (blob.hasTag("apc")) damage *= 2.0f;
		else if (blob.getName() == "maus") damage *= 15.0f;
		else if (blob.hasTag("heavy")) damage *= 7.5f;
		else if (blob.hasTag("tank")) damage *= 3.0f;

		damage *= 1.0f;
		
		this.server_Hit(this, this.getPosition(), blob.getVelocity(), damage, Hitters::builder);
	}
}