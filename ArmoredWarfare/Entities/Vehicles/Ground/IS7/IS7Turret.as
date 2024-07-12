void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("has mount");
	this.Tag("blocks bullet");
	this.Tag("fireshe");

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetOffset(Vec2f(-3,0));
	sprite.RemoveSpriteLayer("arm");
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", sprite.getConsts().filename, 32, 64);
	if (arm !is null)
	{
		Animation@ anim = arm.addAnimation("default", 0, false);
		anim.AddFrame(18);
	}

	if (getNet().isServer())
	{
		CBlob@ bow = server_CreateBlob("heavygun");	

		if (bow !is null)
		{
			bow.server_setTeamNum(this.getTeamNum());
			this.server_AttachTo(bow, "BOW1");
			this.set_u16("bowid", bow.getNetworkID());
	
			bow.SetFacingLeft(this.isFacingLeft());

			AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW1");
			if (point !is null)
				point.offsetZ = -60.0f;
		}
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
    if (!isServer()) return;

    AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW1");
	if (point !is null && point.getOccupied() !is null)
	{
		CBlob@ mg = point.getOccupied();
		mg.server_setTeamNum(this.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
    bool fl = this.isFacingLeft();
    ManageMG(this, fl);
}

void ManageMG(CBlob@ this, bool fl)
{
	if (!isServer()) return;

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("BOW1");
	if (point !is null && point.getOccupied() !is null)
	{
		CBlob@ mg = point.getOccupied();
		mg.SetFacingLeft(fl);
	}
}

void onDie(CBlob@ this)
{
	AttachmentPoint@ turret = this.getAttachments().getAttachmentPointByName("BOW1");
	if (turret !is null)
	{
		if (turret.getOccupied() !is null) turret.getOccupied().server_Die();
	}

	this.getSprite().PlaySound("/turret_die");
}
