void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("apc");
	this.Tag("blocks bullet");

	if (!isClient()) return;
	u8 tn = this.getTeamNum();
	if (tn != 1 && tn)

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("VEHICLE");
	if (ap is null) return;

	CBlob@ vehicle = ap.get
}