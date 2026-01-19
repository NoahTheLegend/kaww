void Setup(SColor ImageColor, string test_name, bool is_fuzzy, bool override_tex = false)
{
	//ensure texture for our use exists
	if(!Texture::exists(test_name))
	{
		if(!Texture::createBySize(test_name, 8, 8))
		{
			warn("texture creation failed");
		}
		else
		{
			ImageData@ edit = Texture::data(test_name);

			for(int i = 0; i < edit.size(); i++)
			{
				edit[i] = ImageColor;
				
				if(is_fuzzy)
				{
					if(i / edit.width() == 0)//Top 
						edit[i].setAlpha(100);
					else if(i % edit.height() == 0)// Left 
						edit[i].setAlpha(100);
					else if(i % edit.width() == 0)//Right 
						edit[i].setAlpha(100);					
					else if(i >= edit.width() * edit.height() - edit.width())//Bottom 
						edit[i].setAlpha(100);
					
					else if(i / edit.width() == 1)//Top
						edit[i].setAlpha(160);
					else if(i % edit.height() == 1)//???? 
						edit[i].setAlpha(160);
					else if(i % edit.width() == 1)//Right?
						edit[i].setAlpha(160);					
					else if(i >= edit.width() * edit.height() - edit.width() - edit.width())//Bottom 
						edit[i].setAlpha(160);
				}
			}

			if(!Texture::update(test_name, edit))
			{
				warn("texture update failed");
			}
		}
	}
	if (override_tex)
	{
		ImageData@ edit = Texture::data(test_name);
		
		for(int i = 0; i < edit.size(); i++)
		{
			edit[i] = ImageColor;
		}

		Texture::update(test_name, edit);
	}
}