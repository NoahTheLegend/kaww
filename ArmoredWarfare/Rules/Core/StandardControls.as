// Standard menu player controls

#include "EmotesCommon.as"
#include "StandardControlsCommon.as"
#include "PerksCommon.as";
#include "KnockedCommon.as";

bool zoomModifier = false; // decides whether to use the 3 zoom system or not
int zoomModifierLevel = 4; // for the extra zoom levels when pressing the modifier key
int zoomLevel = 1; // we can declare a global because this script is just used by myPlayer

void onInit(CBlob@ this)
{
	this.set_s32("tap_time", getGameTime());
	CBlob@[] blobs;
	this.set("pickup blobs", blobs);
	this.set_u16("hover netid", 0);
	this.set_bool("release click", false);
	this.set_bool("can button tap", true);
	this.addCommandID("pickup");
	this.addCommandID("putinheld");
	this.addCommandID("getout");
	this.addCommandID("detach");
	this.addCommandID("cycle");
	this.addCommandID("switch");
	this.addCommandID("tap inventory key");
	this.addCommandID("drop_inventory");

	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";

	AddIconToken("$icon_drop_mats$", "DropMats.png", Vec2f(16, 16), 0);

	//add to the sprite
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.AddScript("StandardControls.as");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (!getNet().isServer())                                // server only!
	{
		return;
	}

	if (cmd == this.getCommandID("putinheld"))
	{
		CBlob@ owner = getBlobByNetworkID(params.read_netid());

		putInHeld(owner);
	}
	else if (cmd == this.getCommandID("tap inventory key"))
	{
		CBlob@ owner = getBlobByNetworkID(params.read_netid());

		if (!putInHeld(owner))
		{
			this.SendCommand(this.getCommandID("cycle"));
		}
	}
	else if (cmd == this.getCommandID("pickup"))
	{
		CBlob@ owner = getBlobByNetworkID(params.read_netid());
		CBlob@ pick = getBlobByNetworkID(params.read_netid());

		if (owner !is null && pick !is null)
		{
			owner.server_Pickup(pick);
		}
	}
	else if (cmd == this.getCommandID("detach"))
	{
		CBlob@ obj = getBlobByNetworkID(params.read_netid());

		if (obj !is null)
		{
			this.server_DetachFrom(obj);
		}
	}
	else if (cmd == this.getCommandID("getout"))
	{
		if (this.getInventoryBlob() !is null)
		{
			this.getInventoryBlob().server_PutOutInventory(this);
		}
	}
	else if (cmd == this.getCommandID("drop_inventory"))
	{
		if (!canDropMats(this)) return;

		CInventory@ inv = this.getInventory();
		if (inv is null) return;

		for (u16 i = 0; i < 50; i++) // getItemsCount() is bullshit
		{
			CBlob@ item = inv.getItem(0);
			if (item is null) break;

			this.server_PutOutInventory(item);
		}
	}
}

bool canDropMats(CBlob@ this)
{
	return !this.isInInventory() && !isKnocked(this);
}

bool putInHeld(CBlob@ owner)
{
	if (owner is null) return false;

	CBlob@ held = owner.getCarriedBlob();

	if (held is null) return false;

	return owner.server_PutInInventory(held);
}

bool ClickGridMenu(CBlob@ this, int button)
{
	CGridMenu @gmenu;
	CGridButton @gbutton;

	if (this.ClickGridMenu(button, gmenu, gbutton))   // button gets pressed here - thing get picked up
	{
		if (gmenu !is null)
		{
			// if (gmenu.getName() == this.getInventory().getMenuName() && gmenu.getOwner() !is null)
			{
				if (gbutton is null)    // carrying something, put it in
				{
					server_PutInHeld(this, gmenu.getOwner());
				}
				else // take something
				{
					// handled by button cmd   // hardcoded still :/
				}
			}
			return true;
		}
	}

	return false;
}

void ButtonOrMenuClick(CBlob@ this, Vec2f pos, bool clear, bool doClosestClick)
{
	if (!ClickGridMenu(this, 0))
		if (this.ClickInteractButton())
		{
			clear = false;
		}
		else if (doClosestClick)
		{
			if (this.ClickClosestInteractButton(pos, this.getRadius() * 1.0f))
			{
				this.ClearButtons();
				clear = false;
			}
		}

	if (clear)
	{
		this.ClearButtons();
		this.ClearMenus();
	}
}

void onTick(CBlob@ this)
{
	if (getCamera() is null)
	{
		return;
	}
	ManageCamera(this);

	// rotate blobs in hands
	//if (isServer())
	{
		CBlob@ carried = this.getCarriedBlob();
		if (carried !is null && carried.hasTag("hand_rotation"))
		{
			Vec2f aimdir = this.getAimPos()-this.getPosition();
			aimdir.Normalize();

			f32 angle = -aimdir.Angle() + (this.isFacingLeft()?-180:0);
			if (angle < -180) angle += 180;
			else if (angle > -180) angle -= 180;

			angle += 180;
			f32 damp = carried.exists("hand_rotation_damp") ? carried.get_f32("hand_rotation_damp") : 0.375f;
			angle = (Maths::Lerp(angle, angle < 0 ? -360 : 360, 1.0f - damp) + 360 + (angle < 0 ? -360*damp : 360*damp)) % 360;

			carried.setAngleDegrees(angle);
		}
	}

	CControls@ controls = getControls();

	// use menu

	if (this.isKeyJustPressed(key_use))
	{
		Tap(this);
		this.set_bool("can button tap", !getHUD().hasMenus());
		this.ClearMenus();
		this.ShowInteractButtons();
		this.set_bool("release click", true);
	}
	else if (this.isKeyJustReleased(key_use))
	{
		if (this.get_bool("release click"))
		{
			ButtonOrMenuClick(this, this.getPosition(), true, isTap(this) && this.get_bool("can button tap"));
		}

		this.ClearButtons();
	}

	// bubble menu

	if (this.isKeyJustPressed(key_bubbles))
	{
		Tap(this);
	}

	// taunt menu

	if (this.isKeyJustPressed(key_taunts))
	{
		Tap(this);
	}

	/*else dont use this cause menu won't be release/clickable
	if (this.isKeyJustReleased(key_bubbles))
	{
	    this.ClearBubbleMenu();
	} */

	// in crate

	if (this.isInInventory())
	{
		if (this.isKeyJustPressed(key_pickup))
		{
			CBlob@ invblob = this.getInventoryBlob();
			// Use the inventoryblob command if it has one (crate for example)
			if (invblob.hasCommandID("getout"))
			{
				CBitStream params;
				params.write_u16(this.getNetworkID());
				invblob.SendCommand(invblob.getCommandID("getout"), params);
			}
			else
			{
				this.SendCommand(this.getCommandID("getout"));
			}
		}

		return;
	}

	// no more stuff possible while in crate...

	// inventory menu

	if (this.getInventory() !is null && this.getTickSinceCreated() > 10)
	{
		if (this.isKeyJustPressed(key_inventory))
		{
			Tap(this);
			this.set_bool("release click", true);
			// this.ClearMenus();

			//  Vec2f center =  getDriver().getScreenCenterPos(); // center of screen
			Vec2f center = controls.getMouseScreenPos();
			if (this.exists("inventory offset"))
			{
				this.CreateInventoryMenu(center + this.get_Vec2f("inventory offset"));
			}
			else
			{
				this.CreateInventoryMenu(center);
			}

			CInventory@ inv = this.getInventory();
			Vec2f inv_slots();
			if (inv !is null) inv_slots = inv.getInventorySlots();
			u16 bsize = 24 + f32(inv_slots.x) * 24;

			CGridMenu@ drop_mats = CreateGridMenu(center + this.get_Vec2f("inventory offset") - Vec2f(bsize, f32(inv_slots.y) / 2 * 24), this, Vec2f(1, 1), "");
			if (drop_mats !is null)
			{
				drop_mats.SetCaptionEnabled(false);
				CGridButton@ b = drop_mats.AddButton("$icon_drop_mats$", "Drop inventory", this.getCommandID("drop_inventory"));
				if (b !is null)
				{
					if (!canDropMats(this))
						b.SetEnabled(false);
				}
			}

			//controls.setMousePosition( center );
		}
		else if (this.isKeyJustReleased(key_inventory))
		{
			if (isTap(this, 7))     // tap - put thing in inventory
			{
				CBitStream params;
				params.write_netid(this.getNetworkID());
				this.SendCommand(this.getCommandID("tap inventory key"), params);

				this.ClearMenus();
				return;
			}
			else // click inventory
			{
				if (this.get_bool("release click"))
				{
					ClickGridMenu(this, 0);
				}

				if (!this.hasTag("dont clear menus"))
				{
					this.ClearMenus();
				}
				else
				{
					this.Untag("dont clear menus");
				}
			}
		}
	}

	// release action1 to click buttons

	if (getHUD().hasButtons())
	{
		if ((this.isKeyJustPressed(key_action1) /*|| controls.isKeyJustPressed(KEY_LBUTTON)*/) && !this.isKeyPressed(key_pickup))
		{
			ButtonOrMenuClick(this, this.getAimPos(), false, true);
			this.set_bool("release click", false);
		}
	}

	// clear grid menus on move

	if (!this.isKeyPressed(key_inventory) &&
	        (this.isKeyJustPressed(key_left) || this.isKeyJustPressed(key_right) || this.isKeyJustPressed(key_up) ||
	         this.isKeyJustPressed(key_down) || this.isKeyJustPressed(key_action2) || this.isKeyJustPressed(key_action3))
	   )
	{
		this.ClearMenus();
	}

	//if (this.isKeyPressed(key_action1))
	//{
	//  //server_DropCoins( this.getAimPos(), 100 );
	//  CBlob@ mat = server_CreateBlob( "cata_rock", 0, this.getAimPos());
	//}

	// keybinds

	//if (controls.ActionKeyPressed(AK_BUILD_MODIFIER))
	//{
	//	EKEY_CODE[] keybinds = { KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0 };
//
	//	// loop backwards so leftmost keybinds have priority
	//	for (int i = keybinds.size() - 1; i >= 0; i--)
	//	{
	//		if (controls.isKeyJustPressed(keybinds[i]))
	//		{
	//			CBitStream params;
	//			params.write_u8(i);
	//			this.SendCommand(this.getCommandID("switch"), params);
	//		}
	//	}
	//}
}

// show dots on chat

void onDie(CBlob@ this)
{
	set_emote(this, "off");
}

// CAMERA

void onInit(CSprite@ this)
{
	//backwards compat - tag the blob if we're assigned to the sprite too
	//so if it's not there, the blob can adjust the camera at 30fps at least
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	blob.Tag("60fps_camera");
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;
	//do 60fps camera
	AdjustCamera(blob, true);
}

void AdjustCamera(CBlob@ this, bool is_in_render)
{
	CCamera@ camera = getCamera();
	f32 zoom = camera.targetDistance;

	f32 zoomSpeed = 0.1f;
	if (is_in_render)
	{
		zoomSpeed *= getRenderApproximateCorrectionFactor();
	}

	f32 minZoom = 0.5f; // TODO: make vars
	f32 maxZoom = 2.0f;

	f32 zoom_target = 1.0f;

	switch (zoomLevel)
	{
		case 1: zoom_target = 1.0f; zoomModifierLevel = 4; break;
		case 2:	zoom_target = 2.0f; zoomModifierLevel = 6; break;
	}

	bool javelin = false;
	CBlob@ b = this.getCarriedBlob();
	if (b !is null && b.getName() == "launcher_javelin") javelin = true;

	if (this.hasTag("scopedin") || javelin)
	{
		zoom_target = 1.0f; //1.25f
		zoomSpeed *= 0.75f; //0.4f
	}

	zoom_target = (zoomLevel == 0 && this.hasTag("increase_max_zoom") ? 0.5f : zoom_target);
	if (this.getName() == "ballista_bolt")
	{
		zoom_target = 0.66f;
	}

	if (stun_factor > 0.0f)
	{
		f32 cos = Maths::Cos(getGameTime()*0.5f)*2;
		zoom_target = (2.0f+stun_factor) + Maths::Sin(getGameTime() * (6 + cos)) / (8 + cos) * stun_factor;
		zoom = zoom_target;
		zoomLevel = 2;

		SetScreenFlash(55, 255, 50, 50, 1.0f);
	}

	if (zoom > zoom_target)
	{
		zoom = Maths::Max(zoom_target, zoom - zoomSpeed);
	}
	else if (zoom < zoom_target)
	{
		zoom = Maths::Min(zoom_target, zoom + zoomSpeed);
	}

	camera.targetDistance = zoom;
}

f32 stun_factor = 0.0f;

void ManageCamera(CBlob@ this)
{
	CCamera@ camera = getCamera();
	CControls@ controls = this.getControls();

	// mouse look & zoom
	if (isClient() && (getGameTime() - this.get_s32("tap_time") > 5) && controls !is null)
	{
		if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT)))
		{
			zoomModifier = controls.isKeyPressed(KEY_LCONTROL);

			zoomModifierLevel = Maths::Max(0, zoomModifierLevel - 1);
			zoomLevel = Maths::Max(0, zoomLevel - 1);

			Tap(this);
		}
		else if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN)))
		{
			zoomModifier = controls.isKeyPressed(KEY_LCONTROL);

			zoomModifierLevel = Maths::Min(6, zoomModifierLevel + 1);
			zoomLevel = Maths::Min(2, zoomLevel + 1);

			Tap(this);
		}
	}

	if (!this.hasTag("60fps_camera"))
	{
		AdjustCamera(this, false);
	}

	f32 zoom = camera.targetDistance;
	bool fixedCursor = true;
	if (zoom < 1.0f)  // zoomed out
	{
		camera.mousecamstyle = 1; // fixed
	}
	else
	{
		// gunner
		if (this.isAttachedToPoint("GUNNER") || this.hasTag("scopedin"))
		{
			camera.mousecamstyle = 2;
		}
		else if (g_fixedcamera) // option
		{
			camera.mousecamstyle = 1; // fixed
		}
		else
		{
			camera.mousecamstyle = 2; // soldatstyle
		}
	}

	if (this.getName() == "ballista_bolt")
	{
		camera.mousecamstyle = 1;
	}

	CPlayer@ local = getLocalPlayer();
	CBlob@ localblob = getLocalPlayerBlob();
	
	if (localblob !is null)
	{
		f32 extra = 0;

		bool lock_zoom = false;

		bool stats_loaded = false;
		PerkStats@ stats;
		if (local.get("PerkStats", @stats) && stats !is null)
			stats_loaded = true;
		
		if (localblob.hasTag("binoculars"))
		{
			f32 extra = 1.0f;
			if (stats_loaded)
			{
				extra = stats.binoculars_distance;
			}
			camera.mouseFactor = 0.65f * extra;
		}
		else if (localblob.hasTag("distant_view"))
		{
			lock_zoom = true;
			camera.mouseFactor = 0.75f;
		}
		else if (localblob.hasTag("driver_vision"))
		{
			camera.mouseFactor = 0.55f;
		}

		if (stats_loaded)
		{
			extra += stats.additional_vision_distance;
			camera.mouseFactor += stats.additional_vision_distance;

			if (stats.id == Perks::bull && this.exists("used medkit"))
			{
				u32 med_use_time = this.get_u32("used medkit");
				u32 diff = getGameTime()-med_use_time;

				f32 new_stun_factor = 1.0f - Maths::Clamp(f32(diff) / stats.kill_bonus_time, 0.25f, 1.0f);
				if (stun_factor != new_stun_factor && stun_factor == 0.0f)
					Sound::Play("contusion.ogg", localblob.getPosition(), 0.25f, 0.6f);
					
				stun_factor = new_stun_factor;
				if (stun_factor > 0.0f) this.set_u32("next_med", getGameTime()+1);
			}
			else stun_factor = 0.0f;
		}

		// camera
		if (localblob.get_u32("far_zoom") < getGameTime() && !lock_zoom)
		{
			localblob.Untag("binoculars");
			if (getLocalPlayer() !is null)
			{
				if (localblob.getName() == "sniper")
				{
					camera.mouseFactor = 0.5f + extra/2;
					return;
				}
				if (localblob.isAttachedToPoint("GUNNER"))// && getLocalPlayer().getBlob().isKeyPressed(key_action2))
				{
					camera.mouseFactor = 0.5f + extra/2;
					return;
				}
			}
			camera.mouseFactor = 0.3f + extra; // doesn't affect fixed cam
		}
	}
}