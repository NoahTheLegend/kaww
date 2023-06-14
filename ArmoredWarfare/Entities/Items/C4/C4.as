#include "WarfareGlobal.as"
#include "Explosion.as"
#include "ProgressBar.as"

const f32 EXPLODE_TIME = 12.5f;
const f32 DEFUSE_REQ_TIME = 75;

void onInit(CBlob@ this)
{
	this.set_s8(penRatingString, 4);
	this.set_f32(projExplosionRadiusString, 52.0f+XORRandom(13));
	this.set_f32(projExplosionDamageString, 4.0f);

	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", true);
	this.Tag("collideswithglass");

	this.set_u16("exploding", 0);
	this.set_bool("explode", false);
	this.set_bool("deactivating", false);

	this.set_f32("defuse_endtime", DEFUSE_REQ_TIME);
	this.set_f32("defuse_time", 10);
	this.set_f32("caller_health", 999.0f);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action3);
	}
	this.set_u8("death_timer", 120);
	this.Tag("change team on pickup");

	this.Tag("medium weight");
	this.addCommandID("switch");
	this.addCommandID("deactivate");
	this.addCommandID("sync timer");

	CSprite@ sprite = this.getSprite();
	sprite.ScaleBy(0.75f, 0.75f);

	ShapeConsts@ consts = this.getShape().getConsts();	

	this.getShape().SetStatic(false);
	consts.mapCollisions = true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("trap")) return false;
	if (blob.hasTag("destructable"))
	{
		return true;
	}
	if (blob.hasTag("structure") && (!blob.hasTag("bunker") || blob.getName() == "sandbags" || blob.getTeamNum() == this.getTeamNum()))
	{
		return false;
	}
	if (blob.hasTag("flesh"))
	{
		return false;
	}
	return (!blob.hasTag("vehicle") && blob.isCollidable());
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return true;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.get_bool("explode");
}

void DoExplosion(CBlob@ this)
{
	if (this.hasTag("exploded")) return;

	f32 angle = -this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 52.0f+XORRandom(5));
	this.set_f32("map_damage_ratio", 0.15f);
	
	for (u8 i = 0; i < 5+XORRandom(2); i++)
	{
		WarfareExplode(this, this.get_f32(projExplosionRadiusString), this.get_f32(projExplosionDamageString));
	}
	
	if (isClient())
	{
		for (int i = 0; i < (v_fastrender ? 5 : 30); i++)
		{
			MakeParticle(this, Vec2f( XORRandom(60) - 30, XORRandom(60) - 30), getRandomVelocity(-angle, XORRandom(125) * 0.01f, 90));
		}
		
		this.Tag("exploded");
		if (!v_fastrender) this.getSprite().Gib();
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.exists("delay") && this.get_u32("delay") > getGameTime()) return;
 	if (caller is null || !caller.isMyPlayer()) return;
	if (this.getDistanceTo(caller) > 10.0f || this.get_bool("deactivating")) return;
	if (this.isAttachedTo(caller) || !this.isAttached())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CButton@ button = caller.CreateGenericButton(11, Vec2f(0, 0), this, this.getCommandID("switch"), "\n\n"+(this.get_bool("explode") ? "Deactivate" : "Activate")+" C-4", params);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	//this.Untag("setstatic");
	//this.getShape().SetStatic(false);
	//this.getShape().getConsts().mapCollisions = true;
		
    if (attached !is null) this.SetDamageOwnerPlayer(attached.getPlayer());
	this.server_setTeamNum(attached.getTeamNum());
}

void onTick(CBlob@ this)
{
	barTick(this);

	if (isServer() && this.get_bool("explode") && getGameTime()%15==0)
	{
		this.server_DetachFromAll();
	}

	//if (isServer() && this.hasTag("setstatic"))
	//{
	//	this.Untag("setstatic");
	//	this.getShape().SetStatic(true);
	//	this.getShape().getConsts().mapCollisions = false;
	//	this.setVelocity(Vec2f(0,0));
	//}

	if (this.get_bool("deactivating"))
	{
		CBlob@ caller = getBlobByNetworkID(this.get_u16("caller_id"));
		if (caller !is null && caller.isOverlapping(this)
			&& (!(caller.getHealth() < this.get_f32("caller_health")-0.1f)
				|| this.get_f32("caller_health") > 500.0f))
		{
			if (this.get_f32("defuse_time") > DEFUSE_REQ_TIME)
			{
				Bar@ bars;
				if (this.get("Bar", @bars))
				{
					bars.RemoveBar("defuse", false);
				}
			}
			this.add_f32("defuse_time", 1);
			this.set_f32("caller_health", caller.getHealth());
		}
		else
		{
			this.set_f32("defuse_time", 10);
			this.set_bool("deactivating", false);

			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				ProgressBar@ defuse = bars.getBar("defuse");
				if (defuse !is null)
					defuse.callback_command = "";

				bars.RemoveBar("defuse", false);
			}
			this.set_f32("caller_health", 999.0f);
		}
	}

	if (isServer() && this.get_bool("explode") && this.get_u16("exploding") > 90) // experimental
	{
		if (getGameTime()%15==0)
		{
			CBitStream params;
			params.write_bool(this.get_bool("explode"));
			params.write_u16(this.get_u16("exploding"));
			this.SendCommand(this.getCommandID("sync timer"), params);
		}
	}

	if (this.getShape() is null) return;
	bool separatists_power = getRules().get_bool("enable_powers") && this.getTeamNum() == 4; // team 4 buff
   	f32 extra_amount = 0;
    if (separatists_power)
	{
		extra_amount = 2.5f;
	}
	f32 explode_time = EXPLODE_TIME - extra_amount;
	u8 scale = Maths::Min(27, (explode_time - this.get_u16("exploding")/30) * 3.0f);
	if (this.get_bool("explode") && this.get_u16("exploding") > 0)
	{
		if (this.get_u8("timer") >= 30-scale && this.get_u16("exploding") > 20)
		{
			this.getSprite().PlaySound("C4Beep.ogg", 1.0f, 1.0f+scale*0.0075f);
			this.set_u8("timer", 0);
		}
		this.add_u8("timer", 1);

		this.set_u16("exploding", this.get_u16("exploding") - 1);
		f32 angle = -this.get_f32("bomb angle");

		Vec2f pos = this.getPosition();

		if (this.get_u16("exploding") == 3)
		{
			DoExplosion(this);

			if (!v_fastrender)
			{
				for (int i = 0; i < 15; i++)
				{
					CParticle@ p = ParticleAnimated("BulletHitParticle1.png", pos + getRandomVelocity(-angle, XORRandom(30) * 1.0f, 360), Vec2f(0,0), XORRandom(360), 1.0f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
				}

				// glow
				this.SetLight(true);
				this.SetLightRadius(300.0f);
				this.SetLightColor(SColor(255, 255, 240, 210));
			}
		}
		else if (this.get_u16("exploding") < 2)
		{
			for (int i = 0; i < 3; i++)
			{
				MakeParticle(this, Vec2f( XORRandom(100) - 50, XORRandom(100) - 50), getRandomVelocity(-angle, XORRandom(125) * 0.01f, 90));
			}

			for (int i = 0; i < 14; i++)
			{
				{ CParticle@ p = ParticleAnimated("BulletChunkParticle.png", pos, getRandomVelocity(-angle, XORRandom(125) * 0.1f, 360), 0.0f, 0.55f + XORRandom(50)*0.01f, 22+XORRandom(3), 0.3f, true);
				if (p !is null) { p.lighting = true; }}
			}

			for (int i = 0; i < 3; i++)
			{
				ParticleAnimated("Smoke", pos, getRandomVelocity(0, XORRandom(10) * 0.12f, 360), 0.0f, 2.0f, 8+XORRandom(4), XORRandom(70) * -0.0003f, true);
			}
		}

		if (this.get_u16("exploding") == 1)
		{
			this.Untag("activated");
			this.server_Die();
		}
	}
}

void sparks(Vec2f at, f32 angle, f32 speed, SColor color)
{
	Vec2f vel = getRandomVelocity(angle + 90.0f, speed, 25.0f);
	at.y -= 2.5f;
	ParticlePixel(at, vel, color, true, 119);
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "Explosion.png")
{
	if (!isClient()) return;
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync timer"))
	{
		if (isClient())
		{
			bool explode = params.read_bool();
			u16 exploding = params.read_u16();
			this.set_bool("explode", explode);
			this.set_u16("exploding", exploding);
		}
	}
	else if (cmd == this.getCommandID("deactivate"))
	{
		if (this.get_bool("explode"))
		{
			if (isClient())
			{
				Sound::Play("C4Defuse.ogg", this.getPosition(), 1.0f, 1.15f);
			}

			this.set_bool("active", false);
			this.set_bool("explode", false);
			this.set_u16("exploding", 0);

			this.set_f32("defuse_time", 10);
			this.set_u16("caller_id", 0);
		}
		this.set_bool("deactivating", false);
	}
   	else if (cmd == this.getCommandID("switch"))
	{
		if (this.get_bool("explode"))
		{
			if (isClient())
			{
				Sound::Play("C4Defuse.ogg", this.getPosition(), 0.75f, 1.05f);
			}

			Bar@ bars;
			if (!this.get("Bar", @bars))
			{
				Bar setbars;
    			setbars.gap = 20.0f;
    			this.set("Bar", setbars);
			}
			if (this.get("Bar", @bars))
			{
				if (!hasBar(bars, "defuse"))
				{
					SColor team_front = SColor(255, 255, 255, 55);
					ProgressBar setbar;
					setbar.Set(this, "defuse", Vec2f(48.0f, 12.0f), true, Vec2f(0, 24), Vec2f(2, 2), back, team_front,
						"defuse_time", this.get_f32("defuse_endtime"), 0.33f, 5, 5, false, "deactivate");

    				bars.AddBar(this, setbar, true);
				}
			}	
			this.set_bool("deactivating", true);
			u16 callerid = params.read_u16();
			this.set_u16("caller_id", callerid);
		}
		else
		{
			if (isClient())
			{
				Sound::Play("C4Plant.ogg", this.getPosition(), 0.75f, 1.075f);
			}
			this.set_u32("delay", getGameTime()+15);
			this.set_f32("defuse_time", 10);

			this.set_bool("active", true);
			this.set_bool("explode", true);
			this.set_u16("exploding", EXPLODE_TIME*getTicksASecond());

			if (isServer())
			{
				this.server_DetachFromAll();
			}

			Bar@ bars;
			if (this.get("Bar", @bars))
			{
				ProgressBar@ defuse = bars.getBar("defuse");
				if (defuse !is null)
					defuse.callback_command = "deactivate";
			}
			this.set_bool("deactivating", false);
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	const f32 vellen = this.getOldVelocity().Length();
	const u8 hitter = this.get_s32("custom_hitter");

	if (blob !is null) return;

	if (isServer() && solid && vellen > 8.0f && this.get_bool("explode")) // avoid abuse while paratrooping
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("switch"), params);
	}

	//if (solid && !this.isAttached())
	//{
	//	this.Tag("setstatic");
	//}
}

void onRender(CSprite@ this)
{
	barRender(this);
}