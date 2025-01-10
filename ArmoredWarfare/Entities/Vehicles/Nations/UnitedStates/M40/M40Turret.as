void onInit(CBlob@ this)
{
	this.Tag("vehicle");
	this.Tag("turret");
	this.Tag("tank");
	this.Tag("blocks bullet");
	this.Tag("fireshe");
	this.Tag("pass_60sec");
	this.Tag("artillery");
	this.set_u16("gui_mat_icon", 50);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player"))
	{
		attached.Tag("covered");
		attached.Tag("artillery");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("player"))
	{
		detached.Untag("covered");
		detached.Untag("artillery");
		detached.Untag("increase_max_zoom");
	}
}