//Main stairs script

#include "Hitters.as"
#include "Staircase.as";
#include "KnockedCommon.as";
#include "GenericButtonCommon.as";
#include "ScreenHoverButton.as";

const int STUNTIME = 45;
Vec2f Up;
Vec2f Down;
bool doesStaircaseExist;

void onInit(CBlob@ this)
{
    this.Tag("stairs");
    this.Tag("structure");
    this.Tag("builder always hit");
    this.addCommandID("go up");
    this.addCommandID("go down");
    this.set_TileType("background tile", CMap::tile_castle_back);
    
    this.getCurrentScript().tickFrequency = 90;

    HoverButton@ buttons;
    if (!this.get("HoverButton", @buttons))
    {
        HoverButton setbuttons(this.getNetworkID());
        setbuttons.offset = Vec2f(0,-16);
        for (u16 i = 0; i < 2; i++)
        {
            SimpleHoverButton btn(this.getNetworkID());
            btn.dim = Vec2f(50, 20);
            btn.font = "menu";

            if (i == 0)
            {
                //btn.text = "UP";
                btn.callback_command = "go up";
                btn.write_local = true;
            }
            else
            {
                //btn.text = "DOWN";
                btn.callback_command = "go down";
                btn.write_local = true;
            }

            setbuttons.AddButton(btn);
        }
        setbuttons.draw_overlap = true;
        setbuttons.draw_attached = false;
        setbuttons.grid = Vec2f(1,2);
        setbuttons.gap = Vec2f(0,64);
        this.set("HoverButton", setbuttons);
    }
    if (!this.get("HoverButton", @buttons)) return;
    if (buttons is null) return;
}

void onTick(CBlob@ this)
{
    if (!this.hasTag("bedrockcheck"))
    {
        if (getMap() !is null && getMap().isTileBedrock(getMap().getTile(this.getPosition()+Vec2f(0, 16)).type))
            this.AddScript("IgnoreDamage.as");
        this.Tag("bedrockcheck");
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    const u16 callerID = params.read_u16();
	CBlob@ caller = getBlobByNetworkID(callerID);

    if(caller !is null && this.getDistanceTo(caller) < this.getRadius() && !isKnocked(caller))
    {
        if(cmd == this.getCommandID("go up"))
        {
            CBlob@[] staircase;
            doesStaircaseExist = getStaircase(this, staircase);
            CBlob@ nextfloor = getNextFloor(this, staircase); 

            if(nextfloor !is null && isKnockable(caller))
            {
                Up = nextfloor.getPosition();
                if(getNet().isServer())
                {
                    Travel(this, caller, nextfloor, Up, true);
                }
                if(getNet().isClient())
                {
                    Travel(this, caller, nextfloor, Up, false);
                }
            }
        }

        if (cmd == this.getCommandID("go down"))
        {
            CBlob@[] staircase;
            doesStaircaseExist = getStaircase(this, staircase);
            CBlob@ prevfloor = getPreviousFloor(this, staircase);

            if(prevfloor !is null && isKnockable(caller))
            {
                Down = prevfloor.getPosition();
                if(getNet().isServer())
                {
                    Travel(this, caller, prevfloor, Down, true);
                }
                if(getNet().isClient())
                {
                    Travel(this, caller, prevfloor, Down, false);
                }  
            }
        }
    }
}

void Travel(CBlob@ this, CBlob@ caller, CBlob@ floor, Vec2f position, bool server)
{
	if (caller !is null)
	{
		
		// No tank travel no no
		if (caller.isAttached())
        {
			return;
        }
		
		// move caller
		caller.setPosition(position);
		caller.setVelocity(Vec2f_zero);

        if(caller.getPosition() == position && !server) //Making knocked clientside works for some reason, altho server still changes animations for blob
        {
            caller.Untag("invincible");
            caller.Sync("invincible", true);
            setKnocked(caller, STUNTIME, false);
        }
		if (caller.isMyPlayer())
		{
			Sound::Play("Travel.ogg");
		}
		else
		{
			Sound::Play("Travel.ogg", this.getPosition());
			Sound::Play("Travel.ogg", caller.getPosition());
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    if (customData != Hitters::builder)
    {
        return 0;
    }
    return damage;
}