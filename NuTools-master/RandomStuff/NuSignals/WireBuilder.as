#include "NuLib.as";
#include "NuSignalsCommon.as";
#include "NuHub.as";

void onInit(CBlob@ blob)
{

}

void onTick(CBlob@ blob)
{
    NuHub@ hub;
    if(!InitHub(rules, @hub)) { return; }
}

void onRender(CBlob@ blob)
{

}