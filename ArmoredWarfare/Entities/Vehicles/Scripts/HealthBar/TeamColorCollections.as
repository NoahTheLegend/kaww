
SColor getNeonColor(u8 team, u8 darkness)
{
    SColor color_light = 0xffd8d8d8;
    SColor color_mid = 0xff989898;
    SColor color_dark = 0xff555555;
    switch (team)
	{
		case 0: // blue
		{
			color_light = 0xff2cafde;
			color_mid	= 0xff1d85ab;
			color_dark	= 0xff1a4e83;
			break;
		}
		case 1: // red
		{
			color_light = 0xffd5543f;
			color_mid	= 0xffb73333;
			color_dark	= 0xff941b1b;
			break;
		}
		case 2: // green
		{
			color_light = 0xff5dc125;
			color_mid	= 0xff429720;
			color_dark	= 0xff295d14;
			break;
		}
		case 3: // purple
		{
			color_light = 0xff9152f7;
			color_mid	= 0xff6f3bc5;
			color_dark	= 0xff462480;
			break;
		}
		case 4: // orange
		{
			color_light = 0xffe89b45;
			color_mid	= 0xffaa671e;
			color_dark	= 0xff643909;
			break;
		}
		case 5: // cyan (changed to yellow)
		{
			color_light = 0xffc1cd00;
			color_mid	= 0xff969e00;
			color_dark	= 0xff727800;
			break;
		}
		case 6: // violet (changed to black)
		{
			color_light = 0xff555555;
			color_mid	= 0xff454545;
			color_dark	= 0xff252525;
			break;
		}
	}

    switch (darkness)
    {
        case 0:
        {
            return color_light;
        }
        case 1:
        {
            return color_mid;
        }
        case 2:
        {
            return color_dark;
        }
    }
    return color_mid;
}