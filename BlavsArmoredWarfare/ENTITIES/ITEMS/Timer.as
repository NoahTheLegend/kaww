//Script by Skemonde
//If you want explosives have this timer simply add this script to explosives' config and...
//...add 'this.set_u8("death_timer", INSERT_YOUR_TIME_IN_SECONDS);' into their script

// modified for KAWW by noah

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ timer = sprite.addSpriteLayer("timer", "Timer.png", 5, 7);
	timer.SetFrameIndex(9);
	if (timer !is null)
	{
		timer.SetOffset(timer_offset);
		timer.setRenderStyle(RenderStyle::additive);
		timer.SetRelativeZ(2000.0f);
		timer.SetVisible(false);
	}
	this.set_u32("death_date", getGameTime() + (this.get_u8("death_timer")+10)); // only for grenade +10 coz 110 timer, needs full
	// too lazy to make smth more smart and optional
}

const Vec2f timer_offset = Vec2f(0, -8);

void onTick(CBlob@ this)
{
	if (this.hasTag("activated"))
	{
		CSpriteLayer@ timer = this.getSprite().getSpriteLayer("timer");
		if (timer is null) return;
		timer.SetFacingLeft(false);
		timer.SetVisible(true);
		if (this.hasTag("activated")) timer.SetVisible(true);

		if (this.get_u32("death_date") >= getGameTime() && timer !is null) {

			timer.SetFrameIndex(Maths::Floor(((this.get_u32("death_date") - getGameTime()) / 30) + 1));
		} else timer.SetVisible(false);
	}
}

void onDie(CBlob@ this)
{
	CSpriteLayer@ timer = this.getSprite().getSpriteLayer("timer");
	if (timer is null) return;
	timer.SetVisible(false);
}