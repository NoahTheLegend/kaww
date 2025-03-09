﻿#include "MapFlags.as"
#include "Hitters.as"
#include "CustomBlocks.as"
#include "PerksCommon.as";

void onInit(CBlob@ this)
{
    this.getSprite().getConsts().accurateLighting = false;  
	this.getSprite().RotateBy(XORRandom(4) * 90, Vec2f(0, 0));
	this.getSprite().SetRelativeZ(-115.0f); //background
	this.Tag("has damage owner");

	// this.getCurrentScript().runFlags |= Script::tick_not_attached;
	
	this.Tag("builder always hit");
	this.Tag("builder urgent hit");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	if (isServer() && blob.hasTag("flesh") && blob.getTeamNum() != this.getTeamNum() && !blob.isAttached())
	{
		CPlayer@ p = blob.getPlayer();
		bool stats_loaded = false;
		PerkStats@ stats;
		if (p !is null && p.get("PerkStats", @stats))
			stats_loaded = true;

		bool is_engi = stats_loaded && stats.id == Perks::fieldengineer;
		this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.15f, is_engi ? Hitters::fall : Hitters::spikes, true);
	}
	if (isServer() && blob.getTeamNum() != this.getTeamNum()
		&& (blob.hasTag("aerial") || blob.hasTag("tank") || blob.hasTag("apc")))
	{
		//this.getSprite().Gib();
		this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 25.0f, Hitters::builder, true);
	}
	if (isServer() && blob.getTeamNum() != this.getTeamNum()
		&& (blob.hasTag("apc") || blob.hasTag("truck")))
	{
		this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.5f, Hitters::spikes, true);
	}
	blob.IgnoreCollisionWhileOverlapped(this, 10);
}

void onTick(CBlob@ this)
{
	if (isServer() && (getGameTime()+this.getNetworkID())%450==0)
	{
		CMap@ map = this.getMap();
		
		Vec2f pos = this.getPosition();
		TileType tb = map.getTile(pos+Vec2f(0,8)).type; // bottom
		TileType tl = map.getTile(pos+Vec2f(-8,0)).type; // left
		TileType tu = map.getTile(pos+Vec2f(0,-8)).type; // up
		TileType tr = map.getTile(pos+Vec2f(8,0)).type; // right
		
		if (!isSolid(map, tb) && !isSolid(map, tl)
		&& !isSolid(map, tu) && !isSolid(map, tr))
		{
			this.server_Die();
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is null && hitterBlob.getTeamNum() != this.getTeamNum() && hitterBlob.hasTag("player"))
	{
		bool stats_loaded = false;
    	PerkStats@ stats = getPerkStats(hitterBlob, stats_loaded);

		if (stats_loaded && stats.id == Perks::fieldengineer)
		{
			damage *= 2.0f;
		}
	}
	if ((customData == Hitters::explosion && hitterBlob.getName() != "c4") || hitterBlob.hasTag("grenade"))
	{
		return damage * Maths::Max(0.0f, damage*1.5f / ((hitterBlob.getPosition() - this.getPosition()).Length()/2+0.1f));
	}
	/*if (hitterBlob !is null && hitterBlob !is this && (customData == Hitters::builder || customData == Hitters::sword))
	{
		if (isServer() && XORRandom(2)==0) this.server_Hit(hitterBlob, this.getPosition(), Vec2f(0, 0), 0.15f, Hitters::spikes, false);
	}*/
	if (isClient())
	{
		this.getSprite().PlaySound("dig_stone.ogg", 1.0f, 0.975f);
	}

	if (customData == Hitters::builder) damage *= 10;
	
	return damage;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}