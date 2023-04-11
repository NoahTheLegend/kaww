#define SERVER_ONLY

#include "BrainCommon.as"
#include "InfantryCommon.as"
#include "RunnerHead.as"

const bool emotes = false; // debug emotes

const bool realemotes = true; // player like emotes

void onInit(CBrain@ this)
{
	InitBrain(this);

	CBlob @blob = this.getBlob();
	
	blob.set_u8("moveover", 0);
	blob.set_u8("hittimer", 0);
	blob.set_u8("myKey", XORRandom(255)+1); // controls all behaviors

	blob.set_string("behavior", ""); //determines what to do
	blob.set_u16("behaviortimer", 0); //times things
	blob.set_u16("secondarytarget", 0); //less important objectives
	blob.set_u16("tertiarytarget", 0); //even less important objectives

	blob.set_Vec2f("generalenemylocation", Vec2f_zero); // determines what direction to move in to find enemies
	blob.set_Vec2f("generalfriendlocation", Vec2f_zero); // determines what direction to move in to be safe
	
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
	if (getRules().getCurrentState() == GAME_OVER) return;
	SearchTarget(this, false, true);

	CBlob @blob = this.getBlob();
	CBlob @target = this.getTarget();
	if (blob is null) return;

	if (blob.get_string("last_attacker") != "" && getPlayerByUsername(blob.get_string("last_attacker")) !is null)
	{
		CBlob@ bs = getPlayerByUsername(blob.get_string("last_attacker")).getBlob();
		if (bs !is null && (blob.getPosition() - bs.getPosition()).Length() < 356.0f)
		{
			@target = bs;
			blob.set_string("last_attacker", "");
		}
	}

	// remove secondary target if it doesnt exist anymore
	if (getBlobByNetworkID(blob.get_u16("secondarytarget")) is null)
	{
		if (blob.get_u16("secondarytarget") != 0)
		{
			//print("target didnt exist, removing");
			blob.set_u16("secondarytarget", 0);
		}
	}

	// remove tertiary target if it doesnt exist anymore
	if (getBlobByNetworkID(blob.get_u16("tertiarytarget")) is null)
	{
		if (blob.get_u16("tertiarytarget") != 0)
		{
			//print("target didnt exist, removing");
			blob.set_u16("tertiarytarget", 0);
		}
	}

	if (blob.get_Vec2f("generalenemylocation") == Vec2f_zero || (getGameTime()) % 600 == 0) // update once in a while & when needed
	{
		LocateGeneralEnemyDirection(blob); // lets figure out which direction we should attack
	}

	if (blob.get_Vec2f("generalfriendlocation") == Vec2f_zero || (getGameTime()) % 1200 == 0) // update once in a while & when needed
	{
		LocateGeneralFriendDirection(blob); // gives the direction we can retreat to
	}
	
	if (isServer() && target !is null) // process only on server, for only server-side bot brain
	{
		CBlob@[] bushes;
		if (target.getPlayer() !is null
		&& getRules().get_string(target.getPlayer().getUsername() + "_perk") == "Camouflage"
		&& target.getOverlapping(@bushes))
		{
			for (u16 i = 0; i < bushes.length; i++)
			{
				CBlob@ bush = bushes[i];
				if (bush is null || bush.getName() != "bush") continue;
				if (target.get_u32("can_spot") > getGameTime())
				{
					target.Tag("disguised"); // add a tag so blobs that werent seen by bots have a pre-check for permormance
					target.set_u32("can_spot", getGameTime()+30); // bot sees player and renews timer for revealing
				}
				else
				{
					target.Tag("disguised");
					return;
				}
			}
		}
	}
	
	if (blob.isAttached()) // vehicle logic
	{
		CBlob@ vehicle = getBlobByNetworkID(blob.get_u16("secondarytarget"));
		CBlob@ tertiarytarget = getBlobByNetworkID(blob.get_u16("tertiarytarget"));
		if (vehicle !is null)
		{
			// driving
			if (blob.isAttachedToPoint("DRIVER"))
			{
				bool shouldigo = false;
				bool repairsneeded = false;
				int vehicledangerlevel = 0;

				// check if this vehicle has a gunner seat
				CAttachment@ at = vehicle.getAttachments();
				if (at !is null)
				{
					AttachmentPoint@ gunnerseat = at.getAttachmentPointByName("GUNNER");
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
						AttachmentPoint@ turret = at.getAttachmentPointByName("TURRET");
						if (turret !is null)
						{
							CBlob@ turretblob = turret.getOccupied();
							if (turretblob !is null)
							{
								//turretblob.getAttach
								// we have a turret
								CAttachment@ turretat = turretblob.getAttachments();
								if (turretat !is null)
								{
									AttachmentPoint@ turretgunnerseat = turretat.getAttachmentPointByName("GUNNER");
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
						}
						else
						{
							AttachmentPoint@ mg = at.getAttachmentPointByName("BOW");
							if (mg !is null)
							{
								CBlob@ mgblob = mg.getOccupied();
								if (mgblob !is null)
								{
									// check if mg has a gunner
									if (mgblob.getAttachments() !is null)
									{
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
							}
							else
							{
								// no gunner seat, lets move
								shouldigo = true;
							}
						}
					}
				}

				// calculate the current danger level
				
				// vehicle health
				vehicledangerlevel += Maths::Ceil(5*Maths::Abs(vehicle.getHealth() - vehicle.getInitialHealth()) / vehicle.getInitialHealth());

				// player health
				vehicledangerlevel += Maths::Ceil(2*Maths::Abs(blob.getHealth() - blob.getInitialHealth()) / blob.getInitialHealth());

				// enemy presence
				if (Maths::Abs(blob.get_Vec2f("generalenemylocation").x - vehicle.getPosition().x) < 200.0f) {
					vehicledangerlevel += 1;
				}
				
				// confidence with allies
				if (Maths::Abs(blob.get_Vec2f("generalfriendlocation").x - vehicle.getPosition().x) < 300.0f) {
					vehicledangerlevel -= 1;
				}

				// is on repair station
				if (tertiarytarget !is null)
				{
					if (Maths::Abs(tertiarytarget.getPosition().x - vehicle.getPosition().x) < 20.0f) {
						vehicledangerlevel -= 1;
					}
				}

				//print("" + vehicle.getName() + ": " + vehicledangerlevel);

				if (tertiarytarget is null)
				{	
					if (shouldigo)
					{
						if (vehicledangerlevel > 3)
						{
							repairsneeded = true;
						}
						else
						{
							// basic vehicle behavior

							if (target !is null)
							{
								// we've got a target
								//print("target " + target.getName());

								if (target.isAttached())
								{
									// target is in a vehicle

									// stay still so gunner can aim

									bool listentogunner = false;
									if ((target.getPosition() - blob.getPosition()).getLength() < 560.0f && vehicle.getAttachments() !is null)
									{
										// is gunner aiming at the target?
										
										if (vehicle.getName() == "techtruck")
										{
											listentogunner = true;
										}
										else {
											AttachmentPoint@ turretpoint = vehicle.getAttachments().getAttachmentPointByName("TURRET");
											if (turretpoint !is null)
											{
												CBlob@ turret = turretpoint.getOccupied();

												if (turret !is null && turret.getAttachments() !is null)
												{
													VehicleInfo@ v;
													if (!turret.get("VehicleInfo", @v)) return;

													AttachmentPoint@ point = turret.getAttachments().getAttachmentPointByName("GUNNER");
													if (point !is null && point.getOccupied() !is null)
													{

														// take directions from gunner

														// respond to gunner emotes
														if (realemotes)
														{
															if (point.getOccupied().get_u8("emote") == 11) // go to left
															{
																blob.setKeyPressed(key_left, true);
																blob.setKeyPressed(key_right, false);
																if (getGameTime() % 30 == 0 && XORRandom(15) == 0)
																{
																	if (XORRandom(2) == 0)
																	{
																		set_emote(blob, Emotes::okhand);
																	}
																	else{
																		set_emote(blob, Emotes::left);
																	}
																}
															}

															if (point.getOccupied().get_u8("emote") == 3) // go to right
															{ 
																blob.setKeyPressed(key_left, false);
																blob.setKeyPressed(key_right, true);
																if (getGameTime() % 30 == 0 && XORRandom(15) == 0)
																{
																	if (XORRandom(2) == 0)
																	{
																		set_emote(blob, Emotes::okhand);
																	}
																	else{
																		set_emote(blob, Emotes::right);
																	}
																}
															}
														}

														f32 gunangle = Vehicle_getWeaponAngle(turret, v);

														if (vehicle.isFacingLeft())
														{
															gunangle -= 90;
															gunangle *= -1;
															gunangle += 360;
														}
														else {
															gunangle += 90;

															if (gunangle <= 0) gunangle += 180;
															else gunangle -= 180;

															gunangle *= -1;
															gunangle += 360;
														}

														if (gunangle > 360) gunangle -= 360;
														else gunangle = gunangle;

														float anglediff = 0.0f;
														if (vehicle.getName() != "techtruck") // temp
														{
															anglediff = Maths::Abs(Maths::Abs(gunangle + -1*(vehicle.getAngleDegrees()-360)) - Maths::Abs((target.getPosition() - point.getOccupied().getPosition()).getAngleDegrees()));
														}

														if (anglediff < 18.0f)
														{
															if (point.getOccupied().getPlayer() !is null && point.getOccupied().getPlayer().isBot())
															{
																// is bot
																if (anglediff < 7.0f)
																{
																	listentogunner = true;
																}
															}
															else{
																listentogunner = true;
															}
															
														}
													}
												}
											}
										}
									}
									
									if (listentogunner)
									{
										if (emotes) set_emote(blob, Emotes::attn, 10);
									}
									else{
										DriveToPos(blob, vehicle, blob.get_Vec2f("generalenemylocation"), 300);
									}
								}
								else{
									//target is ground infantry

									if (emotes) set_emote(blob, Emotes::check, 10);

									DriveToPos(blob, vehicle, blob.get_Vec2f("generalenemylocation"), 300);
								}
							}
							else if (blob.get_Vec2f("generalenemylocation") != Vec2f_zero)
							{
								// no target, drive around to locations where there should be enemies
								DriveToPos(blob, vehicle, blob.get_Vec2f("generalenemylocation"), 300);
							}
						}
					}
					else
					{
						if (vehicledangerlevel > 2)
						{
							repairsneeded = true; // todo: based on distance to repair station
						}

						if (emotes) set_emote(blob, Emotes::down, 10);
					}
				}
				else{
					repairsneeded = true;
				}

				// do driver emotes
				if (realemotes)
				{
					// we are chillin
					if (vehicledangerlevel < 0)
					{
						if (shouldigo)
						{
							if (getGameTime() % 30 == 0 && XORRandom(120) == 0)
							{
								if (XORRandom(2) == 0)
								{
									set_emote(blob, Emotes::flex);
								}
								else{
									if (blob.get_Vec2f("generalenemylocation").x > vehicle.getPosition().x)
									{
										set_emote(blob, Emotes::right);
									}
									else{
										set_emote(blob, Emotes::left);
									}
									
								}
								
							}
						}
						else{
							// come gun please
							if (Maths::Abs(blob.get_Vec2f("generalfriendlocation").x - vehicle.getPosition().x) < 400.0f)
							{
								if (getGameTime() % 30 == 0 && XORRandom(30) == 0)
								{
									set_emote(blob, Emotes::down);
								}
							}
						}
					}

					// we are not chillin
					if (vehicledangerlevel > 3)
					{
						if (getGameTime() % 30 == 0 && XORRandom(90) == 0)
						{
							set_emote(blob, Emotes::attn);
						}
					}
				}

				if (repairsneeded)
				{
					if (tertiarytarget !is null && tertiarytarget.getName() == "repairstation")
					{
						if ((tertiarytarget.getPosition() - vehicle.getPosition()).getLength() > 10.0f)
						{
							if ((tertiarytarget.getPosition() - vehicle.getPosition()).getLength() < 80.0f)
							{
								if (getGameTime() % 5 != 0)
								{
									DriveToPos(blob, vehicle, tertiarytarget.getPosition(), 10); // slow down
								}
							}
							else{
								DriveToPos(blob, vehicle, tertiarytarget.getPosition(), 10);
							}
							
							if (realemotes)
							{
								// do driver repair emotes
								if (getGameTime() % 30 == 0 && XORRandom(120) == 0)
								{
									if (XORRandom(2) == 0)
									{
										set_emote(blob, XORRandom(2) == 0 ? Emotes::builder : Emotes::frown);
									}
									else{
										if (tertiarytarget.getPosition().x > vehicle.getPosition().x)
										{
											set_emote(blob, Emotes::right);
										}
										else{
											set_emote(blob, Emotes::left);
										}
									}
								}
							}
						}
						else if (!(blob.isFacingLeft() && blob.get_Vec2f("generalenemylocation").x < blob.getPosition().x)
							  && !(!blob.isFacingLeft() && blob.get_Vec2f("generalenemylocation").x > blob.getPosition().x))
						{
							DriveToPos(blob, vehicle, tertiarytarget.getPosition(), 10);
						}
						
						if (vehicle.getHealth() == vehicle.getInitialHealth() || tertiarytarget is null)
						{
							blob.set_u16("tertiarytarget", 0); // stop repairing
						}
					}
					else {
						// choose a repair station
						CBlob@[] repairstations;
						getBlobsByName("repairstation", @repairstations);

						if (repairstations.length > 0)
						{
							SortBlobsByDistance(blob, repairstations);

							for (uint i = 0; i < repairstations.length; i++)
							{
								CBlob@ curBlob = repairstations[i];

								// find a same team repair station to use
								if (curBlob.getTeamNum() == vehicle.getTeamNum())
								{
									blob.set_u16("tertiarytarget", curBlob.getNetworkID());
									break;
								}
							}
						}
						else{
							// theres no repair stations..

							if (blob.getPosition().x < (250.0f + blob.get_u8("mykey")) or blob.getPosition().x > (getMap().tilemapwidth * getMap().tilesize) - (250.0f + blob.get_u8("mykey"))) // if on the edge of the map
							{
								// face the danger
								if (vehicle.isFacingLeft() && blob.get_Vec2f("generalenemylocation").x > blob.getPosition().x || !vehicle.isFacingLeft() && blob.get_Vec2f("generalenemylocation").x < blob.getPosition().x )
								{
									DriveToPos(blob, vehicle, blob.get_Vec2f("generalenemylocation"), 100);
								}
							}
							else{
								// flee!
								if (vehicledangerlevel < 5)
								{
									// reverse
									//blob.setKeyPressed(key_action2, true);
								}

								DriveToPos(blob, vehicle, blob.get_Vec2f("generalfriendlocation"), 100);
							}

							// need repairs emotes & hop out!
							if (getGameTime() % 30 == 0 && XORRandom(40) == 0)
							{
								set_emote(blob, XORRandom(2) == 0 ? Emotes::builder : Emotes::heal);

								if (XORRandom(2) == 0)
								{
									blob.server_DetachAll(); // hop out
									blob.set_string("behavior", "");
									blob.set_u16("secondarytarget", 0);
								}
							}
						}
					}
				}
				// special unstuck logic
				if (vehicle.getShape().vellen < 1.85)
				{	
					if (Maths::Abs(vehicle.getAngleDegrees()) > 60 && Maths::Abs(vehicle.getAngleDegrees()) < 300)
					{
						if (realemotes)
						{
							if (XORRandom(200) == 0 && getGameTime() % 30 == 0)
							{
								set_emote(blob, Emotes::mad);
							}
						}

						// we're stuck

						if (blob.get_u16("behaviortimer") < 100)
						{
							if (getGameTime() % 400 + blob.get_u8("mykey") < 250)
							{
								blob.setKeyPressed(key_left, false);
								blob.setKeyPressed(key_right, true);
							}
							else
							{
								blob.setKeyPressed(key_left, true);
								blob.setKeyPressed(key_right, false);
							}

							if (getGameTime() % 200 + blob.get_u8("mykey") < 100)
							{
								blob.setKeyPressed(key_down, true);
							}
						}
					}
				}

				// im in the wrong seat
				if (getGameTime() % 10 == 0 && XORRandom(3) == 0 && blob.get_string("behavior") == "gun_mg" || blob.get_string("behavior") == "gun_turret")
				{
					blob.server_DetachAll(); // hop out
					if (XORRandom(2) == 0) blob.set_string("behavior", ""); // chance to lose interest in that seat
				}

				// okay fine, ill be in this seat
				if (blob.get_string("behavior") == "")
				{
					blob.set_string("behavior", "drive");
				}
			}
		}
		else if (blob.get_u16("secondarytarget") != 0){
			//print("target didnt exist, removing");
			blob.set_u16("secondarytarget", 0); // doesn't exist : remove
		}

		// gunning
		if (blob.isAttachedToPoint("GUNNER"))
		{
			if (target !is null)
			{
				if (XORRandom(30) == 0)
				{
					this.SetTarget(null);
				}

				u8 strategy = blob.get_u8("strategy");

				AttackBlobGunner(blob, target, vehicle);
				//blob.setKeyPressed(key_action1, true);

				if (LoseTarget(this, target))
				{
					strategy = Strategy::idle;
				}

				if (getGameTime() % 10 == 0 && XORRandom(300) == 0)
				{
					blob.server_DetachAll(); // hop out
				}
			}

			// do gunner emotes
			if (realemotes)
			{
				// we are chillin
				if (target is null)
				{
					if (XORRandom(200) == 0 && getGameTime() % 30 == 0)
					{
						set_emote(blob, Emotes::note);
					}
				}
				else{
					if (XORRandom(300) == 0 && getGameTime() % 30 == 0)
					{
						if (XORRandom(2) == 0)
						{
							set_emote(blob, Emotes::troll);
						}
						else{
							set_emote(blob, Emotes::finger);
						}
					}
				}
			}

			// im in the wrong seat
			if (getGameTime() % 10 == 0 && XORRandom(30) == 0 && blob.get_string("behavior") == "drive")
			{
				blob.server_DetachAll(); // hop out
				if (XORRandom(2) == 0) blob.set_string("behavior", ""); // chance to lose interest in that seat
			}

			// okay fine, ill be in this seat
			if (blob.get_string("behavior") == "")
			{
				blob.set_string("behavior", "gun");
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

				if (getGameTime() % 10 == 0 && (blob.getShape().vellen > 0.5 ? XORRandom(60) == 0 : XORRandom(30) == 0))
				{
					blob.server_DetachAll(); // hop out
					blob.set_string("behavior", "");
				}

				//if (blob.get_u32("mag_bullets") != blob.get_u32("mag_bullets_max")) // not 100% full on ammo
				//{
//
				//	if ((XORRandom(100) < 10 && blob.get_u32("mag_bullets") == 0) || XORRandom(350) < 1) // completely out of ammo
				//	{
				//		blob.set_u8("reloadqueue", 5);
				//		blob.Sync("reloadqueue", true);
				//		//blob.set_u32("mag_bullets", blob.get_u32("mag_bullets_max"));
				//	}
				//}
			}


			if (getGameTime() % (blob.getShape().vellen > 0.5 ? 10 : 5) == 0 && XORRandom(getGameTime() > 9000 ? 200 : 100) == 0)
			{
				blob.server_DetachAll(); // hop out
				blob.set_string("behavior", "");
			}
		}
		
	}
	else{ // infantry logic
		CBlob @check;
		u8 strategy = blob.get_u8("strategy");

		if (blob.getHealth() < blob.getInitialHealth() / 2.5) // low hp, seek cover
		{
			strategy = Strategy::seekcover;
		}
		else if (strategy == Strategy::seekcover)
		{
			strategy = Strategy::idle;
		}

		if (blob.get_u32("mag_bullets") == 0) // no ammo, retreat!
		{
			if (blob.getControls() !is null && !blob.hasTag("forcereload") && (getGameTime() + blob.getNetworkID()) % (XORRandom(30) + 1) == 0)
			{
				CBitStream params;
				blob.SendCommand(blob.getCommandID("reload"), params);
			}

			if (target !is null && blob.get_u8("myKey") > 150 && (isVisible(blob, target) || blob.get_u8("myKey") > 210))
			{
				strategy = Strategy::retreating;
			}
		}

		if (target !is null) // logic for target
		{
			f32 distance;
			const bool visibleTarget = isVisible(blob, target, distance);

			// find heals
			if (blob.getInitialHealth() / 2 > blob.getHealth() && distance > 24.0f)
			{
				if (!blob.hasBlob("food", 1) && !blob.hasBlob("heart", 1))
				{
					Vec2f mypos = blob.getPosition();
					Vec2f targetpos = target.getPosition();

					CBlob@[] healing;
					getBlobsByName("food", @healing);
					getBlobsByName("heart", @healing);
					SortBlobsByDistance(blob, @healing);
					for( int i = 0; i < healing.size(); i++ )
					{
						@check = healing[i];
						Vec2f dist = check.getPosition() - mypos;
						Vec2f disttoenemy = check.getPosition() - targetpos;
						if (!check.isInInventory() && check.isAttached())
						{
							if (dist.getLength() < 456.0f && disttoenemy.getLength() > 32.0f)
							{
								strategy = Strategy::seekheal;
								break;
							}
						}
					}

					healing.clear();
				}
			}

			if (strategy == Strategy::seekheal)
			{
				if (XORRandom(300) == 0) strategy = Strategy::idle;

				if (realemotes)
				{
					// do driver repair emotes
					if (getGameTime() % 30 == 0 && XORRandom(200) == 0)
					{
						set_emote(blob, XORRandom(2) == 0 ? Emotes::heal : Emotes::cry);
					}
				}
			}

			if (strategy != Strategy::seekcover && strategy != Strategy::retreating && strategy != Strategy::seekheal) // dont overwrite
			{
				if (visibleTarget)
				{
					if (blob.get_u32("mag_bullets") > blob.get_u32("mag_bullets_max")/2) // i have ammo, push
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
			}

			UpdateBlob(blob, target, strategy, @check);

			// lose target if its killed (with random cooldown)

			if (LoseTarget(this, target))
			{
				strategy = Strategy::idle;
			}

			if (blob.get_u32("mag_bullets") != blob.get_u32("mag_bullets_max")) // not 100% full on ammo
			{
				if ((XORRandom(100) < 10 && blob.get_u32("mag_bullets") == 0) || XORRandom(350) < 1) // completely out of ammo
				{
					if (blob.getControls() !is null && !blob.hasTag("forcereload"))
					{
						CBitStream params;
						blob.SendCommand(blob.getCommandID("reload"), params);
					}
				}
			}

			blob.set_u8("strategy", strategy);

			if (blob.get_u8("strategy") == Strategy::seekcover)
			{
				if (blob.get_Vec2f("generalfriendlocation") != Vec2f_zero)
				{
					Vec2f aimposvar = blob.get_Vec2f("generalfriendlocation");

					blob.setAimPos(Vec2f_lerp(blob.getAimPos(), Vec2f(aimposvar.x, aimposvar.y), 0.02));
				}
			}
		}
		else
		{
			// do objective stuff?

			if (getGameTime() < 30 + blob.get_u8("myKey"))
			{
				// wait a moment before starting
			}
			else
			{
				if (blob.get_u16("secondarytarget") != 0) // we have a secondary objective we should be doing
				{
					CBlob@ secondarytarget = getBlobByNetworkID(blob.get_u16("secondarytarget"));
					if (secondarytarget !is null)
					{
						if (secondarytarget.hasTag("vehicle")) // we are going for a vehicle seat
						{
							if (emotes) set_emote(blob, Emotes::cog, 2);

							if ((secondarytarget.getPosition() - blob.getPosition()).getLength() < 40 && secondarytarget.getAttachments() !is null)
							{
								// fine tuned sitting
								AttachmentPoint@ choosen_seat = null;
								bool sitinoccupied = false;
								bool userealpos = false;
								bool pickadifferentseat = false;
								
								//print("d " + blob.get_string("behavior"));
								if (blob.get_string("behavior") == "drive")
								{
									@choosen_seat = secondarytarget.getAttachments().getAttachmentPointByName("DRIVER");
								}
								else if (blob.get_string("behavior") == "gun_mg")
								{
									@choosen_seat = secondarytarget.getAttachments().getAttachmentPointByName("BOW");
									sitinoccupied = true;
								}
								else if (blob.get_string("behavior") == "gun_turret")
								{
									@choosen_seat = secondarytarget.getAttachments().getAttachmentPointByName("TURRET");
									sitinoccupied = true;
								}

								if (choosen_seat !is null) // if we have a seat in mind
								{
									if ((blob.getPosition() - choosen_seat.getPosition()).getLength() < 12)
									{
										if (getGameTime() % 6 == 0)
										{
											blob.setKeyPressed(key_down, true); // sit

											// force attachment cause bots cant sit while in air
											if (!blob.isOnGround() && !blob.wasOnGround())
											{
												if (sitinoccupied)
												{
													if (choosen_seat.getOccupied() !is null && choosen_seat.getOccupied().getAttachments() !is null)
													{
														AttachmentPoint@ new_seat = choosen_seat.getOccupied().getAttachments().getAttachmentPointByName("GUNNER");

														if (new_seat !is null)
														{
															if (new_seat.getOccupied() is null) // check if nobody is in the seat
															{
																choosen_seat.getOccupied().server_AttachTo(blob, @new_seat);
															}
															else if (XORRandom(5) == 0) // give up
															{
																pickadifferentseat = true;
															}
														}
													}
												}
												else {
													if (choosen_seat.getOccupied() is null) // check if nobody is in the seat
													{
														secondarytarget.server_AttachTo(blob, @choosen_seat);
													}
													else if (XORRandom(5) == 0) // give up
													{
														pickadifferentseat = true;
													}
												}
											}
										}
									}
								}

								if (pickadifferentseat)
								{
									blob.set_string("behavior", "random");
								}

								if (blob.get_string("behavior") == "random" || blob.get_string("behavior") == "")
								{
									AttachmentPoint@[] aps;
									if (secondarytarget.getAttachmentPoints(@aps))
									{
										AttachmentPoint@ ap = aps[XORRandom(aps.length)];

										if (ap.getOccupied() is null)
										{
											// random seat in the vehicle is empty

											// if right next to the seat, attach
											if ((blob.getPosition() - ap.getPosition()).getLength() < 11)
											{
												secondarytarget.server_AttachTo(blob, @ap);

												blob.set_string("behavior", ""); // set it to empty, so that this bot will change its behavior based on the seat type
											}
											else {
												@choosen_seat = @ap;

												blob.set_string("behavior", ""); // fuck

												//blob.set_string("behavior", "movetorandom"); // move to it
											}
										}
									}
								}
								
								if (choosen_seat !is null) // move to it / jump to it
								{
									if (choosen_seat.getPosition().y + 50 > blob.getPosition().y)
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
								GoToPos(blob, secondarytarget.getPosition());

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
									if (XORRandom(70) == 0 || (blob.get_u16("secondarytarget") != 0 && XORRandom(20) == 0))
									{
										blob.set_u8("moveover", 0); //end
									}

									blob.setKeyPressed(key_left, false);
									blob.setKeyPressed(key_right, false);

									if (blob.get_u8("moveover") == 1) // 1 == right
									{
										//if (emotes) set_emote(blob, Emotes::right, 10);
										blob.setKeyPressed(key_right, true);
									}
									else // 0 == left
									{		
										//if (emotes) set_emote(blob, Emotes::left, 10);
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
							}		
						}		
						else if (secondarytarget.getName() == "pointflag") // we are going for flag
						{	
							if (emotes) set_emote(blob, Emotes::redflag, 10);

							if (secondarytarget.getTeamNum() != blob.getTeamNum()) // capturable for us
							{
								if ((secondarytarget.getPosition() - blob.getPosition()).getLength() < 80 + blob.get_u8("mykey")/2)
								{
									// capture the point
								}
								else{
									GoToPos(blob, secondarytarget.getPosition());
								}
							}
							else
							{
								if (realemotes)
								{
									if (XORRandom(12) == 0)
									{
										if (XORRandom(2) == 0)
										{
											set_emote(blob, Emotes::smile);
										}
										else{
											set_emote(blob, Emotes::thumbsup);
										}
									}
								}
								blob.set_u16("secondarytarget", 0); // capture complete
							}
						}
						else if (secondarytarget.getName() == "repairstation") // we are capping a repair station
						{	
							if (emotes) set_emote(blob, Emotes::redflag, 10);

							if (secondarytarget.getTeamNum() != blob.getTeamNum()) // capturable for us
							{
								if ((secondarytarget.getPosition() - blob.getPosition()).getLength() < 10 + blob.get_u8("mykey")/2)
								{
									// capture it
								}
								else{
									GoToPos(blob, secondarytarget.getPosition());
								}
							}
							else
							{
								blob.set_u16("secondarytarget", 0); // capture complete
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

			if (getGameTime() > blob.get_u8("myKey")/4 && blob.getTickSinceCreated() > 70 + blob.get_u8("myKey")/2) // wait a little bit before aiming on match start
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
				blob.setAimPos(Vec2f_lerp(blob.getAimPos(), Vec2f(mousexvar, mouseyvar), 0.03));
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
				if (XORRandom(70) == 0 || (blob.get_u16("secondarytarget") != 0 && XORRandom(20) == 0))
				{
					blob.set_u8("moveover", 0); //end
				}

				blob.setKeyPressed(key_left, false);
				blob.setKeyPressed(key_right, false);

				if (blob.get_u8("moveover") == 1) // 1 == right
				{
					//if (emotes) set_emote(blob, Emotes::right, 10);
					blob.setKeyPressed(key_right, true);
				}
				else // 0 == left
				{		
					//if (emotes) set_emote(blob, Emotes::left, 10);
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
		}

		// unpredictable movement
		if (getGameTime() % blob.get_u8("myKey") == 0 && XORRandom(2) == 0 && target !is null)
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
			if (XORRandom(60) == 0)
			{
				blob.set_u8("moveover", 0); //end
			}

			blob.setKeyPressed(key_left, false);
			blob.setKeyPressed(key_right, false);

			if (blob.get_u8("moveover") == 1) // 1 == right
			{
				//if (emotes) set_emote(blob, Emotes::right, 10);
				blob.setKeyPressed(key_right, true);
			}
			else // 0 == left
			{		
				//if (emotes) set_emote(blob, Emotes::left, 10);
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

		// decide to do something
		if (blob.get_u16("secondarytarget") == 0) // we dont have a secondary target
		{
			// decide to capture a repairstation
			if (getGameTime() % 50 + blob.get_u8("mykey") == 0 && XORRandom(4) == 0) // every once in a while
			{
				CBlob@[] stations;
				getBlobsByName("repairstation", @stations);
				SortBlobsByDistance(blob, @stations);

				if (stations.length > 0) // if there are any neutral ones
				{
					if ((blob.get_Vec2f("generalfriendlocation") - stations[0].getPosition()).getLength() < 500) // is a friendly station
					{
						if ((blob.get_Vec2f("generalenemylocation") - stations[0].getPosition()).getLength() > 400 || XORRandom(50) == 0) // if threat is relatively low
						{
							blob.set_u16("secondarytarget", stations[0].getNetworkID());
						}
					}
				}
			}

			// decide to capture a point
			if (getGameTime() % 100 + blob.get_u8("mykey") == 0 && XORRandom(4) == 0) // every once in a while
			{
				CBlob@[] points;
				getBlobsByName("pointflag", @points);
				SortBlobsByDistance(blob, points);

				if (points.length > 0) // if there are flags on this map
				{
					if ((blob.get_Vec2f("generalenemylocation") - points[0].getPosition()).getLength() > 600 || XORRandom(50) == 0) // if threat is relatively low
					{
						//wip
						blob.set_u16("secondarytarget", points[0].getNetworkID());
					}
				}
			}

			// decide to sit in a vehicle
			if (getGameTime() > 60*30 || (isClient() && isServer())) // vehicles are now available
			{
				if (blob.get_u8("myKey") % 4 != 0) // only some bots are destined to use vehicles
				{				
					CBlob@[] vehicles;
					getBlobsByTag("vehicle", @vehicles);

					if (vehicles.length > 0) // if there are vehicles
					{
						if ((getGameTime() + blob.getNetworkID()) % 30 == 0) // every once in a while
						{
							// choose a random vehicle to get into
							CBlob@ vehicle = vehicles[XORRandom(vehicles.length)];
							if (vehicle !is null)
							{
								// is it on our team?
								if (vehicle.getTeamNum() == blob.getTeamNum())
								{
									// is it nearby me?
									if ((vehicle.getPosition() - blob.getPosition()).getLength() < 850.0f)
									{
										if (!vehicle.hasTag("turret") && !vehicle.hasTag("gun") && !vehicle.hasTag("aerial") // isnt a turret or machine gun or plane
										&& vehicle.hasTag("importantarmory") && vehicle.getName() != "armory") // dont drive this for now
										{
											if (XORRandom(3) == 0) // lets drive a vehicle
											{
												// let's check if the driver seat is occupied
												CAttachment@ ats = vehicle.getAttachments();
												if (ats !is null)
												{
													AttachmentPoint@ point = ats.getAttachmentPointByName("DRIVER");
													if (point !is null && vehicle !is null)
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
											else { // lets get in an needed gunner seat
												// is the driver seat is occupied?
												CAttachment@ ats = vehicle.getAttachments();
												if (ats !is null)
												{
													AttachmentPoint@ point = ats.getAttachmentPointByName("DRIVER");
													if (point !is null && vehicle !is null && vehicle.getAttachments() !is null)
													{
														CBlob@ occupied = point.getOccupied();
														if (occupied !is null)
														{
															// drivers seat is occupied
															// check if this vehicle has a gunner seat

															int typeofemptyseat = 0;

															AttachmentPoint@ gunnerseat = vehicle.getAttachments().getAttachmentPointByName("GUNNER");
															if (gunnerseat !is null)
															{
																if (gunnerseat.getOccupied() is null) { typeofemptyseat = 1; }
															}
															else // either we have no gunner seat, or we have a turret, or an mg
															{
																// check for turret
																AttachmentPoint@ turret = vehicle.getAttachments().getAttachmentPointByName("TURRET");
																if (turret !is null)
																{
																	CBlob@ turretblob = turret.getOccupied();
																	if (turretblob !is null && turretblob.getAttachments() !is null)
																	{
																		AttachmentPoint@ turretgunnerseat = turretblob.getAttachments().getAttachmentPointByName("GUNNER");
																		if (turretgunnerseat !is null)
																		{
																			if (turretgunnerseat.getOccupied() is null) { typeofemptyseat = 2; }
																		}
																	}
																}
																else
																{
																	AttachmentPoint@ mg = vehicle.getAttachments().getAttachmentPointByName("BOW");
																	if (mg !is null)
																	{
																		CBlob@ mgblob = mg.getOccupied();
																		if (mgblob !is null && mgblob.getAttachments() !is null)
																		{
																			// check if mg has a gunner
																			AttachmentPoint@ mgseat = mgblob.getAttachments().getAttachmentPointByName("GUNNER");
																			if (mgseat !is null)
																			{
																				if (mgseat.getOccupied() is null) { typeofemptyseat = 1; }
																			}
																		}
																	}
																}
															}

															if (vehicle.getNetworkID() != 0)
															{
																blob.set_u16("secondarytarget", vehicle.getNetworkID());
																blob.set_string("behavior", typeofemptyseat == 1 ? "gun_mg" : "gun_turret");
																// time to get into this gun
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
			}
		}
	}
	
	JumpOverObstacles(blob);

	FloatInWater(blob);

	AvoidTheVoid(blob);

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

void UpdateBlob(CBlob@ blob, CBlob@ target, u8 strategy, CBlob@ check)
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
	else if (strategy == Strategy::seekcover)
	{
		if (blob.get_Vec2f("generalfriendlocation") != Vec2f_zero)
		{
			SeekCover(blob, blob.get_Vec2f("generalfriendlocation"));
		}
		else{
			DefaultRetreatBlob(blob, target);
		}
	}
	else if (strategy == Strategy::seekheal)
	{
		if (check !is null && (targetPos - myPos).getLength() > 32.0f)
		{
			GoToImportant(blob, @check, @target);
		}
		else
		{
			strategy = Strategy::idle;
		}
	}
	else if (strategy == Strategy::attacking)
	{
		DefaultChaseBlob(blob, target);
		AttackBlob(blob, target);
	}
}