
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
	CBlob@ SpawnPlayerIntoWorld(Vec2f at, PlayerInfo@ p_info, CBlob@ spawner)
	{
		CPlayer@ player = getPlayerByUsername(p_info.username);

		if (player !is null)
		{
			CBlob @newBlob = server_CreateBlob(p_info.blob_name, p_info.team, at);
			newBlob.server_SetPlayer(player);
			player.server_setTeamNum(int(p_info.team));
			
			if (newBlob !is null && spawner !is null)
			{
				//printf(""+newBlob.getName()+" spawned at "+at.x+" "+at.y+" "+spawner.getName());
				AttachmentPoint@[] aps;
				if (spawner.getAttachmentPoints(@aps))
				{
					bool has_free_slot = false;

					for (uint j = 0; j < aps.length; j++)
					{
						//printf("Checking attachment point IDX: " + j);
						AttachmentPoint@ ap = aps[j];
						if (ap is null) continue;
						if (!ap.socket) continue;

						CBlob@ occ = ap.getOccupied();
						
						string name = ap.name;
						//print("Checking attachment point: " + name);
						if (name == "TURRET" && occ !is null)
						{
							AttachmentPoint@ gun = occ.getAttachments().getAttachmentPointByName("GUNNER");
							if (gun !is null)
							{
								CBlob@ gunner = gun.getOccupied();
								
								if (gunner is null)
								{
									//print("Attaching to turret gunner position");
									newBlob.setPosition(gun.getPosition());
									occ.server_AttachTo(newBlob, gun);
									has_free_slot = true;
									break;
								}
							}
						}
						else if (name == "DRIVER" || name.find("PASSENGER") != -1)
						{
							if (occ is null)
							{
								//print("Attaching to " + name + " position");
								newBlob.setPosition(ap.getPosition());
								spawner.server_AttachTo(newBlob, ap);
								has_free_slot = true;
								break;
							}
						}
					}

					if (!has_free_slot)
					{
						warn("NO FREE SLOT IN VEHICLE FOR PLAYER RESPAWN: " + p_info.username + " " + p_info.blob_name + " " + spawner.getName());
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
		if (canSpawnPlayer(p_info))
		{
			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

			if (player is null)
			{
				return;
			}

			CBlob@ spawner;
			Vec2f location = getSpawnLocation(p_info, spawner);
			SpawnPlayerIntoWorld(location, p_info, spawner);
			RemovePlayerFromSpawn(player);
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		/* OVERRIDE ME */
		return true;
	}

	Vec2f getSpawnLocation(PlayerInfo@ p_info, CBlob@ &out spawner)
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
