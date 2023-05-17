
//  BulletMain.as - Vamist


#include "Hitters.as";
#include "BulletTrails.as";
#include "BulletClass.as";
#include "BulletCase.as";
#include "InfantryCommon.as";

Random@ r = Random(12345);

BulletHolder@ BulletGrouped = BulletHolder();

Vertex[] v_r_bullet;
Vertex[] v_r_fade;

SColor white = SColor(255,255,255,255);
SColor eatUrGreens = SColor(255,0,255,0);
int FireGunID;
int FireVehicleID;
int FireShotgunID;

f32 FRAME_TIME = 0;
//

// Set commands, add render:: (only do this once)
void onInit(CRules@ this)
{
	Reset(this);

	if (isClient())
	{
		Render::addScript(Render::layer_postworld, "BulletMain", "GunRender", 0.0f);
		Render::addScript(Render::layer_prehud, "BulletMain", "GUIStuff", 0.0f);
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	r.Reset(12345);
	FireGunID     = this.addCommandID("fireGun");
	FireVehicleID = this.addCommandID("fireVehicleGun");
	FireShotgunID = this.addCommandID("fireShotgun");
	v_r_bullet.clear();
	v_r_fade.clear();
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	r.Reset(12345);
}

// Handles making every bullet go weeee
void onTick(CRules@ this)
{
	FRAME_TIME = 0;
	BulletGrouped.FakeOnTick(this);
}

void GunRender(int id)
{
	FRAME_TIME += Render::getRenderDeltaTime() * getTicksASecond();  // We are using this because ApproximateCorrectionFactor is lerped
	RenderingBullets();
}

void GUIStuff(int id)
{
	renderScreenpls();
}

void RenderingBullets() // Bullets
{
	BulletGrouped.FillArray(); // Fill up v_r_bullets
	if (v_r_bullet.length() > 0) // If there are no bullets on our screen, dont render
	{
		Render::RawQuads("Bullet2.png", v_r_bullet);

		if (g_debug == 0) // useful for lerp testing
		{
			v_r_bullet.clear();
		}
	}
}

void renderScreenpls() // Bullet ammo gui
{
	CBlob@ holder = getLocalPlayerBlob();           
	if (holder !is null) 
	{
		CAttachment@ aps =  holder.getAttachments();
		if (aps is null) return;
		CBlob@ b = aps.getAttachmentPointByName("PICKUP").getOccupied(); 
		CPlayer@ p = holder.getPlayer(); // get player holding this

		if (b !is null && p !is null) 
		{
			if (b.exists("clip")) // make sure its a valid gun
			{
				if (p.isMyPlayer() && b.isAttached())
				{
					uint8 clip = b.get_u8("clip");
					uint8 total = b.get_u8("total"); // get clip and ammo total for easy access later
					CControls@ controls = getControls();
					Vec2f pos = Vec2f(0,getScreenHeight()-80); // controls for screen position
					bool render = false; // used to save render time (more fps basically)

					if (controls !is null)
					{
						int length = (pos - controls.getMouseScreenPos() - Vec2f(-30,-35)).Length();
						// get length for 'fancy' invisiblty when mouse goes near it

						if (length < 256 && length > 0) // are we near it?
						{
							white.setAlpha(length);
							eatUrGreens.setAlpha(length);
							render = true;
						}
						else // check the reverse
						{
							length=-length;
							if(length < 256 && length > 0)
							{
								white.setAlpha(length);
								eatUrGreens.setAlpha(length);
								render = true;
							}
						}
					}

					Render::SetTransformScreenspace(); // set position for render
					Render::SetAlphaBlend(true); // since we are going to be doing the invisiblity thing

					pos = Vec2f(15,getScreenHeight() - 68); // positions for the GUI
					GUI::DrawText(clip+"/"+total, pos, eatUrGreens);

					pos = Vec2f(15,getScreenHeight() - 58);
				}
			}
		}      
	}
}

void onCommand(CRules@ rules, u8 cmd, CBitStream @params) 
{
	if (cmd == rules.getCommandID("fireGun"))
	{
		CBlob@ this = getBlobByNetworkID(params.read_netid());

		if (this !is null)
		{
			this.set_u32("no_more_proj", 0);
			if (this.hasTag("dead")) return;

			f32 angle = params.read_f32();
			const Vec2f pos = params.read_Vec2f();
			Vec2f aimpos = params.read_Vec2f();
			f32 bulletSpread = params.read_f32();
			u8 burstSize = params.read_u8();
			s8 type = params.read_s8(); // 0 normal, -1 shrapnel, 1 strong
			u32 timeSpawnedAt = params.read_u32();

			InfantryInfo@ infantry;
			if (!this.get("infantryInfo", @infantry )) return;

			if (this.get_u32("next_bullet") > getGameTime()) return;
			this.set_u32("next_bullet", getGameTime()+1);

			float damageBody = infantry.damage_body;
			float damageHead = infantry.damage_head;

			if (this.getPlayer() !is null)
			{
				if (getRules().get_string(this.getPlayer().getUsername() + "_perk") == "Sharp Shooter")
				{
					damageBody *= 1.33f; // 150%
					damageHead *= 1.33f;
				}
			}

			s8 bulletPen = infantry.bullet_pen;
			//CBlob@ proj = CreateBulletProj(this, arrowPos, arrowVel, damageBody, damageHead, bulletPen);

			if (this.hasTag("disguised")) this.set_u32("can_spot", getGameTime()+30); // camo perk interaction

			if (isServer())
			{
				if (this.get_u32("mag_bullets") > 0) this.set_u32("mag_bullets", this.get_u32("mag_bullets") - 1);
				this.Sync("mag_bullets", true);
			}

			const u32 magSize = infantry.mag_size;
			if (this.get_u32("mag_bullets") > magSize) this.set_u32("mag_bullets", magSize);
			if (isClient()) this.getSprite().PlaySound(infantry.shoot_sfx, 0.9f, (this.exists("shoot_pitch") ? this.get_f32("shoot_pitch") : 0.90f) + XORRandom(31) * 0.01f);
			
			for (u8 i = 0; i < burstSize; i++)
			{
				Vec2f spreadAimpos = aimpos;
				if (bulletSpread > 0.0f) spreadAimpos += Vec2f(bulletSpread * (0.5f - _infantry_r.NextFloat()), bulletSpread * (0.5f - _infantry_r.NextFloat()));
				angle = -(spreadAimpos - pos).Angle();
				
				BulletObj@ bullet = BulletObj(this, angle, pos, type, damageBody, damageHead, bulletPen, getGameTime(),
					this.get_s32("custom_hitter"), this.get_u8("TTL"), this.get_u8("speed"));

				CMap@ map = getMap();
				u32 time = timeSpawnedAt;

				for (; time < getGameTime(); time++) // Catch up to everybody else
				{
					bullet.onFakeTick(map);
				}


				BulletGrouped.AddNewObj(bullet);
			}
		}
	}
	if (cmd == rules.getCommandID("fireVehicleGun"))
	{
		CBlob@ this = getBlobByNetworkID(params.read_netid());
		CBlob@ gun = getBlobByNetworkID(params.read_netid());

		if (this !is null && gun !is null)
		{
			this.set_u32("no_more_proj", 0);
			if (this.hasTag("dead")) return;

			if (gun.get_u32("next_projectile") > getGameTime()) return;
			gun.set_u32("next_projectile", getGameTime()+1);

			f32 angle = params.read_f32();
			const Vec2f pos = params.read_Vec2f();
			Vec2f aimpos = params.read_Vec2f();
			f32 bulletSpread = params.read_f32();
			u8 burstSize = params.read_u8();
			s8 type = params.read_s8(); // 0 normal, -1 shrapnel, 1 strong
			f32 damageBody = params.read_f32();
			f32 damageHead = params.read_f32();
			s8 bulletPen = params.read_s8();
			u8 timetolive = params.read_u8();
			u8 speed = params.read_u8();
			s32 custom_hitter = params.read_s32();
			u32 timeSpawnedAt = params.read_u32();

			if (this.get_u32("next_bullet") > getGameTime()) return;
			this.set_u32("next_bullet", getGameTime()+1);

			for (u8 i = 0; i < burstSize; i++)
			{
				BulletObj@ bullet = BulletObj(this, angle, pos, type, damageBody, damageHead, bulletPen, getGameTime(),
					custom_hitter, timetolive, speed);

				CMap@ map = getMap();
				u32 time = timeSpawnedAt;

				for (; time < getGameTime(); time++) // Catch up to everybody else
				{
					bullet.onFakeTick(map);
				}


				BulletGrouped.AddNewObj(bullet);
			}

			if (gun.hasTag("machinegun"))
			{
				float overheat_mod = 1.0f;
		
				CAttachment@ aps = gun.getAttachments();
				if (aps !is null)
				{
					CBlob@ gunner = aps.getAttachmentPointByName("GUNNER").getOccupied();
					if (gunner !is null)
					{
						CPlayer@ p = gunner.getPlayer();
						if (p !is null)
						{
							if (getRules().get_string(p.getUsername() + "_perk") == "Operator")
							{
								overheat_mod = 0.5f;
							}
						}
					}
					else
					{
						return;
					}

					gun.add_f32("overheat", gun.get_f32("overheat_per_shot") * overheat_mod);
				}

				f32 anglereal = gun.isFacingLeft()? -angle + 180 : angle;
				Vec2f posreal = pos;
				Vec2f offset = Vec2f(-2, 0);
				Vec2f vel = Vec2f(500.0f / 16.5f * (gun.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);

				if (gun.getSprite() !is null)
				{
					gun.getSprite().PlaySound(gun.get_string("shoot sound"));
				}

				if (isClient())
				{
					ParticleAnimated("SmallExplosion3", (posreal + Vec2f(20, 0).RotateBy(gun.isFacingLeft()?-anglereal+180:anglereal)),
						getRandomVelocity(0.0f, XORRandom(40) * 0.01f, gun.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f),
							float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
				}

				float _angle = gun.isFacingLeft() ? -anglereal+180 : anglereal;
				_angle += -0.099f + (XORRandom(4) * 0.01f);

				bool no_muzzle = false;

				#ifdef STAGING
					no_muzzle = true;
				#endif

				if (!no_muzzle)
				{
					if (gun.isFacingLeft())
					{
						ParticleAnimated("Muzzleflash", posreal + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 90) + Vec2f(0.0f, -0.05f), _angle, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
					}
					else
					{
						ParticleAnimated("Muzzleflashflip", posreal + Vec2f(0.0f, 1.0f), getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 270) + Vec2f(0.0f, -0.05f), _angle + 180, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
					}
				}

				CPlayer@ p = getLocalPlayer();
				if (p !is null && !v_fastrender)
				{
					CBlob@ local = p.getBlob();
					if (local !is null)
					{
						CPlayer@ ply = local.getPlayer();

						if (ply !is null && ply.isMyPlayer())
						{
							const float recoilx = 15;
							const float recoily = 50;
							const float recoillength = 40; // how long to recoil (?)
	
							if (local.isAttachedTo(gun)) ShakeScreen(28, 5, pos);
	
							makeGibParticle(
							"EmptyShellSmall",               // file name
							posreal,                 // position
							(gun.isFacingLeft() ? -offset : offset) + Vec2f((-20 + XORRandom(40))/18,-1.1f),                           // velocity
							0,                                  // column
							0,                                  // row
							Vec2f(16, 16),                      // frame size
							0.2f,                               // scale?
							0,                                  // ?
							"ShellCasing",                      // sound
							gun.get_u8("team_color"));         // team number
	
							gun.getSprite().PlaySound("M60fire.ogg", 1.0f, 0.93f + XORRandom(10) * 0.01f);
						}		
					}
				}
			}
		}
	}
}