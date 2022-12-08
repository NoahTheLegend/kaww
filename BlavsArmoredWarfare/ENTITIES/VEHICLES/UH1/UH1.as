#include "WarfareGlobal.as"
#include "Hitters.as";
#include "Explosion.as";

const Vec2f upVelo = Vec2f(0.00f, -0.015f);
const Vec2f downVelo = Vec2f(0.00f, 0.0050f);
const Vec2f leftVelo = Vec2f(-0.0225f, 0.00f);
const Vec2f rightVelo = Vec2f(0.0225f, 0.00f);

const Vec2f minClampVelocity = Vec2f(-0.40f, -0.70f);
const Vec2f maxClampVelocity = Vec2f( 0.40f, 0.00f);

const f32 thrust = 1020.00f;

const u8 cooldown_time = 15;//210;
const u8 recoil = 0;

const s16 init_gunoffset_angle = -3; // up by so many degrees

// 0 == up, 90 == sideways
const f32 high_angle = 85.0f; // upper depression limit
const f32 low_angle = 115.0f; // lower depression limit

void onInit(CBlob@ this)
{
	this.set_bool("map_damage_raycast", true);
	this.set_u32("duration", 0);
	//this.getSprite().SetRelativeZ(-60.0f);

	this.Tag("vehicle");
	this.Tag("aerial");
	this.Tag("has machinegun");
	
	this.set_bool("lastTurn", false);
	this.set_bool("music", false);
	this.set_bool("glide", false);

	this.addCommandID("shoot bullet");

	if (this !is null)
	{
		CShape@ shape = this.getShape();
		if (shape !is null)
		{
			shape.SetRotationsAllowed(false);
		}
	}

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.offsetZ = 10.0f;
			ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
		}
	}

	//add javlauncher
	if (getNet().isServer())
	{
		CBlob@ launcher = server_CreateBlob("launcher_javelin");	

		if (launcher !is null)
		{
			launcher.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo(launcher, "JAVLAUNCHER");
			this.set_u16("launcherid", launcher.getNetworkID());

			launcher.SetFacingLeft(this.isFacingLeft());
		}
	}

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "UHT_Launcher", 16, 16);

	if (arm !is null)
	{
		f32 angle = low_angle;

		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(20);

		CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
		if (arm !is null)
		{
			arm.SetRelativeZ(0.5f);
			arm.SetOffset(Vec2f(-32.0f, 10.0f));
		}
	}

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	if (isServer())
	{
		CBlob@ bow = server_CreateBlob("heavygun");	
	
		if (bow !is null)
		{
			bow.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo( bow, "BOW" );
			this.set_u16("bowid", bow.getNetworkID());
			bow.SetFacingLeft(this.isFacingLeft());
		}
	
		this.inventoryButtonPos = Vec2f(-8.0f, 0);
	}
}

void onInit(CSprite@ this)
{	
	this.SetRelativeZ(-20.0f);
	//Add blade
	CSpriteLayer@ blade = this.addSpriteLayer("blade", "UH_Blade.png", 92, 8);
	if (blade !is null)
	{
		Animation@ anim = blade.addAnimation("default", 1, true);
		int[] frames = {1, 2, 3, 2};
		anim.AddFrames(frames);
		
		blade.SetOffset(Vec2f(-5, -26));
		blade.SetRelativeZ(20.0f);
		blade.SetVisible(true);
	}

	//Add tail rotor
	CSpriteLayer@ tailrotor = this.addSpriteLayer("tailrotor", "UH_TailRotor.png", 16, 16);
	if (tailrotor !is null)
	{
		Animation@ anim = tailrotor.addAnimation("default", 1, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		
		tailrotor.SetOffset(Vec2f(58.0, -9));
		tailrotor.SetRelativeZ(20.0f);
		tailrotor.SetVisible(true);
	}

	this.SetEmitSound("Eurokopter_Loop.ogg");
	this.SetEmitSoundSpeed(0.01f);
	this.SetEmitSoundPaused(false);
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

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onTick(CBlob@ this)
{
	if (this !is null)
	{
		if (this.hasTag("falling"))
		{
			if (getGameTime()%9==0)
				this.getSprite().PlaySound("FallingAlarm.ogg", 1.5f, 1.15f);
		}
		if (getGameTime() >= this.get_u32("next_shoot"))
		{
			this.Untag("no_more_shooting");
			this.Untag("no_more_proj");
		}
		if (this.getVelocity().x > 6.25f || this.getVelocity().x < -6.25f) this.setVelocity(Vec2f(this.getOldVelocity().x, this.getVelocity().y));

		if (this.getPosition().y < 70.0f && this.getVelocity().y < 0.5f)
		{
			//this.setVelocity(Vec2f(this.getVelocity().x, this.getVelocity().y*0.16f));
			this.AddForce(Vec2f(0, 220.0f));
		}

		for (u8 i = 0; i < 2; i++)
		{
			{
				AttachmentPoint@ pass = this.getAttachments().getAttachmentPointByName("PASSENGER");
				if (i == 0) @pass = this.getAttachments().getAttachmentPointByName("PASSENGER1");
				if (pass !is null && pass.getOccupied() !is null)
				{
					CBlob@ b = pass.getOccupied();
					if (b !is null)
					{
						if (pass.isKeyPressed(key_action1)) b.set_bool("is_a1", true);
						if (pass.isKeyJustPressed(key_action1)) b.set_bool("just_a1", true);
						b.Tag("show_gun");
						b.Tag("can_shoot_if_attached");

						//if (b.isKeyPressed(key_action1)) printf("e");

						if (b.getAimPos().x < b.getPosition().x) b.SetFacingLeft(true);
						else b.SetFacingLeft(false);
					}
				}
			}
		}

		bool has_ammo = false;

		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("JAVLAUNCHER");
		if (this.get_u32("next_shoot") < getGameTime() && ap !is null)
		{
			CBlob@ launcher = ap.getOccupied();
			if (launcher !is null && launcher.hasTag("dead"))
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null && inv.getItem("mat_heatwarhead") !is null)
				{
					has_ammo = true;
					if (isServer()) inv.server_RemoveItems("mat_heatwarhead", 1);
					launcher.Untag("dead");
					this.set_u32("next_shoot", getGameTime()+75);
				}
			}
		}

		this.set_bool("has_ammo", has_ammo);

		CSprite@ sprite = this.getSprite();
		CShape@ shape = this.getShape();
		Vec2f currentVel = this.getVelocity();
		f32 angle = shape.getAngleDegrees();

		const bool flip = this.isFacingLeft();

		Vec2f newForce = Vec2f(0, 0);

		AttachmentPoint@[] aps;
		this.getAttachmentPoints(@aps);
		
		CSpriteLayer@ blade = sprite.getSpriteLayer("blade");
		CSpriteLayer@ tailrotor = sprite.getSpriteLayer("tailrotor");
		for(int a = 0; a < aps.length; a++)
		{
			AttachmentPoint@ ap = aps[a];
			if (ap !is null)
			{
				CBlob@ hooman = ap.getOccupied();
				if (hooman !is null)
				{
					if (ap.name == "DRIVER")
					{
						const bool pressed_w  = ap.isKeyPressed(key_up);
						const bool pressed_s  = ap.isKeyPressed(key_down);
						const bool pressed_a  = ap.isKeyPressed(key_left);
						const bool pressed_d  = ap.isKeyPressed(key_right);
						const bool pressed_c  = ap.isKeyPressed(key_pickup);
						const bool pressed_m1 = ap.isKeyPressed(key_action1);
						const bool pressed_m2 = ap.isKeyPressed(key_action2);

						// shoot
						/*
						if (!this.hasTag("no_more_shooting") && hooman.isMyPlayer() && ap.isKeyPressed(key_action3) && this.get_u32("next_shoot") < getGameTime())
						{
							CInventory@ inv = this.getInventory();
							if (inv !is null && inv.getItem(0) !is null && inv.getItem(0).getName() == "mat_heatwarhead")
							{
								if (!this.hasTag("no_more_shooting")) this.getSprite().PlaySound("Missile_Launch.ogg", 1.25f, 0.95f + XORRandom(15) * 0.01f);
								f32 rot = 1.0f;
								if (this.isFacingLeft()) rot = -1.0f;
								ShootBullet(this, this.getPosition()+Vec2f(54.0f*rot, 0).RotateBy(angle), this.getPosition()+Vec2f(64.0f*rot, 0).RotateBy(angle), 30.0f);
								this.Tag("no_more_shooting");
							}
						}
						*/
						const f32 mass = this.getMass();

						if (!this.hasTag("falling"))
						{
							if (pressed_a) newForce += leftVelo;
							if (pressed_d) newForce += rightVelo;

							if (pressed_m1) this.set_bool("glide", true);
							else
							{
								this.set_bool("glide", false);
								if (pressed_w) newForce += upVelo;
								if (pressed_s) newForce += downVelo;
							}
						}
						else
						{
							newForce -= Vec2f(upVelo.x*0.45f, upVelo.y*0.45f);
							this.set_bool("glide", false);
						}

						Vec2f mousePos = ap.getAimPos();
						CBlob@ pilot = ap.getBlob();
						
						if (!this.hasTag("falling"))
						{
							if (pilot !is null && pressed_m2 && (this.getVelocity().x < 5.00f || this.getVelocity().x > -5.00f))
							{
								if (mousePos.x < pilot.getPosition().x) this.SetFacingLeft(true);
								else if (mousePos.x > pilot.getPosition().x) this.SetFacingLeft(false);
							}
							else if (this.getVelocity().x < -0.50f)
								this.SetFacingLeft(true);
							else if (this.getVelocity().x > 0.50f)
								this.SetFacingLeft(false);
						}
					}
				}
			}
		}
		Vec2f targetForce;
		Vec2f currentForce = this.get_Vec2f("current_force");
		CBlob@ pilot = this.getAttachmentPoint(0).getOccupied();
		if (pilot !is null) targetForce = this.get_Vec2f("target_force") + newForce;
		else targetForce = Vec2f(0, 0);

		f32 targetForce_y = Maths::Clamp(targetForce.y, minClampVelocity.y, maxClampVelocity.y);

		Vec2f clampedTargetForce = Vec2f(Maths::Clamp(targetForce.x, Maths::Max(minClampVelocity.x, -Maths::Abs(targetForce_y)), Maths::Min(maxClampVelocity.x, Maths::Abs(targetForce_y))), targetForce_y);

		Vec2f resultForce;
		if(!this.get_bool("glide"))
		{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), Lerp(currentForce.y, clampedTargetForce.y, lerp_speed_y));
			this.set_Vec2f("current_force", resultForce);
		}
		else
		{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), -0.5890000005);
			this.set_Vec2f("current_force", resultForce);
		}

		if (this.hasTag("falling") && !this.hasTag("set_force"))
		{
			this.Tag("set_force");
			this.set_Vec2f("result_force", resultForce);
		}

		this.AddForce(resultForce * thrust);
		this.setAngleDegrees(resultForce.x * 75.00f);
		if (this.hasTag("falling"))
		{
			this.setAngleDegrees(this.get_Vec2f("result_force").x * 75.00f);
		}
		
		int anim_time_formula = Maths::Floor(1.00f + (1.00f - Maths::Abs(resultForce.getLength())) * 3) % 4;
		if (this.hasTag("falling")) anim_time_formula = Maths::Floor(1.00f + (1.00f - Maths::Abs(this.get_Vec2f("result_force").getLength())) * 3) % 4;
		blade.ResetTransform();
		blade.SetOffset(Vec2f(-4, -26));
		blade.animation.time = anim_time_formula;
		if (blade.animation.time == 0)
		{
			blade.SetOffset(Vec2f(-5, -26));
			blade.SetFrameIndex(0);
			blade.RotateBy(180, Vec2f(0.0f,2.0f));
		}
		
		if (sprite !is null && this.hasTag("falling"))
		{
			if (getGameTime() % 8 == 0)
			{
				sprite.SetFacingLeft(!sprite.isFacingLeft());
			}
		}

		tailrotor.animation.time = anim_time_formula;
		if (tailrotor.animation.time == 0)
		{
			tailrotor.SetFrameIndex(1);
		}
		
		sprite.SetEmitSoundSpeed(Maths::Min(0.00005f + Maths::Abs(resultForce.getLength() * 1.00f), 0.85f) * 1.55);
		if (this.hasTag("falling")) sprite.SetEmitSoundSpeed(Maths::Min(0.00005f + Maths::Abs(this.get_Vec2f("result_force").getLength() * 1.00f), 0.85f) * 1.55);

		this.set_Vec2f("target_force", clampedTargetForce);
	}
}

void ShootBullet(CBlob @this, Vec2f arrowPos, Vec2f aimpos, f32 arrowspeed)
{
	Vec2f arrowVel = (aimpos - arrowPos);
	arrowVel.Normalize();
	arrowVel *= arrowspeed;
	CBitStream params;
	params.write_Vec2f(arrowPos);
	params.write_Vec2f(arrowVel);

	this.SendCommand(this.getCommandID("shoot bullet"), params);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer() && solid && this.hasTag("falling"))
		this.server_Die();
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot bullet"))
	{
		this.set_u32("next_shoot", getGameTime()+15);
		Vec2f arrowPos;
		if (!params.saferead_Vec2f(arrowPos)) return;
		Vec2f arrowVel;
		if (!params.saferead_Vec2f(arrowVel)) return;

		if (getNet().isServer() && !this.hasTag("no_more_proj"))
		{
			CBlob@ proj = CreateProj(this, arrowPos, arrowVel);
			
			proj.set_f32(projExplosionRadiusString, 25.0f);
			proj.set_f32(projExplosionDamageString, 10.0f);

			proj.set_s8(penRatingString, 1);

			proj.server_SetTimeToDie(8);

			CInventory@ inv = this.getInventory();
			if (inv !is null && inv.getItem(0) !is null && inv.getItem(0).getName() == "mat_heatwarhead")
			{
				inv.getItem(0).server_SetQuantity(inv.getItem(0).getQuantity()-1);
			}
		} 
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return this.getTeamNum() == forBlob.getTeamNum();
}

CBlob@ CreateProj(CBlob@ this, Vec2f arrowPos, Vec2f arrowVel)
{
	if (!this.hasTag("no_more_proj"))
	{
		CBlob@ proj = server_CreateBlobNoInit("ballista_bolt");
		if (proj !is null)
		{
			proj.SetDamageOwnerPlayer(this.getPlayer());
			proj.Init();

			proj.set_f32("bullet_damage_body", 6.0f);
			proj.set_f32("bullet_damage_head", 8.0f);
			proj.IgnoreCollisionWhileOverlapped(this);
			proj.server_setTeamNum(this.getTeamNum());
			proj.setVelocity(arrowVel);
			proj.setPosition(arrowPos+Vec2f(0, 12.0f));
		}
		this.Tag("no_more_proj");
		return proj;
	}
	else
		return null;
}

const f32 lerp_speed_x = 0.20f;
const f32 lerp_speed_y = 0.20f;

f32 Lerp(f32 a, f32 b, f32 time)
{
	return a + (b - a) * time;
}

f32 constrainAngle(f32 x)
{
	x = (x + 180) % 360;
	if (x < 0) x += 360;
	return x - 180;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		this.Tag("no barrier pass");
	}
	if (attached !is null)
	{
		if (attached.hasTag("player") && attached.getTeamNum() != this.getTeamNum())
		{
			this.server_setTeamNum(attached.getTeamNum());
		}
		
		if (attached.getName() != "donotspawnthiswithacommand")
		{
			attached.Tag("invincible");
			attached.Tag("invincibilityByVehicle");
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		detached.setVelocity(this.getVelocity());
		detached.AddForce(Vec2f(0.0f, -300.0f));
		this.Untag("no barrier pass");
	}
	if (detached !is null)
	{
		detached.Untag("show_gun");
	detached.Untag("can_shoot_if_attached");
		detached.Untag("invincible");
		detached.Untag("invincibilityByVehicle");
	}
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (!blob.isCollidable() || blob.isAttached()){
		return false;
	} // no colliding against people inside vehicles
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void onRender(CSprite@ this)
{
	if (this is null) return; //can happen with bad reload

	// draw only for local player
	CBlob@ blob = this.getBlob();
	CBlob@ localBlob = getLocalPlayerBlob();

	if (blob is null)
	{
		return;
	}

	if (localBlob is null)
	{
		return;
	}
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(8, 0).RotateBy(this.getAngleDegrees());
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void onDie(CBlob@ this)
{
	DoExplosion(this);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("JAVLAUNCHER");
	if (ap !is null)
	{
		CBlob@ launcher = ap.getOccupied();
		if (launcher !is null) launcher.server_Die();
	}
	AttachmentPoint@ ap1 = this.getAttachments().getAttachmentPointByName("bow");
	if (ap1 !is null)
	{
		CBlob@ launcher = ap.getOccupied();
		if (launcher !is null) launcher.server_Die();
	}
	
	if (this.exists("bladeid"))
	{
		CBlob@ blade = getBlobByNetworkID(this.get_u16("bladeid"));
		if (blade !is null)
		{
			blade.server_Die();
		}
	}
	if (this.exists("bowid"))
	{
		CBlob@ bow = getBlobByNetworkID(this.get_u16("bowid"));
		if (bow !is null)
		{
			bow.server_Die();
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("ignore damage")) return 0;
	if (damage >= this.getHealth())
	{
		this.Tag("ignore damage");
		this.Tag("falling");
		this.set_u32("falling_time", getGameTime());
		return 0;
	}
	if (hitterBlob.getName() == "missile_javelin")
	{
		return damage * 0.85f;
	}
	else if (hitterBlob.hasTag("bullet"))
	{
		return damage * (hitterBlob.hasTag("strong") ? 0.5f : 0.25f);
	}
	return damage;
}

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();

	this.set_f32("map_damage_radius", 48.0f);
	this.set_f32("map_damage_ratio", 0.4f);
	f32 angle = this.get_f32("bomb angle");

	Explode(this, 100.0f, 50.0f);

	for (int i = 0; i < 4; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 40);
		LinearExplosion(this, dir, 40.0f + XORRandom(64), 48.0f, 6, 0.5f, Hitters::explosion);
	}

	Vec2f pos = this.getPosition() + this.get_Vec2f("explosion_offset").RotateBy(this.getAngleDegrees());
	CMap@ map = getMap();

	if (isClient())
	{
		for (int i = 0; i < 40; i++)
		{
			MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(angle, XORRandom(400) * 0.01f, 70), particles[XORRandom(particles.length)]);
		}
	}

	this.getSprite().Gib();
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1 + XORRandom(200) * 0.01f, 2 + XORRandom(5), XORRandom(100) * -0.00005f, true);
}