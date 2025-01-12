//todo: include this file for checks in other files
bool isTDM()
{
    return (getMap() !is null && getMap().tilemapwidth <= 300);
}

shared bool isTDMshared()
{
    return (getMap() !is null && getMap().tilemapwidth <= 300);
}

bool isCTF()
{
    return getBlobByName("pointflag") !is null || getBlobByName("pointflagt2") !is null;
}

shared bool isCTFshared()
{
    return getBlobByName("pointflag") !is null || getBlobByName("pointflagt2") !is null;
}

bool isDTT()
{
    return getBlobByName("importantarmory") !is null || getBlobByName("importantarmoryt2") !is null;
}

shared bool isDTTshared()
{
    return getBlobByName("importantarmory") !is null || getBlobByName("importantarmoryt2") !is null;
}

bool isPTB()
{
    return getBlobByName("core") !is null;
}

shared bool isPTBshared()
{
    return getBlobByName("core") !is null;
}