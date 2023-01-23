// brain

#include "EmotesCommon.as"
#include "InfantryCommon.as"

float mouse_mvspd = 0.5f;

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		chasing,
		attacking,
		seekcover,
		seekheal,
		seekammo,
		retreating
	}
}

void InitBrain(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	blob.set_Vec2f("last pathing pos", Vec2f_zero);
	blob.set_u8("strategy", Strategy::idle);
	this.getCurrentScript().removeIfTag = "dead";   //won't be removed if not bot cause it isnt run

	if (!blob.exists("difficulty"))
	{
		blob.set_s32("difficulty", 15); // max
	}
}

CBlob@ getNewTarget(CBrain@ this, CBlob @blob, const bool seeThroughWalls = false, const bool seeBehindBack = false)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f pos = blob.getPosition();

	SortBlobsByDistance(blob, players);

	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();

		if (potential !is blob && blob.getTeamNum() != potential.getTeamNum())
		{
			if ((pos2 - pos).getLength() < 800.0f && !potential.hasTag("dead")
				&& (XORRandom(10) == 0 || (isVisible(blob, potential) && (!potential.isAttached() || XORRandom(20) == 0))))
			{
				blob.set_Vec2f("last pathing pos", potential.getPosition());
				return potential;
			}
		}
	}
	return null;
}

void Repath(CBrain@ this)
{
	this.SetPathTo(this.getTarget().getPosition(), false);
}

void RepathPos(CBrain@ this, Vec2f pos)
{
	this.SetPathTo(pos, false);
}

bool isVisible(CBlob@blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
}

bool isVisible(CBlob@ blob, CBlob@ target, f32 &out distance)
{
	Vec2f col;
	bool visible = !getMap().rayCastSolid(blob.getPosition(), target.getPosition(), col);
	distance = (blob.getPosition() - col).getLength();
	return visible;
}

bool JustGo(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();
	const f32 horiz_distance = Maths::Abs(point.x - mypos.x);

	if (horiz_distance > blob.getRadius() * 0.75f)
	{
		if (point.x < mypos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (point.y + getMap().tilesize * 0.7f < mypos.y && (target.isOnGround() || target.getShape().isStatic()))  	 // dont hop with me
		{
			blob.setKeyPressed(key_up, true);
		}

		if (blob.isOnLadder() && point.y > mypos.y)
		{
			blob.setKeyPressed(key_down, true);
		}

		return true;
	}

	return false;
}

void JumpOverObstacles(CBlob@ blob)
{
	Vec2f pos = blob.getPosition();
	const f32 radius = blob.getRadius();

	if (blob.isOnWall())
	{
		blob.setKeyPressed(key_up, true);
	}
	else if (!blob.isOnLadder())
		if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(pos + Vec2f(1.3f * radius, radius) * 1.0f))) ||
		        (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(pos + Vec2f(-1.3f * radius, radius) * 1.0f))))
		{
			blob.setKeyPressed(key_up, true);
		}
}

void AvoidTheVoid(CBlob@ blob)
{
	Vec2f pos = blob.getPosition();
	Vec2f futurepos = pos + blob.getVelocity() * 4.0f;
	const f32 radius = blob.getRadius();

	if (!getMap().rayCastSolid(pos, futurepos + Vec2f(0, 200)))
	{
		blob.setKeyPressed(key_left, false);
		blob.setKeyPressed(key_right, false);

		if (blob.isFacingLeft())
		{
			blob.setKeyPressed(key_right, true);
		}
		else{
			blob.setKeyPressed(key_left, true);
		}

		blob.setKeyPressed(key_up, true);
	}
}

void DefaultChaseBlob(CBlob@ blob, CBlob @target)
{
	CBrain@ brain = blob.getBrain();
	Vec2f targetPos = target.getPosition();
	Vec2f myPos = blob.getPosition();
	Vec2f targetVector = targetPos - myPos;
	f32 targetDistance = targetVector.Length();
	// check if we have a clear area to the target
	bool justGo = false;

	if (targetDistance < 1120.0f)
	{
		justGo = true;
	}
	//JustGo(blob, target);

	// repath if no clear path after going at it
	if (XORRandom(50) == 0 && (blob.get_Vec2f("last pathing pos") - targetPos).getLength() > 50.0f)
	{
		Repath(brain);
		blob.set_Vec2f("last pathing pos", targetPos);
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		if (state == CBrain::has_path)
		{
			if (targetDistance < 300.0f)
			{
				//print("!@#");
				brain.SetSuggestedKeys();  // set walk keys here
			}
			else
			{
				JustGo(blob, target);
			}
		}
		else
		{
			JustGo(blob, target);
		}

		// printInt("state", this.getState() );
		switch (state)
		{
			case CBrain::idle:
				Repath(brain);
				break;

			case CBrain::searching:
				//if (sv_test)
				//	set_emote( blob, Emotes::dots );
				break;

			case CBrain::stuck:
				Repath(brain);
				break;

			case CBrain::wrong_path:
				Repath(brain);
				break;
		}
	}
}

void GoToPos(CBlob@ blob, Vec2f pos)
{
	CBrain@ brain = blob.getBrain();
	Vec2f myPos = blob.getPosition();
	Vec2f Vector = pos - myPos;
	f32 vecDistance = Vector.Length();
	// check if we have a clear area to the target
	bool justmove = false;
	bool justjump = false;

	// repath if no clear path after going at it
	if (XORRandom(20) == 0 && (blob.get_Vec2f("last pathing pos") - pos).getLength() > 40.0f)
	{
		RepathPos(brain, pos);
		blob.set_Vec2f("last pathing pos", pos);
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		if (state == CBrain::has_path)
		{
			Vec2f col;
			bool visible = !getMap().rayCastSolid(blob.getPosition(), pos, col);
			if (visible)
			{
				justmove = true;
			}
			else if (getGameTime() % 160 + blob.get_u8("mykey") < 120) {
				//brain.SetSuggestedKeys();  // set walk keys here
				
			}
			justmove = true; //temp
			justjump = true;
		}
		else
		{
			justmove = true;
			justjump = true;
		}

		//printInt("state", brain.getState() );
		switch (state)
		{
			case CBrain::idle:
				RepathPos(brain, pos);
				break;

			case CBrain::searching:
				//if (sv_test)
				//	set_emote( blob, Emotes::dots );
				break;

			case CBrain::stuck:
				RepathPos(brain, pos);
				break;

			case CBrain::wrong_path:
				RepathPos(brain, pos);
				break;
		}
	}

	if (justmove)
	{
		if (pos.x < myPos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (pos.y > myPos.y)
		{
			blob.setKeyPressed(key_down, true);
		}
	}

	if (justjump)
	{
		if (pos.y + getMap().tilesize * 0.7f + 5 < myPos.y)
		{
			blob.setKeyPressed(key_up, true);
		}
	}
}

void GoToImportant(CBlob@ blob, CBlob@ importantblob, CBlob@ target)
{
	CBrain@ brain = blob.getBrain();
	Vec2f myPos = blob.getPosition();
	Vec2f itsPos = importantblob.getPosition();
	Vec2f Vector = itsPos - myPos;
	f32 vecDistance = Vector.Length();
	// check if we have a clear area to the target
	bool justmove = false;
	bool justjump = false;

	// repath if no clear path after going at it
	if (XORRandom(20) == 0 && (blob.get_Vec2f("last pathing pos") - itsPos).getLength() > 40.0f)
	{
		RepathPos(brain, itsPos);
		blob.set_Vec2f("last pathing pos", itsPos);
	}

	const bool stuck = brain.getState() == CBrain::stuck;

	const CBrain::BrainState state = brain.getState();
	{
		if (state == CBrain::has_path)
		{
			Vec2f col;
			bool visible = !getMap().rayCastSolid(blob.getPosition(), itsPos, col);
			if (visible)
			{
				justmove = true;
			}
			else if (getGameTime() % 160 + blob.get_u8("mykey") < 120) {
				//brain.SetSuggestedKeys();  // set walk keys here
				
			}
			justmove = true; //temp
			justjump = true;
		}
		else
		{
			justmove = true;
			justjump = true;
		}

		if ((myPos - target.getPosition()).getLength() < 400.0f)
		{
			justmove = true; // im under pressure
		}

		//printInt("state", brain.getState() );
		switch (state)
		{
			case CBrain::idle:
				RepathPos(brain, itsPos);
				break;

			case CBrain::searching:
				//if (sv_test)
				//	set_emote( blob, Emotes::dots );
				break;

			case CBrain::stuck:
				RepathPos(brain, itsPos);
				break;

			case CBrain::wrong_path:
				RepathPos(brain, itsPos);
				break;
		}
	}

	if (justmove)
	{
		if (itsPos.x < myPos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (itsPos.y > myPos.y)
		{
			blob.setKeyPressed(key_down, true);
		}
	}

	if (justjump)
	{
		if (itsPos.y + getMap().tilesize * 0.7f + 5 < myPos.y)
		{
			blob.setKeyPressed(key_up, true);
		}
	}

	JumpOverObstacles(blob);

	if (target !is null && isVisible(blob, target))
	{
		AttackBlob(blob, target);
	}
	else
	{
		blob.setAimPos(Vec2f_lerp(blob.getAimPos(), Vec2f(itsPos.x, itsPos.y), 0.09));
	}
}

bool DefaultRetreatBlob(CBlob@ blob, CBlob@ target)
{
	//set_emote( blob, Emotes::attn );
	//print("1331 " + blob.getName() + " " + target.getName());

	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();
	if (point.x > mypos.x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}

	if (mypos.y - blob.getRadius() > point.y || getGameTime() % (500 + blob.get_u8("myKey")) < 300)
	{
		//blob.setKeyPressed(key_up, true);
	}

	if (blob.isOnLadder() && point.y < mypos.y)
	{
		blob.setKeyPressed(key_down, true);
	}

	if (target !is null && isVisible(blob, target))
	{
		AttackBlob(blob, target);
	}

	JumpOverObstacles(blob);

	return true;
}

void SeekCover(CBlob@ blob, Vec2f pos)
{
	CBrain@ brain = blob.getBrain();
	Vec2f myPos = blob.getPosition();
	Vec2f Vector = pos - myPos;
	f32 vecDistance = Vector.Length();
	
	if (vecDistance > 22.0f)
	{
		//set_emote( blob, Emotes::cry );

		if (pos.x < myPos.x)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}

		if (pos.y > myPos.y)
		{
			blob.setKeyPressed(key_down, true);
		}
	}

	CBlob @target = brain.getTarget();
	if (target !is null && isVisible(blob, target))
	{
		
		AttackBlob(blob, target);
	}

	JumpOverObstacles(blob);
}

void SearchTarget(CBrain@ this, const bool seeThroughWalls = false, const bool seeBehindBack = true)
{
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// search target if none
	if (target is null || XORRandom(20) == 0)
	{
		@target = null;
		CBlob@ oldTarget = target;
		@target = getNewTarget(this, blob, true, true);
		this.SetTarget(target);

		if (target !is oldTarget && target.get_u32("can_spot") < getGameTime() && !target.hasTag("dead"))
		{
			return;
			onChangeTarget(blob, target, oldTarget);
		}
	}
}

void onChangeTarget(CBlob@ blob, CBlob@ target, CBlob@ oldTarget)
{
	// !!!
	if (oldTarget is null)
	{
		//set_emote(blob, Emotes::attn, 2);
	}
}

bool LoseTarget(CBrain@ this, CBlob@ target)
{
	if (XORRandom(10) == 0 && target.hasTag("dead"))
	{
		@target = null;
		this.SetTarget(target);
		return true;
	}
	return false;
}

void Runaway(CBlob@ blob, CBlob@ target)
{
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (target.getPosition().x > blob.getPosition().x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}
}

void Chase(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	blob.setKeyPressed(key_left, false);
	blob.setKeyPressed(key_right, false);
	if (targetPos.x < mypos.x)
	{
		blob.setKeyPressed(key_left, true);
	}
	else
	{
		blob.setKeyPressed(key_right, true);
	}

	if (targetPos.y + getMap().tilesize < mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

bool isFriendAheadOfMe(CBlob @blob, CBlob @target, const f32 spread = 70.0f)
{
	// optimization
	if ((getGameTime() + blob.getNetworkID()) % 10 > 0 && blob.exists("friend ahead of me"))
	{
		return blob.get_bool("friend ahead of me");
	}

	CBlob@[] players;
	getBlobsByTag("player", @players);
	Vec2f pos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	for (uint i = 0; i < players.length; i++)
	{
		CBlob@ potential = players[i];
		Vec2f pos2 = potential.getPosition();
		if (potential !is blob && blob.getTeamNum() == potential.getTeamNum()
		        && (pos2 - pos).getLength() < spread
		        && (blob.isFacingLeft() && pos.x > pos2.x && pos2.x > targetPos.x) || (!blob.isFacingLeft() && pos.x < pos2.x && pos2.x < targetPos.x)
		        && !potential.hasTag("dead") && !potential.hasTag("migrant")
		   )
		{
			blob.set_bool("friend ahead of me", true);
			return true;
		}
	}
	blob.set_bool("friend ahead of me", false);
	return false;
}

void FloatInWater(CBlob@ blob)
{
	if (blob.isInWater())
	{
		blob.setKeyPressed(key_up, true);
	}
}

void RandomTurn(CBlob@ blob)
{
	if (XORRandom(4) == 0)
	{
		CMap@ map = getMap();
		blob.setAimPos(Vec2f(XORRandom(int(map.tilemapwidth * map.tilesize)), XORRandom(int(map.tilemapheight * map.tilesize))));
	}
}

void DriveToPos(CBlob@ blob, CBlob@ vehicle, Vec2f position, float dist)
{
	//print("a " + blob.get_string("behavior"));
	//print("b " + blob.get_u16("behaviortimer"));
	if (blob.get_string("behavior") == "drive")
	{
		if ((position - blob.getPosition()).getLength() > dist)
		{
			if (position.x > blob.getPosition().x) blob.setKeyPressed(key_right, true);
			else blob.setKeyPressed(key_left, true);
		}
		else if (getGameTime() % 120 == 0)
		{
			LocateGeneralEnemyDirection(blob); // new location
		}

		// lift front end to climb
		if (vehicle.getShape().vellen < 0.5f)
		{
			blob.setKeyPressed(key_down, true);
		}

		bool vehicleislow = (vehicle.getHealth() < vehicle.getInitialHealth() / 3);

		if (vehicle.getShape().vellen < (vehicleislow ? 0.24f : 0.36f))
		{
			// hmm we haven't moved, are we stuck?
			blob.add_u16("behaviortimer", 2);
			if (blob.get_u16("behaviortimer") > XORRandom(150)+10)
			{
				// we are stuck, try to unstuck
				blob.set_string("behavior", "unstuckvehicle");
				
			}	
		}
	}
	else if (blob.get_string("behavior") == "unstuckvehicle")
	{
		if (blob.get_u16("behaviortimer") > 0) // firstly, reverse or turn around
		{
			if (getGameTime() % 200 + blob.get_u8("myKey") < 160)
			{
				blob.setKeyPressed(key_action2, true);
			}
			
			if (position.x > blob.getPosition().x) blob.setKeyPressed(key_left, true);
			else blob.setKeyPressed(key_right, true);
		}
		else // then go forward
		{
			if (position.x > blob.getPosition().x) blob.setKeyPressed(key_right, true);
			else blob.setKeyPressed(key_left, true);
		}

		if (vehicle.getShape().vellen > 0.2f && XORRandom(30) == 0 || XORRandom(30) == 0)
		{
			blob.set_string("behavior", "drive"); // switch to forward
			blob.set_u16("behaviortimer", 0);
		}
	}
}

void SortBlobsByDistance(CBlob@ blob, CBlob@[]@ blobs)
{
    int n = blobs.length;
    for (int i = 0; i < n - 1; i++)
    {
        // Find the minimum blob in the unsorted part of the array
        int minIndex = i;
        for (int j = i + 1; j < n; j++)
        {
            if (CompareBlobsByDistance(blob, blobs[j], blobs[minIndex]))
            {
                minIndex = j;
            }
        }
        // Swap the minimum blob with the first blob in the unsorted part of the array
        CBlob@ temp = blobs[minIndex];
        @blobs[minIndex] = blobs[i];
        @blobs[i] = temp;
    }
}

bool CompareBlobsByDistance(CBlob@ blob, CBlob@ a, CBlob@ b)
{
    // Calculate the distance between the two blobs
    float distance1 = (a.getPosition() - blob.getPosition()).Length();
	float distance2 = (b.getPosition() - blob.getPosition()).Length();

    // Return true if the distance between blob a and the origin is less than the distance between blob b and the origin
    return (distance1 < distance2);
}

void LocateGeneralEnemyDirection(CBlob@ blob)
{
	CBlob@[] threats;
	CBlob@[] enemythreats;
	getBlobsByName("importantarmory", @threats);
	getBlobsByName("tent", @threats);
	getBlobsByTag("vehicle", @threats);
	getBlobsByTag("player", @threats);

	for (uint i = 0; i < threats.length; ++i)
	{
		if (threats[i].getTeamNum() != blob.getTeamNum()) // not on our team
		{
			if (!threats[i].hasTag("turret") && !threats[i].hasTag("gun") && !threats[i].hasTag("weak vehicle") && !threats[i].hasTag("dead"))
			{
				enemythreats.push_back(threats[i]); // enemy threat
			}
		}
	}

	CBlob@ chosenthreat = enemythreats[XORRandom(enemythreats.length)];
	blob.set_Vec2f("generalenemylocation", chosenthreat.getPosition());
	//print("the enemy threat is " + chosenthreat.getName());
}

void LocateGeneralFriendDirection(CBlob@ blob)
{
	CBlob@[] threats;
	CBlob@[] friendlies;
	getBlobsByName("importantarmory", @threats);
	getBlobsByName("tent", @threats);
	getBlobsByTag("player", @threats);
	getBlobsByTag("bunker", @threats);

	for (uint i = 0; i < threats.length; ++i)
	{
		if (threats[i].getTeamNum() == blob.getTeamNum()) // is our team
		{
			if (!threats[i].hasTag("dead"))
			{
				friendlies.push_back(threats[i]);
			}
		}
	}

	CBlob@ chosen = friendlies[XORRandom(friendlies.length)];
	blob.set_Vec2f("generalfriendlocation", chosen.getPosition());
	//print("the friendly is " + chosen.getName());
}

void AttackBlob(CBlob@ blob, CBlob @target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f targetPos = target.getPosition();
	Vec2f targetVector = targetPos - mypos;
	f32 targetDistance = targetVector.Length();
	const s32 difficulty = blob.get_s32("difficulty");
	InfantryInfo infantry;

	// shoot the target
	f32 distance;
	Vec2f col;
	if (!getMap().rayCastSolid(blob.getPosition() + blob.getVelocity()*3.0f, targetPos + getRandomVelocity( 0, target.getRadius() , 360 ) + target.getVelocity()*5.0f, col))
	{
		if (targetDistance > 8.0f)
		{
			//if (targetDistance < infantry.bullet_velocity * (infantry.bullet_lifetime*250)) // is in bullet range why tf not work
			{
				if ((targetDistance < 560.0f && blob.getName() != "shotgun") || targetDistance < 178.0f)
				{
					blob.setKeyPressed(key_action1, true);

					if (blob.get_u8("myKey") % 13 == 0)
					{
						blob.setKeyPressed(key_action2, true);
					}
				}
				else if (blob.get_u8("myKey") > 120 && ((targetDistance < 500.0f && blob.getName() != "shotgun") || targetDistance < 178.0f))
				{
					blob.setKeyPressed(key_action1, true);

					if (blob.get_u8("myKey") % 2 == 0)
					{
						blob.setKeyPressed(key_action2, true);
					}
				}
			}
			//else
			{
				//if (emotes) set_emote(blob, Emotes::cry, 10);
			}

			if (target !is null)
			{
				//compensation = RangerParams::BULLET_VELOCITY;
				blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
									targetPos - Vec2f(0, targetDistance / (40.0f)) + Vec2f(0.0f, 10 -XORRandom(17)) + target.getVelocity() * 5.5f,
									mouse_mvspd));
			}
		}
		else if (target !is null)
		{
			blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
										targetPos - Vec2f(0, targetDistance / 8.0f),
										mouse_mvspd));
		}
	}
	else if (getGameTime() % (300 + blob.get_u8("myKey")) < 130 || blob.getShape().vellen < 1.6f)
	{
		// mouse movement type a     rng based
		blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
								mypos + Vec2f(Maths::Cos(getGameTime()/(blob.get_u8("myKey")*0.5)), Maths::Sin(getGameTime()/(blob.get_u8("myKey")*0.5))),
								blob.get_u8("myKey")/845.0f));
	}
	else
	{
		// mouse movement type b     velocity based
		blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
								mypos + Vec2f(0.0f, 11.0f) + blob.getVelocity()*(blob.get_u8("myKey")/14),
								blob.get_u8("myKey")/1245.0f));
	}
}