#include "CrateCommon.as"
#include "MiniIconsInc.as"
#include "Help.as"
#include "Hitters.as"
#include "GenericButtonCommon.as"

// this file is scuffed could be causing crashes

//property name
const string required_space = "required space";

//proportion of distance allowed (1.0f == overlapping radius, 2.0f = within 1 extra radius)
void onInit(CBlob@ this)
{
	this.Tag("trap");
	this.checkInventoryAccessibleCarefully = true;

	u8 frame = 0;
	if (this.exists("frame"))
	{
		frame = this.get_u8("frame");

		u8 newFrame = 0;

		if (newFrame > 0)
		{
			CSpriteLayer@ icon = this.getSprite().addSpriteLayer("icon", "/MiniIcons.png" , 16, 16, this.getTeamNum(), -1);
			if (icon !is null)
			{
				icon.SetFrame(newFrame);
				icon.SetOffset(Vec2f(-2, 1));
				icon.SetRelativeZ(1);
			}
			this.getSprite().SetAnimation("label");
		}
	}
	else
	{
		this.getSprite().SetRelativeZ(-10.0f);

		this.Tag("dont deactivate");
	}

	this.Tag("activated");

	if (!this.exists(required_space))
	{
		this.set_Vec2f(required_space, Vec2f(5, 4));
	}

	this.getSprite().SetZ(-10.0f);

	// Give random loot items
	if (isServer())
	{
		if (XORRandom(2) == 0)
		{
			CBlob@ b = server_CreateBlob("ammo", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(2) == 0)
		{
			CBlob@ b = server_CreateBlob("ammo", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(2) == 0)
		{
			CBlob@ b = server_CreateBlob("ammo", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(3) == 0)
		{
			CBlob@ b = server_CreateBlob("mat_14mmround", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(3) == 0)
		{
			CBlob@ b = server_CreateBlob("mat_bolts", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(2) == 0)
		{
			CBlob@ b = server_CreateBlob("steak", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(10) == 0)
		{
			CBlob@ b = server_CreateBlob("mat_heatwarhead", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(4) == 0)
		{
			CBlob@ b = server_CreateBlob("grenade", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(3) == 0)
		{
			CBlob@ b = server_CreateBlob("mat_molotov", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(6) == 0)
		{
			CBlob@ b = server_CreateBlob("medkit", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
		if (XORRandom(10) == 0)
		{
			CBlob@ b = server_CreateBlob("binoculars", -1, this.getPosition());
			this.server_PutInInventory(b);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (!blob.hasTag("trap") && !blob.hasTag("bullet") && !blob.hasTag("flesh") && !blob.hasTag("dead") && !blob.hasTag("vehicle") && blob.isCollidable()) || (blob.hasTag("door") && blob.getShape().getConsts().collidable);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob.getCarriedBlob() !is null && this.getInventory().canPutItem(forBlob.getCarriedBlob()))
	{
		return true; // OK to put an item in whenever
	}

	f32 dist = (this.getPosition() - forBlob.getPosition()).Length();
	f32 rad = (this.getRadius() + forBlob.getRadius());

	if (dist < rad * 2.6f)
	{
		return true; // Allies can access from further away
	}

	return false;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	Vec2f buttonpos(0, 0);

	bool putting = caller.getCarriedBlob() !is null && caller.getCarriedBlob() !is this;
	bool canput = putting && this.getInventory().canPutItem(caller.getCarriedBlob());
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("thud.ogg");
}

void onTick(CBlob@ this)
{
	CInventory@ inventory = this.getInventory();
    if (inventory != null && inventory.getItemsCount() < 4)
    {
    	if ((getGameTime() % 300 == 0) && XORRandom(28) == 0)
		{
			if (isServer())
			{
				if (XORRandom(4) == 0)
				{
					CBlob@ b = server_CreateBlob("ammo", -1, this.getPosition());
					this.server_PutInInventory(b);
				}
				else if (XORRandom(5) == 0)
				{
					CBlob@ b = server_CreateBlob("mat_bolts", -1, this.getPosition());
					this.server_PutInInventory(b);
				}
				else if (XORRandom(3) == 0)
				{
					CBlob@ b = server_CreateBlob("steak", -1, this.getPosition());
					this.server_PutInInventory(b);
				}
				else if (XORRandom(5) == 0)
				{
					CBlob@ b = server_CreateBlob("mat_stone", -1, this.getPosition());
					b.server_SetQuantity(XORRandom(150) + 25);
					this.server_PutInInventory(b);
				}
				else if (XORRandom(5) == 0)
				{
					CBlob@ b = server_CreateBlob("mat_wood", -1, this.getPosition());
					b.server_SetQuantity(XORRandom(150) + 25);
					this.server_PutInInventory(b);
				}
			}
		}
    }
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	CInventory@ inventory = blob.getInventory();
    if (inventory != null)
    {
        if (inventory.getItemsCount() <= 0)
        {
            this.SetAnimation("empty");
        }
        else
        {
            this.SetAnimation("full");
        }
    }
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	f32 dmg = damage;
	dmg *= 0.3;

	if (isExplosionHitter(customData) || customData == Hitters::keg)
	{
		if (dmg > 50.0f) // inventory explosion
		{
			this.Tag("crate exploded");
		}
	}

	return dmg;
}

Vec2f crate_getOffsetPos(CBlob@ blob, CMap@ map)
{
	Vec2f halfSize = blob.get_Vec2f(required_space) * 0.5f;

	Vec2f alignedWorldPos = map.getAlignedWorldPos(blob.getPosition() + Vec2f(0, -2)) + (Vec2f(0.5f, 0.0f) * map.tilesize);
	Vec2f offsetPos = alignedWorldPos - Vec2f(halfSize.x , halfSize.y) * map.tilesize;
	return offsetPos;
}

// SPRITE
void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	Vec2f pos2d = blob.getScreenPos();
	u32 gameTime = getGameTime();

	if (blob.isAttached())
	{
		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");

		CBlob@ holder = point.getOccupied();

		if (holder is null) { return; }

		CPlayer@ local = getLocalPlayer();
		if (local !is null && local.getBlob() is holder)
		{
			CMap@ map = blob.getMap();
			if (map is null) return;

			Vec2f space = blob.get_Vec2f(required_space);
			Vec2f offsetPos = crate_getOffsetPos(blob, map);

			const f32 scalex = getDriver().getResolutionScaleFactor();
			const f32 zoom = getCamera().targetDistance * scalex;
			Vec2f aligned = getDriver().getScreenPosFromWorldPos(offsetPos);
			GUI::DrawIcon("CrateSlots.png", 0, Vec2f(40, 32), aligned, zoom);

			for (f32 step_x = 0.0f; step_x < space.x ; ++step_x)
			{
				for (f32 step_y = 0.0f; step_y < space.y ; ++step_y)
				{
					Vec2f temp = (Vec2f(step_x + 0.5, step_y + 0.5) * map.tilesize);
					Vec2f v = offsetPos + temp;
					if (map.isTileSolid(v))
					{
						GUI::DrawIcon("CrateSlots.png", 5, Vec2f(8, 8), aligned + (temp - Vec2f(0.5f, 0.5f)* map.tilesize) * 2 * zoom, zoom);
					}
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().Gib();
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	// Crate gibs
	string fname = CFileMatcher("/Crate.png").getFirst();
	for (int i = 0; i < 4; i++)
	{
		CParticle@ temp = makeGibParticle(fname, pos, vel + getRandomVelocity(90, 1 , 110), 9, 2 + i, Vec2f(16, 16), 2.0f, 20, "Sounds/material_drop.ogg", 0);
	}

	 if (this.hasTag("despawned")) return;

    this.getSprite().Gib();

    // Drop loot on break

    array<string> _items =
    {
    	"mat_scrap",
        "mat_wood",
        "mat_stone",

    	"grenade",
    	"helmet",
    	"medkit",
        "food",
        "ammo",
        "mat_bolts",
        "pipewrench"
    };
    array<float> _chances =
    {
        0.6,
        0.25,
        0.25,

        0.08,
        0.05,
        0.02,
        0.08,
        0.02,
        0.01,
        0.01
    };
    array<u8> _amount =
    {
        (XORRandom(12)+5),
        (XORRandom(9)+1)*10,
        (XORRandom(7)+1)*10,

        1,
        1,
        1,
        1,
        1,
        1,
        1
    };

    if (getNet().isServer())
    {
    	for (int i = 0; i < 2; i++)
		{
	        u32 element = RandomWeightedPicker(_chances, XORRandom(1000));
	        CBlob@ b = server_CreateBlob(_items[element],-1,this.getPosition());  
	        b.AddForce(Vec2f((XORRandom(5)-2)/1.3, -5));  
	        if (b.getMaxQuantity() > 1)
	        {
	            b.server_SetQuantity(_amount[element]);
	        }
    	}
    }
}

shared u32 RandomWeightedPicker(array<float> chances, u32 seed = 0)
{
    if (seed == 0) {seed = (getGameTime() * 404 + 1337 - Time_Local());}

    u32 i;
    float sum = 0.0f;

    for (i = 0; i < chances.size(); i++) {sum += chances[i];}

    Random@ rnd = Random(seed);//Random with seed

    float random_number = (rnd.Next() + rnd.NextFloat()) % sum;//Get our random number between 0 and the sum

    float current_pos = 0.0f;//Current pos in the bar

    for (i = 0; i < chances.size(); i++)//For every chance
    {
        if(current_pos + chances[i] > random_number)
        {
            break;//Exit out with i untouched
        }
        else//Random number has not yet reached the chance
        {
            current_pos += chances[i];//Add to current_pos
        }
    }

    return i;//Return the chance that was got
}