#include "VehicleCommon.as"
#include "GenericButtonCommon.as"
#include "Explosion.as"
#include "Hitters.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "Costs.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "VehiclesParams.as"
#include "GamemodeCheck.as"
#include "ProgressBar.as"
#include "MakeDustParticle.as"

// Armory logic

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.Tag("vehicle");
	this.Tag("armory");
	this.Tag("truck");
	this.Tag("respawn_if_crew_present");

	this.addCommandID("update scrap menu");

	AddIconToken("$icon_10%$", "Scrap.png", Vec2f(16, 16), 3);
	AddIconToken("$icon_5%$", "Scrap.png", Vec2f(16, 16), 2);
	AddIconToken("$icon_2%$", "Scrap.png", Vec2f(16, 16), 1);
	AddIconToken("$icon_1$", "Scrap.png", Vec2f(16, 16), 0);

	Vehicle_Setup(this,
	              4500.0f, // move speed  //103
	              0.4f,  // turn speed
	              Vec2f(0.0f, 0.57f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_SetupGroundSound(this, v, "ArmoryEngine",  // movement sound
	                         0.25f, // movement sound volume modifier   0.0f = no manipulation
	                         0.25f // movement sound pitch modifier     0.0f = no manipulation
	                        );

	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(17.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(15.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-26.0f, 8.0f)); if (w !is null) w.SetRelativeZ(10.0f); }
	{ CSpriteLayer@ w = Vehicle_addRubberWheel(this, v, 0, Vec2f(-27.5f, 8.0f)); if (w !is null) w.SetRelativeZ(-10.0f); }

	this.getShape().SetOffset(Vec2f(-4, 2)); //0,8

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-100.0f);
	
	//CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 80, 80);
	//if (front !is null)
	//{
	//	front.addAnimation("default", 0, false);
	//	int[] frames = { 0, 1, 2 };
	//	front.animation.AddFrames(frames);
	//	front.SetRelativeZ(0.8f);
	//	front.SetOffset(Vec2f(0.0f, 0.0f));
	//}

	//INIT COSTS
	InitCosts();

	CBlob@[] tents;
    getBlobsByName("tent", @tents);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_string("shop description", "Craft Equipment");
	this.set_u8("shop icon", 25);

	AddIconToken("$icon_mg$", "IconMG.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_ft$", "IconFT.png", Vec2f(32, 32), 0, 2);
	AddIconToken("$icon_jav$","JavelinLauncher.png", Vec2f(32, 16), 2, 2);
	AddIconToken("$icon_barge$","IconBarge.png", Vec2f(32, 32), 0, 2);
	
	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	this.SetFacingLeft(this.getTeamNum() == teamright);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1) InitShop(this);

	if (this.getTickSinceCreated() == 60)
	{
		InitClasses(this);
	}
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		CSprite@ sprite = this.getSprite();
		if (getNet().isClient())
		{
			CPlayer@ p = getLocalPlayer();
			if (p !is null)
			{
				CBlob@ local = p.getBlob();
				if (local !is null)
				{
					CSpriteLayer@ front = sprite.getSpriteLayer("front layer");
					if (front !is null)
					{
						//front.setVisible(!local.isAttachedTo(this));
					}
				}
			}
		}

		Vec2f vel = this.getVelocity();
		if (!this.isOnMap())
		{
			Vec2f vel = this.getVelocity();
			this.setVelocity(Vec2f(vel.x * 0.995, vel.y));
		}
		else if (Maths::Abs(vel.x) > 2.0f)
		{
			if (getGameTime() % 4 == 0)
			{
				if (isClient())
				{
					Vec2f pos = this.getPosition();
					CMap@ map = getMap();
					
					ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(18) - 9 + (this.isFacingLeft() ? 30 : -30), XORRandom(18) - 3), getRandomVelocity(0.0f, 0.5f + XORRandom(60) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.1f), float(XORRandom(360)), 0.7f + XORRandom(70) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
				}
			}
		}
	}

	ConstructionEffects(this);
	Vehicle_LevelOutInAir(this);

	CBlob@[] tents;
	getBlobsByName("tent", @tents);
	if (tents.length == 0) this.set_f32("capture time", 0);
}

void InitShop(CBlob@ this)
{
	this.set_Vec2f("shop offset", Vec2f(-18, 0));

	if (isCTF()) this.set_Vec2f("shop menu size", Vec2f(9, 3));
	else 		 this.set_Vec2f("shop menu size", Vec2f(9, 3));

	makeDefaultAmmo(this);
	makeDefaultExplosives(this);
	makeDefaultGear(this);
	makeDefaultUtils(this);
	makeExtraUtils(this);
	makeSmallBombs(this);
	makeC4(this);
	makeFactionVehicle(this, this.getTeamNum(), VehicleType::weapons1, 0, false, true);
	makeMortar(this);
	makeFactionVehicle(this, this.getTeamNum(), VehicleType::machinegun, 0, false, true);
	makeFirethrower(this);
	makeBigBombs(this);
}

void PackerMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer() && caller.getControls() !is null)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(caller.getControls().getMouseScreenPos() + Vec2f(0.0f, 0.0f), this, Vec2f(4, 1), "Take amount");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = false;

			CGridButton@ button1 = menu.AddButton("$icon_1$", "Pick 1", this.getCommandID("pick_1"), Vec2f(1, 1), params);
			CGridButton@ button2 = menu.AddButton("$icon_2%$", "Pick 2", this.getCommandID("pick_2"), Vec2f(1, 1), params);
			CGridButton@ button5 = menu.AddButton("$icon_5%$", "Pick 5", this.getCommandID("pick_5"), Vec2f(1, 1), params);
			CGridButton@ button10 = menu.AddButton("$icon_10%$", "Pick 10", this.getCommandID("pick_10"), Vec2f(1, 1), params);
			
			for (u8 i = 0; i < 4; i++)
			{
				CGridButton@ button;
				if (i == 0) @button = @button1;
				else if (i == 1) @button = @button2;
				else if (i == 2) @button = @button5;
				else if (i == 3) @button = @button10;

				if (button !is null)
				{
					CInventory@ inv = this.getInventory();
					if (inv !is null)
					{
						if (inv.getItem("mat_scrap") is null || inv.getItem("mat_scrap").getQuantity() < (i==0?1:i==1?2:i==2?5:10)) button.SetEnabled(false);
					}
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	this.set_Vec2f("shop offset", Vec2f(-18, 0));

	bool same_team = caller.getTeamNum() == this.getTeamNum();
	this.set_bool("shop available", same_team);

	if (this.getDistanceTo(caller) < this.getRadius() && same_team)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton(24, Vec2f(-9, -10), this, this.getCommandID("separate"), "Pick scrap", params);
	}

	if (!canSeeButtons(this, caller)) return;

	// button for runner
	// create menu for class change
	if (canChangeClass(this, caller) && same_team)
	{
		caller.CreateGenericButton("$change_class$", Vec2f(10, 0), this, buildSpawnMenu, getTranslatedString("Swap Class"));
		caller.CreateGenericButton("$change_perk$", Vec2f(0, -10), this, buildPerkMenu, getTranslatedString("Switch Perk"));
	}
}

// Lose
void onDie(CBlob@ this)
{
    Explode(this, 64.0f, 1.0f);
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue)
{
	return false;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _charge)
{
	
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle"))
	{
		return false;
	}

	if (blob.hasTag("flesh") && !blob.isAttached())
	{
		return true;
	}
	else
	{
		return Vehicle_doesCollideWithBlob_ground(this, blob);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		if (blob.hasTag("material") && !blob.hasTag("no_armory_pickup") && !blob.isAttached() && !blob.isInInventory())
		{
			if (isServer())
			{
				this.server_PutInInventory(blob);
				RequestClientTakeScrapSync(this, getLocalPlayerBlob());
			}
			//else this.getSprite().PlaySound("BridgeOpen.ogg", 1.0f);
		}
		TryToAttachVehicle(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	attachedPoint.offsetZ = 1.0f;
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

bool isOverlapping(CBlob@ this, CBlob@ blob)
{
	Vec2f tl, br, _tl, _br;
	this.getShape().getBoundingRect(tl, br);
	blob.getShape().getBoundingRect(_tl, _br);
	return br.x > _tl.x
	       && br.y > _tl.y
	       && _br.x > tl.x
	       && _br.y > tl.y;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
	if (cmd == this.getCommandID("separate"))
	{
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (this !is null && blob !is null)
		{
			PackerMenu(this, blob);
		}
	}
	else if (isClient() && cmd == this.getCommandID("update scrap menu"))
	{
		u16 id = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(id);

		if (blob !is null && blob.isMyPlayer())
			UpdatePickScrapMenu(this);
	}
	else if (isServer() && cmd == this.getCommandID("pick_1") || cmd == this.getCommandID("pick_2")
	|| cmd == this.getCommandID("pick_5") || cmd == this.getCommandID("pick_10"))
	{
		u16 blobid;
		if (!params.saferead_u16(blobid)) return;
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (blob !is null)
		{
			if (this !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					CBlob@ item = inv.getItem("mat_scrap");
					if (item !is null)
					{
						u8 amount = 0;
						u16 count = item.getQuantity();

						if (cmd == this.getCommandID("pick_1"))
							amount = 1;
						else if (cmd == this.getCommandID("pick_2"))
							amount = 2;
						else if (cmd == this.getCommandID("pick_5"))
							amount = 5;
						else if (cmd == this.getCommandID("pick_10"))
							amount = 10;

						if (isServer() && count > 0)
						{
							if ((0.0f+count)-amount >= 0)
							{
								item.server_SetQuantity(count-amount);

								CBlob@ drop = server_CreateBlob(item.getName(), item.getTeamNum(), this.getPosition());
								drop.server_SetQuantity(amount);

								if (!blob.server_PutInInventory(drop))
								{
									blob.server_AttachTo(drop, "PICKUP");
									drop.setPosition(this.getPosition());
								}
							}

							RequestClientTakeScrapSync(this, blob);
						}
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort.ogg");
		
		bool isServer = (getNet().isServer());
		if (!isServer) return;
			
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		CBlob@ blob = getBlobByNetworkID( caller );
		CBlob@ purchase = getBlobByNetworkID( item );
		Vec2f pos = this.getPosition();
		
		string name = params.read_string();
		if (name == "mat_5tbomb" || name == "mat_907kgbomb")
		{
			u8 teamleft = getRules().get_u8("teamleft");
			u8 teamright = getRules().get_u8("teamright");
			u8 id = (name == "mat_5tbomb" ? 1 : 0);

			CBitStream params1;
			params1.write_bool(this.getTeamNum() == teamleft);
			params1.write_u8(id);
			this.SendCommand(this.getCommandID("warn_opposite_team"), params1);
		}
	}
	else if (cmd == this.getCommandID("warn_opposite_team"))
	{
		if (isClient())
		{
			bool warn_team = params.read_bool(); // left is true
			u8 id = params.read_u8();

			if (getLocalPlayer() !is null)
			{
				bool spectator = getLocalPlayer().getTeamNum() == getRules().getSpectatorTeamNum();

				u8 teamleft = getRules().get_u8("teamleft");
				u8 teamright = getRules().get_u8("teamright");
				//printf(""+(getLocalPlayer().getTeamNum())+" "+teamleft+" "+teamright+" "+warn_team);
				if (!spectator
					&& ((getLocalPlayer().getTeamNum() == teamleft && !warn_team)
					|| (getLocalPlayer().getTeamNum() == teamright && warn_team)))
				{
					Sound::Play("nuke_warn.ogg", getDriver().getWorldPosFromScreenPos(getDriver().getScreenCenterPos()), 2.0f, 0.825f);
					client_AddToChat("Enemy has constructed a "+(id==0?"907kg":"5 ton")+" bomb!", SColor(255, 255, 0, 0));

					//error("debug: playing sound & sending bomb warn message");
				}
				else if (!spectator)
				{
					client_AddToChat("Your team has constructed a "+(id==0?"907kg":"5 ton")+" bomb. Enemies see that.", SColor(255, 0, 150, 0));
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "missile_javelin" || hitterBlob.getName() == "ballista_bolt")
	{
		return damage * 1.25f;
	}
	if (hitterBlob.hasTag("atgrenade"))
	{
		return damage * 0.5f;
	}
	bool is_bullet = (customData >= HittersAW::bullet && customData <= HittersAW::apbullet);
	if (is_bullet)
	{
		return damage *= 1.25f;
	}
	return damage;
}

void onInventoryQuantityChange(CBlob@ this, CBlob@ blob, int oldQuantity)
{
	if (blob.getName() == "mat_scrap")
	{
		UpdatePickScrapMenu(this);
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "mat_scrap")
	{
		UpdatePickScrapMenu(this);
	}
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "mat_scrap")
	{
		UpdatePickScrapMenu(this);
	}
}

void UpdatePickScrapMenu(CBlob@ this)
{
	if (!isClient()) return;

	CBlob@ local = getLocalPlayerBlob();
	if (local is null) return;
	
	CGridMenu@ menu = getGridMenuByName("Take amount");
	if (menu !is null)
	{
		//PackerMenu(this, local);
		for (u8 i = 0; i < 4; i++)
		{
			CGridButton@ button = menu.getButtonOfIndex(i);
			if (button !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					CBlob@ item = inv.getItem("mat_scrap");
					if (item !is null)
					{
						u16 count = item.getQuantity();
						if (count < (i==0?1:i==1?2:i==2?5:10)) button.SetEnabled(false);
					}
				}
			}
		}
	}
}

void RequestClientTakeScrapSync(CBlob@ this, CBlob@ blob)
{
	if (!isServer()) return;
	if (blob is null) return;

	CBitStream params;
	params.write_u16(blob.getNetworkID());
	this.SendCommand(this.getCommandID("update scrap menu"), params);
}

void ConstructionEffects(CBlob@ this)
{
	if (this.get_bool("constructing") && getMap() !is null)
	{
		CBlob@[] overlapping;
		getMap().getBlobsInBox(this.getPosition()-Vec2f(24, 8), this.getPosition()+Vec2f(24, 8), @overlapping);

		bool has_caller = false;
		s8 caller_team = -1;
		s8 count = -1;
		
		for (u16 i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			if (blob is null || blob.isAttached() || blob.hasTag("dead"))
					continue;

			if (blob.getNetworkID() == this.get_u16("builder_id"))
			{
				has_caller = true;
				caller_team = blob.getTeamNum();
			}
		}

		for (u16 i = 0; i < overlapping.length; i++)
		{
			CBlob@ blob = overlapping[i];
			if (blob is null || blob.isAttached() || blob.hasTag("dead"))
					continue;

			if (caller_team == blob.getTeamNum() && blob.hasTag("player"))
			{
				count++;
			}
		}

		if (has_caller)
		{
			if (isClient() && getGameTime()%25==0)
			{
				this.add_u32("step", 1);
				if (this.get_u32("step") > 2) this.set_u32("step", 0);

				if (XORRandom(4)==0) this.set_u32("step", XORRandom(3));

				u8 rand = XORRandom(5);
				for (u8 i = 0; i < rand; i++)
				{
					MakeDustParticle(this.getPosition()+Vec2f(XORRandom(24)-12, XORRandom(16)), XORRandom(5)<2?"Smoke.png":"dust2.png");
					
					if (XORRandom(3) != 0)
					{
						CParticle@ p = makeGibParticle("WoodenGibs.png", this.getPosition()+Vec2f(XORRandom(24)-12, XORRandom(16)), Vec2f(0, (-1-XORRandom(3))).RotateBy(XORRandom(61)-30.0f), XORRandom(16), 0, Vec2f(8, 8), 1.0f, 0, "", 7);
					}
				}

				this.getSprite().PlaySound("Construct"+(this.get_u32("step")+1), 0.6f+XORRandom(11)*0.01f, 0.95f+XORRandom(6)*0.01f);
			}
		}
		this.add_f32("construct_time", has_caller || this.get_f32("construct_time") / this.get_u32("construct_endtime") > 0.975f ? 1 + count : -1);
		
		if (this.get_f32("construct_time") <= 0)
		{
			this.set_f32("construct_time", 0);
			this.set_string("constructing_name", "");
			this.set_s8("constructing_index", 0);
			this.set_bool("constructing", false);

			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				if (hasBar(bars, "construct"))
				{
					bars.RemoveBar("construct", false);
				}
			}
		}
	}
}