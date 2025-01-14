
//the respawn system interface, provides some sane default functions
//  but doesn't spawn players on its own (so you can plug your own implementation)

// designed to work in tandem with a rulescore
//  to get playerinfos and whatnot from usernames reliably and to hold team info
//  can be designed to work without one of course.

#include "PlayerInfo"

shared class RespawnSystem
{
	private RulesCore@ core;

	RespawnSystem() { @core = null; }

	void Update() { /* OVERRIDE ME */ }

	void AddPlayerToSpawn(CPlayer@ player)  { /* OVERRIDE ME */ }

	void RemovePlayerFromSpawn(CPlayer@ player) { /* OVERRIDE ME */ }

	void SetCore(RulesCore@ _core) { @core = _core; }

	//the actual spawn functions
	CBlob@ SpawnPlayerIntoWorld(Vec2f at, PlayerInfo@ p_info, CBlob@ spawner, CBlob@ default_spawn)
	{
		CPlayer@ player = getPlayerByUsername(p_info.username);

		if (player !is null)
		{
			CBlob @newBlob = server_CreateBlob(p_info.blob_name, p_info.team, at);
			newBlob.server_SetPlayer(player);
			player.server_setTeamNum(int(p_info.team));
			
			if (newBlob !is null && spawner !is null && !spawner.hasTag("importantarmory"))
			{
				//printf(""+newBlob.getName()+" spawned at "+at.x+" "+at.y+" "+spawner.getName());
				AttachmentPoint@[] aps;
				if (spawner.getAttachmentPoints(@aps))
				{
					bool has_free_seat = false;
					bool has_occupied_seat = false;
					AttachmentPoint@ end;

					for (uint j = 0; j < aps.length; j++)
					{
						AttachmentPoint@ ap = aps[j];
						if (ap is null) continue;
						if (!ap.socket) continue;

						CBlob@ occ = ap.getOccupied();

						string name = ap.name;
						if (name == "TURRET" && occ !is null)
						{
							AttachmentPoint@ gun = occ.getAttachments().getAttachmentPointByName("GUNNER");
							if (gun !is null)
							{
								CBlob@ gunner = gun.getOccupied();
								
								if (gunner is null)
								{
									if (end is null) @end = @gun;
									has_free_seat = true;
								}
								else if (gunner.hasTag("player")) has_occupied_seat = true;
							}
						}
						else if (name == "DRIVER" || name.find("PASSENGER") != -1)
						{
							if (occ is null)
							{
								if (end is null) @end = @ap;
								has_free_seat = true;
							}
							else if (occ.hasTag("player")) has_occupied_seat = true;
						}
					}

					if (end !is null && has_free_seat && has_occupied_seat)
					{
						newBlob.setPosition(spawner.getPosition());
						spawner.server_AttachTo(newBlob, end);
					}
					else if (default_spawn !is null)
					{
						newBlob.setPosition(default_spawn.getPosition());
					}
				}
			}

			if (p_info.customImmunityTime >= 0)
			{
				newBlob.set_u32("custom immunity time", p_info.customImmunityTime);
			}

			return newBlob;
		}

		return null;
	}

	//suggested implementation, doesn't have to be used of course
	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		/* OVERRIDE ME */
		return true;
	}

	Vec2f getSpawnLocation(PlayerInfo@ p_info, CBlob@ &out spawner, CBlob@ &out default_spawn)
	{
		/* OVERRIDE ME */
		return Vec2f();
	}

	CBlob@ getSpawnBlob(PlayerInfo@ p_info)
	{
		/* OVERRIDE ME */
		return null;
	}

	/*
	 * Override so rulescore can re-add when appropriate
	 */
	bool isSpawning(CPlayer@ player)
	{
		return false;
	}


};
