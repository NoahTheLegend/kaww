#include "Explosion.as"
#include "WarfareGlobal.as"
#include "GunStandard.as"
#include "Hitters.as"

const string target_player_id = "target_player_id";
const u8 fire_rate = 7;

void onInit(CBlob@ this)
{
	this.addCommandID("shoot");

	this.set_bool("spawned", false);
	this.set_u16(target_player_id, 0);

	this.set_u32("next repair", 0);

	this.set_u8("TTL", 60);
	this.set_Vec2f("KB", Vec2f(0,0));
	this.set_u8("speed", 20);
	this.set_s32("custom_hitter", HittersAW::machinegunbullet);
	this.set_s8(penRatingString, 3);

	// init arm sprites
	CSprite@ sprite = this.getSprite();
	this.Tag("builder always hit");

	this.Tag("vehicle");
	this.Tag("turret");

	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "DefenseTurret_gun", 48, 32);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("defaultarm", 0, false);
		anim.AddFrame(0);
		anim.AddFrame(1);

		arm.SetOffset(Vec2f(-8.0f, -8.0f));
		arm.SetRelativeZ(50.0f);

		arm.animation.frame = 0;
	}

	CSpriteLayer@ barrel = sprite.addSpriteLayer("barrel", "DefenseTurret_gun", 48, 32);
	if (barrel !is null)
	{
		Animation@ anim = barrel.addAnimation("default", 0, false);
		anim.AddFrame(2);

		barrel.SetOffset(Vec2f(-8.0f, -8.0f));
		barrel.SetRelativeZ(49.0f);
	}

	CSpriteLayer@ shield = sprite.addSpriteLayer("shield", "DefenseTurret", 32, 32);
	if (shield !is null)
	{
		Animation@ anim = shield.addAnimation("defaultshield", 0, false);
		anim.AddFrame(1);

		shield.SetOffset(Vec2f(-1.0f, -9.0f));
		shield.SetRelativeZ(100.0f);
		shield.animation.frame = 0;
		shield.SetAnimation(anim);
		shield.SetRelativeZ(51.0f);
	}

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

	bool facing_left = this.getTeamNum() == teamright;
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
							true_angle, this.getPosition()+Vec2f(0,this.isFacingLeft()?6:-6).RotateBy(true_angle),
							targetblob.getPosition(), bulletSpread, 1, 0, 0.35f, 0.5f, this.get_s8(penRatingString),
								this.get_u8("TTL"), this.get_u8("speed"), this.get_s32("custom_hitter"));
					}

					this.set_u32("next shot", getGameTime() + fire_rate);			
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

	f32 diff = 1.0f - (this.get_u32("next shot") > getGameTime() ? f32(this.get_u32("next shot") - getGameTime()) / fire_rate : 0.0f);

	CSpriteLayer@ arm = sprite.getSpriteLayer("arm");
	CSpriteLayer@ barrel = sprite.getSpriteLayer("barrel");
	if (arm !is null && barrel !is null)
	{
		bool facing_left = sprite.isFacingLeft();
		//f32 rotation = angle * (facing_left ? -1 : 1);

		arm.ResetTransform();
		arm.SetFacingLeft(facing_left);
		arm.RotateBy(angle, Vec2f(facing_left ? -9.0f : 8.0f, 7.0f));

		barrel.ResetTransform();
		barrel.SetFacingLeft(facing_left);
		Vec2f offset = Vec2f(facing_left ? -9.0f : 8.0f, 7.0f);
		barrel.RotateBy(angle, offset);
		barrel.SetOffset(Vec2f(-4 - 4*diff, -8).RotateBy(facing_left ? angle : -angle, Vec2f(facing_left ? offset.x : -offset.x, facing_left ? -offset.y : -offset.y)));
		//barrel.SetOffset(Vec2f(barrel.getOffset().x, -8));
	}
}

void ClientFire(CBlob@ this)
{
	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.animation.frame += 1;
	if (sprite.animation.frame >= 2) sprite.animation.frame = 0;

	Vec2f pos_2 = this.getPosition()-Vec2f(0.0f, 7.0f);
	f32 angle = getAimAngle(this);
	angle += ((XORRandom(512) - 256) / 76.0f);
	Vec2f vel = Vec2f(490.0f / 16.5f * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);

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
	

	sprite.PlaySound("DefenseTurretShoot.ogg", 1.1f, 1.0f + XORRandom(11) * 0.01f);
	ParticleAnimated("SmallExplosion3", this.getPosition() + Vec2f(this.isFacingLeft() ? -32.0f : 32.0f, -6.0f).RotateBy(angle), getRandomVelocity(0.0f, XORRandom(40) * 0.01f, this.isFacingLeft() ? 90 : 270) + Vec2f(0.0f, -0.05f), float(XORRandom(360)), 0.75f + XORRandom(50) * 0.01f, 2 + XORRandom(3), XORRandom(70) * -0.00005f, true);
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
	bool visible = !getMap().rayCastSolidNoBlobs(blob.getPosition()-Vec2f(0,8), targetblob.getPosition() + targetblob.getVelocity() * 2.0f, col);
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