#include "Hitters.as";

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || blob is null)
		return;

	bool hasAttachments = otherTeamHitting(this, blob);
	f32 vel_thresh =  hasAttachments ? 1.5f : 2.5f;
	f32 dir_thresh =  hasAttachments ? -0.7f : 0.25f;

	const f32 vellen = this.getShape().vellen;
	if (blob !is null && vellen > vel_thresh && blob.isCollidable())
	{
		Vec2f pos = this.getPosition();
		Vec2f vel = this.getVelocity();
		Vec2f other_pos = blob.getPosition();
		Vec2f direction = other_pos - pos;
		direction.Normalize();
		vel.Normalize();

		bool vehicle_collision = blob.hasTag("vehicle");
		if (vel * direction > dir_thresh)
		{
			//if (vehicle_collision && (blob.getVelocity().x - vel.x) < 1.7f) return;

			f32 power = blob.getShape().isStatic() ? 10.0f * vellen : 2.0f * vellen;
			if (this.getTeamNum() == blob.getTeamNum())
				power = 0.0f;
			power *= vehicle_collision ? 0.10f : 0.35f;
			this.server_Hit(blob, point1, vehicle_collision ? Vec2f(0,0) : vel, power, Hitters::flying, false);
			blob.server_Hit(this, point1, vehicle_collision ? Vec2f(0,0) : vel, Maths::Min(power * 0.25f, 0.5f), Hitters::flying, false);
			this.setVelocity(Vec2f(vehicle_collision ? this.getVelocity().x * 0.45f : this.getVelocity().x * 0.52f, this.getVelocity().y)); // CPHPSHAGHGRGHHGRHHHHT is the sound of running over someone in a tank
		}

		if (vehicle_collision)
		{
			this.getSprite().PlaySound("VehicleCollide", 1.15f, 0.9f + XORRandom(35)*0.01f);

			CParticle@ p = ParticleAnimated("SparkParticle.png", point1, Vec2f(0,0),  0.0f, 1.0f, 2+XORRandom(2), 0.0f, false);
			if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }
		}
	}
}

bool otherTeamHitting(CBlob@ this, CBlob@ blob)
{
	if (this.hasAttached())
	{
		const int otherTeam = blob.getTeamNum();
		int count = this.getAttachmentPointCount();
		for (int i = 0; i < count; i++)
		{
			AttachmentPoint @ap = this.getAttachmentPoint(i);
			if (ap.getOccupied() !is null)
			{
				if (otherTeam != ap.getOccupied().getTeamNum())
				{
					return true;
				}
			}
		}
	}
	return false;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null && customData == Hitters::flying)
	{
		const f32 othermass = hitBlob.getMass();
		if (othermass > 0.0f)
		{
			hitBlob.AddForce(velocity * this.getMass() * 0.1f * othermass / 70.0f);
		}
	}
}
