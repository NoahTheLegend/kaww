#include "GenericButtonCommon.as"

string[] radio_channels = {"FanfareArabic", "FanfareRussian", "FanfareGerman"};

void onInit(CBlob@ this)
{	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(50);

	SetChannel(this, "FanfareArabic");

	this.addCommandID("switch_channel");
	this.addCommandID("static_sound");
	this.addCommandID("randomize_play_pos");
	
	u8 radio_channel = this.exists("radio channel") ? this.get_u8("radio channel") : 0;
	this.set_u8("radio channel", radio_channel);
	this.set_u16("switch channel time", 0);
	this.set_u16("in water ticks", 0);

	SetChannel(this, radio_channels[radio_channel]);

	this.getCurrentScript().tickFrequency = 5;

	this.Tag("trap");
}

void onDie(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundPaused(true);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller) || this.hasTag("drowned")) return;

	CButton@ button = caller.CreateGenericButton(8, Vec2f(0, 0), this, this.getCommandID("static_sound"), getTranslatedString("Switch Channel"));
	button.enableRadius = 20.0f;
}

void onTick(CBlob@ this)
{
	// drown in water
	if ((this.isInWater() || this.hasTag("drowned")) && !this.hasTag("broken quiet"))
	{
		f32 water_ticks = this.get_u16("in water ticks");
		water_ticks++;

		f32 drown_factor = 1/(1 + water_ticks * 0.12f);

		CSprite@ sprite = this.getSprite();

		if (sprite !is null)
		{
			sprite.SetEmitSoundSpeed(drown_factor);
			sprite.SetEmitSoundVolume(drown_factor);
		}

		this.set_u16("in water ticks", water_ticks);
		this.Tag("drowned");
		
		// muted for good
		if (drown_factor < 0.1f)
		{
			sprite.SetEmitSoundPaused(true);
			this.Tag("broken quiet");
			this.getCurrentScript().tickFrequency = 0;
		}
		
		// stop boomboxing
		StopAnimation(this);
	}

	// switch from static to next channel
	u16 radio_switch_time = this.get_u16("switch channel time");
	
	if (this.hasTag("should switch channel") && radio_switch_time < getGameTime())
	{
		this.SendCommand(this.getCommandID("switch_channel"));
		this.getCurrentScript().tickFrequency = 5;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this.hasTag("drowned"))
		return;

	if (cmd == this.getCommandID("static_sound"))
	{	
		u8 next_radio_channel = (this.get_u8("radio channel") + 1) % radio_channels.length();
		this.set_u8("radio channel", next_radio_channel);
		
		SetChannel(this, "BoomboxStatic");

		this.set_u16("switch channel time", getGameTime() + 15 + XORRandom(25));
		this.getCurrentScript().tickFrequency = 5;
		this.Tag("should switch channel");
	}
	else if (cmd == this.getCommandID("switch_channel"))
	{
		u8 radio_channel = this.get_u8("radio channel");
		SetChannel(this, radio_channels[radio_channel]);
		this.Untag("should switch channel");
		this.SendCommand(this.getCommandID("randomize_play_pos"));
	}
	else if (cmd == this.getCommandID("randomize_play_pos"))
	{
		CSprite@ sprite = this.getSprite();

		if (sprite !is null)
		{
			sprite.SetEmitSoundPlayPosition(XORRandom(15) * 1000);
		}
	}
}

void SetChannel(CBlob@ blob, string channel)
{
	CSprite@ sprite = blob.getSprite();

	if (sprite !is null)
	{
		sprite.RewindEmitSound();
		sprite.SetEmitSound(channel);
		sprite.SetEmitSoundPaused(false);
	}
}

void StopAnimation(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	if (sprite !is null)
	{
		Animation@ anim = sprite.getAnimation("default");
		
		if (anim !is null)
		{
			anim.loop = false;
		}
	}
}