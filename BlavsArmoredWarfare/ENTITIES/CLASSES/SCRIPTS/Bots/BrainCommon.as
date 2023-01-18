// brain

#include "EmotesCommon.as"

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		chasing,
		attacking,
		seekcover,
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
				&& (XORRandom(6) == 0 || (isVisible(blob, potential) && !potential.isAttached())))
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
			else {
				brain.SetSuggestedKeys();  // set walk keys here
			}
			
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

bool DefaultRetreatBlob(CBlob@ blob, CBlob@ target)
{
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
		blob.setKeyPressed(key_up, true);
	}

	if (blob.isOnLadder() && point.y < mypos.y)
	{
		blob.setKeyPressed(key_down, true);
	}

	JumpOverObstacles(blob);

	return true;
}

void SearchTarget(CBrain@ this, const bool seeThroughWalls = false, const bool seeBehindBack = true)
{
	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();

	// search target if none
	if (target is null || target.get_u32("can_spot") < getGameTime() || XORRandom(30) == 0)
	{
		CBlob@ oldTarget = target;
		@target = getNewTarget(this, blob, true, true);
		this.SetTarget(target);

		if (target !is oldTarget)
		{
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

		if (vehicle.getShape().vellen < (vehicleislow ? 0.07f : 0.35f))
		{
			// hmm we haven't moved, are we stuck?
			blob.add_u16("behaviortimer", vehicleislow ? 1 : 2);
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