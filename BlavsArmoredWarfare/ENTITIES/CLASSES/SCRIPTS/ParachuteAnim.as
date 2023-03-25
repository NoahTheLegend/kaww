/* #include "InfantryCommon.as"
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as"; */

void onInit(CSprite@ this)
{
	this.RemoveSpriteLayer("parachute");
	CSpriteLayer@ parachute = this.addSpriteLayer("parachute", "ParachuteSL.png", 64, 64);

	if (parachute !is null)
	{
		Animation@ anim = parachute.addAnimation("default", 3, true);
		int[] frames = {0, 1, 2};
		anim.AddFrames(frames);
		parachute.SetRelativeZ(-100);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	CSpriteLayer@ parachute = this.getSpriteLayer("parachute");

	if (parachute !is null && blob.isMyPlayer())
	{
		if (blob.hasTag("parachute") && !blob.isAttached() && !blob.hasTag("dead"))
		{
			parachute.SetFacingLeft(false);

			parachute.SetOffset(blob.getVelocity()*-1 + Vec2f(0.0f, -23.0f + Maths::Sin(getGameTime() / 5.0f)) + Vec2f(-1,0));
			
			f32 parachute_angle = (Maths::Sin((blob.getOldVelocity().x + blob.getVelocity().x)/2)*-10);
			parachute_angle = parachute_angle;

			parachute.ResetTransform();
			parachute.RotateBy(parachute_angle, Vec2f(0.5, 35.0));
			
			parachute.SetVisible(true);
		}
		else
		{	
			parachute.SetVisible(false);
		}		
	}
}