void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(84.0f);
	this.SetLightColor(SColor(255, 255, 200, 150));

	this.set_TileType("background tile", CMap::tile_wood_back);

	this.SetFacingLeft(XORRandom(100) < 50 ? true : false);

	this.set_bool("light", true);

	this.Tag("destructable_nosoak");

	this.getSprite().SetZ(-5);

	if (this !is null) this.Sync("light", true);
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if (this.get_bool("light"))
	{
		for (uint i = 0; i < 9 + XORRandom(8); i++)
		{
			Vec2f velr = Vec2f((XORRandom(19) - 9.0f)/3, (XORRandom(10) - 9.0f)/5);
			velr.y = -Maths::Abs(velr.y) + Maths::Abs(velr.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

			ParticlePixel(this.getPosition(), velr, SColor(255, 255, 255, 0), true);
		}

		this.getSprite().PlaySound("GlassBreak", 2.0f, 0.7f + XORRandom(40) * 0.01f);

		this.set_bool("light", false);

		this.getSprite().SetAnimation("broken");
		this.SetLight(false);
	}
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.getShape().isStatic();
}