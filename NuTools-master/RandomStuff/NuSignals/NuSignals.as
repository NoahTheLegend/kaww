#include "NuSignalsCommon.as";

void onInit(CRules@ rules)
{
    if(!isServer()){ return; }
    
    array<SignalNetwork@> networks = array<SignalNetwork@>();
    
    rules.set("S-N", networks);//Signal networks. S-N for short.
}

void onTick(CRules@ rules)
{
    if(!isServer()){ return; }

    array<SignalNetwork@> networks;

    rules.get("S-N", networks);//Signal networks. S-N for short.
    
    for(u16 i = 0; i < networks.size(); i++)
    {
        networks[i].TallySignals();

        networks[i].OfferSignals();
    }
}