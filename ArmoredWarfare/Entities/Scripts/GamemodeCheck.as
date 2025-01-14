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
    Vec2f empty;
    return getMap().getMarker("ptb blue", empty) || getMap().getMarker("ptb red", empty);
}

shared bool isPTBshared()
{
    Vec2f empty;
    return getMap().getMarker("ptb blue", empty) || getMap().getMarker("ptb red", empty);
}

u8 defendersTeamPTB()
{
    u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

    Vec2f empty;
    return getMap().getMarker("ptb blue", empty) ? teamleft : getMap().getMarker("ptb red", empty) ? teamright : 255;
}

shared u8 defendersTeamPTBshared()
{
    u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");

    Vec2f empty;
    return getMap().getMarker("ptb blue", empty) ? teamleft : getMap().getMarker("ptb red", empty) ? teamright : 255;
}
