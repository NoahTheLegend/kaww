#include "AllHashCodes.as"

void onInit(CBlob@ this)
{
    f32 susheight = this.exists("suspension_height") ? this.get_f32("suspension_height") : 3;
    int blobHash = this.getName().getHash();
    
    switch (blobHash)
    {
        case _pszh4:
        case _btr82a:
		{
			susheight = 3.0f;
			break;
		}
        case _techtruck:
        case _techbigtruck:
        case _armory:
        case _importantarmory:
        case _importantarmoryt2:
        {
            susheight = 2.5f;
            break;
        }
        case _motorcycle:
        case _transporttruck:
        case _civcar:
        case _lada:
        case _artillery:
        {
            susheight = 2.0f;
            break;
        }
        case _m60:
        case _t10:
        case _maus:
        case _pinkmaus:
        case _desertmaus:
        case _bradley:
        {
            susheight = 1.5f;
            break;
        }
        {
            susheight = 1.0f;
            break;
        }
    }

    this.set_f32("suspension_height", susheight);
}

void onTick(CBlob@ this)
{
    UpdateSuspension(this, this.get_f32("suspension_height"));
}

void UpdateSuspension(CBlob@ this, f32 susheight)
{
	if (!isClient() || !this.isOnScreen()) return;

	CSprite@ sprite = this.getSprite();
	uint sprites = sprite.getSpriteLayerCount();

	CSpriteLayer@[]@ wheels;
	Vec2f[]@ offsets;
	Vec2f[]@ new_offsets;

	if (!this.get("wheel_offsets", @offsets))
	{
		Vec2f[] set_offsets;
		CSpriteLayer@[] wheel_spritelayers;

		for (uint i = 0; i < sprites; i++)
		{
			CSpriteLayer@ current_wheel = sprite.getSpriteLayer(i);
			if (current_wheel.name.substr(0, 2) == "!w") // this is a wheel
			{
				set_offsets.push_back(current_wheel.getOffset());
				wheel_spritelayers.push_back(@current_wheel);
			}
		}

		Vec2f[] temp_offsets = set_offsets;

		this.set("wheel_offsets", @set_offsets);
		this.set("wheel_spritelayers", @wheel_spritelayers);
		this.set("wheel_new_offsets", @temp_offsets);
	}

	if (this.get("wheel_spritelayers", @wheels)
		&& this.get("wheel_new_offsets", @new_offsets)
		&& wheels !is null
		&& offsets !is null
		&& new_offsets !is null
		&& wheels.length == offsets.length
		&& wheels.length == new_offsets.length)
	{
		Vec2f[] temp_offsets;

		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
		if (map is null) return;
		for (u8 i = 0; i < wheels.length; i++)
		{
			CSpriteLayer@ wheel = wheels[i];
			if (wheel is null) continue;

			bool fl = this.isFacingLeft();
			f32 rot = this.getAngleDegrees();
			Vec2f init_offset = offsets[i];
			Vec2f current_offset = new_offsets[i];
			Vec2f cast_pos = Vec2f(0,8).RotateBy(rot);
			Vec2f wpos = pos+Vec2f(fl?init_offset.x:-init_offset.x, init_offset.y).RotateBy(rot);
			
			Vec2f hitpos;
			bool hashit = false;
			if (map.rayCastSolid(wpos, wpos+cast_pos, hitpos))
			{
				hashit = true;
			}

			f32 len = Maths::Min(susheight, (hitpos-wpos).Length());
			if (!hashit) wheel.SetOffset(Vec2f_lerp(current_offset, init_offset+Vec2f(0,len), 0.33f));
			else wheel.SetOffset(Vec2f_lerp(current_offset, init_offset, 0.33f));

			temp_offsets.push_back(wheel.getOffset());
		}

		this.set("wheel_new_offsets", @temp_offsets);
	}
}