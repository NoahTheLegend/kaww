//Set gamemode to "Testing" for this to activate.

#include "NuMenuCommon.as";//For menus.
#include "NuLib.as";//For misc usefulness.
#include "NuTextCommon.as";//For text and fonts.
#include "NuHub.as";//For hauling around menus and fonts.

void onInit( CRules@ this )
{
    if(!isClient())
    {
        return;
    }

    NuHub@ hub;//First we make the hub variable.
    if(!getHub(@hub)) { return; }//Then we try to get it. 
    //The hub is the place that stores menus, helps you easily add them, and ticks them. (rendering is done elsewhere.) It also holds fonts, id's, lets you cast without kag breaking, and is generally useful.


    print("Menu Example Creation");


    NuMenu::GridMenu@ grid_menu = NuMenu::GridMenu(//This menu is a GridMenu. The GridMenu inherits from BaseMenu, and is designed to hold other menus in an array in a grid fashion.
        Vec2f(64, 64),//The top left of the menu.
        Vec2f(128 * 1, 128 * 1),//The bottom right of the menu.
        "TestMenu");//Name of the menu which you can get later.

    //Some useful functions.
    //grid_menu.setUpperLeft(Vec2f(0,0));
    //grid_menu.setLowerRight(Vec2f(0,0));
    //grid_menu.setPos(Vec2f(0,0));
    //grid_menu.getMiddle();

    grid_menu.setIsWorldPos(false);//At any time you can swap a menu to be on world position, or screen position. This tells the menu to work on the screen.

    grid_menu.clearBackgrounds();//Here we wipe the GridMenu's background.

    Nu::NuStateImage@ grid_image = Nu::NuStateImage(Nu::POSPositionsCount);//Here we create a state image with POSPositionCount states (for color and frames and stuff) 

    grid_image.CreateImage("grid_menu_image", "RenderExample.png");//Creates an image from a png

    grid_image.setFrameSize(Vec2f(32, 32));//Here we set the frame size of the image.

    grid_image.setDefaultFrame(3);//Sets the default frame to frame 3.

    grid_menu.addBackground(grid_image);//And here we add the grid_image as the background. The background image streches to meet the upper left and lower right.


    //How would you assign a grid of buttons to the menu?

    grid_menu.top_left_buffer = Vec2f(8.0f, 8.0f);//This allows you to change the distance of all the buttons from the top left of the menu

    grid_menu.setBuffer(Vec2f(32.0f, 32.0f));//This sets the buffer between buttons on the menu

    for(u16 x = 0; x < 4; x++)//Grid width
    {
        for(u16 y = 0; y < 4; y++)//Grid height
        {
            NuMenu::MenuButton@ buttony = NuMenu::MenuButton(Vec2f(32, 32), Vec2f(32 * 2, 32 * 2), x + "ButtonName" + y);//Create any menu of any sort and do whatever you want with it.        
            grid_menu.setMenu(x,//Set the position on the width of the grid
                y,//The position on the height of the grid
                @buttony);//And add the button
        }
    }










    hub.addMenuToList(grid_menu);//This tells the grid_menu to be ticked. It also stores it for other places to easily grab it.


    //Other menus.
    
    //Here we create a button.
    NuMenu::MenuButton@ button1 = NuMenu::MenuButton("ButtonName");

    button1.setSize(Vec2f(32, 32));//Here we tell the button to be 32 by 32.
    
    button1.setPos(Vec2f(25.0f, 270.0f));//Then we put it at this position.



    //There are several ways to see if a button was pressed.
    
    button1.addReleaseListener(@ButtonTestFunction);//A function.

    button1.send_to_rules = true;//If this is true, instead of sending a command to the buttons owner blob, it will send it to rules. 
    button1.setCommandID("CommandIDHere");//The command id can either be the string or u8 id. Either way it turns into a u8 id in the end.

    //button1.instant_press = true;//If this is true, the button will release upon first press. Sending the commands in the process.

    //button1.kill_on_release = true;//This being true will remove the button after it is released.

    //button1.enableRadius = 16.0f;//Provided this button has an owner blob, if the owner blob is farther away than this radius, the button will enter a disabled state and be unpressable.


    if(button1.getMenuClass() == NuMenu::ButtonClass){}//Check for what class a button is like this.

    //If you want a raidus collision rather than a collision box.
    button1.setRadius(80.0f);//This sets the radius of the button.
    button1.setCollisionLowerRight(Vec2f(0,0));//This sets the collision box's lower right to 0,0. removing it basicaly
    button1.setCollisionSetter(false);//By default if you change the size of the button, the collision box will match it. This stops that.

    button1.menu_sounds_on[NuMenu::Released] = "buttonclick.ogg";//This allows you to add a sound when a state is just changed to.
    button1.menu_volume = 3.0f;//This is the volume of said sound.

    //To send params,

    CBitStream@ params;//Create your params.
    @button1.params = @params;//Put them in the button.


    hub.addMenuToList(button1);//Add it to the do menu stuff array.




    NuMenu::MenuBaseExEx@ text_menu1 = NuMenu::MenuBaseExEx("Render_Test");
    
    text_menu1.setSize(Vec2f(200, 200));
    text_menu1.setPos(Vec2f(20.0f, 350.0f));

    text_menu1.default_buffer = 50.0f;//Buffer. For example how far text/icons are from the sides of the menu. Other buffery things too.

    //This is how you add an image to a menu.
    text_menu1.setImage("GUI/AccoladeBadges.png",//Image name
        Vec2f(16, 16),//Image frame size
        19,//Image frame
        18,//Image frame while hovered
        18,//Image frame while pressed
        Nu::POSTopLeft);//Position the image is in

    text_menu1.reposition_images = true;//While this is true, all images will automatically reposition if the menu changes it's size.


    text_menu1.setText("ZCenter textZ");//By default the text will be set to font Lato-Regular, and be put in element POSCenter which is at the center of the button.

    text_menu1.setText("ZTop textZ"   , Nu::POSTop);
    text_menu1.setText("ZAbove textZ" , Nu::POSAbove);

    text_menu1.setText("ZLeft textZ"  , Nu::POSLeft);
    text_menu1.setText("ZLefter textZ"  , Nu::POSLefter);

    text_menu1.setText("ZRight textZ" , Nu::POSRight);
    text_menu1.setText("ZRighter textZ" , Nu::POSRighter);

    text_menu1.setText("ZBottom textZ", Nu::POSBottom);
    text_menu1.setText("ZUnder textZ" , "Lato-Regular", Nu::POSUnder);//You can specify the font on creation.

    

    text_menu1.setFont("Lato-Regular");//Everything that changes the text should be set after text is created. The values are stored in the text afterall.
    
    text_menu1.setTextColor(SColor(255, 255, 0, 0));//By default these text setting changes affect all currently existing fonts.
    
    text_menu1.setTextColor(SColor(255, 0, 0, 255),
    Nu::POSTop);//Feel free to specifcy an element to change only one part of the text. This is an optional parameter present with other text setting changing methods too.

    text_menu1.setTextScale(0.3f);//Set the scale of all the text.

    text_menu1.reposition_text = true;//Same as icon repositioning, but for text.

    hub.addMenuToList(text_menu1);//Add it.







    NuMenu::MenuBase@ nothing_menu = NuMenu::MenuBase("Nothing");//Create a MenuBase menu with no parameters

    hub.addMenuToList(nothing_menu);//Add it.


}

void onReload( CRules@ this )
{
    NuHub@ hub;
    if(!getHub(@hub)) { return; }
    
    hub.ClearMenuList();//refresh all menu's on reload
    
    onInit(this);
}
//                    -Caller of button-     -Params-     -Menu pressed-
void ButtonTestFunction(CPlayer@ caller, CBitStream@ params, NuMenu::IMenu@ menu, u16 key_code)
{
    print("function: button was pressed. Button had name " + menu.getName());
}

void onTick( CRules@ this )
{
    NuHub@ hub;
    if(!getHub(@hub)) { return; }
   

    DebugOptionChanger(hub);//A method for messing around with a menu.
}





void DebugOptionChanger(NuHub@ hub)
{
    NuMenu::IMenu@ _menu = @null;//Make a menu var that can hold any menu type.
    if(hub.getMenuListSize() > 0)//If there is a menu in the menu array.
    {
        hub.getMenuFromList(0, _menu);//Grab it and put it in _menu.
    }

    CPlayer@ player = getLocalPlayer();
    if(player != null)//If the player is not null.
    {
        CControls@ controls = player.getControls();
        if(controls.isKeyPressed(KEY_LCONTROL))//If left control is being pressed.
        {
            if(_menu != null)//If _menu is not null.
            {
                if(controls.isKeyPressed(KEY_LBUTTON))//If left mouse is being pressed.
                {
                    Vec2f _pos;
                    if(_menu.isWorldPos())//If this menu is world pos
                    {
                        _pos = controls.getMouseWorldPos();//Set the upper left of the menu to the upper left of mouse world pos.
                    }
                    else
                    {
                        _pos = controls.getMouseScreenPos();//Set the upper left of the menu to the upper left of mouse screen pos.
                    }
                    _menu.setUpperLeft(_pos);//Set it.
                    print("upperleft mouse = " + _pos);//Print it.
                }
                if(controls.isKeyPressed(KEY_RBUTTON))//If right mouse is being pressed
                {
                    Vec2f _pos;
                    if(_menu.isWorldPos())
                    {
                        _pos = controls.getMouseWorldPos();
                    }
                    else
                    {
                        _pos = controls.getMouseScreenPos();
                    }

                    _menu.setLowerRight(_pos);
                    print("lowerright mouse = " + _pos);
                }
                if(controls.isKeyJustPressed(KEY_KEY_X))//If key x just pressed
                {
                    _menu.setInterpolated(!_menu.isInterpolated());//If interpolation is on, turn it off. If it's off, turn it on.
                    print("Interpolation of menu = " + _menu.isInterpolated());//Print what changed.
                }
                if(controls.isKeyJustPressed(KEY_KEY_Z))//If key z just pressed.
                {
                    _menu.setIsWorldPos(!_menu.isWorldPos());//If the menu is on world position, set it to screen position. Menu on screen position? set it to world position.
                    print("IsWorldPos = " + _menu.isWorldPos());//Print what changed.
                }
                if(controls.isKeyJustPressed(KEY_DELETE))//delete key just pressed?
                {
                    _menu.KillMenu();//Kill the menu.
                    print("Menu removed");//Print that we massacared this menu.
                }
            }
            if(controls.isKeyJustPressed(KEY_INSERT))//If key insert was just pressed.
            {
                int rnd_x = XORRandom(800) + 20;//Between 820 and 20 x
                int rnd_y = XORRandom(800) + 20;//Between 820 and 20 y
                NuMenu::MenuButton@ to_remove_button = NuMenu::MenuButton(//Create a menu button.
                    Vec2f(rnd_x, rnd_y),//Top left
                    Vec2f(rnd_x + rnd_x / 5, rnd_y + rnd_y / 5),//Bottom right
                    "delety." + hub.getMenuListSize());//Menu name
                to_remove_button.kill_on_release = true;//After pressing this button, delete it.

                hub.addMenuToList(to_remove_button);//Add this menu to the list.
                print("Menu added");//Inform the client of their newborn button.
            }
        }
    }
}