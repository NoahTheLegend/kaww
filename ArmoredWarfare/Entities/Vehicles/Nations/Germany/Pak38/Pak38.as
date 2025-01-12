#include "MakeCrate.as"
#include "ProgressBar.as";

const f32 packing_time = 150;
const f32 min_health_to_pack = 0.9f;
const f32 shield_lean_mod = 0.5f;
const bool can_rotate = false;

void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("respawn_if_crew_present");
	this.Tag("apc"); // hack projectile type

	this.Tag("builder always hit");
	this.Tag("builder urgent hit");

	this.set_f32("custom_capture_time", 10);

	// shits in console if not added
	this.addCommandID("fire");
	this.addCommandID("fire blob");
	this.addCommandID("flip_over");
	this.addCommandID("getin_mag");
	this.addCommandID("load_ammo");
	this.addCommandID("ammo_menu");
	this.addCommandID("swap_ammo");
	this.addCommandID("sync_ammo");
	this.addCommandID("sync_last_fired");
	this.addCommandID("putin_mag");
	this.addCommandID("vehicle getout");
	this.addCommandID("reload");
	this.addCommandID("recount ammo");

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	bool facing_left = this.getTeamNum() == teamright;
	this.SetFacingLeft(facing_left);

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.RemoveSpriteLayer("arm");
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 16, 48);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(5);
	}

	CSpriteLayer@ shield = sprite.addSpriteLayer("shieldfront", sprite.getConsts().filename, 32, 32);
	if (shield !is null)
	{
		Animation@ anim = shield.addAnimation("default", 0, false);
		anim.AddFrame(3);

		shield.SetOffset(Vec2f(-2,-3));
		shield.SetRelativeZ(10.0f);
	}
	CSpriteLayer@ shieldback = sprite.addSpriteLayer("shieldback", sprite.getConsts().filename, 32, 32);
	if (shieldback !is null)
	{
		Animation@ anim = shieldback.addAnimation("default", 0, false);
		anim.AddFrame(4);

		shieldback.SetOffset(Vec2f(-2,-3));
		shieldback.SetRelativeZ(-10.0f);
	}

	this.addCommandID("pack_to_crate");
	this.addCommandID("start_packing");

	this.set_u32("packing_endtime", 0);
	this.set_f32("packing_time", 0);

	Bar@ bars;
	if (!this.get("Bar", @bars))
	{
		Bar setbars;
    	setbars.gap = 20.0f;
    	this.set("Bar", setbars);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	f32 gun_angle = blob.get_f32("gunelevation");
	if (gun_angle < 0) gun_angle += 90;
	else if (gun_angle > 0) gun_angle -= 90;

	if (blob.isFacingLeft()) gun_angle -= 180;

	gun_angle *= shield_lean_mod;
	f32 angle = gun_angle;

	CSpriteLayer@ shieldfront = this.getSpriteLayer("shieldfront");
	if (shieldfront !is null)
	{
		shieldfront.ResetTransform();
		shieldfront.RotateBy(angle, Vec2f(0, 0));
	}

	CSpriteLayer@ shieldback = this.getSpriteLayer("shieldback");
	if (shieldback !is null)
	{
		shieldback.ResetTransform();
		shieldback.RotateBy(angle, Vec2f(0, 0));
	}
}

void onTick(CBlob@ this)
{
	visualTimerTick(this);
	
	u32 endtime = this.get_u32("packing_endtime");
	if (endtime != 0) this.add_f32("packing_time", 1);

	if (this.get_f32("packing_time") >= endtime || this.hasAttached())
	{	
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (hasBar(bars, "packing"))
				bars.RemoveBar("packing", false);
		}
	}

	if (!can_rotate) return;
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("GUNNER");
	if (ap !is null)
	{
		CBlob@ gunner = ap.getOccupied();
		if (gunner !is null)
		{
			f32 posx = this.getPosition().x;
			f32 aimposx = ap.getAimPos().x;

			if (aimposx < posx - this.getRadius())
			{
				this.SetFacingLeft(true);
			}
			else if (aimposx > posx + this.getRadius())
			{
				this.SetFacingLeft(false);
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;
	if (caller.getDistanceTo(this) > 32.0f) return;
	if (caller.getTeamNum() != this.getTeamNum()) return;
	if (this.hasAttached()) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	bool enough_health = this.getHealth()/this.getInitialHealth() >= min_health_to_pack;
	CButton@ button = caller.CreateGenericButton("$icon_mg$", Vec2f(0, -12), this, this.getCommandID("start_packing"), enough_health ? "Pack to crate" : "Needs a repair before packing", params);
	if (button !is null)
	{
		button.SetEnabled(enough_health);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("start_packing"))
	{
		if (this.getHealth()/this.getInitialHealth() < min_health_to_pack) return;
		
		u16 caller_id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(caller_id);

		if (caller is null) return;
		if (!caller.isMyPlayer()) return;

		this.set_f32("packing_time", 0);
		this.set_u32("packing_endtime", packing_time);

		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (hasBar(bars, "packing"))
				return;
		}

		SColor team_front = SColor(255, 133, 133, 160);

		ProgressBar setbar;
		setbar.Set(this.getNetworkID(), "packing", Vec2f(64.0f, 16.0f), true, Vec2f(0, 64), Vec2f(2, 2), back, team_front,
			"packing_time", this.get_u32("packing_endtime"), 0.25f, 5, 5, true, "pack_to_crate", caller.getNetworkID());
		
		bars.AddBar(this.getNetworkID(), setbar, true);
	}
	else if (cmd == this.getCommandID("pack_to_crate"))
	{
		if (this.getHealth()/this.getInitialHealth() < min_health_to_pack) return;

		u16 caller_id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(caller_id);
		
		if (caller is null) return;

		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			bars.RemoveBar("packing", false);
		}

		if (isClient())
		{
			// idk some sound and particles here?
		}
		if (isServer())
		{
			if (this.getInventory() !is null && this.getDistanceTo(caller) < 64.0f) this.MoveInventoryTo(caller);
			CBlob@ crate = server_MakeCrate("pak38", "Crate with Pak-38", 0, caller.getTeamNum(), this.getPosition());
			if (crate !is null)
			{}

			this.server_Die();
		}
	}
}

void onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f && this.getHealth()/this.getInitialHealth() < min_health_to_pack)
	{
		Bar@ bars;
		if (this.get("Bar", @bars))
		{
			if (hasBar(bars, "packing"))
				bars.RemoveBar("packing", false);
		}

		this.set_f32("packing_time", 0);
		this.set_u32("packing_endtime", 0);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player"))
	{
		attached.Tag("increase_max_zoom");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("player"))
	{
		detached.Untag("increase_max_zoom");
	}
}

void onRender(CSprite@ this)
{
	visualTimerRender(this);
}