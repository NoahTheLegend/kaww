#include "Explosion.as"
#include "WarfareGlobal.as"
const string target_player_id = "target_player_id";

void onInit(CBlob@ this)
{
	this.addCommandID("shoot");

	this.set_bool("spawned", false);
	this.set_u16(target_player_id, 0);

	this.set_u32("next repair", 0);

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "DefenseTurret_gun", 48, 32);
	this.Tag("builder always hit");


	this.Tag("structure");
	this.Tag("vehicle");
	this.Tag("turret");

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("defaultarm", 0, false);
		arm.SetOffset(Vec2f(-8.0f, -11.0f));
		arm.SetRelativeZ(100.0f);

		arm.animation.frame = 2;
	}

	bool facing_left = this.getTeamNum() == 1 ? true : false;
	this.SetFacingLeft(facing_left);

	this.getShape().SetRotationsAllowed(false);

	sprite.SetZ(20.0f);
}


void onTick(CBlob@ this)
{
	u16 target = this.get_u16(target_player_id); //target's netid

	CBlob@ targetblob = getBlobByNetworkID(this.get_u16(target_player_id)); //target's blob

	this.getCurrentScript().tickFrequency = 12;

	if (this.get_u16(target_player_id) == 0) // don't have a target
	{		
		@targetblob = getNewTarget( this, true, true);
		if (targetblob !is null)
		{
			this.set_u16(target_player_id, targetblob.getNetworkID());	
			this.Sync(target_player_id, true);
		}
	}
	else // i got a target
	{
		if (targetblob !is null && this.getDistanceTo(targetblob) < 735.0f)
		{
			this.getCurrentScript().tickFrequency = 1;

			f32 distance;
			const bool visibleTarget = isVisible(this, targetblob, distance);
			if (visibleTarget && distance < 735.0f)
			{
				if (this.get_u32("next shot") < getGameTime())
				{
					ClientFire(this);
					this.SendCommand(this.getCommandID("shoot"));
					this.set_bool("spawned", false);		

					this.set_u32("next shot", getGameTime() + 7);			
				}
			}

			LoseTarget(this, targetblob);

			if (XORRandom(200) == 0)
			{
				this.set_u16(target_player_id, 0);
				this.Sync(target_player_id, true);
			}
		}
		else this.set_u16(target_player_id, 0);
	}

	//angle
	f32 angle = getAimAngle(this);
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

	if (arm !is null)
	{
		bool facing_left = sprite.isFacingLeft();
		//f32 rotation = angle * (facing_left ? -1 : 1);

		arm.ResetTransform();
		arm.SetFacingLeft(facing_left);
		arm.RotateBy(angle, Vec2f(facing_left ? -9.0f : 8.0f, 7.0f));
	}
}

void ClientFire(CBlob@ this)
{
	Vec2f pos_2 = this.getPosition()-Vec2f(0.0f, 7.0f);
	f32 angle = getAimAngle(this);
	angle += ((XORRandom(512) - 256) / 76.0f);
	Vec2f vel = Vec2f(490.0f / 16.5f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);

	this.SendCommand(this.getCommandID("shoot"));

	makeGibParticle(
		"EmptyShellSmall",               // file name
		this.getPosition() + Vec2f(0.0f, -6),                 // position
		Vec2f((this.isFacingLeft() ? 1 : -1)*2+XORRandom(3),-1.2f),           // velocity
		0,                                  // column
		0,                                  // row
		Vec2f(16, 16),                      // frame size
		0.2f,                               // scale?
		0,                                  // ?
		"ShellCasing",                      // sound
		this.get_u8("team_color"));         // team number

	if (isClient())
	{
		this.getSprite().PlaySound("DefenseTurretShoot.ogg", 1.1f, 0.90f + XORRandom(25) * 0.01f);

		ParticleAnimated("SmallExplosion3", (pos_2) + vel*0.8, getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);

		bool no_muzzle = false;

		#ifdef STAGING
			no_muzzle = true;
		#endif

		if (!no_muzzle)
		{
			if (this.isFacingLeft())
			{
				ParticleAnimated("Muzzleflashflip", pos_2 - Vec2f(0.0f, 3.0f) + vel*0.16, getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 90) + Vec2f(0.0f, -0.05f), angle, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
			}
			else
			{
				ParticleAnimated("Muzzleflashflip", pos_2 + Vec2f(0.0f, 3.0f) + vel*0.16, getRandomVelocity(0.0f, XORRandom(3) * 0.01f, 270) + Vec2f(0.0f, -0.05f), angle + 180, 0.1f + XORRandom(3) * 0.01f, 2 + XORRandom(2), -0.15f, false);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot"))
	{

		if (getNet().isServer())
		{
			if (!this.get_bool("spawned"))
			{
				CBlob@ bullet = server_CreateBlobNoInit("bulletheavy");

				if (bullet !is null)
				{
					this.set_bool("spawned", true);
					bullet.Init();

					bullet.set_s8(penRatingString, 1);

					bullet.set_f32("bullet_damage_body", 0.18f);
					bullet.set_f32("bullet_damage_head", 0.18f);
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					Vec2f pos_ = this.getPosition()-Vec2f(0.0f, 7.0f);
					bullet.setPosition(pos_);

					f32 angle = getAimAngle(this);
					angle += ((XORRandom(512) - 256) / 132.0f);
					Vec2f vel = Vec2f(530.0f / 16.5f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
					bullet.setVelocity(vel);

				}
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}


bool LoseTarget(CBlob@ this, CBlob@ targetblob)
{
	if (XORRandom(19) == 0 && targetblob.hasTag("dead"))
	{
		this.set_u16(target_player_id, 0);
		this.Sync(target_player_id, true);

		return true;
	}
	return false;
}

CBlob@ getNewTarget(CBlob @blob, const bool seeThroughWalls = false, const bool seeBehindBack = false)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f pos = blob.getPosition();
	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();
		f32 distance;
		if (potential !is blob && blob.getTeamNum() != potential.getTeamNum()
		        && (pos2 - pos).getLength() < 700.0f
		        && !potential.hasTag("dead")
		        && (XORRandom(200) == 0 || isVisible(blob, potential, distance))
		   )
		{
			return potential;
		}
	}
	return null;
}

bool isVisible(CBlob@ blob, CBlob@ targetblob, f32 &out distance)
{
	Vec2f col;
	bool visible = !getMap().rayCastSolid(blob.getPosition(), targetblob.getPosition() + targetblob.getVelocity() * 2.0f, col);
	distance = (blob.getPosition() - col).getLength();
	return visible;
}

f32 getAimAngle(CBlob@ this)
{
	CBlob@ targetblob = getBlobByNetworkID(this.get_u16(target_player_id)); //target's blob

	f32 angle = 0;
	bool facing_left = this.isFacingLeft();

	bool failed = true;

	if (targetblob !is null)
	{
		Vec2f aim_vec = (this.getPosition() - Vec2f(0.0f, 10.0f)) - (targetblob.getPosition() + Vec2f(0.0f, -4.0f) + targetblob.getVelocity() * 5.0f);

		aim_vec += Vec2f(0, (this.getPosition() - targetblob.getPosition()).getLength() / 55.0f);

		if ((!facing_left && aim_vec.x < 0) ||
		        (facing_left && aim_vec.x > 0))
		{

			angle = (-(aim_vec).getAngle() + 180.0f);
			if (facing_left)
			{
				angle += 180;
			}
		}
		else
		{
			this.SetFacingLeft(!facing_left);
		}
	}

	return angle;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("grenade"))
	{
		return damage * 10;
	}
	
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("projectile") && blob.getTeamNum() == this.getTeamNum()) return true;

	if (blob.hasTag("boat"))
	{
		return true;
	}
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle"))
	{
		return true;
	}

	if (blob.hasTag("flesh") && !blob.isAttached())
	{
		return true;
	}
	else
	{
		return false;
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 random = XORRandom(5);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = -this.get_f32("bomb angle");
	
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();

	for (int i = 0; i < (v_fastrender ? 5: 15); i++)
	{
		MakeParticle(this, Vec2f( XORRandom(32) - 16, XORRandom(32) - 16), getRandomVelocity(-angle, XORRandom(220) * 0.01f, 90), particles[XORRandom(particles.length)]);
	}
	
	this.Tag("exploded");
	if (!v_fastrender) this.getSprite().Gib();
}

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

string[] smokes = 
{
	"LargeSmoke.png",
	"SmallSmoke1.png",
	"SmallSmoke2.png"
};

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!getNet().isClient()) return;

	ParticleAnimated(CFileMatcher(filename).getFirst(), this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}