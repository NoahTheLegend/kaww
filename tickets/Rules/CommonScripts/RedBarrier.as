////  VARS  ////

#include "GamemodeCheck.as";

// Server owners should edit the value inside RedBarrierVars.cfg
f32 barrier_width_left = 0.0f;
f32 barrier_width_right = 0.0f;
f32 VEL_PUSHBACK = 1.0;

f32 damage_tickrate = 30;
f32 damage_players_min = 0.5f;
f32 damage_players_steps = 10;
f32 damage_players_max = 1.5f;
f32 damage_vehicles = 3.0f;

f32 base_barrier_speed = 0.5f;
int keep_middle_tiles = 50;

// Var to know if the barrier is currently up 
// (used for clearing the barrier once when its game time)
// 
// Defaults to true because we want clients to remove the barrier
// if they join and its no longer warm up (fixes some rare bug)
bool IS_barrier_left_SET = true; 

// Gets toggled to true when we know the 
// config has different values
bool SYNC_CUSTOM_VARS = false;

////  HOOKS  ////

void onInit(CRules@ this)
{
	this.addCommandID("set_barrier_pos");
	this.addCommandID("set_barrier_vars");

	this.addCommandID("sync_ptb");
	this.addCommandID("request_sync_ptb");

	onRestart(this);
}

void onRestart(CRules@ this)
{
	barrier_width_left = 0.0f;
	barrier_width_right	= 0.0f;

	ResetOldValues();
	loadBarrier(this);

	this.Untag("respawns_set");
}

void ResetRespawns(CRules@ this)
{
	bool defenders_on_left = defendersOnLeft();

	CBlob@[] tents;
	getBlobsByName("tent", @tents);
	getBlobsByName("outpost", @tents);

	for (uint i = 0; i < tents.length; i++)
	{
		CBlob@ tent = tents[i];
		Vec2f pos = tent.getPosition();

		if (defenders_on_left)
		{
			//printf(""+pos.x+" "+this.get_u16("barrier_left_x2")+" "+tent.getNetworkID());
			if (pos.x < this.get_u16("barrier_left_x2"))
			{
				tent.Untag("respawn");
			}
			else
			{
				tent.Tag("respawn");
				this.Tag("respawns_set");
			}
		}
		else
		{
			if (pos.x > this.get_u16("barrier_right_x1"))
			{
				tent.Untag("respawn");
			}
			else
			{
				tent.Tag("respawn");
				this.Tag("respawns_set");
			}
		}
	}
}

void ResetOldValues()
{
	CMap@ map = getMap();
	
	old_left = Vec2f_zero;
	old_right = Vec2f_zero;
	old_left2 = Vec2f(map.tilemapwidth * map.tilesize, 0);
	old_right2 = Vec2f(map.tilemapwidth * map.tilesize, 0);
}

void loadBarrier(CRules@ this)
{
	if (!isServer())
	{
		IS_barrier_left_SET = true;
		return;
	}

	LoadConfigVars();
	SetBarrierPosition(this);

	const int playerCount = getPlayerCount();
	for (int a = 0; a < playerCount; a++)
	{
		CPlayer@ player = getPlayer(a);

		if (player is null)
			continue;

		SyncToPlayer(this, player);

		if (SYNC_CUSTOM_VARS)
			SyncVarsToPlayer(this, player);
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if (!isServer() && !shouldBarrier(this))
		return;

	SyncToPlayer(this, player);

	if (SYNC_CUSTOM_VARS)
		SyncVarsToPlayer(this, player);
}

bool reachedMid(CRules@ this)
{
	CMap@ map = getMap();
	const f32 mw = map.tilemapwidth * map.tilesize;

	return this.get_u16("barrier_left_x2") >= mw * 0.5f - keep_middle_tiles * map.tilesize && this.get_u16("barrier_right_x1") <= mw * 0.5f + keep_middle_tiles * map.tilesize;
}

void onTick(CRules@ this)
{
	f32 speed_factor = 1.0f;
	bool ptb = isPTB();
	CMap@ map = getMap();

	Vec2f[] empty;
	if (getLocalPlayer() !is null && getBlobByName("core") !is null && !map.getMarkers("core zone", @empty))
	{
		CPlayer@ player = getLocalPlayer();
		if (player !is null)
		{
			CBitStream params;
			params.write_u16(player.getNetworkID());
			this.SendCommand(this.getCommandID("request_sync_ptb"), params);
		}
	}
	
	if (shouldBarrier(this) || ptb)
	{
		if (ptb)
		{
			SetBarrierPosition(this);
			if (isServer() || getGameTime() % 10 == 0) ResetRespawns(this);
		}
		else if (!reachedMid(this))
		{
			CMap@ map = getMap();
			const f32 mw = map.tilemapwidth * map.tilesize;
			const f32 barrier_left_pos = this.get_u16("barrier_left_x2");
			const f32 barrier_right_pos = this.get_u16("barrier_right_x1");
			const f32 max_distance = mw * 0.5f - keep_middle_tiles * map.tilesize;

			f32 left_progress = barrier_left_pos / max_distance;
			f32 right_progress = (mw - barrier_right_pos) / max_distance;
			f32 progress = Maths::Max(left_progress, right_progress);

			speed_factor = Maths::Lerp(1.0f, 0.25f, progress);

			ChangeBarrierPositions(this, base_barrier_speed * speed_factor);
		}
	}

	if (!shouldBarrier(this))
	{
		IS_barrier_left_SET = false;
		return;
	}

	if (getGameTime() % damage_tickrate != 0)
	{	
		return;
	}

	Vec2f tll, brl, tlr, brr;
	getBarrierRect(@this, tll, brl, tlr, brr);
		
	CBlob@[] blobsInBoxLeft;
	if (map.getBlobsInBox(tll, brl - Vec2f(16,0), @blobsInBoxLeft))
	{
		for (uint i = 0; i < blobsInBoxLeft.length; i++)
		{
			CBlob@ b = blobsInBoxLeft[i];

			if (b !is null)
			{
				//PushBlob(b, (tl.x + br.x) * 0.5, tl.x, br.x);
				DamageBlob(b);
			}
		}
	}
	CBlob@[] blobsInBoxRight;
	if (map.getBlobsInBox(tlr + Vec2f(16,0), brr, @blobsInBoxRight))
	{
		for (uint i = 0; i < blobsInBoxRight.length; i++)
		{
			CBlob@ b = blobsInBoxRight[i];

			if (b !is null)
			{
				//PushBlob(b, (tl.x + br.x) * 0.5, tl.x, br.x);
				DamageBlob(b);
			}
		}
	}
}


Vec2f old_left = Vec2f_zero;
Vec2f old_right = Vec2f_zero;
Vec2f old_left2 = Vec2f_zero;
Vec2f old_right2 = Vec2f_zero;

void onRender(CRules@ this)
{
	if (!shouldBarrier(this))
		return;

	const u16 xl1 = this.get_u16("barrier_left_x1");
	const u16 xl2 = this.get_u16("barrier_left_x2");
	const u16 xr1 = this.get_u16("barrier_right_x1");
	const u16 xr2 = this.get_u16("barrier_right_x2");

	if (xl2 > 0.0f)
	{
		Driver@ driver = getDriver();
		Vec2f left_world = Vec2f(Maths::Lerp(old_left.x, xl1, 0.05f), 0);
		Vec2f right_world = Vec2f(Maths::Lerp(old_right.x, xl2, 0.05f), 0);
		Vec2f left = driver.getScreenPosFromWorldPos(left_world);
		Vec2f right = driver.getScreenPosFromWorldPos(right_world);
		old_left = left_world;
		old_right = right_world;

		left.y = 0;
		right.y = driver.getScreenHeight();

		GUI::DrawRectangle(left, right, SColor(50, 235, 0, 0));
	}
	if (xr2 > 0.0f)
	{
		CMap@ map = getMap();

		Driver@ driver = getDriver();
		if (old_left2 == Vec2f_zero) old_left2 = Vec2f(xr1, 0);
		if (old_right2 == Vec2f_zero) old_right2 = Vec2f(xr2, 0);

		Vec2f left_world = Vec2f(Maths::Lerp(old_left2.x, xr1, 0.05f), 0);
		Vec2f right_world = Vec2f(Maths::Lerp(old_right2.x, xr2, 0.05f), 0);
		Vec2f left = driver.getScreenPosFromWorldPos(left_world);
		Vec2f right = driver.getScreenPosFromWorldPos(right_world);
		old_left2 = left_world;
		old_right2 = right_world;

		left.y = 0;
		right.y = driver.getScreenHeight();

		GUI::DrawRectangle(left, right, SColor(50, 235, 0, 0));
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (isClient() && cmd == this.getCommandID("set_barrier_pos"))
	{
		const u16 xl1 = params.read_u16();
		const u16 xl2 = params.read_u16();
		const u16 xr1 = params.read_u16();
		const u16 xr2 = params.read_u16();

		this.set_u16("barrier_left_x1", xl1);
		this.set_u16("barrier_left_x2", xl2);
		this.set_u16("barrier_right_x1", xr1);
		this.set_u16("barrier_right_x2", xr2);

	}
	else if (isClient() && cmd == this.getCommandID("set_barrier_vars"))
	{
		VEL_PUSHBACK = params.read_f32();
	}
	else if (cmd == this.getCommandID("request_sync_ptb"))
	{
		if (!isServer()) return;
		//printf("requested sync");
		SyncPTB(this);
	}
	else if (cmd == this.getCommandID("sync_ptb"))
	{
		if (!isClient()) return;
		//printf("syncing");
		CMap@ map = getMap();
		
		this.set_bool("ptb", params.read_bool());
		s8 side = params.read_s8();

		this.set_s8("ptb side", side);
		//printf("Receiving "+this.get_bool("ptb")+" "+this.get_s8("ptb side"));

		if (side != -1)
		{
			//printf("added ptb marker "+side);
			map.AddMarker(Vec2f(0,0), side == 0 ? "ptb blue" : "ptb red");
		}

		u16 count = params.read_u16();
		for (uint i = 0; i < count; i++)
		{
			Vec2f pos = params.read_Vec2f();
			//printf("reading "+pos);
			map.AddMarker(pos, "core zone");
		}

		SetBarrierPosition(this);
	}
}

void SyncPTB(CRules@ this)
{
	CBitStream params;

	params.write_bool(this.get_bool("ptb"));
	params.write_s8(this.get_s8("ptb side"));

	//printf("Sending "+this.get_bool("ptb")+" "+this.get_s8("ptb side"));
	
	Vec2f[]@ core_zones;
	this.get("core_zones", @core_zones);

	params.write_u16(core_zones.size());
	for (uint i = 0; i < core_zones.size(); i++)
	{
		//printf("writing "+core_zones[i]);
		params.write_Vec2f(core_zones[i]);
	}

	this.SendCommand(this.getCommandID("sync_ptb"), params);
}

////  FUNCTIONS  ////

void PushBlob(CBlob@ blob, const u16 &in middle, const u16 &in x1, const u16 &in x2)
{
	Vec2f vel = blob.getVelocity();
	Vec2f pos = blob.getPosition();
	
	//players clamped to edge
	if (blob.getPlayer() !is null)
	{
		if (pos.x >= x1 && pos.x <= x2)
		{
			const f32 margin = 0.01f;
			const f32 vel_base = 0.01f;
			if (pos.x < middle)
			{
				pos.x = Maths::Min(x1 - margin, pos.x) - margin;
				vel.x = Maths::Min(-vel_base, -Maths::Abs(vel.x));
			}
			else
			{
				pos.x = Maths::Max(x2 + margin, pos.x) + margin;
				vel.x = Maths::Max(vel_base, Maths::Abs(vel.x));
			}
			blob.setPosition(pos);
		}
	}
	else
	{
		vel.x += pos.x < middle ? -VEL_PUSHBACK : VEL_PUSHBACK;
	}

	blob.setVelocity(vel);
}

void DamageBlob(CBlob@ blob)
{
	if (!isServer() || blob is null)
		return;

	CRules@ this = getRules();
	if (blob.hasTag("player"))
	{
		bool ptb = isPTB();
		if (ptb && blob.isAttached()) blob.server_DetachFromAll();

		CMap@ map = getMap();
		Vec2f pos = blob.getPosition();
		f32 mapWidth = map.tilemapwidth * map.tilesize;
		f32 dmg = 0.0f;

		if (ptb)
		{
			dmg = 1.5f;
		}
		else
		{
			if (pos.x < mapWidth * 0.5f)
			{
				f32 distance = pos.x - this.get_u16("barrier_left_x1");
				f32 max_distance = this.get_u16("barrier_left_x2") - this.get_u16("barrier_left_x1");
				dmg = damage_players_min + (damage_players_max - damage_players_min) * (1.0f - (distance / max_distance));
			}
			else
			{
				f32 distance = this.get_u16("barrier_right_x2") - pos.x;
				f32 max_distance = this.get_u16("barrier_right_x2") - this.get_u16("barrier_right_x1");
				dmg = damage_players_min + (damage_players_max - damage_players_min) * (1.0f - (distance / max_distance));
			}
		}
		
		blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), dmg, 0);
	}
	else if (!isPTB() && (blob.hasTag("vehicle") || blob.hasTag("machinegun") || blob.hasTag("turret")))
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), damage_vehicles, 0);
	}
}

void LoadConfigVars()
{
	ConfigFile cfg;
	if (!cfg.loadFile("RedBarrierVars.cfg"))
		return; // We tried :(

	// Check that we have edited the var
	// and that the client needs said value
	const f32 pushback = cfg.read_f32("blob_pushback", 1.0f);

	if (pushback != VEL_PUSHBACK)
	{
		SYNC_CUSTOM_VARS = true;
		VEL_PUSHBACK = pushback;
	}
}

void ChangeBarrierPositions(CRules@ this, const f32 shift)
{
	if (!isServer()) return;

	barrier_width_left += shift;
	barrier_width_right += shift;

	SetBarrierPosition(this);

	const int playerCount = getPlayerCount();
	for (int a = 0; a < playerCount; a++)
	{
		CPlayer@ player = getPlayer(a);

		if (player is null)
			continue;

		SyncToPlayer(this, player);
	}
}

// Only used server side, client doesnt normally have info required
void SetBarrierPosition(CRules@ this)
{
	IS_barrier_left_SET = true;
	CMap@ map = getMap();

	Vec2f[] markers = getPTBZonesMarkers();
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	
	if (!isPTB())
	{
		// Fallback to default behavior if no markers are found
		u16 xl1, xl2, xr1, xr2;

		xl1 = 0;
		xl2 = barrier_width_left;

		xr1 = map.tilemapwidth * map.tilesize - barrier_width_right;
		xr2 = map.tilemapwidth * map.tilesize;

		this.set_u16("barrier_left_x1", xl1);
		this.set_u16("barrier_left_x2", xl2);
		this.set_u16("barrier_right_x1", xr1);
		this.set_u16("barrier_right_x2", xr2);
	}
	else
	{
		if (markers.length != 0)
		{
			bool defenders_on_left = defendersOnLeft();
			Vec2f left_marker, right_marker;

			if (defenders_on_left)
			{
				left_marker = markers[markers.length - 1];
				this.set_u16("barrier_left_x1", 0);
				this.set_u16("barrier_left_x2", left_marker.x);
				this.set_u16("barrier_right_x1", map.tilemapwidth * map.tilesize);
				this.set_u16("barrier_right_x2", map.tilemapwidth * map.tilesize);
			}
			else
			{
				right_marker = markers[0];
				this.set_u16("barrier_right_x1", right_marker.x);
				this.set_u16("barrier_right_x2", map.tilemapwidth * map.tilesize);
				this.set_u16("barrier_left_x1", 0);
				this.set_u16("barrier_left_x2", 0);
			}

			ResetRespawns(this);
		}
	}
}

// Sync barrier to said player
// Only send x as we dont have horizontal barriers (mods will add that in manually anyhow)
void SyncToPlayer(CRules@ this, CPlayer@ player)
{
	CBitStream stream;
	stream.write_u16(this.get_u16("barrier_left_x1"));
	stream.write_u16(this.get_u16("barrier_left_x2"));
	stream.write_u16(this.get_u16("barrier_right_x1"));
	stream.write_u16(this.get_u16("barrier_right_x2"));

	this.SendCommand(this.getCommandID("set_barrier_pos"), stream, player);
}

// Server will send its vars to the current player
// We only send this if we know that the cfg has been edited
void SyncVarsToPlayer(CRules@ this, CPlayer@ player)
{
	// Only send pushback as its the only one client needs
	CBitStream stream;
	stream.write_f32(VEL_PUSHBACK);

	this.SendCommand(this.getCommandID("set_barrier_vars"), stream, player);
}

void getBarrierRect(CRules@ rules, Vec2f &out tll, Vec2f &out brl, Vec2f &out tlr, Vec2f &out brr)
{
	CMap@ map = getMap();
	const u16 xl1 = rules.get_u16("barrier_left_x1");
	const u16 xl2 = rules.get_u16("barrier_left_x2");
	const u16 xr1 = rules.get_u16("barrier_right_x1");
	const u16 xr2 = rules.get_u16("barrier_right_x2");

	f32 mw = map.tilemapwidth * map.tilesize;
	f32 mh = map.tilemapheight * map.tilesize;

	tll = Vec2f(xl1, -50 * map.tilesize);
	brl = Vec2f(xl2, mh);
	tlr = Vec2f(xr1, -50 * map.tilesize);
	brr = Vec2f(xr2, mh);
}

const bool shouldBarrier(CRules@ rules)
{
	if (isPTB()) return true;

	u8 teamleft = rules.get_u8("teamleft");
	u8 teamright = rules.get_u8("teamright");
	
	if (!rules.isMatchRunning() || rules.isWarmup()) return false;
	return rules.get_s16("teamLeftTickets") == 0 && rules.get_s16("teamRightTickets") == 0 && !isTDM() && !isDTT() && !isCTF();
}

Vec2f[] getPTBZonesMarkers()
{
	Vec2f[] markers;
	getMap().getMarkers("core zone", @markers);
	int map_height = getMap().tilemapheight * getMap().tilesize;

	CBlob@[] cores;
	getBlobsByName("core", @cores);
	bool defenders_on_left = defendersOnLeft();

	Vec2f[] return_markers;
	for (int i = 0; i < markers.length; i++)
	{
		bool add = false;
		bool has_core_after = false;

		for (int j = 0; j < cores.length; j++)
		{
			Vec2f core_pos = cores[j].getPosition();
			has_core_after = defenders_on_left ? core_pos.x > markers[i].x : core_pos.x < markers[i].x;
			
			if (has_core_after) // ignore marker if at least one core is after it
			{
				add = true;
				j = cores.length;
			}
		}

		if (has_core_after)
		{
			return_markers.push_back(Vec2f(markers[i].x, map_height));
		}
	}

	return return_markers;
}

bool defendersOnLeft()
{
	CRules@ rules = getRules();
	u8 teamleft = rules.get_u8("teamleft");
	u8 teamright = rules.get_u8("teamright");

	return teamleft == defendersTeamPTB();
}