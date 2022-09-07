#include "NuLib.as";

void onInit( CRules@ this )
{
    print("Hotbar Example Creation");
}

void onReload( CRules@ this )
{
    
}

void onTick( CRules@ this )
{
    if(!isClient()) { return; }
    //Add hotbar to player blobs. Feel free to do this in the cfg of the blob.
    
    CControls@ controls = getControls();

    if(controls != null)
    {
        if(controls.isKeyJustPressed(KEY_KEY_Z))
        {
            CBlob@ plob = getLocalPlayerBlob();
            if(plob != null)
            {
                if(!plob.hasScript("NuHotbar.as"))
                {
                    plob.AddScript("NuHotbar.as");
                    //TODO. Add config settings here.
                    
                    print("hotbar added.");
                }
                else
                {
                    print("hotbar already exists.");
                }
            }
        }
    }
}