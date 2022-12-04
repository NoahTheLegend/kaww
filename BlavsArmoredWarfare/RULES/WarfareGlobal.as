
// s8 armorRating : use negative numbers for weakness. Set in stone on f32 onHit() hooks.
const string armorRatingString = "armor_level";

// s8 penRating : opposite of armor rating. Use negative for extreme cases. Usually, armor will be reduced by this value.
const string penRatingString = "pen_level";

// bool hardShelled : if true, penRating above 0 will be reduced by 1. Negative penRating is unaffected.
const string hardShelledString = "hard_shelled";

// s8 weaponRating : Essentially the same as penRating, but as a reference for firing projectiles
const string weaponRatingString = "weapon_level";

// float backsideOffset : for hitting weakspots
const string backsideOffsetString = "backside_offset";

const s8 minArmor = -2;
const s8 maxArmor = 5;

const string projDamageString = "proj_damage";

const string projExplosionRadiusString = "proj_ex_radius";
const string projExplosionDamageString = "proj_ex_damage";

s8 getFinalRating(CBlob@ this, s8 armorRating, s8 penRating, bool hardShelled, CBlob@ blob = null, Vec2f hitPos = Vec2f_zero, bool &out isHitUnderside = false, bool &out isHitBackside = false )
{
	s8 finalRating = armorRating;

	if (blob != null)
	{
		Vec2f blobPos = blob.getPosition();
		f32 bd = blob.getAngleDegrees();
		float backsideOffset = blob.get_f32(backsideOffsetString);
		if (backsideOffset > 0)
		{
			blobPos = blobPos.RotateBy(bd);
			hitPos = hitPos.RotateBy(bd);
			isHitUnderside = hitPos.y > (blobPos + Vec2f(0, 4.0f).RotateBy(bd)).y;
			isHitBackside = blob.isFacingLeft() ? hitPos.x > (blobPos.x + backsideOffset) : hitPos.x < (blobPos.x - backsideOffset);
		}
		
		if (isHitUnderside && isHitBackside) finalRating -= 1;
	}

	if (hardShelled && penRating > 0)
	{
		penRating--;
	}
	
	finalRating = Maths::Clamp(finalRating-penRating, minArmor, maxArmor);

	return finalRating;
}