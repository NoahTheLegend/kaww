#include "NuLib.as";
#include "NuHub.as";

array<Nu::NuImage@> image_array;
Nu::NuImage@ image_rough;
Nu::NuImage@ image_vignette;
Nu::NuImage@ image_text;
Nu::NuImage@ black_pixel;

u16 fade_time = 30 * 2;//x seconds. How long it takes to fade between images.
u16 until_fade_time = 30 * 3.5;//How long after finishing a fade, until the next fade will start.

s16 current_fade = 1;//Starts at fade_time, goes down to 0, then gets set back to fade_time activating current_until_fade.
s16 current_until_fade = 0;//Starts at until_fade_time, goes down to 0, then gets set back to until_fade_time activating current_fade.

u8 splash_front;// Image to render in front (will fade out)
u8 splash_back;// Image to render behind will stay opaque. and it will become the front image once fade is done

u16 times_faded = 0;//Amount of times one image has faded out and a new image has faded in.
u16 max_times_faded = 3;//Amount of times images can be faded between before stopping.


void onInit(CRules@ rules)
{
    if (!isClient()) { return; }

    @black_pixel = @Nu::NuImage();
    black_pixel.CreateImage("BlackPixel.png");
    // ! combine vignette and rough
    //@image_vignette = @Nu::NuImage();
    //image_vignette.CreateImage("VignetteSplash.png"); // Overlay over everything

    //@image_rough = @Nu::NuImage();
    //image_rough.CreateImage("KAWWrough.png");

    @image_text = @Nu::NuImage();
    image_text.CreateImage("text_splash.png"); // Text that will display over image continuously 

    @black_pixel = @Nu::NuImage();
    black_pixel.CreateImage("BlackPixel.png");

    //image_array = array<Nu::NuImage@>(3);
    //for(u16 i = 0; i < image_array.size(); i++)
    //{
    //    Nu::NuImage@ _image = @Nu::NuImage();
    //    _image.CreateImage("KAWWback" + i + ".png");
//
    //    @image_array[i] = @_image;
    //}

    u8 pos = Nu::getRandomInt(image_array.size());//Returns a random position in the array

    splash_back = pos;

    //Sound::Play("Splash_Intro" + Nu::getRandomInt(4)); // Random intro theme
}

void onReload(CRules@ rules)//when rebuild is called
{
    onInit(rules);
}

//Puts splash_back on splash front, randomizes splash_back to be something splash_front isn't.
void getNewSplash()
{
    splash_front = splash_back;
    if(image_array.size() < 2) { error("image_array.size() was below 2, this would cause an infinite loop if it were allowed to run."); return; }

    do//Do once
    {
        splash_back = Nu::getRandomInt(image_array.size());//Get a random pos
    } while(splash_back == splash_front);//Do once more if pos was equal to splash_front.

    times_faded += 1;
}

void onTick(CRules@ rules)
{
    if (!isClient()) { return; }

    if (current_until_fade == 0) //Until fade complete
    {
        if (current_fade != 0) //Current fade complete
        {
            current_fade -= 1;
            if (current_fade == 0)
            {
                getNewSplash();
                current_until_fade = until_fade_time;
                current_fade = fade_time;
            }
        }
    }
    else
    {
        current_until_fade -= 1;
    }
    
    if (times_faded >= max_times_faded)
    {
        return;
    }

    //Screen sizing
    //image_array[splash_back].setPointUpperLeft(Vec2f(0,0));
    image_array[splash_back].setPointLowerRight(Vec2f(getScreenWidth(), getScreenHeight()));
    image_array[splash_front].setPointLowerRight(Vec2f(getScreenWidth(), getScreenHeight()));

    if (times_faded + 1 < max_times_faded)//If this is not the last iteration
    {
        black_pixel.setPointLowerRight(Vec2f(getScreenWidth(), getScreenHeight()));
        RenderImage(
            Render::layer_posthud, // layer
            black_pixel,
            Vec2f(0.0f,0.0f), // pos
            false); // is drawn on the world?

        u8 back_alpha =  Maths::Lerp(255, 0, current_fade / f32(fade_time));
        image_array[splash_back].setColor(SColor(back_alpha, 255, 255, 255));
        
        RenderImage(
            Render::layer_posthud, // layer
            image_array[splash_back],
            Vec2f(0.0f,0.0f), // pos
            false); // is drawn on the world?
    }

    u8 front_alpha = Maths::Lerp(0, 255, Maths::Clamp((current_fade / f32(fade_time)) * 2, 0, 1));
    image_array[splash_front].setColor(SColor(front_alpha, 255, 255, 255));
    
    //RenderImage(
    //    Render::layer_posthud, // layer
    //    image_array[splash_front],
    //    Vec2f(0.0f,0.0f), // pos
    //    false); // is drawn on the world?

    if (times_faded + 1 == max_times_faded)//If this is the last iteration
    {
        // fade out text overlay and the vignette
        //image_vignette.setColor(SColor(front_alpha, 255, 255, 255));
        //image_rough.setColor(SColor(front_alpha, 255, 255, 255));
        image_text.setColor(SColor(front_alpha, 255, 255, 255));
    }
    /*
    RenderImage(
        Render::layer_posthud, // layer
        image_vignette,
        Vec2f(0.0f,0.0f), // pos
        false); // is drawn on the world?

    RenderImage(
        Render::layer_posthud, // layer
        image_rough,
        Vec2f(0.0f,0.0f), // pos
        false); // is drawn on the world?
        */

    RenderImage(
        Render::layer_posthud, // layer
        image_text, // Text
        Vec2f(0.0f,0.0f), // pos
        false); // is drawn on the world?
}