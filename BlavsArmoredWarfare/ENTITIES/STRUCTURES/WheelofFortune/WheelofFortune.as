const string coin_input_green = "coin_input_green";
const string coin_input_blue = "coin_input_blue";
const string coin_input_yellow = "coin_input_yellow";

const string wheel_rot = "wheel rotation";

const string current_player = "current_player";

#include "GenericButtonCommon.as"


const uint spinSecs = 30; //60

void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();

    this.SetZ(-10); //background

    CSpriteLayer@ wheel = this.addSpriteLayer("wheel", "WheelofFortune.png", 25, 25, 0, 0);
    if (wheel !is null)
    {
        //default anim
        {
            Animation@ anim = wheel.addAnimation("default", 0, false);
            int[] frames = {2};
            anim.AddFrames(frames);
        }
        //wheel setup
        wheel.SetOffset(Vec2f(-6.0f, 7.0f));
        wheel.SetRelativeZ(10);
        wheel.SetVisible(true);
    }

    CSpriteLayer@ arrow = this.addSpriteLayer("arrow", "WheelofFortune.png", 11, 24, 0, 0);
    if (arrow !is null)
    {
        //default anim
        {
            Animation@ anim = arrow.addAnimation("default2", 0, false);
            int[] frames = {7};
            anim.AddFrames(frames);
        }

        arrow.SetOffset(Vec2f(-6.0f, 6.5f));
        arrow.SetRelativeZ(12);
        arrow.SetVisible(true);
    }

    // coin
    CSpriteLayer@ coingreen = this.addSpriteLayer("coingreen", "WheelofFortune.png", 24, 20, 0, 0);
    if (coingreen !is null)
    {
        Animation@ anim = coingreen.addAnimation("default3", 1, true);
        int[] frames = {8, 9, 10, 11, 12, 13, 14, 15};
        anim.AddFrames(frames);

        coingreen.SetOffset(Vec2f(18.5f, 2.5f));
        coingreen.SetRelativeZ(5);
        coingreen.SetVisible(true);
    }
    CSpriteLayer@ coinblue = this.addSpriteLayer("coinblue", "WheelofFortune.png", 24, 20, 0, 0);
    if (coinblue !is null)
    {
        Animation@ anim = coinblue.addAnimation("default4", 1, true);
        int[] frames = {8, 9, 10, 11, 12, 13, 14, 15};
        anim.AddFrames(frames);

        coinblue.SetOffset(Vec2f(13.5f, 2.5f));
        coinblue.SetRelativeZ(4);
        coinblue.SetVisible(true);
    }
    CSpriteLayer@ coinyellow = this.addSpriteLayer("coinyellow", "WheelofFortune.png", 24, 20, 0, 0);
    if (coinyellow !is null)
    {
        Animation@ anim = coinyellow.addAnimation("default5", 1, true);
        int[] frames = {8, 9, 10, 11, 12, 13, 14, 15};
        anim.AddFrames(frames);

        coinyellow.SetOffset(Vec2f(8.5f, 2.5f));
        coinyellow.SetRelativeZ(3);
        coinyellow.SetVisible(true);
    }
}

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

    this.set_u8(coin_input_green, 0);
    this.set_u8(coin_input_blue, 0);
    this.set_u8(coin_input_yellow, 0);

    this.set_f32(wheel_rot, 0);

    AddIconToken("$add_coin$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 25, 2);
    AddIconToken("$take_coin$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);

    //commands
    this.addCommandID("add coin green");
    this.addCommandID("take coin green");
    this.addCommandID("add coin blue");
    this.addCommandID("take coin blue");
    this.addCommandID("add coin yellow");
    this.addCommandID("take coin yellow");
    
    this.set_u32("spin secs", spinSecs);
    this.set_u32("spin time", getGameTime() + spinSecs * getTicksASecond());  

    this.set_bool("choosing", false);  

    this.set_f32("wheel velocity", 0.0f);

    this.set_u16(current_player, 0);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
    if (!canSeeButtons(this, caller)) return;

    CBitStream params;
    params.write_u16(caller.getNetworkID());

    bool choosing = this.get_bool("choosing");

    CPlayer@ player = caller.getPlayer();

    if (this.get_u8(coin_input_green) < 7)
    {
        CButton@ button = caller.CreateGenericButton("$add_coin$", Vec2f(-12.3f, -2.0f), this, this.getCommandID("add coin green"), getTranslatedString("Add coin to green"), params);
        if (button !is null)
        {
            button.deleteAfterClick = true;
            button.SetEnabled(player.getCoins() >= 10 && !choosing);
        }
    }
    if (this.get_u8(coin_input_green) > 0)
    {
        CButton@ button = caller.CreateGenericButton("$take_coin$", Vec2f(-12.3f, 6.0f), this, this.getCommandID("take coin green"), getTranslatedString("Take coin from green"), params);
        if (button !is null)
        {
            button.deleteAfterClick = true;
            button.SetEnabled(this.get_u8(coin_input_green) > 0 && !choosing);
        }
    }
    if (this.get_u8(coin_input_blue) < 7)
    {
        CButton@ button = caller.CreateGenericButton("$add_coin$", Vec2f(-6.3f, -2.0f), this, this.getCommandID("add coin blue"), getTranslatedString("Add coin to blue"), params);
        if (button !is null)
        {
            button.deleteAfterClick = true;
            button.SetEnabled(player.getCoins() >= 10 && !choosing);
        }
    }
    if (this.get_u8(coin_input_blue) > 0)
    {
        CButton@ button = caller.CreateGenericButton("$take_coin$", Vec2f(-6.3f, 6.0f), this, this.getCommandID("take coin blue"), getTranslatedString("Take coin from blue"), params);
        if (button !is null)
        {
            button.deleteAfterClick = true;
            button.SetEnabled(this.get_u8(coin_input_blue) > 0 && !choosing);
        }
    }
    if (this.get_u8(coin_input_yellow) < 7)
    {
        CButton@ button = caller.CreateGenericButton("$add_coin$", Vec2f(-0.3f, -2.0f), this, this.getCommandID("add coin yellow"), getTranslatedString("Add coin to yellow"), params);
        if (button !is null)
        {
            button.deleteAfterClick = true;
            button.SetEnabled(player.getCoins() >= 10 && !choosing);
        }
    }
    if (this.get_u8(coin_input_yellow) > 0)
    {
        CButton@ button = caller.CreateGenericButton("$take_coin$", Vec2f(-0.3f, 6.0f), this, this.getCommandID("take coin yellow"), getTranslatedString("Take coin from yellow"), params);
        if (button !is null)
        {
            button.deleteAfterClick = true;
            button.SetEnabled(this.get_u8(coin_input_yellow) > 0 && !choosing);
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    CSprite@ blob = this.getSprite();

    if (cmd == this.getCommandID("add coin green"))
    {
        CBlob@ caller = getBlobByNetworkID(params.read_u16()); if (caller is null) return;
        CBlob@ carried = caller.getCarriedBlob();

        if (this.get_u16(current_player) != caller.getNetworkID() && this.get_u16(current_player) != 0) return;

        CPlayer@ player = caller.getPlayer();
        if (player !is null)
    	{
    		player.server_setCoins(player.getCoins() - 10);
    	}
        
        this.set_u8(coin_input_green, this.get_u8(coin_input_green) + 1);
        blob.PlaySound("/AddCoins", 2.4f, (XORRandom(10)/30)+0.82f);

        this.set_u16(current_player, caller.getNetworkID());
    }
    if (cmd == this.getCommandID("take coin green"))
    {
        CBlob@ caller = getBlobByNetworkID(params.read_u16()); if (caller is null) return;
        if (this.get_u16(current_player) != caller.getNetworkID() && this.get_u16(current_player) != 0) return;

        CPlayer@ player = caller.getPlayer();
        if (player !is null)
    	{
    		player.server_setCoins(player.getCoins() + 10);
    	}

        this.set_u8(coin_input_green, this.get_u8(coin_input_green) - 1);
        blob.PlaySound("/TakeCoins", 2.4f, 1.0f);

        if (this.get_u8(coin_input_green) == 0 && this.get_u8(coin_input_blue) == 0 && this.get_u8(coin_input_yellow) == 0)
        {
            this.set_u16(current_player, 0);
            return;
        }
    }
    if (cmd == this.getCommandID("add coin blue"))
    {
        CBlob@ caller = getBlobByNetworkID(params.read_u16()); if (caller is null) return;
        CBlob@ carried = caller.getCarriedBlob();

        if (this.get_u16(current_player) != caller.getNetworkID() && this.get_u16(current_player) != 0) return;

        CPlayer@ player = caller.getPlayer();
        if (player !is null)
    	{
    		player.server_setCoins(player.getCoins() - 10);
    	}

        this.set_u8(coin_input_blue, this.get_u8(coin_input_blue) + 1);
        blob.PlaySound("/AddCoins", 2.4f, (XORRandom(10)/30)+0.82f);

        this.set_u16(current_player, caller.getNetworkID());
    }
    if (cmd == this.getCommandID("take coin blue"))
    {
        CBlob@ caller = getBlobByNetworkID(params.read_u16()); if (caller is null) return;
        if (this.get_u16(current_player) != caller.getNetworkID() && this.get_u16(current_player) != 0) return;

        CPlayer@ player = caller.getPlayer();
        {
    		player.server_setCoins(player.getCoins() + 10);
    	}

        this.set_u8(coin_input_blue, this.get_u8(coin_input_blue) - 1);
        blob.PlaySound("/TakeCoins", 2.4f, 1.0f);

        if (this.get_u8(coin_input_green) == 0 && this.get_u8(coin_input_blue) == 0 && this.get_u8(coin_input_yellow) == 0)
        {
            this.set_u16(current_player, 0);
            return;
        }
    }
    if (cmd == this.getCommandID("add coin yellow"))
    {
        CBlob@ caller = getBlobByNetworkID(params.read_u16()); if (caller is null) return;
        CBlob@ carried = caller.getCarriedBlob();

        if (this.get_u16(current_player) != caller.getNetworkID() && this.get_u16(current_player) != 0) return;

        CPlayer@ player = caller.getPlayer();
        {
    		player.server_setCoins(player.getCoins() - 10);
    	}

        caller.TakeBlob("coin", 1);
        this.set_u8(coin_input_yellow, this.get_u8(coin_input_yellow) + 1);
        blob.PlaySound("/AddCoins", 2.4f, (XORRandom(10)/30)+0.82f);

        this.set_u16(current_player, caller.getNetworkID());
    }
    if (cmd == this.getCommandID("take coin yellow"))
    {
        CBlob@ caller = getBlobByNetworkID(params.read_u16()); if (caller is null) return;
        if (this.get_u16(current_player) != caller.getNetworkID() && this.get_u16(current_player) != 0) return;

        CPlayer@ player = caller.getPlayer();
        {
    		player.server_setCoins(player.getCoins() + 10);
    	}

        this.set_u8(coin_input_yellow, this.get_u8(coin_input_yellow) - 1);
        blob.PlaySound("/TakeCoins", 2.4f, 1.0f);

        if (this.get_u8(coin_input_green) == 0 && this.get_u8(coin_input_blue) == 0 && this.get_u8(coin_input_yellow) == 0)
        {
            this.set_u16(current_player, 0);
            return;
        }
    }
}

void onTick(CBlob@ this)
{
    if (this.get_f32(wheel_rot) > 360.0f)
        this.set_f32(wheel_rot, this.get_f32(wheel_rot) - 360);

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;
    CSpriteLayer@ coingreen = sprite.getSpriteLayer("coingreen");
    if (coingreen is null) return;
    Animation@ animgreen = coingreen.getAnimation("default3");
    if (animgreen is null) return;

    animgreen.frame = this.get_u8(coin_input_green)-1;

    CSpriteLayer@ coinblue = sprite.getSpriteLayer("coinblue");
    if (coinblue is null) return;
    Animation@ animblue = coinblue.getAnimation("default4");
    if (animblue is null) return;

    animblue.frame = this.get_u8(coin_input_blue)-1;

    CSpriteLayer@ coinyellow = sprite.getSpriteLayer("coinyellow");
    if (coinyellow is null) return;
    Animation@ animyellow = coinyellow.getAnimation("default5");
    if (animyellow is null) return;

    animyellow.frame = this.get_u8(coin_input_yellow)-1;

    this.set_f32("wheel velocity", this.get_f32("wheel velocity") * 0.988f);

    bool choosing = this.get_bool("choosing");

    if (choosing)
    {
        if (this.get_f32("wheel velocity") < 0.04f)
        {
            this.set_f32("wheel velocity", 0.0f);

            choosing = false;
        }
    }

    this.set_bool("choosing", choosing);
}

void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();

    Vec2f pos2d = blob.getScreenPos();
    u32 gameTime = getGameTime();
    u32 spinTime = blob.get_u32("spin time");
    bool choosing = blob.get_bool("choosing");

    if (spinTime > gameTime && !choosing)
    {
        CBlob@ blob = this.getBlob();
        Vec2f center = blob.getPosition();
        Vec2f mouseWorld = getControls().getMouseWorldPos();
        const f32 renderRadius = (blob.getRadius()) * 0.96f;
        bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;

        if (!g_videorecording && mouseOnBlob)
        {
            int top = pos2d.y - 1.0f * blob.getHeight();
            Vec2f dim(32.0f, 12.0f);
            int secs = 1 + (spinTime - gameTime) / getTicksASecond();
            Vec2f upperleft(pos2d.x - dim.x / 2, top - dim.y - dim.y);
            Vec2f lowerright(pos2d.x + dim.x / 2, top - dim.y);
            f32 progress = 1.0f - (float(secs) / float(blob.get_u32("spin secs")));
            GUI::DrawProgressBar(upperleft, lowerright, progress);

            GUI::DrawText("Wheel spinning in "+ secs + " seconds!", upperleft - Vec2f(32.0f, 16.0f), SColor(255, 255, 255, 255));

            if (blob.get_u16(current_player) != 0)
            {
            	GUI::DrawText("Wheel is currently being used.", upperleft - Vec2f(32.0f, 28.0f), SColor(255, 255, 255, 255));
        	}
        }
    }
    else if (spinTime <= gameTime)
    {
        if (spinTime == gameTime)
        {
            choosing = true;
        }

        if (choosing)
        {
            if (spinTime == gameTime)
            {
                blob.set_f32("wheel velocity", 13.0f + XORRandom(3));

                this.PlaySound("/Start", 2.2, 1.0f);
            }
            
            if (Maths::Round(blob.get_f32(wheel_rot)) % 20 == 0)
            {
                this.PlaySound("/Tick", (XORRandom(10)/20)+0.8, 1.0f);
            }  
        }
        else
        {
            if (blob.get_u8(coin_input_green) > 0 || blob.get_u8(coin_input_blue) > 0 || blob.get_u8(coin_input_yellow) > 0)
            {
                int r = 1;

                int wheel = blob.get_f32(wheel_rot);

                if (wheel > 0 && wheel < 22.5)
                    r = 2;
                if (wheel > 22.5 && wheel < 45)
                    r = 1;
                if (wheel > 45 && wheel < 67.5)
                    r = 0;
                if (wheel > 67.5 && wheel < 90)
                    r = 1;
                if (wheel > 90 && wheel < 112.5)
                    r = 2;
                if (wheel > 112.5 && wheel < 135)
                    r = 1;
                if (wheel > 135 && wheel < 157.5)
                    r = 2;
                if (wheel > 157.5 && wheel < 180)
                    r = 1;
                if (wheel > 180 && wheel < 202.5)
                    r = 3;
                if (wheel > 202.5 && wheel < 225)
                    r = 1;
                if (wheel > 225 && wheel < 247.5)
                    r = 0;
                if (wheel > 247.5 && wheel < 270)
                    r = 1;
                if (wheel > 270 && wheel < 292.5)
                    r = 3;
                if (wheel > 292.5 && wheel < 315)
                    r = 1;
                if (wheel > 315 && wheel < 337.5)
                    r = 2;
                if (wheel > 337.5 && wheel < 360)
                    r = 1;

                switch (r)
                {
                    case 0:
                    {
                        //red
                        this.PlaySound("/Fail", 4.0, 1.0f);

                        break;
                    }
                    case 1:
                    {
                        if (blob.get_u8(coin_input_green) > 0)
                        {

                            //green
                            for (int i = 1; i < (blob.get_u8(coin_input_green)*2)+1; i++)
                            {
                                CBlob@ spawn = server_CreateBlob("coinsblob", -1, blob.getPosition());
                            	if (spawn !is null)
                            	{
                            		spawn.set_u16(current_player, blob.get_u16(current_player));

									Vec2f vel(5 - XORRandom(10), -1.0f - XORRandom(5));
									spawn.setVelocity(vel);
                            	}
                            }
                            this.PlaySound("/WinGreen", 4.0, 1.0f);
                        }
                        else
                        {
                            this.PlaySound("/Fail", 4.0, 1.0f);
                        }
                        break;
                    }
                    case 2:
                    {
                        if (blob.get_u8(coin_input_blue) > 0)
                        {
                            //blue
                            for (int i = 1; i < (blob.get_u8(coin_input_blue)*3)+1; i++)
                            {
                            	CBlob@ spawn = server_CreateBlob("coinsblob", -1, blob.getPosition());
                            	if (spawn !is null)
                            	{
                            		spawn.set_u16(current_player, blob.get_u16(current_player));

									Vec2f vel(5 - XORRandom(10), -1.0f - XORRandom(5));
									spawn.setVelocity(vel);
                            	}
                            }
                            this.PlaySound("/WinBlue", 4.0, 1.0f);
                        }
                        else
                        {
                            this.PlaySound("/Fail", 4.0, 1.0f);
                        }
                        break;
                    }
                    case 3:
                    {
                        if (blob.get_u8(coin_input_yellow) > 0)
                        {
                            //yellow
                            for (int i = 1; i < (blob.get_u8(coin_input_yellow)*5)+1; i++)
                            {
                            	CBlob@ spawn = server_CreateBlob("coinsblob", -1, blob.getPosition());
                            	if (spawn !is null)
                            	{
                            		spawn.set_u16(current_player, blob.get_u16(current_player));

									Vec2f vel(5 - XORRandom(10), -1.0f - XORRandom(5));
									spawn.setVelocity(vel);
                            	}
                            }
                            this.PlaySound("/WinYellow", 4.0, 1.0f);
                            this.PlaySound("/Jackpot", 4.0, 1.0f);
                        }
                        else
                        {
                            this.PlaySound("/Fail", 4.0, 1.0f);
                        }
                        break;
                    }
                }
            }

            blob.set_u8(coin_input_green, 0);
            blob.set_u8(coin_input_blue, 0);
            blob.set_u8(coin_input_yellow, 0);

            blob.set_u32("spin secs", spinSecs);
            blob.set_u32("spin time", getGameTime() + spinSecs * getTicksASecond());  

            blob.set_u16(current_player, 0);
        }
    }

    if (this is null) return;
    CSpriteLayer@ wheel = this.getSpriteLayer("wheel");
    if (wheel is null) return;

    wheel.RotateBy(blob.get_f32("wheel velocity"), Vec2f());
    blob.set_f32(wheel_rot, blob.get_f32(wheel_rot) + blob.get_f32("wheel velocity"));

    int top = pos2d.y - 1.0f * blob.getHeight();
    Vec2f dim(32.0f, 12.0f);
    Vec2f upperleft(pos2d.x - dim.x / 2, top - dim.y - dim.y);

    blob.set_bool("choosing", choosing);
}