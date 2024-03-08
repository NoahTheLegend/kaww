#include "KnockedCommon.as";

void onInit(CBlob@ this)
{
    this.set_f32("target_angle_body", 0);
    this.set_f32("target_angle_head", 0);
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();

	const bool left		= blob.isKeyPressed(key_left);
	const bool right	= blob.isKeyPressed(key_right);
	const bool up		= blob.isKeyPressed(key_up);
	const bool down		= blob.isKeyPressed(key_down);

	const bool isknocked = isKnocked(blob);

	CMap@ map = blob.getMap();
	Vec2f vel = blob.getVelocity();
	Vec2f pos = blob.getPosition();
	CShape@ shape = blob.getShape();

	const f32 vellen = shape.vellen;
	const bool onground = blob.isOnGround() || blob.isOnLadder();

    Vec2f aimpos = blob.getAimPos();

    CSpriteLayer@ head = this.getSpriteLayer("head");
    if (head !is null)
    {

    }
}