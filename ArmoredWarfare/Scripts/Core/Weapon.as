//////////////////////////////////////////////////////
//
//  StandardFire.as - Vamist & Gingerbeard
//
//  Handles client side activities
//
//CustomCycle

#include "GunCommon.as";
#include "WeaponStandard.as";
#include "GunModule.as"
#include "BulletCase.as";
#include "Recoil.as";
#include "CustomBlocks.as";
#include "UtilityChecks.as";
#include "TextureCreation.as";

const uint8 NO_AMMO_INTERVAL = 25;

void onInit(CBlob@ this) 
{
	// Prevent classes from jabbing n stuff
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null) 
	{
		ap.SetKeysToTake(key_action1);
	}

	this.set_string("inv_name", this.getInventoryName());

	u8 t;
	if (this.hasTag("pistol")) t = 5;
	else if (this.hasTag("sniper")) t = 45;
	else t = 30;
	this.set_u8("a1time", t);
	this.set_u8("holdtime", t);
	this.set_u32("lastshot", 0);

	// Set commands
	this.addCommandID("reload");
	this.addCommandID("fireProj");
	this.addCommandID("sync_interval");

	// Set vars
	this.set_bool("beginReload", false); //Starts a reload
	this.set_bool("doReload", false); //Determines if the gun is in a reloading phase
	this.set_u8("actionInterval", 0); //Timer for gun activities like shooting and reloading
	this.set_u8("clickReload", 1); //'Click' moment after shooting
	this.set_f32("gun_recoil_current", 0.0f); //Determines how far the kickback animation is when shooting

	this.Tag("weapon");
	this.Tag("no shitty rotation reset");
	this.Tag("hopperable");

	if (!this.exists("laser_texture")) this.set_string("laser_texture", "Laser_Blue.png");
	if (!this.exists("laser_distance")) this.set_f32("laser_distance", 32.0f);
	if (!this.exists("falloff_start")) this.set_f32("falloff_start", 16.0f);
	if (!this.exists("laser_alpha_mod")) this.set_f32("laser_alpha_mod", 0.0f);
	if (!this.exists("falloff_max")) this.set_f32("falloff_max", 1.0f);
	if (!this.exists("laser_offset")) this.set_Vec2f("laser_offset", Vec2f(0,0));
	this.set_Vec2f("laser_hitpos", Vec2f(-1, -1));

	if (isClient() && this.hasTag("laser"))
	{
		int cb_id = Render::addBlobScript(Render::layer_prehud, this, "Weapon.as", "laserEffects");
	}

	GunSettings@ settings;
	this.get("gun_settings", @settings);

	if (!this.exists("CustomBullet")) this.set_string("CustomBullet", "item_bullet.png");  // Default bullet image
	if (!this.exists("CustomBulletWidth")) this.set_f32("CustomBulletWidth", 1.0f);  // Default bullet width
	if (!this.exists("CustomBulletLength")) this.set_f32("CustomBulletLength", 14.0f); // Default bullet length

	string vert_name = this.get_string("CustomBullet");
	CRules@ rules = getRules();

	if (isClient()) //&& !rules.get_bool(vert_name + '-inbook'))
	{
		if (vert_name == "")
		{
			// warn(this.getName() + " Attempted to add an empty CustomBullet, this can cause null errors");
			return;
		}

		//rules.set_bool(vert_name + '-inbook', true);

		Vertex[]@ bullet_vertex;
		rules.get(vert_name, @bullet_vertex);

		if (bullet_vertex is null)
		{
			Vertex[] vert;
			rules.set(vert_name, vert);
		}

		// #blamekag
		if (!rules.exists("VertexBook"))
		{
			string[] book;
			rules.set("VertexBook", @book);
			book.push_back(vert_name);
		}
		else
		{
			string[]@ book;
			rules.get("VertexBook", @book);
			book.push_back(vert_name);
		}
	}

	this.set_u8("clip", settings.CLIP); //Clip u8 for easy maneuverability
	CSprite@ sprite = this.getSprite();

	if (this.hasTag("CustomSoundLoop"))
	{
		sprite.SetEmitSound(settings.FIRE_SOUND);
		sprite.SetEmitSoundVolume(this.exists("CustomShootVolume") ? this.get_f32("CustomShootVolume") : 2.0f);
		sprite.SetEmitSoundSpeed(settings.FIRE_PITCH + XORRandom(settings.FIRE_PITCH_RANDOM*100)/100.0f);
		sprite.SetEmitSoundPaused(true);
	}
/*
	// Required or stuff breaks due to wonky mouse syndrome
#ifndef GUNS
	if (isServer())
		getControls().setMousePosition(Vec2f(0,0));
#endif
*/
	if (!this.exists("CustomFlash") || (this.exists("CustomFlash") && !this.get_string("CustomFlash").empty()))
	{
		// Determine muzzleflash sprite
		const string muzzleflash_file = this.exists("CustomFlash") ? this.get_string("CustomFlash") : "flash_bullet";

		// Add muzzle flash
		CSpriteLayer@ flash = sprite.addSpriteLayer("muzzle_flash", muzzleflash_file, 16, 8, this.getTeamNum(), 0);
		if (flash !is null)
		{
			Animation@ anim = flash.addAnimation("default", 1, false);
			int[] frames = {0, 1, 2, 3, 4, 5, 6, 7};
			anim.AddFrames(frames);
			flash.SetRelativeZ(1.0f);
			flash.SetOffset(settings.MUZZLE_OFFSET);
			flash.SetFacingLeft(this.hasTag("CustomMuzzleLeft"));
			flash.SetVisible(false);
			//flash.setRenderStyle(RenderStyle::additive);
		}
	}

	/*GunModule[] modules = {};
	modules.push_back(TestModule());
	this.set("GunModules", modules);*/

	/*if (true)//(this.exists("GunModule"))
	{
		GunModule[]@ modules;
		this.get("GunModule", @modules);
		print("done");
		for (int a = 0; a < modules.length(); a++)
			modules[a].onModuleInit(this);
	}*/
}

void laserEffects(CBlob@ this, int id)
{
	if (!isClient()) return;

	bool laser_enabled = this.get_bool("laser_enabled");
	if (!laser_enabled) return;
	
	if (this.isInInventory()) return;
	//if (!this.get_bool("in_proximity")) return;

	string laser_texture = this.get_string("laser_texture");
	f32 laser_distance = this.get_f32("laser_distance");
	f32 falloff_start = this.get_f32("falloff_start");
	f32 laser_alpha_mod = this.get_f32("laser_alpha_mod");
	f32 falloff_max = this.get_f32("falloff_max");
	Vec2f laser_offset = this.get_Vec2f("laser_offset");
	Vec2f laser_hitpos = this.get_Vec2f("laser_hitpos");

	f32 angle = this.getAngleDegrees();
	if (this.isFacingLeft())
	{
		angle += 180;
		laser_offset.y = -laser_offset.y;
	}

	Vec2f pos = getDriver().getWorldPosFromScreenPos(this.getScreenPos());
	Vec2f thisPos = Vec2f_lerp(this.getOldPosition(), pos, getInterpolationFactor()) + laser_offset.RotateBy(angle);
	Vec2f endPos = thisPos + Vec2f(laser_distance, 0).RotateBy(angle);

	if (laser_hitpos != Vec2f(-1, -1))
	{
		endPos = laser_hitpos;
		laser_distance = (endPos - thisPos).Length();
	}

	Vec2f[] v_pos;
	Vec2f[] v_uv;
	SColor[] v_col;
	
	f32 halfWidth = 0.5f; // Adjust the width of the laser
	for (f32 i = 0; i < laser_distance; i += 1.0f)
	{
		Vec2f currPos = thisPos + Vec2f(i, 0).RotateBy(angle);
		f32 alpha = 1.0f;
		if (i > falloff_start)
		{
			alpha = 1.0f - ((i - falloff_start) / (laser_distance - falloff_start)) * falloff_max;
		}
		alpha = Maths::Clamp(alpha * laser_alpha_mod, 0.0f, 1.0f);

		SColor color = SColor(uint8(alpha * 255), 255, 255, 255);

		v_pos.push_back(currPos + Vec2f(-halfWidth, -halfWidth).RotateBy(angle));
		v_uv.push_back(Vec2f(0, 0));
		v_col.push_back(color);

		v_pos.push_back(currPos + Vec2f(halfWidth, -halfWidth).RotateBy(angle));
		v_uv.push_back(Vec2f(1, 0));
		v_col.push_back(color);

		v_pos.push_back(currPos + Vec2f(halfWidth, halfWidth).RotateBy(angle));
		v_uv.push_back(Vec2f(1, 1));
		v_col.push_back(color);

		v_pos.push_back(currPos + Vec2f(-halfWidth, halfWidth).RotateBy(angle));
		v_uv.push_back(Vec2f(0, 1));
		v_col.push_back(color);
	}

	Render::QuadsColored(laser_texture, -10.0f, v_pos, v_uv, v_col);
}

void onTick(CBlob@ this)
{
	this.Untag("just_shot");
	this.set_bool("in_proximity", inProximity(this, getLocalPlayerBlob()));
	
	if (this.hasTag("laser"))
	{
		this.set_Vec2f("laser_hitpos", Vec2f(-1, -1));
		f32 angle_deg = this.getAngleDegrees();

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point is null) return;
	
		CBlob@ holder = point.getOccupied();
		if (holder !is null)
		{
			Vec2f aimpos = holder.getAimPos();
			angle_deg = -(aimpos - this.getPosition()).Angle();
			if (this.isFacingLeft()) angle_deg += 180.0f;
		}

		Vec2f offset = this.get_Vec2f("laser_offset").RotateBy(angle_deg);
		HitInfo@[] hitInfos;
		if (getMap().getHitInfosFromRay(this.getPosition() + offset, (this.isFacingLeft() ? 180 : 0) + angle_deg, this.get_f32("laser_distance"), this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				if (hi.blob is null)
				{
					this.set_Vec2f("laser_hitpos", hi.hitpos);
					break;
				}
			}
		}
	}

	if (this.hasTag("a1") && getGameTime() >= this.get_u32("disable_a1")) this.Untag("a1");
	if (this.hasTag("hold") && getGameTime() >= this.get_u32("disable_hold")) this.Untag("hold");
	// Server will always get put back to sleep (doesnt need to run any of this)
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		if (holder !is null)
		{
			CSprite@ sprite = this.getSprite();
			f32 aimangle = getAimAngle(this, holder);
			f32 tempangle = aimangle;
			if (tempangle > 360.0f)
				tempangle -= 360.0f;
			else if (tempangle < -360.0f)
				tempangle += 360.0f;
			if (holder.isKeyPressed(key_action2))// || isBot)
			{
				u8 t = this.get_u8("a1time");
				
				this.Tag("a1");
				this.set_u32("disable_a1", getGameTime()+t);
			}

			this.set_f32("gun_recoil_current", Maths::Lerp(this.get_f32("gun_recoil_current"), 0, 0.45f));

			GunSettings@ settings;
			this.get("gun_settings", @settings);

			this.setInventoryName(this.get_string("inv_name")+" ("+this.get_u8("clip")+"/"+settings.TOTAL+")");

			// Case particle the gun uses
			string casing = this.exists("CustomCase") ? this.get_string("CustomCase") : "Case";
			f32 oAngle = (aimangle % 360) + 180;

			// Shooting
			const bool can_shoot = holder.isAttached() ? 
					   holder.isAttachedToPoint("PASSENGER") || holder.isAttachedToPoint("PILOT") : true;

			// Keys
			const bool pressing_shoot = (!this.get_bool("force_nofire") && (this.hasTag("CustomSemiAuto") ?
					   point.isKeyJustPressed(key_action1) || holder.isKeyJustPressed(key_action1) : //automatic
					   point.isKeyPressed(key_action1) || holder.isKeyPressed(key_action1))); //semiautomatic

			// Sound
			const f32 reload_pitch = settings.RELOAD_PITCH + XORRandom(settings.RELOAD_PITCH_RANDOM*100)/100.0f;
			const f32 cycle_pitch  = this.exists("CustomCyclePitch")  ? this.get_f32("CustomCyclePitch")  : 1.0f;
			const f32 shoot_volume = settings.FIRE_VOLUME;

			// Loop firing sound
			if (this.hasTag("CustomSoundLoop"))
			{
				sprite.SetEmitSoundPaused(!(pressing_shoot && this.get_u8("clip") > 0 && !this.get_bool("doReload")));
			}

			// Start reload sequence when pressing [R]
			CControls@ controls = holder.getControls();
			if (controls !is null && holder.isMyPlayer() && controls.isKeyJustPressed(KEY_KEY_R) &&
				!this.get_bool("beginReload") && !this.get_bool("doReload") && 
				this.get_u8("clip") < settings.TOTAL && HasAmmo(this))
			{
				this.set_bool("beginReload", true);
			}

			uint8 actionInterval = this.get_u8("actionInterval");
			if (actionInterval > 0)
			{
				actionInterval--; // Timer counts down with ticks

				if (this.exists("CustomCycle") && isClient())
				{
					// Custom cycle sequence 
					if ((actionInterval == settings.FIRE_INTERVAL / 2) && this.get_bool("justShot"))
					{
						sprite.PlaySound(this.get_string("CustomCycle"));
						//ParticleCase2(casing, this.getPosition(), this.isFacingLeft() ? oAngle : aimangle);
						this.set_bool("justShot", false);
					}
				}
			} 
			else if (this.get_bool("beginReload")) // Beginning of reload
			{
				// CLIENTSIDE ONLY
				// Start reload sequence
				f32 reload_time = settings.RELOAD_TIME;

				actionInterval = reload_time;

				CBitStream params;
				params.write_u8(actionInterval);
				this.SendCommand(this.getCommandID("sync_interval"), params);

				this.set_bool("beginReload", false);
				this.set_bool("doReload", true);

				if (HasAmmo(this) && this.get_u8("clip") < settings.TOTAL) 
				{
					if (!this.hasTag("CustomShotgunReload"))
						sprite.PlaySound(settings.RELOAD_SOUND, 1.0f, reload_pitch);
				}
			}
			else if (this.get_bool("doReload")) // End of reload
			{
				/*for (int a = 0; a < modules.length(); a++)
				{
					modules[a].onReload(this);
				}*/

				if (this.hasTag("CustomShotgunReload"))
				{
					if (HasAmmo(this) && this.get_u8("clip") < settings.TOTAL)
					{
						sprite.PlaySound(settings.RELOAD_SOUND, 1.0f, reload_pitch);
					}
					else if (this.exists("CustomReloadingEnding"))
					{
						actionInterval = settings.RELOAD_TIME * 2;
						sprite.PlaySound(this.get_string("CustomReloadingEnding"), 1.0f, cycle_pitch);
					}
				}

				if (holder.isMyPlayer() || (isServer() && holder.getBrain() !is null && holder.getBrain().isActive()))
				{
					Reload(this, holder);
				}

				if (this.hasTag("CustomShotgunReload")) this.set_bool("doReload", false);
			} 
			else if (pressing_shoot && can_shoot)
			{
				if (this.get_u8("clip") > 0)
				{
					/*for (int a = 0; a < modules.length(); a++)
					{
						modules[a].onFire(this);
					}*/

					// Shoot weapon
					actionInterval = settings.FIRE_INTERVAL;
					//bool accurateHit = !this.hasTag("sniper") && getGameTime() >= (this.get_u32("lastshot") + actionInterval * 5);
					//this.set_u32("lastshot", getGameTime());

					Vec2f fromBarrel = Vec2f((settings.MUZZLE_OFFSET.x / 3) * (this.isFacingLeft() ? 1 : -1), settings.MUZZLE_OFFSET.y + 1);
					fromBarrel = fromBarrel.RotateBy(aimangle);

					//bool a2 = holder.isKeyPressed(key_action2) || isBot;

					if ((settings.B_SPREAD != 0 && settings.B_PER_SHOT == 1))// || this.hasTag("sniper"))
					{
						f32 spr = settings.B_SPREAD;
						//f32 res = a2 ? 1 : 2;
						//if (!isBot)
						//{
						//	u8 sniperspr = this.hasTag("sniper") ? 5 : 0;
						//	if (!a2) spr += sniperspr;
						//	spr *= res;
						//}
						
						//if (!accurateHit) aimangle += XORRandom(2) != 0 ? -XORRandom(spr) : XORRandom(spr);
						aimangle += XORRandom(2) != 0 ? -XORRandom(spr) : XORRandom(spr);
					}

					if (holder.isMyPlayer() || (isServer() && holder.getPlayer() is null && holder.getBrain() !is null && holder.getBrain().isActive()))
					{
						if (this.exists("ProjBlob"))
						{
							shootProj(this, aimangle);

							if (isClient())
							{
								Recoil@ coil = Recoil(holder, settings.G_RECOIL, settings.G_RECOILT, settings.G_BACK_T, settings.G_RANDOMX, settings.G_RANDOMY);
								coil.onTick();
							}
						}
						else
						{
							this.Tag("just_shot");
							// Local hosts / clients will run this
							if (isClient())
							{
								shootGun(this.getNetworkID(), aimangle, holder.getNetworkID(), sprite.getWorldTranslation() + fromBarrel);
							}
							else // Server will run this
							{
								shootGun(this.getNetworkID(), aimangle, holder.getNetworkID(), this.getPosition() + fromBarrel);
							}
						}
					}

					// Shooting sound
					if (!this.hasTag("CustomSoundLoop"))
						sprite.PlaySound(settings.FIRE_SOUND, shoot_volume, settings.FIRE_PITCH + XORRandom(settings.FIRE_PITCH_RANDOM*100)/100.0f);

					// Gun 'kickback' anim
					this.set_f32("gun_recoil_current", this.exists("CustomGunRecoil") ? this.get_u32("CustomGunRecoil") : 3);

					CSpriteLayer@ flash = sprite.getSpriteLayer("muzzle_flash");
					if (flash !is null)
					{
						//Turn on muzzle flash
						flash.SetFrameIndex(0);
						flash.SetVisible(true);
					}

					if (isClient()) 
					{
						this.set_bool("justShot", true);
					}
				}
				else if (this.get_u8("clickReload") == 1 && HasAmmo(this))
				{
					// Start reload sequence if no ammo in gun
					actionInterval = settings.RELOAD_TIME;
					this.set_bool("beginReload", false);
					this.set_bool("doReload", true);
					sprite.PlaySound(settings.RELOAD_SOUND, 1.0f, reload_pitch);
				}
				else if (!this.get_bool("beginReload") && !this.get_bool("doReload") && !this.hasTag("custom_reload"))
				{
					// Gun empty sequence
					sprite.PlaySound(this.exists("CustomSoundEmpty") ? this.get_string("CustomSoundEmpty") : "Gun_Empty.ogg");	
					actionInterval = NO_AMMO_INTERVAL;
					this.set_u8("clickReload", 1);
				}
			}

			if (actionInterval != 0 || this.get_u8("actionInterval") != 0) this.set_u8("actionInterval", actionInterval);
			//if (getGameTime()%15==0)printf(""+this.get_u8("actionInterval"));

			sprite.ResetTransform();
			//sprite.RotateBy( aimangle, holder.isFacingLeft() ? Vec2f(-3,3) : Vec2f(3,3) );

			this.setAngleDegrees(aimangle);
			sprite.SetOffset(Vec2f(this.get_f32("gun_recoil_current"), 0)); //Recoil effect for gun blob
		}
	} 
	else 
	{
		if (isClient() && this.hasTag("CustomSoundLoop"))
		{
			// Turn off sound if detached
			this.getSprite().SetEmitSoundPaused(true);
		}
	}
}
