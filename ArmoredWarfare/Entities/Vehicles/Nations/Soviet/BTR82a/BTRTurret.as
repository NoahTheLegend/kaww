void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("apc");
	this.Tag("blocks bullet");

	this.getSprite().SetOffset(Vec2f(8,0));
}

void onAttach(CBlob@ this, CBlob@ blob, AttachmentPoint@ point)
{
	if (!isClient()) return;
	u8 tn = this.getTeamNum();
	if (tn == 0 || tn > 4) return;

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("VEHICLE");
	if (ap is null) return;

	CBlob@ vehicle = point.getOccupied();
	if (blob !is vehicle) return;
	Animation@ def_tur = this.getSprite().addAnimation("destruction", 0, false);
	Animation@ def_veh = vehicle.getSprite().addAnimation("destruction", 0, false);

	if (def_tur is null || def_veh is null) return;
	int[] frames = {3,4,5};
	
	def_tur.AddFrames(frames);
	this.getSprite().SetAnimation(def_tur);
	this.getSprite().animation.frame = 0;

	def_veh.AddFrames(frames);
	vehicle.getSprite().SetAnimation(def_veh);
	vehicle.getSprite().animation.frame = 0;

	CSpriteLayer@ arm = this.getSprite().getSpriteLayer("arm");
	if (arm is null) return;

	Animation@ def_arm = arm.getAnimation("default");
	if (def_arm is null) return;

	def_arm.RemoveFrame(0);
	def_arm.AddFrame(30);
	arm.SetAnimation(def_arm);
}