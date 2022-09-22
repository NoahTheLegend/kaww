
// s8 armorRating : use negative numbers for weakness. Set in stone on f32 onHit() hooks.
const string armorRatingString = "armor_level";

// s8 penRating : opposite of armor rating. Use negative for extreme cases. Usually, armor will be reduced by this value.
const string penRatingString = "pen_level";

// bool hardShelled : if true, penRating above 0 will be reduced by 1. Negative penRating is unaffected.
const string hardShelledString = "hard_shelled";

const s8 minArmor = -2;
const s8 maxArmor = 5;

s8 getFinalRating( s8 armorRating, s8 penRating, bool hardShelled = false)
{
	s8 finalRating = armorRating;

	if (hardShelled && penRating > 0)
	{
		penRating--;
	}
	
	finalRating = Maths::Clamp(finalRating-penRating, minArmor, maxArmor);

	return finalRating;
}