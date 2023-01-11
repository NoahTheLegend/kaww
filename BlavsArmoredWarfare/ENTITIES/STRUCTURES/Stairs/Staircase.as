//Staircase formation

bool getStaircase(CBlob@ this, CBlob@[]@ stairs)                                //Gets all Staircase blobs that are on the same X position
{
    stairs.clear();                                                             //Clears stairs[] at the start to prevent infinite pushing back of same elements
    CBlob@[] list;
    getBlobsByTag("stairs", @list);

    for (uint i = 0; i < list.length; i++) 
	{
		CBlob@ blob = @list[i];
        if(blob.getPosition().x == this.getPosition().x)
        {
            stairs.push_back(blob);
        }
    }

    return stairs.length > 0;
}

CBlob@ getNextFloor(CBlob@ this, CBlob@[]@ staircase)           //Returns stairs 1 floor higher than this
{
    CBlob@ floor = this;
    for (uint i = 0; i < staircase.length; i++)
    {
        if(staircase[i] !is this)                                                //Finds the highest floor.
        {
            if(staircase[i].getPosition().y < floor.getPosition().y)
            {
                @floor = staircase[i];
            }

        }
    }
    if(floor is this)
    { return null; }
    else
    {
        for (uint i = 0; i < staircase.length; i++)                             //Finds the next floor otherwise
        {
            if(staircase[i] !is this && staircase[i].getPosition().y > floor.getPosition().y && staircase[i].getPosition().y < this.getPosition().y)
            {
                @floor = staircase[i];
            }
        }
        return @floor;
    }
    
    
}

CBlob@ getPreviousFloor(CBlob@ this, CBlob@[]@ staircase)       //Returns stairs 1 floor lower than this
{
    CBlob@ floor = this;
    for (uint i = 0; i < staircase.length; i++)
    {
        if(staircase[i] !is this)                                                //Finds the lowest floor.
        {
            if(staircase[i].getPosition().y > floor.getPosition().y)
            {
                @floor = staircase[i];
            }

        }
    }

    if(floor is this)
    { return null; }
    else
    {
        for (uint i = 0; i < staircase.length; i++)                             //Finds the previous floor otherwise
        {
            if(staircase[i] !is this && staircase[i].getPosition().y < floor.getPosition().y && staircase[i].getPosition().y > this.getPosition().y)
            {
                @floor = staircase[i];
            }
        }
        return @floor;
    }
}