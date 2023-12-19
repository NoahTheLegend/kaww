#include "ScreenHoverButton.as";

const f32 high_angle = 45;
const f32 low_angle = 75;

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	this.addCommandID("reload");
	this.addCommandID("shoot");
	this.addCommandID("sync");
	this.addCommandID("angle_up");
	this.addCommandID("angle_down");

	this.set_f32("current_angle", 45);
	this.set_u8("ammo", 0);
	this.Tag("heavy weight");
	
    HoverButton setbuttons(this.getNetworkID());
    setbuttons.offset = Vec2f(0,32);
    for (u16 i = 0; i < 4; i++)
    {
        SimpleHoverButton btn(this.getNetworkID());
        btn.dim = Vec2f(65, 25);
        btn.font = "menu";
		btn.write_local = true;
		btn.sound = "select.ogg";

        switch (i)
        {	
			case 0:
            	btn.text = "RELOAD ";
            	btn.callback_command = "reload";
				break;

			case 1:
				btn.text = "Δ ";
            	btn.callback_command = "angle_up";
				btn.send_if_held = true;
				break;

			case 2:
				btn.text = "SHOOT ";
				btn.callback_command = "shoot";
				break;
			
			case 3:
				btn.text = "∇ ";
				btn.callback_command = "angle_down";
				btn.send_if_held = true;
				break;
        }

        setbuttons.AddButton(btn);
    }
	

    setbuttons.draw_attached = false;
    setbuttons.grid = Vec2f(2,2);
    setbuttons.gap = Vec2f(1,2);
    this.set("HoverButton", setbuttons);
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	bool fl = this.isFacingLeft();
	f32 fl_f = fl?1:-1;
	bool att = this.isAttached();
	if (sprite.animation !is null)
	{
		sprite.animation.frame = att ? 0 : 1;
	}

	this.set_bool("tips_active", false);
	CBlob@ local = getLocalPlayerBlob();
	if (local !is null)
	{
		if (this.isOnScreen())
		{
			HoverButton@ buttons;
			if (this.get("HoverButton", @buttons) && !att && local.getDistanceTo(this) < 32.0f)
			{
				buttons.active = true;
				this.set_bool("tips_active", true);
			}
			else
			{
				buttons.active = false;
			}
		}
	}

	f32 angle = this.get_f32("current_angle");

	CSpriteLayer@ tripod = sprite.getSpriteLayer("tripod");
	CSpriteLayer@ pip = sprite.getSpriteLayer("pip");
	if (tripod !is null && pip !is null)
	{
		tripod.SetVisible(!att);
		pip.SetVisible(!att);

		tripod.ResetTransform();
		pip.ResetTransform();
		tripod.RotateBy(fl_f*-angle, Vec2f(0,0));
		pip.RotateBy(fl_f*-angle, Vec2f(0,0));

		f32 rot = (1.0f-angle/45);
		tripod.SetOffset(Vec2f(-4*rot, 6 + 4*rot));
		pip.SetOffset(tripod.getOffset());
	}

	CShape@ shape = this.getShape();
	if (att)
	{
		sprite.ResetTransform();
		sprite.SetRelativeZ(-10.0f);
		sprite.RotateBy(fl_f*90, Vec2f_zero);

		shape.SetAngleDegrees(0);
		shape.SetRotationsAllowed(true);
	}
	else
	{
		sprite.ResetTransform();
		sprite.SetRelativeZ(0.0f);
		
		shape.SetAngleDegrees(fl_f*angle);
		shape.SetRotationsAllowed(false);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (!isClient()) return;

		u8 ammo;
		if (!params.saferead_u8(ammo)) return;
		f32 angle;
		if (!params.saferead_f32(angle)) return;

		this.set_u8("ammo", ammo);
		this.set_f32("current_angle", angle);
	}
	else if (cmd == this.getCommandID("reload"))
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		if (caller.hasBlob("mat_smallbomb", 1))
		{
			if (caller.isMyPlayer() && this.get_u8("ammo") == 1)
			{
				this.getSprite().PlaySound("NoAmmo.ogg", 0.75f, 1.25f);
			}

			if (isClient() && this.get_u8("ammo") == 0)
			{
				
			}
			
			if (isServer())
			{
				if (this.get_u8("ammo") == 0)
				{
					caller.TakeBlob("mat_smallbomb", 1);
					this.set_u8("ammo", 1);
				}

				Sync(this);
			}
		}
	}
	else if (cmd == this.getCommandID("shoot"))
	{
		if (this.get_u8("ammo") == 0)
		{
			return;
		}

		Vec2f pos;
		if (!params.saferead_Vec2f(pos)) return;
		Vec2f vel;
		if (!params.saferead_Vec2f(vel)) return;

		f32 angle = -vel.getAngle();

		if (isServer())
		{
			this.set_u8("ammo", 0);
			Sync(this);

			CreateProjectile(this, pos, vel);
		}

		if (isClient())
		{
			bool facing = this.isFacingLeft();

			for (int i = 0; i < 16; i++)
			{
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(10+XORRandom(24)), float(XORRandom(360)), 0.5f + XORRandom(40) * 0.01f, 2 + XORRandom(2), -0.0031f, true);
			}

			for (int i = 0; i < 6; i++)
			{
				float angle = Maths::ATan2(vel.y, vel.x) + 20;
				ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle2 = Maths::ATan2(vel.y, vel.x) - 20;
				ParticleAnimated("LargeSmoke", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.8f + XORRandom(75) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle3 = Maths::ATan2(vel.y, vel.x) + 10;
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle), Maths::Sin(angle))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);
				float angle4 = Maths::ATan2(vel.y, vel.x) - 10;
				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + Vec2f(Maths::Cos(angle2), Maths::Sin(angle2))/2, float(XORRandom(360)), 0.5f + XORRandom(45) * 0.01f, 4 + XORRandom(3), -0.0031f, true);

				ParticleAnimated("LargeSmokeGray", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.005f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 10 + XORRandom(3), -0.0031f, true);
				ParticleAnimated("Explosion", pos, this.getShape().getVelocity() + getRandomVelocity(0.0f, XORRandom(45) * 0.0065f, 360) + vel/(50+XORRandom(24)), float(XORRandom(360)), 0.6f + XORRandom(45) * 0.01f, 2, -0.0031f, true);
			}

			this.getSprite().PlaySound("sound_128mm.ogg", 1.0f, 1.25f);
		}
	}
	else if (cmd == this.getCommandID("angle_up"))
	{
		if (!isServer()) return;

		this.add_f32("current_angle", 1);
		if (this.get_f32("current_angle") > low_angle)
			this.set_f32("current_angle", low_angle);
		
		Sync(this);
	}
	else if (cmd == this.getCommandID("angle_down"))
	{
		if (!isServer()) return;

		this.add_f32("current_angle", -1);
		if (this.get_f32("current_angle") < high_angle)
			this.set_f32("current_angle", high_angle);
		
		Sync(this);
	}
}

void CreateProjectile(CBlob@ this, Vec2f pos, Vec2f vel)
{

}

void Sync(CBlob@ this)
{
	if (isServer())
	{
		CBitStream params;
		params.write_u8(this.get_u8("ammo"));
		params.write_f32(this.get_f32("current_angle"));
		this.SendCommand(this.getCommandID("sync"), params);
	}
}

void onRender(CSprite@ this)
{
	hoverRender(this);

	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (!blob.get_bool("tips_active")) return;

	Vec2f pos2d = getDriver().getScreenPosFromWorldPos(blob.getPosition());

	GUI::SetFont("menu");
	GUI::DrawTextCentered("L/R click", pos2d+Vec2f(0,128), SColor(50,255,255,255));
}

void onInit(CSprite@ sprite)
{
	string fn = "Mortar.png";
	CSpriteLayer@ tripod = sprite.addSpriteLayer("tripod", fn, 32, 32);
	if (tripod !is null)
	{
		tripod.SetVisible(false);
		Animation@ anim = tripod.addAnimation("default", 0, false);
		if (anim !is null)
		{anim.AddFrame(2);tripod.SetAnimation(anim);}
	}

	CSpriteLayer@ pip = sprite.addSpriteLayer("pip", fn, 32, 32);
	if (pip !is null)
	{
		pip.SetVisible(false);
		pip.SetRelativeZ(-1.0f);
		Animation@ anim = pip.addAnimation("default", 0, false);
		if (anim !is null)
		{anim.AddFrame(3);pip.SetAnimation(anim);}
	}
	
	CSpriteLayer@ disc = sprite.addSpriteLayer("disc", fn, 8, 8);
	if (disc !is null)
	{
		disc.SetVisible(false);
		Animation@ anim = tripod.addAnimation("default", 0, false);
		if (anim !is null)
		{anim.AddFrame(6);disc.SetAnimation(anim);}
	}
}