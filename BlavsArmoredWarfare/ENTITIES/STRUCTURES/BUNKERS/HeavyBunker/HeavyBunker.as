#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.Tag("builder always hit");
	this.Tag("bunker");

	this.getShape().getConsts().mapCollisions = false;

	CSprite@ sprite = this.getSprite();
	sprite.SetAnimation("back");
	sprite.SetZ(-30.0f);
	CSpriteLayer@ front = sprite.addSpriteLayer("front layer", sprite.getConsts().filename, 32, 32);
	if (front !is null)
	{
		front.addAnimation("default", 0, false);
		int[] frames = { 0, 1, 2, 3};
		front.animation.AddFrames(frames);
		front.SetRelativeZ(65.8f);
		front.SetOffset(Vec2f(0.0f, 0.0f));
	}

	this.SetFacingLeft(this.getTeamNum() == 1);
}

void onDie(CBlob@ this)
{
	if (!isServer())
		return;
	server_CreateBlob("constructionyard",this.getTeamNum(),this.getPosition());
}

void onHealthChange(CBlob@ this, f32 health_old)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	CSpriteLayer@ front = sprite.getSpriteLayer("front layer");
	if (front is null) return;

	front.animation.frame = u8((this.getInitialHealth() - this.getHealth()) / (this.getInitialHealth() / front.animation.getFramesCount()));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (!blob.isCollidable() || blob.isAttached() || blob.getTeamNum() == this.getTeamNum()) // no colliding against people inside vehicles
		return false;
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}


f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "grenade")
	{
		return damage * 2;
	}
	if (customData == Hitters::flying)
	{
		this.server_Hit(hitterBlob, hitterBlob.getPosition(), this.getOldVelocity(), 5.0f, Hitters::flying, true);

		if (!hitterBlob.hasTag("deal_bunker_dmg")) return 0;
		return damage / 35;
	}
	if (customData == Hitters::explosion)
	{
		return damage / 2.5;
	}
	if (hitterBlob.hasTag("vehicle") && customData != Hitters::explosion)
	{
		if (!hitterBlob.hasTag("deal_bunker_dmg")) return 0;
		return Maths::Min(0.2f, damage);
	}
	return damage;
}