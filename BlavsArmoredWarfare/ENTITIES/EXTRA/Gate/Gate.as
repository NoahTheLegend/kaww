#include "DoorCommon.as"

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(false);

	this.getShape().SetRotationsAllowed(false);
	this.getSprite().getConsts().accurateLighting = true;
	
	this.Tag("blocks sword");
	this.Tag("blocks bullets");

	// 0 = 25
	// 1 = 50

	this.set_u16("openCost", (this.getTeamNum()+1)*25);
}

bool isOpen(CBlob@ this)
{
	return !this.getShape().getConsts().collidable;
}

void setOpen(CBlob@ this, bool open)
{
	CSprite@ sprite = this.getSprite();
	if (open)
	{
		sprite.SetZ(-100.0f);
		sprite.SetAnimation("open");
		this.getShape().getConsts().collidable = false;
		this.getCurrentScript().tickFrequency = 3;
		
		this.getSprite().PlaySound("/GateOpen.ogg", 1.5f, 1.0f);
	}
	
	const uint count = this.getTouchingCount();
	uint collided = 0;
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.isCollidable())
		{
			blob.AddForce(Vec2f(0, 0)); // Hack to awake sleeping blobs' physics
		}
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 2.0f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob && !isOpen(blob))
	{
		Vec2f dimensions;
		GUI::SetFont("menu");

		string mytext = "Open for $" + blob.get_u16("openCost");

		GUI::GetTextDimensions(mytext, dimensions);
		GUI::DrawText(getTranslatedString(mytext), getDriver().getScreenPosFromWorldPos(blob.getPosition() - Vec2f(0, -blob.getHeight() / 2)) - Vec2f(dimensions.x / 2, -8.0f), SColor(200, 255, 255, 255));
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.hasTag("player") && !isOpen(this))
	{
		CPlayer@ player = blob.getPlayer();
		if (player !is null)
		{
			if (player.getCoins() >= this.get_u16("openCost"))
			{
				player.server_setCoins(Maths::Max(player.getCoins() - this.get_u16("openCost"), 0));

				setOpen(this, true);
			}
			else if (getGameTime() % 12 == 0)
			{
				this.getSprite().PlaySound("NoAmmo.ogg", 0.5);
			}
		}
	}

	return !isOpen(this);
}