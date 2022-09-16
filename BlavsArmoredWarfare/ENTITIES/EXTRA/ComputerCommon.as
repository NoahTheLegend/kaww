const string curTargetNetIDString = "target_NetID";
const string navigationPhaseString = "nav_phase";
const string lastAbsoluteVelString = "last_absoulte_vel";

const SColor greenConsoleColor = SColor(200, 0, 255, 0);
const SColor redConsoleColor = SColor(200, 255, 20, 20);
const SColor yellowConsoleColor = SColor(200, 255, 255, 0);

void makeTargetSquare( Vec2f centerPos = Vec2f_zero, f32 drawAngle = 0.0f, Vec2f scale = Vec2f(1.0f, 1.0f), f32 cornerSeparation = 1.0f, f32 particleStepDistance = 2.0f, SColor color = greenConsoleColor)
{
	if (centerPos == Vec2f_zero)
	{ return; }

	Vec2f[] vertexPos =
	{
		Vec2f(1.0f, 0.0), 		//			O
		Vec2f(1.0f, 1.0), 		//			|
		Vec2f(0.0f, 1.0) 		//		O---O
	};

	for(int i = 0; i < vertexPos.length(); i++)
	{
		vertexPos[i].x *= scale.x;
		vertexPos[i].y *= scale.y;
		//vertexPos[i] += centerPos;
	}

	Vec2f separationVec = Vec2f(cornerSeparation, cornerSeparation);
	for(u8 corner = 0; corner < 4; corner++) //4 corners
	{
		for(uint vertex = 0; vertex < (vertexPos.length() - 1); vertex++) 
		{
			Vec2f pos1 = vertexPos[vertex];
			Vec2f pos2 = vertexPos[vertex+1];

			pos1 += separationVec;
			pos2 += separationVec;

			switch(corner+1)
			{
				case 2:
				pos1.x *= -1.0f;
				pos2.x *= -1.0f;
				break;

				case 3:
				pos1.y *= -1.0f;
				pos2.y *= -1.0f;
				break;

				case 4:
				pos1 *= -1.0f;
				pos2 *= -1.0f;
				break;
			}

			pos1.RotateByDegrees(drawAngle);
			pos2.RotateByDegrees(drawAngle);

			//pos1.RotateByDegrees((90*corner) + drawAngle);
			//pos2.RotateByDegrees((90*corner) + drawAngle);

			drawParticleLine( pos1 + centerPos, pos2 + centerPos, Vec2f_zero, color, 0, particleStepDistance);
		}
	}
}

void drawParticleLine( Vec2f pos1 = Vec2f_zero, Vec2f pos2 = Vec2f_zero, Vec2f pVel = Vec2f_zero, SColor color = SColor(255, 255, 255, 255), u8 timeout = 0, f32 pixelStagger = 1.0f)
{
	Vec2f lineVec = pos2 - pos1;
	Vec2f lineNorm = lineVec;
	lineNorm.Normalize();

	f32 lineLength = lineVec.getLength();

	for(f32 i = 0; i < lineLength; i += pixelStagger) 
	{
		Vec2f pPos = (lineNorm * i) + pos1;

		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 1000;
			p.timeout = timeout;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}