
//  BulletClass.as - Vamist


#include "BulletCase.as";
#include "BulletParticle.as";
#include "Hitters.as";

const SColor trueWhite = SColor(255,255,255,255);
Driver@ PDriver = getDriver();
const int ScreenX = getDriver().getScreenWidth();
const int ScreenY = getDriver().getScreenWidth();

class BulletObj
{
	CBlob@ hoomanShooter;

	BulletFade@ Fade;

	s8 CurrentType;

	Vec2f TrueVelocity;
	Vec2f CurrentPos;
	Vec2f BulletGrav;
	Vec2f RenderPos;
	Vec2f OldPos;
	Vec2f LastPos;
	Vec2f Gravity;
	Vec2f KB;
	f32 StartingAimPos;
	f32 lastDelta;
	f32 DamageBody;
	f32 DamageHead;
	s8 CurrentPen;

	u8 TeamNum;
	u8 Speed;

	s8 TimeLeft;

	bool FacingLeft;

	
	BulletObj(CBlob@ humanBlob, f32 angle, Vec2f pos, s8 type, f32 damage_body, f32 damage_head, s8 penetration)
	{
		CurrentType = type;
		CurrentPos = pos;
		FacingLeft = humanBlob.isFacingLeft();
		BulletGrav = humanBlob.get_Vec2f("grav");
		DamageBody = damage_body;
		DamageHead = damage_head;
		CurrentPen = penetration;
		TeamNum  = humanBlob.getTeamNum();
		TimeLeft = humanBlob.get_u8("TTL");
		KB       = humanBlob.get_Vec2f("KB");
		Speed    = humanBlob.get_u8("speed");
		@hoomanShooter = humanBlob;
		StartingAimPos = angle;
		OldPos     = CurrentPos;
		LastPos    = CurrentPos;
		RenderPos  = CurrentPos;

		lastDelta = 0;
		//@Fade = BulletGrouped.addFade(CurrentPos);
	}

	void SetStartAimPos(Vec2f aimPos, bool isFacingLeft)
	{
		Vec2f aimvector = aimPos - CurrentPos;
		StartingAimPos = isFacingLeft ? -aimvector.Angle()+180.0f : -aimvector.Angle();
	}

	bool onFakeTick(CMap@ map)
	{
		//Time to live check
		TimeLeft--;

		if (TimeLeft <= 0)
		{
			return true;
		}

		// Angle update
		OldPos = CurrentPos;
		Gravity -= BulletGrav;
		const f32 angle = FacingLeft ? StartingAimPos+180 : StartingAimPos;
		Vec2f dir = Vec2f((FacingLeft ? -1 : 1), 0.0f).RotateBy(angle);
		CurrentPos = ((dir * Speed) - (Gravity * Speed)) + CurrentPos;
		TrueVelocity = CurrentPos - OldPos;


		bool endBullet = false;
		bool breakLoop = false;
		HitInfo@[] list;
		if (map.getHitInfosFromRay(OldPos, -(CurrentPos - OldPos).Angle(), (OldPos - CurrentPos).Length(), hoomanShooter, @list))
		{
			for (int a = 0; a < list.length(); a++)
			{
				breakLoop = false;
				HitInfo@ hit = list[a];
				Vec2f hitpos = hit.hitpos;
				CBlob@ blob = @hit.blob;
				if (blob !is null) // blob
				{   
					int hash = blob.getName().getHash();
					switch (hash)
					{
						case 1296319959: // Stone_door
						case 213968596:  // Wooden_door
						case 916369496:  // Trapdoor
						{
							if (blob.isCollidable())
							{
								CurrentPos = hitpos;
								breakLoop = true;
								//Sound::Play(ObjectHitSound, hitpos, 1.5f);
								
								if (isServer())
								{
									if (hash == 213968596)
									{
										if (XORRandom((10 / DamageBody) + 2) == 0)
										{
											map.server_DestroyTile(hitpos, DamageBody);     
										}
									}
								}
							}
						}
						break;

						case 804095823: // platform
						{
							if (CollidesWithPlatform(blob,TrueVelocity))
							{
								CurrentPos = hitpos;
								breakLoop = true;
								//Sound::Play(ObjectHitSound, hitpos, 1.5f);

								if (isServer())
								{
									if (XORRandom((10 / DamageBody) + 1) == 0)
									{
									   map.server_DestroyTile(hitpos, DamageBody);     
									}
								}
							}
						}
						break;

						default:
						{
							//print(blob.getName() + '\n'+blob.getName().getHash()); useful for debugging new tiles to hit

							if (blob.hasTag("flesh") && blob.isCollidable() || blob.hasTag("vehicle"))
							{
								if (blob.getTeamNum() == TeamNum) { continue; }
								CurrentPos = hitpos;
								if (!blob.hasTag("invincible") && !blob.hasTag("seated")) 
								{
									if (isServer())
									{
										CPlayer@ p = hoomanShooter.getPlayer();
										int coins = 0;
										hoomanShooter.server_Hit(blob, CurrentPos, Vec2f(0, 0), DamageBody, Hitters::arrow); 
									}
									if (isClient())
									{
										//Sound::Play(FleshHitSound,  CurrentPos, 1.5f); 
									}

								}
								breakLoop = true;
							}
						}
					}

					if (breakLoop)//So we can break while inside the switch
					{
						endBullet = true;
						break;
					}
				}
				else
				{ 
					if (isServer())
					{
						Tile tile = map.getTile(hitpos);
						switch (tile.type)
						{
							case 196: // wood states
							case 200:
							case 201:
							case 202:
							case 203:
							{
								if (XORRandom((10 / DamageBody) + 1) == 0)
								{
									map.server_DestroyTile(hitpos, DamageBody);     
								}
							}
							break;
							
						}
					}
					else
					{
						//Sound::Play(ObjectHitSound, hitpos, 1.5f);
					}

					CurrentPos = hitpos;
					endBullet = true;
					//ParticleFromBullet("Bullet.png",CurrentPos,-TrueVelocity.Angle());
					ParticleBullet(CurrentPos, TrueVelocity);
				}
			}
		}

		if (endBullet == true)
		{
			TimeLeft = 1;
		}
		return false;
	}

	void JoinQueue() // Every bullet gets forced to join the queue in onRenders, so we use this to calc to position
	{   
		// Are we on the screen?
		const Vec2f xLast = PDriver.getScreenPosFromWorldPos(LastPos);
		const Vec2f xNew  = PDriver.getScreenPosFromWorldPos(CurrentPos);
		if(!(xNew.x > 0 && xNew.x < ScreenX)) // Is our main position still on screen?
		{
			if(!(xLast.x > 0 && xLast.x < ScreenX)) // Was our last position on screen?
			{
				return; // No, lets not stay here then
			}
		}

		// Lerp
		Vec2f newPos = Vec2f_lerp(LastPos, CurrentPos, FRAME_TIME);
		LastPos = newPos;

		f32 angle = Vec2f(CurrentPos.x-newPos.x, CurrentPos.y-newPos.y).getAngleDegrees();//Sets the angle

		// y increases length, x increases width
		Vec2f scale = Vec2f(2.0f, 2.0f);
		if (CurrentType == -1)
			scale = Vec2f(1.75f, 1.25f);
		else if (CurrentType == 1)
			scale = Vec2f(2.0f, 5.0f+XORRandom(11)*0.1f);

		Vec2f TopLeft  = Vec2f(newPos.x -0.7*scale.x, newPos.y-3*scale.y);
		Vec2f TopRight = Vec2f(newPos.x -0.7*scale.x, newPos.y+3*scale.y);
		Vec2f BotLeft  = Vec2f(newPos.x +0.7*scale.x, newPos.y-3*scale.y);
		Vec2f BotRight = Vec2f(newPos.x +0.7*scale.x, newPos.y+3*scale.y);

		angle = -((angle % 360) + 90);

		BotLeft.RotateBy( angle,newPos);
		BotRight.RotateBy(angle,newPos);
		TopLeft.RotateBy( angle,newPos);
		TopRight.RotateBy(angle,newPos);   

		/*if(FacingLeft)
		{
			Fade.JoinQueue(TopLeft,TopRight);
		}
		else
		{
			//Fade.JoinQueue(newPos,BotRight);
		}*/


		v_r_bullet.push_back(Vertex(TopLeft.x,  TopLeft.y,      0, 0, 0,   trueWhite)); // top left
		v_r_bullet.push_back(Vertex(TopRight.x, TopRight.y,     0, 1, 0,   trueWhite)); // top right
		v_r_bullet.push_back(Vertex(BotRight.x, BotRight.y,     0, 1, 1, trueWhite));   // bot right
		v_r_bullet.push_back(Vertex(BotLeft.x,  BotLeft.y,      0, 0, 1, trueWhite));   // bot left
	}

}

class BulletHolder
{
	BulletObj[] bullets;
	BulletFade[] fade;
	PrettyParticle@[] PParticles;
	BulletHolder(){}

	void FakeOnTick(CRules@ this)
	{
		CMap@ map = getMap();
		for (int a = 0; a < bullets.length(); a++)
		{
			BulletObj@ bullet = bullets[a];
			if (bullet.onFakeTick(map))
			{
				bullets.erase(a);
				a--;
			}
		}
		//print(bullets.length() + '');
		 
		for (int a = 0; a < PParticles.length(); a++)
		{
			if (PParticles[a].ttl == 0)
			{
				PParticles.erase(a);
				a--;
				continue;
			}
			PParticles[a].FakeTick();
		}
	}

	BulletFade addFade(Vec2f spawnPos)
	{   
		BulletFade@ fadeToAdd = BulletFade(spawnPos);
		fade.push_back(fadeToAdd);
		return fadeToAdd; 
	}

	void addNewParticle(CParticle@ p,const u8 type)
	{
		PParticles.push_back(PrettyParticle(p,type));
	}
	
	void FillArray()
	{
		for (int a = 0; a < bullets.length(); a++)
		{
			bullets[a].JoinQueue();
		}
	}

	void AddNewObj(BulletObj@ this)
	{
		CMap@ map = getMap();
		this.onFakeTick(map);
		bullets.push_back(this);
	}
	
	void Clean()
	{
		bullets.clear();
	}

	int ArrayCount()
	{
		return bullets.length();
	}
}

const bool CollidesWithPlatform(CBlob@ blob, const Vec2f velocity) // Stolen from rock.as
{
	const f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	const float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}

