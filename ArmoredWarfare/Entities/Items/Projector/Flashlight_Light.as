
const f32 max_light_radius = 48.0f;
const f32 distance_factor = 6.0f;
const f32 min_light_radius = 16.0f;

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(max_light_radius);
	this.SetLightColor(SColor(255, 225, 200, 150));
	
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;

	this.addCommandID("sync");

	if (isClient())
	{
		CBitStream params;
		params.write_bool(true);
		params.write_u16(0);
		params.write_u16(getLocalPlayer().getNetworkID());
		this.SendCommand(this.getCommandID("sync"), params);
	}
}

void onTick(CBlob@ this)
{
	if (this.get_u16("remote_id_flashlight") == 0) return;
	CBlob@ follow = getBlobByNetworkID(this.get_u16("remote_id_flashlight"));
	this.SetLight(follow !is null);
	if (follow is null) return;

	f32 rad = Maths::Max(min_light_radius, max_light_radius - Maths::Abs(follow.getDistanceTo(this) / distance_factor));
	this.SetLightRadius(Maths::Min(max_light_radius, rad));

	if (!isClient()) return;
	if (!this.isOnScreen()) return;
	if (getMap() is null) return;
	#ifndef STAGING
	getMap().UpdateLightingAtPosition(this.getOldPosition(), rad+16.0f);
	#endif
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync"))
	{
		bool init;
		if (!params.saferead_bool(init)) return;
		
		if (init && isServer())
		{
			u16 id = params.read_u16();
			u16 ply_id = params.read_u16();

			CPlayer@ ply = getPlayerByNetworkId(ply_id);
			if (ply is null) return;

			CBitStream nextparams;
			nextparams.write_bool(false);
			nextparams.write_u16(this.get_u16("remote_id_flashlight"));
			this.server_SendCommandToPlayer(this.getCommandID("sync"), nextparams, ply);
		}
		if (!init && isClient())
		{
			u16 id = params.read_u16();
			this.set_u16("remote_id_flashlight", id);
		}
	}
}