#define CLIENT_ONLY

#include "KnockedCommon.as";
#include "PerksCommon.as";
#include "Perks.as";

void onInit(CBlob@ this)
{
    this.set_f32("angle_head", 0);
	this.set_f32("angle_body", 0);
}

const f32 lean_mod = 2.0f; // body lean mod
const f32 lean_mid_sprint_additional = 0.25f;
const f32 lean_air_mod = 1.75f;
const f32 max_vel = 4; // max lean vel

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	if (!this.isOnScreen()) return;

	if (isKnocked(this))
	{
		ResetDegrees(this);
		return;
	}

	const bool att = this.isAttached();
	bool exposed = this.hasTag("machinegunner") || this.hasTag("collidewithbullets") || this.hasTag("can_shoot_if_attached");
	if (att && !exposed)
	{
		ResetDegrees(this);
		return;
	}

	const bool left		= this.isKeyPressed(key_left);
	const bool right	= this.isKeyPressed(key_right);
	const bool up		= this.isKeyPressed(key_up);
	const bool down		= this.isKeyPressed(key_down);

	const bool isknocked = isKnocked(this);

	CMap@ map = this.getMap();
	Vec2f vel = this.getVelocity();
	Vec2f pos = this.getPosition();
	CShape@ shape = this.getShape();

	const f32 vellen = shape.vellen;
	const bool onground = this.isOnGround() || this.isOnLadder();
	const bool onwall = this.isOnWall();

	if (!onground && onwall)
	{
		ResetDegrees(this);
		return;
	}

    Vec2f aimpos = this.getAimPos();
	/* // doesnt work?
	if (att && exposed)
	{
		AttachmentPoint@[] ats;
		if (this.getAttachmentPoints(ats))
		{
			for (u8 i = 0; i < ats.size(); i++)
			{
				AttachmentPoint@ ap = ats[i];
				if (ap is null || ap.socket) continue;
				if (ap.getOccupied() is null || ap.getOccupied() !is this) continue;

				printf(ap.name);
				aimpos = ap.getAimPos();
				break;
			}
		}
	}
	*/
	Vec2f aimdir = aimpos - this.getPosition();
	aimdir.Normalize();

	f32 stun_factor = 1.0f;

	CPlayer@ p = this.getPlayer();
	if (p !is null)
	{
		bool stats_loaded = false;
		PerkStats@ stats;
		if (p.get("PerkStats", @stats) && stats !is null)
			stats_loaded = true;

		if (stats_loaded)
		{
			if (stats.id == Perks::bull && this.exists("used medkit"))
			{
				u32 med_use_time = this.get_u32("used medkit");
				u32 diff = getGameTime()-med_use_time;

				stun_factor = Maths::Clamp(f32(diff) / stats.kill_bonus_time, 0.0f, 1.0f);
			}
		}
	}
	
	f32 lerp_head = 0.66f * stun_factor;
	f32 damp = 0.4f;

	f32 angle_head = -aimdir.Angle() + (this.isFacingLeft()?-180:0);
	if (angle_head < -180) angle_head += 180;
	else if (angle_head > -180) angle_head -= 180;

	angle_head += 180;
	f32 angle_head_target = (Maths::Lerp(angle_head, angle_head < 0 ? -360 : 360, 1.0f - damp) + 360 + (angle_head < 0 ? -360*damp : 360*damp)) % 360;
	angle_head = Maths::Clamp(Maths::Lerp(this.get_f32("angle_head"), angle_head_target, lerp_head), -360.0f, 360.0f);
	this.set_f32("angle_head", angle_head);

	// calculate aim dir body lean
	f32 lerp_body = 0.5f * stun_factor;

	f32 angle_body = -aimdir.Angle() + (this.isFacingLeft()?-180:0);
	if (angle_body < -180) angle_body += 180;
	else if (angle_body > -180) angle_body -= 180;
	angle_body += 180;
	

	// calculate movement lean
	f32 lean_walk = (vel.x < 0 ? Maths::Max(-max_vel, vel.x) : Maths::Min(max_vel, vel.x))
		* (onground ? lean_mod + (this.hasTag("sprinting") ? lean_mid_sprint_additional : 0) : lean_air_mod);

	// decrease lean if going backwards
	if ((vel.x > 0 && this.isFacingLeft())
		|| (vel.x < 0 && !this.isFacingLeft()))
	{
		lean_walk *= 0.75f;
	}

	// recalculate body lean
	f32 lean = 0.1f * (1.0f - Maths::Abs(vel.x) / max_vel);

	f32 angle_body_target = (Maths::Lerp(angle_body, angle_body < 0 ? -360 : 360, 1.0f - lean) + 360 + (angle_body < 0 ? -360*lean : 360*lean)) % 360;
	angle_body = Maths::Clamp(Maths::Lerp(this.get_f32("angle_body"), !onground ? 0 : angle_body_target, lerp_body), -360.0f, 360.0f);

	this.set_f32("angle_body", angle_body);

	// disable aim dir lean if we are moving
	if (!onground || ((vel.x < -1.0f && lean_walk < vel.x)
		|| (vel.x > 1.0f && lean_walk > vel.x)))
	{
		angle_body = lean_walk;
	}

	// rotate
	this.setAngleDegrees(angle_body);

	CSpriteLayer@ head = sprite.getSpriteLayer("head");
    if (head !is null)
    {
		head.ResetTransform();
		head.RotateBy(angle_head, Vec2f(0,4));
    }
	CSpriteLayer@ helmet = sprite.getSpriteLayer("helmet");
    if (helmet !is null)
    {
		helmet.ResetTransform();
		helmet.RotateBy(angle_head, Vec2f(0,4));
    }
}

void ResetDegrees(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ head = sprite.getSpriteLayer("head");
    if (head !is null)
    {
		head.ResetTransform();
    }
	CSpriteLayer@ helmet = sprite.getSpriteLayer("helmet");
    if (helmet !is null)
    {
		helmet.ResetTransform();
    }

	this.setAngleDegrees(0);
}