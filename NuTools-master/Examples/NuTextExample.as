//Set gamemode to "Testing" for this to activate.
//See the top of NuTextCommon.as for how to create new fonts to add. 

#include "NuMenuCommon.as";
#include "NuTextCommon.as";

void onInit( CRules@ this )
{
    if(!isClient())
    {
        return;
    }
    
    init = true;

    NuHub@ hub;
    if(!getHub(@hub)) { return; }

    //Example of how to add a font.
    //hub.addFont("FontName",//Font render name.
    //    "Font.png");//Font file

    print("Text Example Creation");

    is_world_pos = true;//Do note that when rendering text alone (without a menu), you must manually set if it should be on the world position or the screen position.
    
    @text_test = @NuText("Lato-Regular",//What is the text's font
        "Hello World!\n! @ # $ % ^ & * ( ) _ + } { ");//What does the text draw.

    text_test.setString(text_test.getString() + "\nNext Line!");//Get and add something to NuText's string.
    
    text_test.setColor(SColor(255, 255, 0, 0));//What color is this text.
    
    text_test.setWidthCap(200.0f);//When will the text forcefuly next line to not go past this width.

    text_test.setAngle(0.0f);//What angle is the text at.
}

void onReload( CRules@ this )
{
    onInit(this);
}

void onTick( CRules@ this )
{

   
}

NuText@ text_test;

bool is_world_pos;

bool init;

void onRender(CRules@ this)
{
    if(!init){ return; }//If the init has not yet happened.
    
    if(!is_world_pos)//Is not world pos.
    {
        Render::SetTransformScreenspace();//Render the text on the screen.
    }
    else//World pos
    {
        Render::SetTransformWorldspace();//Render the text on the world.
    }

    text_test.Render(//Render the text
        Vec2f(128.0f, 128.0f),//At what position is this text drawn at.
        0);//What state is the text drawn in. (can be ignored and removed. state is a way to store details on states if desired. Most importantly used for example, what color text will be on x button state. I.E button being pressed/hovered.)
}