void onInit(CSprite@ this){
	Animation@ animation = this.getAnimation("default");
	if (animation is null) return;
	Vec2f pos =	this.getBlob().getPosition();
	this.animation.frame = XORRandom(animation.getFramesCount());
	this.SetFacingLeft(XORRandom(2) == 0);
	this.SetZ(-20);
	CBlob@ blob = this.getBlob();
	if (blob !is null) {
		// emergency supplies
		if (getNet().isServer())
		{
			CBlob@ ammo = server_CreateBlob("ammo");
			if (ammo !is null)
			{
				ammo.server_SetQuantity(30);
				if (!blob.server_PutInInventory(ammo)) ammo.server_Die();
			}
		}
	}
	blob.server_SetHealth(0.01f);
	//blob.Tag("vehicle");
	blob.server_setTeamNum(0);
}

void onTick(CBlob@ this) {
	if (getGameTime() % 30 == 0) {
		ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(8) - 4, XORRandom(8) - 4), getRandomVelocity(0.0f, XORRandom(35) * 0.005f, 360) + Vec2f(0.2,0), float(XORRandom(360)), 1.0f + XORRandom(20) * 0.01f, 15 + XORRandom(6), -0.01 + XORRandom(10) * -0.0001f, true);
	}
}