
#include "LoaderColors.as";
#include "CustomBlocks.as";

const u16[][] t_empty_grid = {{}};
const string[][] b_empty_grid = {{}};

const int canvas_bg        = 0xfff5c485;
const int canvas_bg_darker = 0xffdda45a;
const int canvas_border    = 0xff472a03;
const int canvas_outline   = 0xffffffff;

u16[][] buildTileGrid(string filename)
{
    u16[][] grid;
    CFileImage@ image;
	CMap@ map;

    @image = CFileImage(filename);

	if(image.isLoaded())
	{
        u16 i = 0;
        u16 j = 0;

        int w = image.getWidth(); 
        int h = image.getHeight();

        grid.set_length(h);

        while(image.nextPixel() && w != 0 && h != 0)
		{
			const SColor pixel = image.readPixel();
			const int offset = image.getPixelOffset();
            int pixel_color = pixel.color;

            bool skip = (pixel_color == canvas_bg || pixel_color == canvas_border 
                || pixel_color == canvas_bg_darker || pixel_color == canvas_outline);

            u16 t = 0;

			if (pixel_color != map_colors::sky)
			{
				switch (pixel_color)
			    {
			        case map_colors::tile_castle:           t = CMap::tile_castle;              break;
			        case map_colors::tile_castle_back:      t = CMap::tile_castle_back;         break;
			        case map_colors::tile_wood:             t = CMap::tile_wood;                break;
			        case map_colors::tile_wood_back:        t = CMap::tile_wood_back;           break;
			        case map_colors::tile_scrap:            t = CMap::tile_scrap;               break;
                    case map_colors::platform_up:           t = blobTileMap::platform_up;       break;
			        case map_colors::platform_right:        t = blobTileMap::platform_right;    break;
			        case map_colors::platform_down:         t = blobTileMap::platform_down;     break;
			        case map_colors::platform_left:         t = blobTileMap::platform_left;     break;
			    }
		    }

            if (!skip)
            {
                grid[i].push_back(t);
            }

            j++;
            i = Maths::Floor(j/w);
        }
    }
    return grid;
}