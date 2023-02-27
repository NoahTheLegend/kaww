#include "Hitters.as";
//#include "ZombieCommon.as";

const int segments = 14;
const float segment_size = 13; //17
const float target_radius = 700;
const float compensation_amount = 40; //40

const float frame_w = 24;
const float frame_h = 24;

const u8 LOOT_CASH = 5;

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(100);
	this.getSprite().SetRelativeZ(100);
	this.getSprite().force_onrender = true;
	this.getSprite().SetEmitSound("Breath.ogg");
	this.getSprite().SetEmitSoundPaused(false);

	this.Tag("flesh");
	this.Tag("enemy");
	
	Vec2f[] segments_pos;
	segments_pos.set_length(segments);
	for(int i = 0; i < segments; i++)
	{
		segments_pos[i] = this.getPosition()-Vec2f(segment_size*i,0);
	}
	this.set("segments", @segments_pos);
	Vec2f[] segments_pos_old;
	segments_pos_old = segments_pos;
	this.set("old_segments", @segments_pos_old);

	SColor[] segments_colors;
	segments_colors.set_length(segments);
	for(int i = 0; i < segments; i++)
	{
		segments_colors[i] = color_white;
	}
	this.set("segments_colors", @segments_colors);
	
	Render::addBlobScript(Render::layer_objects, this, "Worm.as", "Render");

	this.server_setTeamNum(-1);
	Sound::Play("/WormRoar", this.getPosition());

	this.getSprite().SetAnimation("default");
}

// LOOT
void onDie(CBlob@ this)
{
	server_DropCoins(this.getPosition(), 120 + XORRandom(80));
	Sound::Play("/WormSound", this.getPosition());

    // Death effect

	if (isClient())
	{
		CParticle@ p = ParticleAnimated("MonsterDie.png", this.getPosition(), Vec2f(0,0), 0.0f, 1.0f, 5, 0.0f, false);
		if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }
	}
	int i;
	for (i = 0; i < 10; i++)
	{
		const Vec2f pos = this.getPosition() + getRandomVelocity(0, 22.0f+XORRandom(30), 360);
		CParticle@ p = ParticleAnimated("MonsterDiePart.png", pos, Vec2f(0,0),  0.0f, 1.0f, 8+XORRandom(4), -0.04f, false);
		if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = true; }
	}
}

void onTick(CBlob@ this)
{
	this.SetFacingLeft(false);
	CMap@ map = getMap();
	bool inGround = map.isTileSolid(this.getPosition()) || map.isInWater(this.getPosition());
	CShape@ shape = this.getShape();
	ShapeConsts@ shape_consts = shape.getConsts();
	
	if (inGround)
	{
		shape.setDrag(0.41);
		shape.SetGravityScale(0);
	}
	else
	{
		shape.setDrag(0.242);
		shape.SetGravityScale(0.5);
	}
	
	// AI
	if (isServer())
	{
		CBlob@ target;
		this.get("target", @target);
		bool found = false;
		if (target !is null)
		{
			found = true;
			if (getGameTime() % 25 == 2) // check if there are no target in range
			{
				@target = getClosestTarget(this.getPosition(), target_radius);
				this.set("target", @target);
				found = (target !is null);
			}
		}
		else if (getGameTime() % 4 == 2)
		{
			@target = getClosestTarget(this.getPosition(), target_radius);
			this.set("target", @target);
			found = (target !is null);
		}
		if (found)
		{
			bool wasinGround = map.isTileSolid(this.getOldPosition()) || map.isInWater(this.getOldPosition());

			if (!inGround && wasinGround && (this.getVelocity().y) < -3.5f)
			{
				int i;
				for (i = 0; i < (XORRandom(10)+6); i++)
				{
					const Vec2f pos = this.getPosition() + getRandomVelocity(0, XORRandom(5), 360);
					CParticle@ p = ParticleAnimated("BlackParticle.png", pos, Vec2f((2-XORRandom(4) + this.getVelocity().x)/2,this.getVelocity().y/(1+XORRandom(11)/8)),  0.0f, 1.0f, 8+XORRandom(4), 0.25f, false);
					if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = true; }
				}

				ShakeScreen(16, 8, target.getPosition());

				if (isClient())
					this.getSprite().PlaySound("/rocks_explode1", 1.2f, 0.6f);

					this.AddForce(Vec2f(0.0f, -150.0f));
			}

			if (inGround)
			{
				Vec2f old_vec = this.getVelocity();
				old_vec.Normalize();
				Vec2f vec = Vec2f(0,0);
				if (Maths::Abs(this.getVelocity().x + this.getVelocity().y) > 3.75f && target.getPosition().y < this.getPosition().y)
				{
					// Directly target the player
					vec = ((target.getPosition() + target.getVelocity()*10) - Vec2f(0.0f, 128.0f) - this.getPosition());
				}
				else if (Maths::Abs(this.getVelocity().x + this.getVelocity().y) < 1.0f && (target.getPosition() - this.getPosition()).getLength() < 64.0f)
				{
					// Move below ground
					vec = (target.getPosition() + Vec2f(0.0f, 128.0f) - this.getPosition());
				}
				else
				{
					// AI
					if (target.getPosition().x < this.getPosition().x)
					{
						if (target.getPosition().y < this.getPosition().y)
							vec = ((target.getPosition() + Vec2f(-compensation_amount, -compensation_amount)) - this.getPosition());
						else
							vec = ((target.getPosition() + Vec2f(-compensation_amount, compensation_amount*3)) - this.getPosition());
					}
					else
					{
						if (target.getPosition().y < this.getPosition().y)
							vec = ((target.getPosition() + Vec2f(compensation_amount, -compensation_amount)) - this.getPosition());
						else
							vec = ((target.getPosition() + Vec2f(compensation_amount, compensation_amount*3)) - this.getPosition());
					}
				}

				vec.Normalize();
				vec = vec * 0.3;
				this.setVelocity(this.getVelocity() + vec);
			} 
		}
		else
		{
			this.setVelocity(this.getVelocity() * 0.95);
		}
	}
	
	Vec2f vec = this.getVelocity();
	vec.y = -1*vec.y;
	this.setAngleDegrees(360-this.getVelocity().AngleDegrees());

	Vec2f[]@ segments_pos;
	this.get("segments", @segments_pos);
	Vec2f[]@ segments_pos_old;
	this.get("old_segments", @segments_pos_old);
	SColor[]@ segments_colors;
	this.get("segments_colors", @segments_colors);
	if(segments_pos !is null && segments_pos_old !is null && segments_colors !is null)
	{
		float change = (segments_pos[0]-this.getPosition()).Length()/2;
		segments_pos[0] = this.getPosition(); // head
		for(int i = 1; i < segments; i++)
		{
			segments_pos_old[i] = segments_pos[i];
			Vec2f last = segments_pos[i-1];
			Vec2f current = segments_pos[i];
			Vec2f vec = last-current;
			if(vec.Length() > segment_size)
			{
				float diff = vec.Length()-segment_size;
				vec.Normalize();
				vec = vec*diff;
				segments_pos[i] = current+vec;
			}
			segments_colors[i] = map.getColorLight(segments_pos[i]);
		}
	}
}


// RENDER SEGMENTS

void Render(CBlob@ this, int id)
{
	Vec2f[]@ segments_pos;
	this.get("segments", @segments_pos);
	Vec2f[]@ segments_pos_old;
	this.get("old_segments", @segments_pos_old);
	float RenderTime = getRules().get_f32("RenderTime");
	SColor[]@ segments_colors;
	this.get("segments_colors", @segments_colors);
	if(segments_pos !is null && segments_pos_old !is null && segments_colors !is null)
	{
		Vertex[] verts;
		for(int i = segments-1; i > 0; i--)
		{
			Vec2f vec = segments_pos[i-1]-segments_pos[Maths::Min(i+1, segments-1)];
			vec.y = -1*vec.y;
			float angle = vec.AngleDegrees();
			
			Vec2f tempA = Vec2f(0.5*frame_w, -0.5*frame_h).RotateByDegrees(angle);
			Vec2f tempB = Vec2f(0.5*frame_w, 0.5*frame_h).RotateByDegrees(angle);

			Vec2f draw_pos = Vec2f_lerp(segments_pos_old[i], segments_pos[i], RenderTime);
			
			float add = ((i == (segments-1)) ? 0.25 : 0);
			
			SColor col = segments_colors[i];

			verts.push_back(Vertex(draw_pos.x-tempB.x, draw_pos.y-tempB.y, 0, 0.25+add, 0, col));
			verts.push_back(Vertex(draw_pos.x+tempA.x, draw_pos.y+tempA.y, 0, 0.5+add, 0, col));
			verts.push_back(Vertex(draw_pos.x+tempB.x, draw_pos.y+tempB.y, 0, 0.5+add, 1, col));
			verts.push_back(Vertex(draw_pos.x-tempA.x, draw_pos.y-tempA.y, 0, 0.25+add, 1, col));
		}
		Render::SetTransformWorldspace();
		Render::SetAlphaBlend(true);
		Render::SetZBuffer(true, true);
		Render::RawQuads("Worm.png", verts);
	}
}

// CLOSEST TARGET
CBlob@ getClosestTarget(Vec2f pos, float radius)
{
	CBlob@[] possible_targets;
	getBlobsByTag("player", @possible_targets);
	
	for(int i = 0; i < possible_targets.size(); i++)
	{
		CBlob@ check = possible_targets[i];
		Vec2f dist = check.getPosition() - pos;
		if(dist.getLength() > radius)
		{
			possible_targets.removeAt(i);
		}
	}
	
	CBlob@ target;
	@target = null;
	float smallest_dist = 1000;
	for(int i = 0; i < possible_targets.size(); i++)
	{
		CBlob@ check = possible_targets[i];
		Vec2f dist = check.getPosition() - pos;
		if(dist.getLength() < smallest_dist)
		{
			@target = @check;
			smallest_dist = dist.getLength();
		}
	}
	return @target;
}

// ATTACK BLOB STUFF
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// Don't collide with anything
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null)
		{ return; }

	const f32 vellen = this.getShape().vellen;
	if ((vellen > 0.1f) && blob.hasTag("flesh") && blob.getName() != this.getName())
	{
		Vec2f vel = this.getVelocity();

		if (vellen > 0.4f)
		{
			Sound::Play("/WormBite", this.getPosition());
			this.getSprite().PlaySound("/Eat", 2.0f, 0.75f);

			if (XORRandom(2) == 0)
			{
				Sound::Play("/WormSound", this.getPosition());
			}

			this.server_Hit(blob, point1, vel, 0.5f, Hitters::bite, true);
		}

		this.server_Hit(blob, point1, vel, 0.25f, Hitters::bite, true);
	}
}


void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ attackedBlob, u8 customData)
{
	if (attackedBlob !is null && customData == Hitters::bite)
	{
		Vec2f force = velocity * 160.0f * 0.35f ;
		force.y -= 80.0f;
		attackedBlob.AddForce(force);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	ShakeScreen(16, 8, hitterBlob.getPosition());

	if (isClient())
	{
		Sound::Play("/WormSound", this.getPosition());
	}
	
	return damage;
}

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();

	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ Flesh1     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 1,    40), 0, 0, Vec2f(16, 16), 0.2f, 20, "/BodyGibFall", team);
	CParticle@ Flesh2     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 40), 0, 1, Vec2f(16, 16), 0.2f, 20, "/BodyGibFall", team);
	CParticle@ Flesh3     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 40), 0, 2, Vec2f(16, 16), 0.2f, 20, "/BodyGibFall", team);
	CParticle@ Flesh4     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 3,    40), 0, 3, Vec2f(16, 16), 0.4f, 20, "/BodyGibFall", team);
	CParticle@ Flesh5     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 3,    40), 0, 0, Vec2f(16, 16), 0.5f, 20, "/BodyGibFall", team);
	CParticle@ Flesh6     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 4,    40), 0, 1, Vec2f(16, 16), 0.5f, 20, "/BodyGibFall", team);
	CParticle@ Flesh7     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 4,    40), 0, 2, Vec2f(16, 16), 0.5f, 20, "/BodyGibFall", team);
	CParticle@ Flesh8     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 4,    40), 0, 3, Vec2f(16, 16), 0.6f, 20, "/BodyGibFall", team);
	CParticle@ Flesh9     = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 6,    40), 0, 1, Vec2f(16, 16), 0.5f, 20, "/BodyGibFall", team);
	CParticle@ Flesh10    = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 10,    40), 0, 2, Vec2f(16, 16), 0.5f, 20, "/BodyGibFall", team);
	CParticle@ Flesh11    = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 10,    40), 0, 3, Vec2f(16, 16), 0.6f, 20, "/BodyGibFall", team);
	CParticle@ Head       = makeGibParticle("Worm/WormGibs.png", pos, vel + getRandomVelocity(90, hp + 12 ,   40), 0, 4, Vec2f(16, 16), 0.3f, 0,  "Sounds/material_drop.ogg", team);
}
