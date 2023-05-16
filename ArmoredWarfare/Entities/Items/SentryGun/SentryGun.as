#include "WarfareGlobal.as"
#include "Explosion.as"
#include "Hitters.as"
#include "GunStandard.as"

const string target_player_id = "target_player_id";

void onInit(CBlob@ this)
{
	this.addCommandID("shoot");
	this.Tag("never_repair");

	this.set_bool("spawned", false);
	this.set_u16(target_player_id, 0);

	this.set_u32("next repair", 0);
	this.getSprite().PlaySound( "/UpgradeT2.ogg", 0.75f, 1.25f );

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "SentryGun_gun", 32, 16);
	this.Tag("builder always hit");

	this.set_u8("TTL", 45);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 18);
	this.set_s32("custom_hitter", Hitters::machinegunbullet);

	this.Tag("structure");
	this.Tag("vehicle");
	this.Tag("turret");

	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("defaultarm", 0, false);
		Animation@ shoot = arm.addAnimation("armshoot", 3, false);

		arm.SetOffset(Vec2f(-6.0f, -5.0f));
		arm.SetRelativeZ(25.0f);

		arm.animation.frame = 0;
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	bool facing_left = this.getTeamNum() == teamright ;
	this.SetFacingLeft(facing_left);

	this.getShape().SetRotationsAllowed(false);

	sprite.SetZ(20.0f);
	if (isServer()) this.server_SetTimeToDie(90.0f);
}


void onTick(CBlob@ this)
{
	u16 target = this.get_u16(target_player_id); //target's netid

	CBlob@ targetblob = getBlobByNetworkID(this.get_u16(target_player_id)); //target's blob

	this.getCurrentScript().tickFrequency = 6;

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
		if (targetblob !is null && this.getDistanceTo(targetblob) < 400.0f)
		{
			this.getCurrentScript().tickFrequency = 1;

			f32 distance;
			const bool visibleTarget = isVisible(this, targetblob, distance);
			if (visibleTarget && distance < 400.0f)
			{
				if (this.get_u32("next shot") < getGameTime())
				{
					ClientFire(this);
					//this.SendCommand(this.getCommandID("shoot"));
					//this.set_bool("spawned", false);

					if (isServer())
					{
						f32 angle = (targetblob.getPosition()-this.getPosition()+Vec2f(0, 8)).Angle();
						f32 bulletSpread = 5.0f;
						angle += XORRandom(bulletSpread+1)/10-bulletSpread/10/2;
						f32 true_angle = -angle;

						bool has_owner = false;
						CPlayer@ p = this.getDamageOwnerPlayer();
						if (p !is null && p.getBlob() !is null)
							has_owner = true;
							
						shootVehicleGun(has_owner ? p.getBlob().getNetworkID() : this.getNetworkID(), this.getNetworkID(),
							true_angle, this.getPosition()+Vec2f(0,this.isFacingLeft()?8:-8).RotateBy(true_angle),
							targetblob.getPosition(), bulletSpread, 1, 0, 0.25f, 0.33f, 2,
								this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));		
					}

					this.set_u32("next shot", getGameTime() + 10);			
				}
			}

			LoseTarget(this, targetblob);

			if (XORRandom(100) == 0)
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

	if (this.get_u16(target_player_id) == 0)
	{
		this.getCurrentScript().tickFrequency = 1;
		angle += Maths::Round(Maths::Sin(getGameTime()*0.066f)*7.5f);
	}

	if (arm !is null)
	{
		bool facing_left = sprite.isFacingLeft();
		//f32 rotation = angle * (facing_left ? -1 : 1);

		arm.ResetTransform();
		arm.SetFacingLeft(facing_left);
		arm.RotateBy(angle, Vec2f(facing_left ? -6.0f : 6.0f, 6.0f));
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
		this.getSprite().PlaySound("DefenseTurretShoot.ogg", 1.1f, 1.35f + XORRandom(20) * 0.1f);

		ParticleAnimated("SmallExplosion3", (pos_2)+Vec2f(0, 2.0f) + vel*0.8, getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.6f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
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
					bullet.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

					bullet.set_f32("bullet_damage_body", 0.25f);
					bullet.set_f32("bullet_damage_head", 0.325f);
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					Vec2f pos_ = this.getPosition()-Vec2f(0.0f, 2.0f);
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
	bool visible = !getMap().rayCastSolidNoBlobs(blob.getPosition(), targetblob.getPosition() + targetblob.getVelocity() * 2.0f, col);
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
	if (customData == Hitters::builder)
	{
		return damage * 3.3f;
	}
	if (hitterBlob.hasTag("grenade"))
	{
		return damage * 10;
	}
	
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("projectile") && blob.getTeamNum() == this.getTeamNum()) return false;

	if (blob.hasTag("boat"))
	{
		return true;
	}
	if (blob.hasTag("vehicle"))
	{
		return false;
	}
	if ((!blob.getShape().isStatic() || blob.getName() == "wooden_platform") && blob.getTeamNum() == this.getTeamNum()) return false;
	if (blob.hasTag("vehicle"))
	{
		return true;
	}

	return false;
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