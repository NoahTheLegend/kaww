#include "NuLib.as";
#include "NuSignalsCommon.as";
#include "NuWiresCommon.as";
#include "NuHub.as";

bool init = false;

void onInit(CRules@ rules)
{
    if(!isServer()){ return; }

    array<SignalNetwork@> networks = array<SignalNetwork@>();
    rules.set("W-N", networks);//Wire networks. W-N for short.
    
    NuHub@ hub;
    if(!getHub(@hub)) { return; }

    CMap@ map = getMap();//Get the map
        
    for(u8 i = 0; i < hub.wire_positions.size(); i++)//For every wire team in the wire positions array.
    {
        hub.wire_positions[i] = array<u16>(map.tilemapwidth * map.tilemapheight, Nu::u16_max());//Alloacate the wire team to the size of the map for wires to be in. All positions contain no wires.
    }

    init = true;
}

u16 getFreeSignalNetwork(CRules@ rules)
{
    array<SignalNetwork@> networks;
    rules.get("W-N", networks);//Wire networks. W-N for short.

    for(u16 i = 0; i < networks.size(); i++)//For every network
    {
        if(networks[i] == @null)//If this network is not null
        {
            @networks[i] = @SignalNetwork();//Make it
            return i;//Return it, it's free
        }
    }

    SignalNetwork@ net = SignalNetwork();

    networks.push_back(net);

    return networks.size() - 1;
}

void onReload(CRules@ rules)
{
    if(!isServer()){ return; }

    onInit(rules);
}

void onTick(CRules@ rules)
{
    if(!isServer()){ return; }

    array<SignalNetwork@> networks;
    rules.get("W-N", networks);//Wire networks. W-N for short.
    
    for(u16 i = 0; i < networks.size(); i++)
    {
        networks[i].TallySignals();

        networks[i].OfferSignals();
    }
}

//Returns true if a wire of this team is at this position
bool WireAtPos(Vec2f pos, u8 team)
{
    NuHub@ hub;
    if(!getHub(@hub)) { return false; }

    Vec2f wire_pos = Nu::TilePosify(pos);
    u16 wire_offset_pos = wire_pos.x * wire_pos.y;

    if(hub.wire_positions.size() <= team || hub.wire_positions[team].size() <= wire_offset_pos)
    {
        print("Tried to access the outside of the wire team array bounds.");
        return false;
    }

    if(hub.wire_positions[team][wire_offset_pos] != Nu::u16_max())//If the wire with this team is at this position
    {
        return true;//Yup, a wire is here
    }

    return false;//Wire.exe not found
}

bool CanBuildWire(Vec2f pos, u8 team, bool require_backwall = true)
{
    Vec2f wire_pos = Nu::TilePosify(pos);//Convert world position into tile space.
    u16 wire_offset_pos = wire_pos.x * wire_pos.y;

    CMap@ map = getMap();//Get the map

    if(wire_pos.x > map.tilemapwidth || wire_pos.y < 0 || wire_pos.y > map.tilemapheight || wire_pos.y < 0)//If the wire position is beyond the right/left/bottom/top of the map.
    {
        print("Out of map.");
        return false;//You cannot
    }
    
    if(map.getTile(wire_offset_pos).type == CMap::tile_empty || map.isTileBedrock(wire_offset_pos) || map.isTileStone(wire_offset_pos) || map.isTileThickStone(wire_offset_pos)
    || map.isTileGround(wire_offset_pos) || map.isTileGroundBack(wire_offset_pos))
    {
        print("Wrong tile.");
        return false;//Nope
    }

    if(WireAtPos(pos, team))
    {
        print("Wire already in position");
        return false;//Cease
    }

    return true;
}

//I'm aware this code is horrible
bool BuildWire(CRules@ rules, Vec2f pos, u8 team, bool require_backwall = true)
{
    NuHub@ hub;
    if(!getHub(@hub)) { return false; }

    array<SignalNetwork@> networks;
    rules.get("W-N", networks);//Wire networks. W-N for short.

    if(!CanBuildWire(pos, team, require_backwall))//Check if a wire can be built here
    {
        return false;
    }

    Vec2f wire_pos = Nu::TilePosify(pos);//Convert world position into tile space.
    u16 wire_offset_pos = wire_pos.x * wire_pos.y;

    u16 net;//For later consumption

    u8 adjacennt_wires = 0;//Amount of adjacent wires

    array<u16> net_directions = array<u16>(4);//Stores the network of the wire in every direction
    
    net_directions[0] = hub.wire_positions[team][wire_pos.x * (wire_pos.y - 1)];//above
    net_directions[1] = hub.wire_positions[team][wire_offset_pos + 1];//right
    net_directions[2] = hub.wire_positions[team][wire_pos.x * (wire_pos.y + 1)];//below
    net_directions[3] = hub.wire_positions[team][wire_offset_pos - 1];//left

    u16 i;

    //Calculate the amount of adjacent wires
    for(i = 0; i < net_directions.size(); i++)
    {
        if(net_directions[i] != Nu::u16_max())
        {
            adjacennt_wires++;
        } 
    }

    if(adjacennt_wires == 0)//0 Adjacent wires
    {
        net = getFreeSignalNetwork(rules);//Find a free network in the network array and make it the network
    }
    else if(adjacennt_wires == 1)//1 Adjacent wire
    {
        //Figure out which wire is adjacent, and take it as our own
        for(i = 0; i < net_directions.size(); i++)
        {
            if(net_directions[i] != Nu::u16_max())
            {
                net = net_directions[i];
            }
        }
    }
    else//More than 1 adjacent wires
    {
        for(i = 0; i < net_directions.size(); i++)//For each direction
        {
            if(net_directions[i] != Nu::u16_max())//Find direction that has a wire
            {
                //This will be the main direction. This direction shall consume the networks of other wires.
                net = net_directions[i];
                
                for(u16 q = i; q < net_directions.size(); q++)//Starting from this direction
                {
                    if(net_directions[q] != Nu::u16_max())//Provided this direction has a wire
                    {
                        u16 old_net = net_directions[q];//Temp old_net variable
                        
                        //For everything that is connected to the old_net variable, change it to the net variable.
                        ConvertConnectedWireNetwork(team, old_net, net);
                    }
                }
            }
        }

    }

    hub.wire_positions[team][wire_offset_pos] = net;//Assign this wire's network

    ConnectAdjacentBlobs(rules, pos, team);//Connect adjacent blobs to this wire

    return true;
}

bool RemoveWire(Vec2f pos, u8 team)
{
    //Floor pos, then divide pos by tile size. This gets the wire position like it is a tile.
    //Check if a wire with this team is on this position, if not return false
    //If there is a wire on this pos, with this team, call onWireRemoved()
    //Remove the wire then return true.

    return true;
}

void onWireRemoved()
{
    //Check network of the wire to be removed

    //Check for amount of adjacent connected wires(of the same color?), if there are more than 1, split the networks.
    //Splitting logic: For ease, the inital network will be removed. But before that, make new networks across every adjacent wire(same color?) that was just cut off. and apply the new network to all connected blobs to those wires as well.

    //Get adjacent blobs where the wire was removed.
    //Check if they have the SignalConnector class.
    //If they do, remove it from the current network both input/output provided it is in that network.
    
    //If splitting logic was triggered, remove the current network.
}

//Converts all wires and blobs that are connected by the same wire, to a new network. 
void ConvertConnectedWireNetwork(u8 team, u16 old_net, u16 new_net)
{
    //Use a stack to go through every connected wire. Think maze algorithm. Unfortunately, I don't know a better way to do this. For each wire, check for adjacent blobs that are connected to the network as well. Only conver the network that is being converted.
    //Ignore what's written above, just loop through the array and change the old_net to the new_net. nothing so fancy. Hah, I'm lazy.
}

//Connects adjacent blobs to this position to the network of the wire on this position.
void ConnectAdjacentBlobs(CRules@ rules, Vec2f pos, u8 team)
{
    NuHub@ hub;
    if(!getHub(@hub)) { return; }

    Vec2f wire_pos = Nu::TilePosify(pos);//Convert world position into tile space.
    u16 wire_offset_pos = wire_pos.x * wire_pos.y;

    u16 net = hub.wire_positions[team][wire_offset_pos];


    CMap@ map = getMap();
    array<CBlob@> blobs;

    map.getBlobsInBox(wire_pos - Vec2f(map.tilesize, map.tilesize),//Upper left
        wire_pos + Vec2f(map.tilesize, map.tilesize),//Lower right
        blobs);//Blobs

    array<SignalNetwork@> networks;
    rules.get("W-N", networks);//Wire networks. W-N for short.

    for(u16 i = 0; i < blobs.size(); i++)
    {
        if(blobs[i] != @null)
        {
            SignalConnector@ signal_connector;
            blobs[i].get("sig-con", signal_connector);
            if(signal_connector != @null)
            {
                float angle = blobs[i].getPosition().AngleWithDegrees(pos);

                bool output = false;
                bool input = false;
                
                if(angle > 45 && angle <= 135)//right angle
                {
                    print("right");
                    if(signal_connector.network_output[1])  { output = true;    }
                    if(signal_connector.network_input[1])   { input = true;     }
                }
                else if(angle > 135 && angle <= 225)//Below
                {
                    print("below");
                    if(signal_connector.network_output[2])  { output = true;    }
                    if(signal_connector.network_input[2])   { input = true;     }
                }
                else if(angle > 225 && angle <= 315)//Left
                {
                    print("left");
                    if(signal_connector.network_output[3])  { output = true;    }
                    if(signal_connector.network_input[3])   { input = true;     }
                }
                else//Up angle
                {
                    print("Up");
                    if(signal_connector.network_output[0])  { output = true;    }
                    if(signal_connector.network_input[0])   { input = true;     }
                }

                if(input)
                {
                    networks[i].signal_inputs.push_back(@signal_connector);
                }
                if(output)
                {
                    networks[i].signal_outputs.push_back(@signal_connector);
                }
            }
        }
    }

    //Get adjacent blobs where the wire was built.
    //Check if they have the SignalConnector class.
    //If they do, check what side we are on in relation to the blob. Only add the SignalConnector to the network of the wire if the side the wire is on has a true in the array.
}

void UnconnectAdjacentBlobs(CRules@ rules, Vec2f pos, u8 team)
{
    //Get adjacent blobs where the wire was removed.
    //Check if they have the SignalConnector class.
    //If they do, check what side we are on in relation to the blob. Only remove the SignalConnector from the wire's network if the blob has a true in the array on the side of the wire.
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    //If this tile has a wire behind it
    //If the newTile does not support a wire
    //Remove each wire behind this position   
}

void onRender(CRules@ rules)
{
    if(!init) { return; }//If init has not yet happened

    if(false)//If wires are not supposed to be rendered for this client
    { return; }//Just don't render them
    
    NuHub@ hub;
    if(!getHub(@hub)) { return; }
    
}