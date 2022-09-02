// Archer brain

#define SERVER_ONLY

#include "BrainCommon.as"
#include "ArcherCommon.as"

float mouse_mvspd = 0.40f;

void onInit(CBrain@ this)
{
	CBlob @blob = this.getBlob();

	InitBrain(this);

	blob.set_u8("moveover", 0);
	blob.set_u8("myKey", XORRandom(250)+1); // 1-250
}

void onTick(CBrain@ this)
{
	SearchTarget(this, false, true);

	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// logic for target

	this.getCurrentScript().tickFrequency = 29;
	if (target !is null)
	{
		this.getCurrentScript().tickFrequency = 1;

		u8 strategy = blob.get_u8("strategy");

		f32 distance;
		const bool visibleTarget = isVisible(blob, target, distance);
		if (visibleTarget)
		{
			const s32 difficulty = blob.get_s32("difficulty");
			if ((!blob.isKeyPressed(key_action1) && getGameTime() % 300 < 240 && distance < 30.0f + 3.0f * difficulty))
				strategy = Strategy::attacking;
			else
			{
				strategy = Strategy::attacking;
			}
		}
		else
		{
			strategy = Strategy::attacking;
		}

		UpdateBlob(blob, target, strategy);

		// lose target if its killed (with random cooldown)

		if (LoseTarget(this, target))
		{
			strategy = Strategy::idle;
		}




		// unpredictable movement
		if (getGameTime() % blob.get_u8("myKey") == 0 && XORRandom(3) == 0)
		{
			//print('asddddd!!!!!!!!!!');
			if (blob.get_u8("moveover") == 0)
			{
				blob.set_u8("moveover", XORRandom(2)+1); // rand dir
			}
			else
			{
				blob.set_u8("moveover", 0); // stop move dir
			}
		}

		//secondary random

		if (blob.get_u8("moveover") != 0)
		{
			if (XORRandom(70) == 0)
			{
				blob.set_u8("moveover", 0); //end
			}

			blob.setKeyPressed(key_left, false);
			blob.setKeyPressed(key_right, false);

			if (blob.get_u8("moveover") == 1) // 1 == right
			{
				blob.setKeyPressed(key_right, true);
			}
			else // 0 == left
			{		
				blob.setKeyPressed(key_left, true);
			}

			// hardcode rand
			if (blob.get_u8("myKey") > 160)
			{
				blob.setKeyPressed(key_up, true);
			}
			if (blob.get_u8("myKey") < 50)
			{
				blob.setKeyPressed(key_up, false);
			}
			if (blob.get_u8("myKey") > 220)
			{
				blob.setKeyPressed(key_down, true);
			}
		}




		blob.set_u8("strategy", strategy);

		if (XORRandom(1000) == 0)
		{
			@target = null;
		}
	}
	else
	{
		RandomTurn(blob);
	}

	FloatInWater(blob);
}

void UpdateBlob(CBlob@ blob, CBlob@ target, const u8 strategy)
{
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	if (strategy == Strategy::chasing)
	{
		DefaultChaseBlob(blob, target);
	}
	else if (strategy == Strategy::retreating)
	{
		DefaultRetreatBlob(blob, target);
	}
	else if (strategy == Strategy::attacking)
	{
		AttackBlob(blob, target);
	}
}

void AttackBlob(CBlob@ blob, CBlob @target)
{
	DefaultChaseBlob(blob, target);

	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	Vec2f targetVector = targetPos - mypos;
	f32 targetDistance = targetVector.Length();
	const s32 difficulty = blob.get_s32("difficulty");

	JumpOverObstacles(blob);

	// fire

	f32 distance;
	Vec2f col;
	if (!getMap().rayCastSolid(blob.getPosition() + blob.getVelocity()*2.5f, targetPos + getRandomVelocity( 0, target.getRadius() , 360 ) + target.getVelocity()*5.0f, col))
	{
		if (targetDistance > 25.0f)
		{
			blob.setKeyPressed(key_action1, true);

			if (target !is null)
			{
				blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
									targetPos + Vec2f(0.0f, 10 -XORRandom(17)) + target.getVelocity() * 4.0f,
									mouse_mvspd));
			}
		}
		else if (target !is null)
		{
			blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
										targetPos,
										mouse_mvspd));
		}
	}
	else if (blob.getShape().vellen > 1.6f)
	{
		blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
									mypos + Vec2f(0.0f, 11.0f) + blob.getVelocity()*(blob.get_u8("myKey")/9),
									blob.get_u8("myKey")/1245.0f));
	}
}

