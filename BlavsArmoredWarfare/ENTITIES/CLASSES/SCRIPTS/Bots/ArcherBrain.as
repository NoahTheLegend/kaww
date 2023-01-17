// Archer brain

#define SERVER_ONLY

#include "BrainCommon.as"
#include "ArcherCommon.as"
#include "RunnerHead.as"

float mouse_mvspd = 0.5f;

void onInit(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	
	InitBrain(this);

	blob.set_u8("moveover", 0);
	blob.set_u8("hittimer", 0);
	blob.set_u8("myKey", XORRandom(255)+1); // controls all behaviors

	blob.set_string("behavior", ""); //determines what to do
	blob.set_u16("behaviortimer", 0); //times things
	blob.set_u16("secondarytarget", 0); //less important objectives

	blob.set_Vec2f("generalenemylocation", Vec2f_zero); // determines what direction to move in
	
	// default aim
	Vec2f aimposvar = Vec2f(20 - XORRandom(40), 20 - XORRandom(40));
	float mousexvar = aimposvar.x;
	float mouseyvar = aimposvar.y / 50;

	blob.setAimPos(blob.getPosition() + aimposvar);
}


f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("player") && !this.hasTag("dead"))
		//PromptAction(this, get_hurt, 5 + XORRandom(5));

	this.add_u8("hittimer", Maths::Ceil(damage));
	//print("D " + this.get_u8("hittimer"));

	return damage;
}

void onTick(CBrain@ this)
{
	//this.getCurrentScript().tickFrequency = 1;

	SearchTarget(this, false, true);

	CBlob @blob = this.getBlob();
	
	// remove secondary target if it doesnt exist anymore
	if (getBlobByNetworkID(blob.get_u16("secondarytarget")) is null)
	{
		blob.set_u16("secondarytarget", 0);
	}
	
	CBlob @target = this.getTarget();

	if (blob.get_Vec2f("generalenemylocation") == Vec2f_zero || getGameTime() % 300 == 0) // update every 30 sec
	{
		LocateGeneralEnemyDirection(blob);// lets figure out which direction we should attack
	}
	
	

	if (blob.isAttached()) // vehicle logic
	{
		CBlob@ vehicle = getBlobByNetworkID(blob.get_u16("secondarytarget"));
		if (vehicle !is null)
		{
			// driving
			if (blob.isAttachedToPoint("DRIVER"))
			{
				//print("going to " + blob.get_Vec2f("generalenemylocation"));
				bool shouldigo = false;

				// check if this vehicle has a gunner seat
				AttachmentPoint@ gunnerseat = vehicle.getAttachments().getAttachmentPointByName("GUNNER");
				if (gunnerseat !is null)
				{
					// do we have a gunner?
					if (gunnerseat.getOccupied() !is null)
					{
						shouldigo = true;
					}
				}
				else // either we have no gunner seat, or we have a turret, or an mg
				{
					// check for turret
					AttachmentPoint@ turret = vehicle.getAttachments().getAttachmentPointByName("TURRET");
					if (turret !is null)
					{
						CBlob@ turretblob = turret.getOccupied();
						if (turretblob !is null)
						{
							//turretblob.getAttach
							// we have a turret
							AttachmentPoint@ turretgunnerseat = turretblob.getAttachments().getAttachmentPointByName("GUNNER");
							if (turretgunnerseat !is null)
							{
								if (turretgunnerseat.getOccupied() !is null)
								{
									shouldigo = true;
								}
								else
								{
									//turret has no gunner, lets wait
								}
							}
						}
					}
					else
					{
						AttachmentPoint@ mg = vehicle.getAttachments().getAttachmentPointByName("BOW");
						if (mg !is null)
						{
							CBlob@ mgblob = mg.getOccupied();
							if (mgblob !is null)
							{
								// check if mg has a gunner
								AttachmentPoint@ mgseat = mgblob.getAttachments().getAttachmentPointByName("GUNNER");
								if (mgseat !is null)
								{
									if (mgseat.getOccupied() !is null)
									{
										// we have a gunner, go
										shouldigo = true;
									}
									
								}
								
							}
						}
						else
						{
							// no gunner seat, lets move
							shouldigo = true;
						}
					}
				}

				if (shouldigo)
				{
					if (blob.get_string("behavior") == "drive")
					{
						if (blob.get_Vec2f("generalenemylocation") != Vec2f_zero)
						{
							if ((blob.get_Vec2f("generalenemylocation") - blob.getPosition()).getLength() > 200.0f)
							{
								if (blob.get_Vec2f("generalenemylocation").x > blob.getPosition().x)
								{
									blob.setKeyPressed(key_right, true);
								}
								else {
									blob.setKeyPressed(key_left, true);
								}
							}
							else if (getGameTime() % 120 == 0)
							{
								LocateGeneralEnemyDirection(blob); // new location
							}
						}

						// lift front end to climb
						if (vehicle.getShape().vellen < 0.5f)
						{
							blob.setKeyPressed(key_down, true);
						}

						if (vehicle.getShape().vellen < 0.4f)
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
							
							if (blob.getTeamNum() == 0) blob.setKeyPressed(key_left, true);
							else blob.setKeyPressed(key_right, true);
						}
						else // then go forward
						{
							if (blob.getTeamNum() == 0) blob.setKeyPressed(key_right, true);
							else blob.setKeyPressed(key_left, true);
						}

						if (vehicle.getShape().vellen > 0.2f && XORRandom(30) == 0 || XORRandom(40) == 0)
						{
							blob.set_string("behavior", "drive"); // switch to forward
						}
					}
				}
			}
		}
		else {
			blob.set_u16("secondarytarget", 0); // doesn't exist : remove
		}

		// gunning
		if (blob.isAttachedToPoint("GUNNER"))
		{
			if (target !is null)
			{
				u8 strategy = blob.get_u8("strategy");

				AttackBlob(blob, target);
				//blob.setKeyPressed(key_action1, true);

				if (LoseTarget(this, target))
				{
					strategy = Strategy::idle;
				}

				if (getGameTime() % 10 == 0 && XORRandom(90) == 0)
				{
					blob.server_DetachAll(); // hop out
				}
			}
		}

		// passenger
		if (blob.isAttachedToPoint("PASSENGER") || blob.isAttachedToPoint("PASSENGER1") || blob.isAttachedToPoint("PASSENGER2") || blob.isAttachedToPoint("PASSENGER3") || blob.isAttachedToPoint("PASSENGER4"))
		{		
			if (target !is null)
			{
				u8 strategy = blob.get_u8("strategy");

				AttackBlob(blob, target);
				//blob.setKeyPressed(key_action1, true);

				if (LoseTarget(this, target))
				{
					strategy = Strategy::idle;
				}

				if (getGameTime() % 10 == 0 && XORRandom(90) == 0)
				{
					blob.server_DetachAll(); // hop out
				}
			}

			if (getGameTime() % 10 == 0 && XORRandom(90) == 0)
			{
				blob.server_DetachAll(); // hop out
			}
		}
		
	}
	else{ // infantry logic
		// logic for target
		if (target !is null)
		{
			u8 strategy = blob.get_u8("strategy");

			f32 distance;
			const bool visibleTarget = isVisible(blob, target, distance);
			if (visibleTarget)
			{
				if (blob.get_u32("mag_bullets") == 0) // low hp, seek cover
				{

				}
				if (blob.get_u32("mag_bullets") == 0) // no ammo, retreat!
				{
					strategy = Strategy::retreating;
				}
				else // i have ammo, push
				{
					const s32 difficulty = blob.get_s32("difficulty");
					if ((!blob.isKeyPressed(key_action1) && getGameTime() % (300 + blob.get_u8("myKey")) < 240 && distance < 30.0f + 3.0f * difficulty))
						strategy = Strategy::attacking;
					else
					{
						strategy = Strategy::attacking;
					}
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






			if (blob.get_u32("mag_bullets") != blob.get_u32("mag_bullets_max")) // not 100% full on ammo
			{

				if ((XORRandom(100) < 10 && blob.get_u32("mag_bullets") == 0) || XORRandom(350) < 1) // completely out of ammo
				{
					blob.set_u8("reloadqueue", 5);
					blob.Sync("reloadqueue", true);
					//blob.set_u32("mag_bullets", blob.get_u32("mag_bullets_max"));
				}
			}
			
			


			// unpredictable movement
			if (getGameTime() % blob.get_u8("myKey") == 0 && XORRandom(3) == 0)
			{
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

			if (XORRandom(500) == 0)
			{
				@target = null;
			}
		}
		else
		{
			// do objective stuff?

			if (getGameTime() > 60*30) // vehicles are now available
			{
				
				if (blob.get_u8("myKey") % 3 != 0) // only some bots are destined to use vehicles
				{				
					
					CBlob@[] vehicles;
					getBlobsByTag("vehicle", @vehicles);

					if (vehicles.length > 0) // if there are vehicles
					{
						
						if (getGameTime() % 50 == 0) // every once in a while
						{
							
							if (blob.get_u16("secondarytarget") == 0) // we dont have a secondary target
							{
								// choose a random vehicle to drive
								CBlob@ vehicle = vehicles[XORRandom(vehicles.length)];
								if (vehicle !is null)
								{
									// is it on our team?
									if (vehicle.getTeamNum() == blob.getTeamNum())
									{
										// is it nearby me?
										if ((vehicle.getPosition() - blob.getPosition()).getLength() < 750.0f)
										{
											if (!vehicle.hasTag("turret") && !vehicle.hasTag("gun") && !vehicle.hasTag("aerial") // isnt a turret or machine gun or plane
											&& vehicle.getName() != "importantarmory") // dont drive this for now
											{
												// let's check if the driver seat is occupied
												AttachmentPoint@ point = vehicle.getAttachments().getAttachmentPointByName("DRIVER");
												if (point !is null)
												{
													CBlob@ occupied = point.getOccupied();
													if (occupied is null)
													{
														// drivers seat is empty

														// add the vehicle to secondary target
														if (vehicle.getNetworkID() != 0)
														{
															blob.set_u16("secondarytarget", vehicle.getNetworkID());
															blob.set_string("behavior", "drive");
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}

			
			//return;

			if (getGameTime() < 30 + blob.get_u8("myKey"))
			{
				// wait a moment before starting
			}
			else
			{
				if (blob.get_u16("secondarytarget") != 0) // we have a secondary objective we should be doing
				{
					CBlob@ target = getBlobByNetworkID(blob.get_u16("secondarytarget"));
					if (target !is null)
					{
						if ((target.getPosition() - blob.getPosition()).getLength() < 50)
						{
							// fine tuned sitting
							AttachmentPoint@ choosen_seat = null;
							
							if (blob.get_string("behavior") == "drive")
							{
								@choosen_seat = target.getAttachments().getAttachmentPointByName("DRIVER");
							}

							if (blob.get_string("behavior") == "gun")
							{
								@choosen_seat = target.getAttachments().getAttachmentPointByName("GUNNER");
							}

							if ((blob.getPosition() - choosen_seat.getPosition()).getLength() < 8)
							{
								if (getGameTime() % 6 == 0)
								{
									blob.setKeyPressed(key_down, true); // sit
								}
							}
							else
							{
								if (choosen_seat.getPosition().y + 16 > blob.getPosition().y)
								{
									blob.setKeyPressed(key_up, true);
								}

								if (choosen_seat.getPosition().x > blob.getPosition().x)
								{
									blob.setKeyPressed(key_right, true);
								}
								else
								{
									blob.setKeyPressed(key_left, true);
								}
							}
							

							
						}
						else{
							// walk to
							if (target.getPosition().x > blob.getPosition().x)
							{
								blob.setKeyPressed(key_right, true);
							}
							else
							{
								blob.setKeyPressed(key_left, true);
							}
						}					
					}
				}
				else
				{
					if (blob.getTeamNum() == 0)
					{
						blob.setKeyPressed(key_right, true);
					}
					else
					{
						blob.setKeyPressed(key_left, true);
					}
				}
			}

			Vec2f mypos = blob.getPosition();

			if (getGameTime() > blob.get_u8("myKey")/4 && blob.getTickSinceCreated() > 20) // wait a little bit before aiming on match start
			{
				Vec2f aimposvar = Vec2f(0, 0);

				if (blob.get_Vec2f("generalenemylocation") != Vec2f_zero)
				{
					aimposvar = blob.get_Vec2f("generalenemylocation");
				}

				if (blob.get_u16("secondarytarget") != 0) // we have a secondary target
				{
					// aim at it
					aimposvar = getBlobByNetworkID(blob.get_u16("secondarytarget")).getPosition();
				}

				if (blob.get_u8("moveover") > 0) // bot is doing a complex movement
				{
					//aimposvar = 0;
				}




				float mousexvar = aimposvar.x;
				float mouseyvar = aimposvar.y; //Maths::Clamp(aimposvar.y / 10,	-25, 25);
				blob.setAimPos(Vec2f_lerp(blob.getAimPos(), mypos + Vec2f(mousexvar, mouseyvar), 0.05));
			}


			// unpredictable movement
			if (getGameTime() % blob.get_u8("myKey") == 0 && XORRandom(3) == 0)
			{
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
				if (blob.get_u8("myKey") < 120)
				{
					blob.setKeyPressed(key_up, false);
				}
				if (blob.get_u8("myKey") > 220)
				{
					blob.setKeyPressed(key_down, true);
				}
			}

			//RandomTurn(blob);
		}

	}
	
	JumpOverObstacles(blob);

	FloatInWater(blob);

	// Eat if lost hp
	if (blob.getInitialHealth() - 0.5f > blob.getHealth())
	{
		blob.setKeyPressed(key_eat, true);
	}

	if (blob.get_u16("behaviortimer") > 0)
	{
		blob.sub_u16("behaviortimer", 1);
	}
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

	//JumpOverObstacles(blob);

	// fire
	f32 distance;
	Vec2f col;
	if (!getMap().rayCastSolid(blob.getPosition() + blob.getVelocity()*3.0f, targetPos + getRandomVelocity( 0, target.getRadius() , 360 ) + target.getVelocity()*5.0f, col))
	{
		if (targetDistance > 8.0f)
		{
			if (targetDistance < 460.0f)
			{
				blob.setKeyPressed(key_action1, true);

				if (blob.get_u8("myKey") % 13 == 0)
				{
					blob.setKeyPressed(key_action2, true);
				}
			}
			else if (blob.get_u8("myKey") > 120 && targetDistance < 500.0f)
			{
				blob.setKeyPressed(key_action1, true);

				if (blob.get_u8("myKey") % 2 == 0)
				{
					blob.setKeyPressed(key_action2, true);
				}
			}

			if (target !is null)
			{
				blob.setAimPos(Vec2f_lerp(blob.getAimPos(),
									targetPos - Vec2f(0, targetDistance / 40.0f) + Vec2f(0.0f, 10 -XORRandom(17)) + target.getVelocity() * 5.5f,
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

	/*
			AttachmentPoint@ point = vehicle.getAttachments().getAttachmentPointByName("DRIVER");
			if (point !is null)
			{
				CBlob@ occupied = point.getOccupied();
				if (occupied !is null)
				{
					print("o " + occupied.getName());
					print("b " + blob.getName());

					if (occupied is blob)
					{
						print("sa");
					}
					//if (occupied.ge == blob)
					{
						//print("a " + occupied.getName());
					}
					//else
					{
						//print("b " + occupied.getName());
					}
					
				}
				
			}*/

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