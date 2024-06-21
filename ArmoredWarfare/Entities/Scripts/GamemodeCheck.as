//todo: include this file for checks in other files
bool isTDM()
{
    return (getMap() !is null && getMap().tilemapwidth <= 300);
}

bool isCTF()
{
    return getBlobByName("pointflag") !is null || getBlobByName("pointflagt2") !is null;
}

bool isDTT()
{
    return getBlobByName("importantarmory") !is null || getBlobByName("importantarmoryt2") !is null;
}