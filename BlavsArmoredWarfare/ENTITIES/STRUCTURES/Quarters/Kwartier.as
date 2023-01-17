// Quarters.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "StandardControlsCommon.as"

const f32 beer_amount = 1.0f;
const f32 heal_amount = 0.5f;
const u8 heal_rate = 60;

void onInit(CSprite@ this)
{
	CSpriteLayer@ bed = this.addSpriteLayer("bed", "Kwartier.png", 32, 16);
	if (bed !is null)
	{
		{
			bed.addAnimation("default", 0, false);
			int[] frames = {14, 15};
			bed.animation.AddFrames(frames);
		}
		bed.SetOffset(Vec2f(-2, 8));
		bed.SetVisible(true);
	}

	CSpriteLayer@ bed2 = this.addSpriteLayer("bed", "Kwartier.png", 32, 16);
	if (bed2 !is null)
	{
		{
			bed2.addAnimation("default", 0, false);
			int[] frames = {14, 15};
			bed2.animation.AddFrames(frames);
		}
		bed2.SetOffset(Vec2f(-2, -3));
		bed2.SetVisible(true);
	}

	CSpriteLayer@ zzz = this.addSpriteLayer("zzz", "Kwartier.png", 8, 8);
	if (zzz !is null)
	{
		{
			zzz.addAnimation("default", 15, true);
			int[] frames = {96, 97, 98, 98, 99};
			zzz.animation.AddFrames(frames);
		}
		zzz.SetOffset(Vec2f(-6, -6));
		zzz.SetLighting(false);
		zzz.SetVisible(false);
	}

	CSpriteLayer@ backpack = this.addSpriteLayer("backpack", "Kwartier.png", 9, 16);
	if (backpack !is null)
	{
		{
			backpack.addAnimation("default", 0, false);
			int[] frames = {26};
			backpack.animation.AddFrames(frames);
		}
		backpack.SetOffset(Vec2f(-2, 7));
		backpack.SetVisible(false);
	}

	CSpriteLayer@ lantern = this.addSpriteLayer("lantern", "Kwartier.png", 8, 16);
	if (lantern !is null)
	{
		Animation@ anim = lantern.addAnimation("light", 4, true);
		if (anim !is null)
		{
			int[] frames = {32,33,34};
			anim.AddFrames(frames);
			lantern.SetOffset(Vec2f(-12, 4));
			lantern.SetVisible(true);
			lantern.SetFrameIndex(0);
			lantern.SetAnimation(anim);
		}
	}

	this.SetEmitSound("MigrantSleep.ogg");
	this.SetEmitSoundPaused(true);
	this.SetEmitSoundVolume(0.5f);
}

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	this.addCommandID("shop made item");
	{
		AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
		if (bed !is null)
		{
			bed.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_pickup | key_inventory);
			bed.SetMouseTaken(true);
		}
	}

	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 240, 155));

	{
		AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED2");
		if (bed !is null)
		{
			bed.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_pickup | key_inventory);
			bed.SetMouseTaken(true);
		}
	}


	this.addCommandID("rest");
	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	//INIT COSTS
	InitCosts();

	// ICONS
	AddIconToken("$quarters_beer$", "Kwartier.png", Vec2f(24, 24), 7);
	AddIconToken("$quarters_meal$", "Kwartier.png", Vec2f(48, 24), 2);
	AddIconToken("$quarters_egg$", "Kwartier.png", Vec2f(24, 24), 8);
	AddIconToken("$quarters_burger$", "Kwartier.png", Vec2f(24, 24), 9);
	AddIconToken("$rest$", "InteractionIcons.png", Vec2f(32, 32), 29);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(5, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Beer - 1 Heart", "$quarters_beer$", "beer", Descriptions::beer, false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::beer);
	}
	{
		ShopItem@ s = addShopItem(this, "Meal - Full Health", "$quarters_meal$", "meal", Descriptions::meal, false);
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::meal);
	}
	{
		ShopItem@ s = addShopItem(this, "Egg - Full Health", "$quarters_egg$", "egg", Descriptions::egg, false);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::egg);
	}
	{
		ShopItem@ s = addShopItem(this, "Burger - Full Health", "$quarters_burger$", "food", Descriptions::burger, true);
		AddRequirement(s.requirements, "coin", "", "Coins", CTFCosts::burger);
	}
}

void onTick(CBlob@ this)
{
	// TODO: Add stage based sleeping, rest(2 * 30) | sleep(heal_amount * (patient.getHealth() - patient.getInitialHealth())) | awaken(1 * 30)
	// TODO: Add SetScreenFlash(rest_time, 19, 13, 29) to represent the player gradually falling asleep
	bool isServer = getNet().isServer();
	{
		AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
		if (bed !is null)
		{
			CBlob@ patient = bed.getOccupied();
			if (patient !is null)
			{
				if (bed.isKeyJustPressed(key_up))
				{
					if (isServer)
					{
						patient.server_DetachFrom(this);
					}
				}
				else if (getGameTime() % heal_rate == 0)
				{
					if (requiresTreatment(this, patient))
					{
						if (patient.isMyPlayer())
						{
							Sound::Play("Heart.ogg", patient.getPosition());
						}
						if (isServer)
						{
							patient.server_Heal(heal_amount);
						}
					}
					else
					{
						if (isServer)
						{
							patient.server_DetachFrom(this);
						}
					}
				}
			}
		}
	}
	{
		AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED2");
		if (bed !is null)
		{
			CBlob@ patient = bed.getOccupied();
			if (patient !is null)
			{
				if (bed.isKeyJustPressed(key_up))
				{
					if (isServer)
					{
						patient.server_DetachFrom(this);
					}
				}
				else if (getGameTime() % heal_rate == 0)
				{
					if (requiresTreatment(this, patient))
					{
						if (patient.isMyPlayer())
						{
							Sound::Play("Heart.ogg", patient.getPosition());
						}
						if (isServer)
						{
							patient.server_Heal(heal_amount);
						}
					}
					else
					{
						if (isServer)
						{
							patient.server_DetachFrom(this);
						}
					}
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	// TODO: fix GetButtonsFor Overlapping, when detached this.isOverlapping(caller) returns false until you leave collision box and re-enter
	Vec2f tl, br, c_tl, c_br;
	this.getShape().getBoundingRect(tl, br);
	caller.getShape().getBoundingRect(c_tl, c_br);
	bool isOverlapping = br.x - c_tl.x > 0.0f && br.y - c_tl.y > 0.0f && tl.x - c_br.x < 0.0f && tl.y - c_br.y < 0.0f;

	if(!isOverlapping || !bedAvailable(this,1) && !bedAvailable(this,2) || !requiresTreatment(this, caller) || caller.getShape().getConsts().collidable == false)
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton("$rest$", Vec2f(-6, 0), this, this.getCommandID("rest"), getTranslatedString("Rest"), params);
	}
	this.set_bool("shop available", isOverlapping);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = (getNet().isServer());

	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
		{
			return;
		}
		string name = params.read_string();
		{
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob is null)
			{
				return;
			}
			if (name == "beer")
			{
				// TODO: gulp gulp sound
				if (isServer)
				{
					callerBlob.server_Heal(beer_amount);
				}
			}
			else if (name == "meal")
			{
				this.getSprite().PlaySound("/Eat.ogg");
				if (isServer)
				{
					callerBlob.server_SetHealth(callerBlob.getInitialHealth());
				}
			}
		}
	}
	else if (cmd == this.getCommandID("rest"))
	{
		u16 caller_id;
		if (!params.saferead_netid(caller_id))
			return;

		CBlob@ caller = getBlobByNetworkID(caller_id);
		if (caller !is null)
		{
			AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
			AttachmentPoint@ bed2 = this.getAttachments().getAttachmentPointByName("BED");
			if (bed !is null && bedAvailable(this,1))
			{
				CBlob@ carried = caller.getCarriedBlob();
				if (isServer)
				{
					if (carried !is null)
					{
						if (!caller.server_PutInInventory(carried))
						{
							carried.server_DetachFrom(caller);
						}
					}
					this.server_AttachTo(caller, "BED");
				}
			}
			else if(bed2 !is null && bedAvailable(this,2))
			{
				CBlob@ carried = caller.getCarriedBlob();
				if (isServer)
				{
					if (carried !is null)
					{
						if (!caller.server_PutInInventory(carried))
						{
							carried.server_DetachFrom(caller);
						}
					}
					this.server_AttachTo(caller, "BED2");
				}
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	attached.getShape().getConsts().collidable = false;
	attached.SetFacingLeft(true);
	attached.AddScript("WakeOnHit.as");
	attached.Tag("collidewithbullets");

	if (not getNet().isClient()) return;

	CSprite@ sprite = this.getSprite();

	if (sprite is null) return;
	if(attachedPoint.name == "BED")
		updateLayer(sprite, "bed", 1, true, false);
	else
		updateLayer(sprite, "bed2", 1, true, false);
	updateLayer(sprite, "zzz", 0, true, false);
	updateLayer(sprite, "backpack", 0, true, false);

	sprite.SetEmitSoundPaused(false);
	sprite.RewindEmitSound();

	CSprite@ attached_sprite = attached.getSprite();

	if (attached_sprite is null) return;

	attached_sprite.SetVisible(false);
	attached_sprite.PlaySound("GetInVehicle.ogg");

	CSpriteLayer@ head = attached_sprite.getSpriteLayer("head");

	if (head is null) return;

	Animation@ head_animation = head.getAnimation("default");

	if (head_animation is null) return;
	CSpriteLayer@ bed_head;
	if(attachedPoint.name == "BED")
		@bed_head = sprite.addSpriteLayer("bed head", head.getFilename(), 16, 16, attached.getTeamNum(), attached.getSkinNum());
	else
		@bed_head = sprite.addSpriteLayer("bed head2", head.getFilename(), 16, 16, attached.getTeamNum(), attached.getSkinNum());

	if (bed_head is null) return;

	Animation@ bed_head_animation = bed_head.addAnimation("default", 0, false);

	if (bed_head_animation is null) return;

	bed_head_animation.AddFrame(head_animation.getFrame(2));

	bed_head.SetAnimation(bed_head_animation);
	bed_head.RotateBy(80, Vec2f_zero);
	if(attachedPoint.name == "BED")
		bed_head.SetOffset(Vec2f(3, 2));
	else
		bed_head.SetOffset(Vec2f(3, -6));
	bed_head.SetFacingLeft(true);
	bed_head.SetVisible(true);
	bed_head.SetRelativeZ(2);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.getShape().getConsts().collidable = true;
	detached.AddForce(Vec2f(0, -20));
	detached.RemoveScript("WakeOnHit.as");
	detached.Untag("collidewithbullets");

	CSprite@ detached_sprite = detached.getSprite();
	if (detached_sprite !is null)
	{
		detached_sprite.SetVisible(true);
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		if(attachedPoint.name == "BED")
		{
			updateLayer(sprite, "bed head", 0, false, true);
			updateLayer(sprite, "bed", 0, true, false);
		}
		else
		{
			updateLayer(sprite, "bed head2", 0, false, true);
			updateLayer(sprite, "bed2", 0, true, false);
		}
		updateLayer(sprite, "zzz", 0, false, false);
		updateLayer(sprite, "backpack", 0, false, false);

		sprite.SetEmitSoundPaused(true);
	}
}

void updateLayer(CSprite@ sprite, string name, int index, bool visible, bool remove)
{
	if (sprite !is null)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(name);
		if (layer !is null)
		{
			if (remove == true)
			{
				sprite.RemoveSpriteLayer(name);
				return;
			}
			else
			{
				layer.SetFrameIndex(index);
				layer.SetVisible(visible);
			}
		}
	}
}

bool bedAvailable(CBlob@ this,u8 bedNumber)
{
	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	AttachmentPoint@ bed2 = this.getAttachments().getAttachmentPointByName("BED2");
	if (bed !is null && bedNumber == 1)
	{
		CBlob@ patient = bed.getOccupied();
		if (patient !is null)
		{
			return false;
		}
	}
	else if(bed2 !is null && bedNumber == 2)
	{
		CBlob@ patient = bed2.getOccupied();
		if (patient !is null)
		{
			return false;
		}
	}
	

	return true;
}

bool requiresTreatment(CBlob@ this, CBlob@ caller)
{
	return caller.getHealth() < caller.getInitialHealth() && (!caller.isAttached() || caller.isAttachedTo(this));
}
