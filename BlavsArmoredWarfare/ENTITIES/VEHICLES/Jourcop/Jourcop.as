#include "Hitters.as";
#include "Explosion.as";

const Vec2f upVelo = Vec2f(0.00f, -0.015f);
const Vec2f downVelo = Vec2f(0.00f, 0.006f);
const Vec2f leftVelo = Vec2f(-0.031f, 0.00f);
const Vec2f rightVelo = Vec2f(0.031f, 0.00f);

const Vec2f minClampVelocity = Vec2f(-0.40f, -0.70f);
const Vec2f maxClampVelocity = Vec2f( 0.40f, 0.00f);

const f32 thrust = 1000.00f;

void onInit(CBlob@ this)
{
	this.set_string("custom_explosion_sound", "bigbomb_explosion.ogg");
	this.set_bool("map_damage_raycast", true);
	this.set_bool("UPF_Skin", false);
	this.set_u32("duration", 0);
	//this.getSprite().SetRelativeZ(-60.0f);
	
	this.addCommandID("play_music");
	this.addCommandID("stop_music");
	this.addCommandID("change_skin");

	this.Tag("vehicle");
	this.Tag("aerial");
	this.set_bool("lastTurn", false);
	this.set_bool("music", false);
	this.set_bool("glide", false);

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

	this.getCurrentScript().tickFrequency = 1;
}

void onInit(CSprite@ this)
{	
	//Add blade
	CSpriteLayer@ blade = this.addSpriteLayer("blade", "UHT_Blade.png", 67, 8);
	if (blade !is null)
	{
		Animation@ SPEEEN = blade.addAnimation("SPEEEN", 1, true);
		int[] frames = {1, 2, 3, 2};
		SPEEEN.AddFrames(frames);
		Animation@ stopped = blade.addAnimation("No speen?", 0, false);
		stopped.AddFrame(0);
		
		blade.SetAnimation("SPEEEN");
		blade.SetOffset(Vec2f(10.5, -21));
		blade.SetRelativeZ(-70.0f);
		blade.SetVisible(true);
	}
	
	//Add interior
	CSpriteLayer@ interior = this.addSpriteLayer("interior", "Jourcop_Interior.png", 34, 32);
	if (interior !is null)
	{
		interior.SetOffset(Vec2f(0, 1));
		interior.SetRelativeZ(-70.0f);
		interior.SetVisible(true);
	}
	
	//Add tail rotor
	CSpriteLayer@ tailrotor = this.addSpriteLayer("tailrotor", "UHT_TailRotor.png", 16, 16);
	if (tailrotor !is null)
	{
		Animation@ anim = tailrotor.addAnimation("default", 1, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		
		tailrotor.SetOffset(Vec2f(46.5, -7));
		tailrotor.SetRelativeZ(-70.0f);
		tailrotor.SetVisible(true);
	}
	
	//Add glass
	CSpriteLayer@ glass = this.addSpriteLayer("glass", "Jourcop_Glass.png", 32, 32);
	if (glass !is null)
	{
		glass.SetOffset(Vec2f(0, 0));
		glass.SetRelativeZ(300.0f);
		glass.SetVisible(true);
		glass.setRenderStyle(RenderStyle::additive);
	}
	
	//Add door
	CSpriteLayer@ door = this.addSpriteLayer("door", "Jourcop_Door.png", 32, 32);
	if (door !is null)
	{
		door.SetOffset(Vec2f(0, 1));
		door.SetRelativeZ(300.0f);
		door.SetVisible(false);
	}
	
	//Add seat
	CSpriteLayer@ seat = this.addSpriteLayer("seat", "Jourcop_Seat.png", 32, 32);
	if (seat !is null)
	{
		seat.SetOffset(Vec2f(0, 1));
		seat.SetRelativeZ(-70.0f);
		seat.SetVisible(false);
	}
	
	//Add glare
	CSpriteLayer@ glare = this.addSpriteLayer("glare", "Jourcop_Glare.png", 32, 32);
	if (glare !is null)
	{
		glare.SetOffset(Vec2f(0, 0));
		glare.SetRelativeZ(300.0f);
		glare.SetVisible(true);
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

		int size = aps.size();
		for(int a = 0; a < size; a++)
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

						const f32 mass = this.getMass();


							if (pressed_a) newForce += leftVelo;
							if (pressed_d) newForce += rightVelo;
							
							if (pressed_m1)this.set_bool("glide", true);
							else
							{
								this.set_bool("glide", false);
								if (pressed_w) newForce += upVelo;
								if (pressed_s) newForce += downVelo;
							}

						Vec2f mousePos = ap.getAimPos();
						CBlob@ pilot = ap.getBlob();
						
						if (pilot !is null && pressed_m2 && (this.getVelocity().x < 3.00f || this.getVelocity().x > -3.00f))
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
		Vec2f targetForce;
		Vec2f currentForce = this.get_Vec2f("current_force");
		CBlob@ pilot = this.getAttachmentPoint(0).getOccupied();
		if (pilot !is null)
		{
			targetForce = this.get_Vec2f("target_force") + newForce;
			if (this.get_bool("glide")) targetForce = Vec2f(targetForce.x, -0.5890000005);
		}
		else targetForce = Vec2f(0, 0);
		
		
		CSpriteLayer@ seat = this.getSprite().getSpriteLayer("seat");
		
		CSpriteLayer@ door = this.getSprite().getSpriteLayer("door");
		CSpriteLayer@ glass = this.getSprite().getSpriteLayer("glass");
		CSpriteLayer@ glare = this.getSprite().getSpriteLayer("glare");
		
		if (pilot !is null)
		{
			if (this.getTeamNum() == 250 || this.get_bool("UPF_Skin")) door.SetVisible(true);
			else seat.SetVisible(true);
			
			door.SetRelativeZ(300.0f);
			glass.SetRelativeZ(300.0f);
			glare.SetRelativeZ(300.0f);
		}
		else
		{
			door.SetVisible(false);
			seat.SetVisible(false);
			
			door.SetRelativeZ(0.0f);
			glass.SetRelativeZ(0.0f);
			glare.SetRelativeZ(0.0f);
		}

		f32 targetForce_y = Maths::Clamp(targetForce.y, minClampVelocity.y, maxClampVelocity.y);

		Vec2f clampedTargetForce = Vec2f(Maths::Clamp(targetForce.x, Maths::Max(minClampVelocity.x, -Maths::Abs(targetForce_y)), Maths::Min(maxClampVelocity.x, Maths::Abs(targetForce_y))), targetForce_y);
		
		Vec2f resultForce;
		//if(!this.get_bool("glide"))
		//{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), Lerp(currentForce.y, clampedTargetForce.y, lerp_speed_y));
			this.set_Vec2f("current_force", resultForce);
		//}
		//else
		//{
		//	resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), -0.5890000005);
		//	this.set_Vec2f("current_force", resultForce);
		//}

		this.AddForce(resultForce * thrust);
		this.setAngleDegrees(resultForce.x * 80.00f);
		
		int anim_time_formula = Maths::Floor(1.00f + (1.00f - Maths::Abs(resultForce.getLength())) * 3) % 4;
		if (this.get_Vec2f("current_force").getLength() > 0.6) anim_time_formula = 1;
		
		if (this.get_Vec2f("current_force").getLength() < 0.02)
		{
			blade.SetAnimation("No speen?");
			blade.animation.time = 0;
			
			tailrotor.SetFrameIndex(0);
			tailrotor.animation.time = 0;
		} else
		{
			blade.animation.time = anim_time_formula;
			blade.SetAnimation("SPEEEN");
			
			tailrotor.animation.time = anim_time_formula;
		}
		
		sprite.SetEmitSoundSpeed(Maths::Min(0.0001f + Maths::Abs(resultForce.getLength() * 1.50f), 1.10f) * 1.8);

		this.set_Vec2f("target_force", clampedTargetForce);
	}
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
	if (attached !is null && attached.getTeamNum() != this.getTeamNum())
	{
		if (attached.hasTag("player"))
		{
			this.server_setTeamNum(100);
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

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	Vec2f buttonPos;
	buttonPos = Vec2f(-8, 2);
	if (caller.getTeamNum() == this.getTeamNum())
	{
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null)
		{
			if (this.get_bool("music") == false)
			{
				if(carried.getName() == "musicdisc")
				{
					u16 carried_netid = carried.getNetworkID();
		
					CBitStream params;
					params.write_u16(carried_netid);
					
					caller.CreateGenericButton("$musicdisc$", buttonPos, this, this.getCommandID("play_music"), "Make it play funny music.", params);
				}
			} else 
			if(this.get_bool("music") == true){
				if(carried.getName() == "wrench")
					caller.CreateGenericButton("$icon_wrench$", buttonPos, this, this.getCommandID("stop_music"), "Stop the music.");
			}
			if(carried.getName() == "paper")
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				params.write_u16(carried.getNetworkID());
		
				CButton@ buttonWrite = caller.CreateGenericButton("$icon_paper$", buttonPos, this, this.getCommandID("change_skin"),
				"Change vehicle skin.", params);
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	switch (customData)
	{
		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:
			dmg *= 0.25f;
			break;
		case Hitters::bomb:
			dmg *= 1.25f;
			break;
		case Hitters::keg:
		case Hitters::explosion:
			dmg *= 0.5f;
			break;
		case Hitters::bomb_arrow:
			dmg *= 0.5f;
			break;
		case Hitters::flying:
			dmg *= 0.5f;
			break;
	}
	return dmg;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("change_skin"))
	{
		if (isServer())
		{
			CBlob @caller = getBlobByNetworkID(params.read_u16());
			CBlob @carried = getBlobByNetworkID(params.read_u16());

			if (caller !is null && carried !is null)
			{
				if (carried.get_string("text") == "upfskin") this.set_bool("UPF_Skin", true);
				else this.set_bool("UPF_Skin", false);
			}
		}
	}
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

	AttachmentPoint@ gunner = blob.getAttachments().getAttachmentWithBlob(localBlob);
	if (gunner !is null)
	{

	}

	Vec2f mouseWorld = getControls().getMouseWorldPos();
	bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
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
	
	if (this.exists("bladeid"))
	{
		CBlob@ blade = getBlobByNetworkID(this.get_u16("bladeid"));
		if (blade !is null)
		{
			blade.server_Die();
		}
	}
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

	if (isServer())
	{
		for (int i = 0; i < (5 + XORRandom(5)); i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, this.getPosition());
			blob.setVelocity(Vec2f(XORRandom(10) - 5, -XORRandom(10)));
			blob.server_SetTimeToDie(10 + XORRandom(5));
		}
	}

	if (isClient())
	{
		for (int i = 0; i < 40; i++)
		{
			MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(angle, XORRandom(400) * 0.01f, 70), particles[XORRandom(particles.length)]);
		}
	}

	this.getSprite().Gib();
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	CSpriteLayer@ glass = this.getSprite().getSpriteLayer("glass");
	glass.setRenderStyle(RenderStyle::additive);
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1 + XORRandom(200) * 0.01f, 2 + XORRandom(5), XORRandom(100) * -0.00005f, true);
}