void onInit(CBlob@ this)
{
	if (this.hasTag("invincibility done"))
	{
		return;
	}
	this.Tag("invincible");

	this.addCommandID("invincibility sync");

	if (!this.exists("spawn immunity time"))
		this.set_u32("spawn immunity time", getGameTime());
}

void onTick(CBlob@ this)
{
	bool immunity = false;

	float time_modifier = (this.isKeyPressed(key_action1) ? 0.5f : 0.75f);

	bool federation_power = getRules().get_bool("enable_powers") && this.getTeamNum() == 1; // team 1 buff
    f32 extra_amount = 0.0f;
    if (federation_power) extra_amount = 45.0f;

	u32 ticksSinceImmune = getGameTime() - this.get_u32("spawn immunity time");
	u32 maximumImmuneTicks = getRules().get_f32("immunity sec") * getTicksASecond() * time_modifier + extra_amount;
	if (ticksSinceImmune < maximumImmuneTicks)
	{
		CSprite@ s = this.getSprite();
		if (s !is null)
		{
			s.setRenderStyle(getGameTime() % 7 < 5 ? RenderStyle::normal : RenderStyle::additive);
			CSpriteLayer@ layer = s.getSpriteLayer("head");
			if (layer !is null)
				layer.setRenderStyle(getGameTime() % 7 < 5 ? RenderStyle::normal : RenderStyle::additive);
		}
		immunity = true;
	}

	if (!immunity || this.getPlayer() is null)
	{
		this.Untag("invincible");
		this.Tag("invincibility done");
		
		CBitStream params;
		this.SendCommand(this.getCommandID("invincibility sync"), params);

		this.getCurrentScript().runFlags |= Script::remove_after_this;
		this.getSprite().setRenderStyle(RenderStyle::normal);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("invincibility sync"))
	{
		if (isClient())
		{
			this.Tag("invincibility done");
		}
	}
}
