//Main stairs script

#include "Staircase.as";
#include "KnockedCommon.as";
#include "GenericButtonCommon.as";

const float INTERDIST = 10.0f; // Minimal distance to staircase in order to interact with it (Keep it a small value to prevent using other floors)
const int STUNTIME = 45;       // Should be balanced between "Can be abused to avoid players" and "Too annoying to wait"
CBlob@ nextfloor;
CBlob@ prevfloor;
Vec2f Up;
Vec2f Down;
CBlob@[] staircase;
bool doesStaircaseExist;


void onInit(CBlob@ this)
{
    this.Tag("stairs");
    this.Tag("builder always hit");
    this.addCommandID("go up");
    this.addCommandID("go down");
    this.set_TileType("background tile", CMap::tile_castle_back);
}


void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
    
    if (!canSeeButtons(this, caller))
    {
        return;
    }

    bool doesStaircaseExist = getStaircase(this, staircase);
    @nextfloor = getNextFloor(this, staircase); 
    @prevfloor = getPreviousFloor(this, staircase);
    CBitStream params;
	params.write_u16(caller.getNetworkID());

    if(doesStaircaseExist && this.getDistanceTo(caller) < INTERDIST)       //Are there even other stairs?
    {
        /*print("Debug start");                                 //DEBUG STUFF, IGNORE
        print("thispos: " + this.getPosition());
        if(@nextfloor !is null)
        {
            print(" nextfloorpos: " + nextfloor.getPosition());
        }
        else 
        {
            print("Next floor does not exist");
        }
        if(@prevfloor !is null)
        {
            print("prevfloorpos:" + prevfloor.getPosition());
        }
        else
        {
            print("Previous floor does not exist");
        }
        print("Staircase length: " + staircase.length);
        print("Debug end"); */

        if (nextfloor !is null)                                                                                 //Show "go up" button if there is next floor
        {
            caller.CreateGenericButton( 16, Vec2f(4,0), this, this.getCommandID("go up"), "Go Up", params );
            
        }

        if (prevfloor !is null)                                                                                 //Shows "go down" button if there is previous floor
        {
            caller.CreateGenericButton( 19, Vec2f(-4,0), this, this.getCommandID("go down"), "Go Down", params );
            
        }
    }

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    const u16 callerID = params.read_u16();
	CBlob@ caller = getBlobByNetworkID(callerID);

    if(caller !is null && this.getDistanceTo(caller) < INTERDIST && !isKnocked(caller))
    {
        if(cmd == this.getCommandID("go up") )
        {
            doesStaircaseExist = getStaircase(this, staircase);
            @nextfloor = getNextFloor(this, staircase); 

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
            doesStaircaseExist = getStaircase(this, staircase);
            @prevfloor = getPreviousFloor(this, staircase);

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
