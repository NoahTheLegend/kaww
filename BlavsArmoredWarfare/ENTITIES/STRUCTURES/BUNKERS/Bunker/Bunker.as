#include "Hitters.as";
#include "WarfareGlobal.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.Tag("builder always hit");
	this.Tag("bunker");
	this.set_s8(armorRatingString, 2);

	this.getShape().getConsts().mapCollisions = false;

	CSprite@ sprite = this.getSprite();
	sprite.SetAnimation("back");
	sprite.SetZ(-30.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 32, 32);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 1, 2, 3, 4, 5};
		front.animation.AddFrames(frames);
		front.SetRelativeZ(65.8f);
		front.SetOffset(Vec2f(0.0f, -4.0f));
	}

	this.SetFacingLeft(this.getTeamNum() == 1);
}

void onHealthChange(CBlob@ this, f32 health_old)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	CSpriteLayer@ front = sprite.getSpriteLayer("front layer");
	if (front is null) return;

	front.animation.frame = u8((this.getInitialHealth() - this.getHealth()) / (this.getInitialHealth() / front.animation.getFramesCount()));
}

void onDie(CBlob@ this)
{
	for (uint i = 0; i < 4; i++)
	{
		makeGibParticle(
		"Bunker",               			// file name
		this.getPosition() + Vec2f(0, -6),  // position
		getRandomVelocity(180, 1.5, 360) - Vec2f(0,2.5),      // velocity
		i,                                  // column
		6,                                  // row
		Vec2f(16, 16),                      // frame size
		1.0f,                               // scale?
		0,                                  // ?
		"",                     			// sound
		255);         // team number
	}

	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum()) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile") || blob.hasTag("grenade"))
	{
		return true;
	}
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	const bool is_explosive = customData == Hitters::explosion || customData == Hitters::keg;
	s8 armorRating = this.get_s8(armorRatingString);
	s8 penRating = hitterBlob.get_s8(penRatingString);
	bool hardShelled = this.get_bool(hardShelledString);

	float damageNegation = 0.0f;
	s8 finalRating = getFinalRating(this, armorRating, penRating, false, this, hitterBlob.getPosition(), false, false);
	switch (finalRating)
	{
		// negative armor, trickles up
		case -2:
		{
			if (is_explosive && damage != 0) damage += 1.5f; // suffer bonus base damage (you just got your entire vehicle burned)
			damage *= 2.5f;
		}
		case -1:
		case 0:
		{
			damage *= 2.0f;
		}
		break;

		// positive armor, trickles down
		case 5:
		{
			damageNegation += 0.15f; // reduction to final damage, extremely tanky
		}
		case 4:
		{
			damage *= 0.35f;
		}
		case 3:
		{
			damage *= 0.75f;
		}
		case 2:
		{
			damage *= 1.0f;
		}
		case 1:
		{
			damage *= 1.25f;
		}
		break;
	}

	if (hitterBlob.hasTag("grenade"))
	{
		return damage * 0.65f;
	}
	if (customData == Hitters::flying || customData == Hitters::flying)
	{
		this.server_Hit(hitterBlob, hitterBlob.getPosition(), this.getOldVelocity(), 3.5f, Hitters::flying, true);
		if (!hitterBlob.hasTag("deal_bunker_dmg")) return 0;
		return damage / 30;
	}
	if (customData == Hitters::arrow)
	{
		//this.server_Hit(hitterBlob, hitterBlob.getPosition(), this.getOldVelocity(), 3.5f, Hitters::flying, true);

		return damage * 1.5;
	}
	if (customData == Hitters::explosion)
	{
		return damage *= 0.25f;
	}
	if (hitterBlob.hasTag("vehicle"))
	{
		if (!hitterBlob.hasTag("deal_bunker_dmg")) return 0;
		return Maths::Min(0.2f, damage);
	}
	
	return damage;
}