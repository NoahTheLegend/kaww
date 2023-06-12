void ManageTracks(CBlob@ this)
{
    if (this.getSprite() !is null)
    {
        CSpriteLayer@ tracks = this.getSprite().getSpriteLayer("tracks");
		if (tracks !is null)
		{
			if (Maths::Abs(this.getVelocity().x) > 0.3f)
			{
				if ((this.getVelocity().x) > 0)
				{
					if (!this.isFacingLeft())
					{
						if ((this.getVelocity().x) > 1.5f)
						{
							if (!tracks.isAnimation("default"))
							{
								tracks.SetAnimation("default");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
						else
						{
							if (!tracks.isAnimation("slow"))
							{
								tracks.SetAnimation("slow");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
					}
					else if (!tracks.isAnimation("reverse"))
					{
						tracks.SetAnimation("reverse");
						tracks.animation.timer = 1;
						tracks.SetFrameIndex(0);
					}
					
				}
				else{
					if (this.isFacingLeft())
					{
						if ((this.getVelocity().x) > -1.5f)
						{
							if (!tracks.isAnimation("slow"))
							{
								tracks.SetAnimation("slow");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
						else
						{
							if (!tracks.isAnimation("default"))
							{
								tracks.SetAnimation("default");
								tracks.animation.timer = 1;
								tracks.SetFrameIndex(0);
							}
						}
					}
					else if (!tracks.isAnimation("reverse"))
					{
						tracks.SetAnimation("reverse");
						tracks.animation.timer = 1;
						tracks.SetFrameIndex(0);
					}
				}
			}
			else
			{
				tracks.SetAnimation("slow");
				tracks.animation.timer = 0;
            }
        }
    }
}