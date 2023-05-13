
//  BulletClass.as - Vamist


#include "BulletCase.as";
#include "BulletParticle.as";
#include "Hitters.as";
#include "CustomBlocks.as";

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

	Vec2f GetIntersectionPoint(Vec2f start1, Vec2f end1, Vec2f start2, Vec2f end2)
	{
	    f32 x1 = start1.x;
	    f32 y1 = start1.y;
	    f32 x2 = end1.x;
	    f32 y2 = end1.y;
	    f32 x3 = start2.x;
	    f32 y3 = start2.y;
	    f32 x4 = end2.x;
	    f32 y4 = end2.y;

	    f32 det = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

	    if (det == 0)
	    {
	        // Отрезки параллельны или совпадают, вернуть точку по умолчанию
	        return Vec2f(0, 0);
	    }
	    else
	    {
	        Vec2f intersectionPoint;
	        intersectionPoint.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / det;
	        intersectionPoint.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / det;

	        return intersectionPoint;
	    }
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
		f32 angle = FacingLeft ? StartingAimPos+180 : StartingAimPos;
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
				TileType tile = map.getTile(hitpos).type;

				if (blob !is null) // blob
				{   
					//int hash = blob.getName().getHash();
					//switch (hash)
					//{
					//	
					//}

					if (breakLoop)//So we can break while inside the switch
					{
						endBullet = true;
						break;
					}
				}
				else
				{
					bool stop = true;

					if (map.isTileWood(tile) && XORRandom(3)==0)
					{ // hit wood
						map.server_DestroyTile(hitpos, 0.1f);
					}
					else if (!isTileCompactedDirt(tile) && (((tile == CMap::tile_ground || isTileScrap(tile)) 
					&& XORRandom(100) <= 1) || (tile != CMap::tile_ground && tile <= 255 && XORRandom(100) < 3)))
					{ // hit resistant tile
						if (map.getSectorAtPosition(hitpos, "no build") is null)
						{
							map.server_DestroyTile(hitpos, CurrentType == 1 ? 1.5f : 0.65f);
						}
					}

					// ricochet, not done yet
					
					bool has_rico = false;
					// change the direction, if the angle is small
					bool doContinue = false;
					u16 raw_angle = 0;
					for (u8 i = 0; i < 4; i++)
					{ // check collision tile clock-wise, starting from top
						if (doContinue) continue;

						f32 x = hitpos.x%8.0f; // check if the hitpos is left\right\down\top from 0.0 to 8.0
						f32 y = hitpos.y%8.0f;
						Vec2f side = Vec2f(x, y);

						has_rico = false;
						doContinue = true;
					}

					f32 angle_diff = 0;
					f32 current_angle = angle+270;

					// the angle is a bit weird if !faceleft, so we have to evaluate sides
					if (current_angle >= -180.0f && current_angle < -270.0f)
						current_angle += 270;
					if (!FacingLeft)
						current_angle = -current_angle;
					
					//printf("raw "+raw_angle+" | angle "+current_angle);

					if (has_rico || XORRandom(100) > 100-angle_diff)
					{
						if (!v_fastrender)
						{
							for (uint i = 0; i < 3+XORRandom(6); i++) {
								Vec2f velr = TrueVelocity/(XORRandom(5)+3.0f);
								velr += Vec2f(0.0f, -6.5f);
								velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

								ParticlePixel(hitpos, velr, SColor(255, 255, 255, 0), true);
							}
						}
						Sound::Play("/BulletMetal" + XORRandom(4), CurrentPos, 1.2f, 0.8f + XORRandom(40) * 0.01f);

						stop = false;
					}
					else // hit map
					{
						ParticleAnimated("Smoke", hitpos, Vec2f(0.0f, -0.1f), 0.0f, 1.0f, 5, XORRandom(70) * -0.00005f, true);

						Sound::Play("/BulletDirt" + XORRandom(3), CurrentPos, 1.7f, 0.85f + XORRandom(25) * 0.01f);

						if (!v_fastrender)
						{
							CParticle@ p = ParticleAnimated("SparkParticle.png", CurrentPos, Vec2f(0,0), XORRandom(360), 1.0f, 1+XORRandom(2), 0.0f, false);
							if (p !is null) { p.diesoncollide = true; p.fastcollision = true; p.lighting = false; }

							{ CParticle@ p = ParticleAnimated("BulletChunkParticle.png", hitpos, Vec2f(0.5f - XORRandom(100)*0.01f,-0.5), XORRandom(360), 0.55f + XORRandom(50)*0.01f, 22+XORRandom(3), 0.2f, true);
							if (p !is null) { p.lighting = true; }}
						}

						u16 impact_angle = 0;

						// ??? this is probably not working and heavy, remove\rewrite later
						{ TileType tile = map.getTile(hitpos + Vec2f(0, -1)).type;
						if (map.isTileSolid(tile)) impact_angle = 180;}

						{ TileType tile = map.getTile(hitpos + Vec2f(0, 1)).type;
						if (map.isTileSolid(tile)) impact_angle = 0;}

						{ TileType tile = map.getTile(hitpos + Vec2f(-1, 0)).type;
						if (map.isTileSolid(tile)) impact_angle = 90;}

						{ TileType tile = map.getTile(hitpos + Vec2f(1, 0)).type;
						if (map.isTileSolid(tile)) impact_angle = 270;}

						if (XORRandom(2) == 0 && !v_fastrender)
						{
							CParticle@ p = ParticleAnimated("BulletHitParticle1.png", hitpos + Vec2f(0.0f, 1.0f), Vec2f(0,0), impact_angle, 0.55f + XORRandom(50)*0.01f, 2+XORRandom(2), 0.0f, true);
							if (p !is null) { p.diesoncollide = false; p.fastcollision = false; p.lighting = false; }
						}
					}

					if (stop)
					{
						CurrentPos = hitpos;
						endBullet = true;
						ParticleBullet(CurrentPos, TrueVelocity);
					}
				}
			}
		}

		if (endBullet == true)
		{
			TimeLeft = 0;
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

