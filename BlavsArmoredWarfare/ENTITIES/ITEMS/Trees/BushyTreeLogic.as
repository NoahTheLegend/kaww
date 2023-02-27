// Bushy tree Logic

#include "TreeSync.as"
#include "TreeCommon.as";

const string spritefile = "BushyTree.png";

void onInit(CBlob@ this)
{
	InitVars(this);

	s32 seed = 0;

	if (this.exists("tree_rand"))
	{
		seed = this.get_s32("tree_rand");
	}
	else
	{
		seed = this.getNetworkID() * 139 + getGameTime() * 7;
		if (isServer())
		{
			this.set_s32("tree_rand", seed);
			this.Sync("tree_rand", true);
		}
	}

	this.server_setTeamNum(-1);
	TreeVars vars;
	vars.r.Reset(seed);
	vars.growth_time = 250 + vars.r.NextRanged(30);
	vars.height = 0;
	vars.max_height = 3 + vars.r.NextRanged(4);
	vars.grown_times = 0;
	vars.max_grow_times = 50;
	vars.last_grew_time = getGameTime() - 1; //pretend we started a frame ago ;)
	this.SetFacingLeft(vars.r.NextRanged(300) > 150);
	InitTree(this, vars);
	this.set("TreeVars", vars);

	u8 icon_frame = 8;
	if (this.hasTag("startbig")) icon_frame = 10;

	reloadSprite(this);
}

void reloadSprite(CBlob@ this)
{
	if (getBlobByName("info_desert") !is null)
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.ReloadSprite("BushyTreeDesert.png", sprite.getFrameWidth(), sprite.getFrameHeight());
			for (int j = 0; j < sprite.getSpriteLayerCount(); j++)
			{
				CSpriteLayer @layer = sprite.getSpriteLayer(j);
				if (layer !is null)
				{
					layer.ReloadSprite("BushyTreeDesert.png", layer.getFrameWidth(), layer.getFrameHeight());
				}
			}
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 3)
	{
		reloadSprite(this);
	}
	if (isServer() && this.getTickSinceCreated() == 1)
	{
		if (isServer())
		{
			if (getBlobByName("info_snow") !is null) this.set_u8("particle type", 1);
			else if (getBlobByName("info_desert") !is null) this.set_u8("particle type", 2);
			else this.set_u8("particle type", 0);

			this.Sync("particle type", true);
		}

		if (getBlobByName("info_snow") !is null)
		{
			CBlob@ tree = server_CreateBlobNoInit("tree_pine");
			if(tree !is null)
			{
				tree.Tag("startbig");
				tree.setPosition(this.getPosition());
				tree.Init();
				this.Tag("no logs");
				this.server_Die();
			}
		}
	}
	if (this.get_u16("grow check tick frequency") != 0 
		&& this.getTickSinceCreated() % this.get_u16("grow check tick frequency") == 0)
	{
		GrowCheck(this);
	}
	
	if (this.exists("cut_down_time")				// tree is falling
		|| this.get_u8("wiggly leaves count") == 0)	// no leaves to wiggle
	{
		return;
	}

	if (this.get_u16("leaf proximity check tick frequency") != 0
		&& this.getTickSinceCreated() % this.get_u16("leaf proximity check tick frequency") == 0)
	{
		LeafProximityCheck(this);
	}
	
	ProcessLeafWiggle(this);
}

void GrowSprite(CSprite@ this, TreeVars@ vars)
{
	CBlob@ blob = this.getBlob();
	if (vars is null)
		return;

	if (vars.height == 0)
	{
		this.animation.frame = 0;
	}
	else //vanish
	{
		this.animation.frame = 1;
	}

	TreeSegment[]@ segments;
	blob.get("TreeSegments", @segments);
	if (segments is null)
		return;
	for (uint i = 0; i < segments.length; i++)
	{
		TreeSegment@ segment = segments[i];

		if (segment !is null && !segment.gotsprites)
		{
			segment.gotsprites = true;

			if (segment.grown_times == 1)
			{
				CSpriteLayer@ newsegment = this.addSpriteLayer("segment " + i, spritefile, 32, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(18);
					animGrow.AddFrame(18);

					if (i == 0)
					{
						animGrow.AddFrame(6);
						animGrow.AddFrame(12);

						if (segment.r.NextRanged(2) == 0)
						{
							animGrow.AddFrame(25);
						}
						else
						{
							animGrow.AddFrame(31);
						}
					}
					else
					{
						animGrow.AddFrame(24);

						if (i == vars.max_height - 1)
						{
							animGrow.AddFrame(7);
							animGrow.AddFrame(13);
						}
						else
						{
							animGrow.AddFrame(30);
							animGrow.AddFrame(19);
						}
					}

					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-100.0f - vars.height);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));

					newsegment.SetFacingLeft(segment.flip);

					Vec2f offset = segment.start_pos + Vec2f(-8, 0);
					newsegment.SetOffset(offset);
				}
			}
			else if (segment.grown_times == 3 && i > 0 && i != vars.max_height - 1)
			{
				f32 scalex = 1.0f;

				if (segment.flip)
				{
					scalex = -1.0f;
				}

				for (int spriteindex = 0; spriteindex < 3; spriteindex++)
				{
					string layerName = "leaves " + i + " " + spriteindex;	
					CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						float z = -550.0f - (vars.height / 100.0f);

						if ((i < 2 && segment.r.NextRanged(2) == 0) || spriteindex != 2)
						{
							animGrow.AddFrame(8);
						}
						else
						{
							SaveWigglyLeaf(blob, layerName);
							animGrow.AddFrame(9);
							z =  510.0f + (vars.height * 10.0f);
						}

						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(z);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						Vec2f offset = Vec2f(5 * scalex, -8);

						if (spriteindex == 1)
						{
							offset = Vec2f(-10 * scalex, 0);
						}
						else if (spriteindex == 2)
						{
							offset = Vec2f(16 * scalex, -4);
						}

						newsegment.TranslateBy(segment.start_pos + offset);
					}
				}
			}
			else if (i == 0 && segment.grown_times == 4) //add roots
			{
				f32 flipsign = 1.0f;
				CSpriteLayer@ newsegment = this.addSpriteLayer("roots", spritefile, 32, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame((segment.r.NextRanged(2) == 0 ? 2 : 8));

					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-80.0f);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					newsegment.SetOffset(segment.start_pos + Vec2f(0, 8.0f));

					newsegment.SetFacingLeft(segment.flip);
				}
			}
			else if (segment.grown_times == 4 && i == vars.max_height - 1) //top of the tree
			{
				string layerName = "extra leaves top";
				CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					float z = -550.0f;
					SaveWigglyLeaf(blob, layerName);
					animGrow.AddFrame(9);
					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(z);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					Vec2f offset = Vec2f(0, -10);
					newsegment.TranslateBy(segment.start_pos + offset);
				}
			}
			else if (segment.grown_times == 5 && i == vars.max_height - 1) //top of the tree
			{
				f32 scalex = 1.0f;
				if (segment.r.NextRanged(2) == 0)
				{
					scalex = -1.0f;
				}

				for (int spriteindex = 0; spriteindex < 3; spriteindex++)
				{
					string layerName = "leaves " + i + " " + spriteindex;
					CSpriteLayer@ newsegment = this.addSpriteLayer(layerName, spritefile, 32, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						float z = -550.0f - (vars.height * 10.0f);

						if (spriteindex == 0)
						{
							animGrow.AddFrame(8);
						}
						else
						{
							SaveWigglyLeaf(blob, layerName);
							
							animGrow.AddFrame(9);
							z =  500.0f + (vars.height * 10.0f);
						}

						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(z);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						Vec2f offset = Vec2f(16 * scalex, 4);

						if (spriteindex == 1)
						{
							offset = Vec2f(-16 * scalex, -4);
						}
						else if (spriteindex == 2)
						{
							offset = Vec2f(22 * scalex, -12);
						}

						newsegment.TranslateBy(segment.start_pos + offset);
					}
				}

				{
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + 3, spritefile, 64, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(2);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(550.1f);
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						newsegment.TranslateBy(segment.end_pos);
					}
				}

				{
					CSpriteLayer@ newsegment = this.addSpriteLayer("leaves " + i + " " + 4, spritefile, 64, 32, 0, 0);

					if (newsegment !is null)
					{
						Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
						animGrow.AddFrame(5);
						newsegment.SetAnimation(animGrow);
						newsegment.ResetTransform();
						newsegment.SetRelativeZ(-550.0f - (i * 5.0f));
						newsegment.RotateBy(segment.angle, Vec2f(0, 0));
						newsegment.TranslateBy(segment.end_pos);
					}
				}
			}

			if (segment.grown_times < 5)
			{
				CSpriteLayer@ segmentlayer = this.getSpriteLayer("segment " + i);

				if (segmentlayer !is null)
				{
					segmentlayer.animation.frame++;

					if (i == vars.max_height - 1 && segment.grown_times == 3)
					{
						segmentlayer.SetOffset(segmentlayer.getOffset() + Vec2f(8, 0));
					}
				}
			}
		}
	}
}

void UpdateMinimapIcon(CBlob@ this, TreeVars@ vars)
{

}