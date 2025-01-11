// get spawn points for CTF

#include "HallCommon.as"

shared void PopulateSpawnList(CBlob@[]@ respawns, const int teamNum)
{
	CBlob@[] posts;
	getBlobsByTag("respawn", @posts);

	for (uint i = 0; i < posts.length; i++)
	{
		CBlob@ blob = posts[i];

		if (blob.getTeamNum() == teamNum &&
		        !isUnderRaid(blob))
		{
			respawns.push_back(blob);
		}
	}

	CBlob@[] vehicles;
	getBlobsByTag("respawn_if_crew_present", @vehicles);

	for (uint i = 0; i < vehicles.length; i++)
	{
		CBlob@ blob = vehicles[i];
		if (blob is null) continue;

		if (blob.getTeamNum() == teamNum
				&& blob.hasTag("vehicle")
				&& blob.get_u8("numcapping") == 0
				&& !blob.hasTag("turret"))
		{
			AttachmentPoint@[] aps;
			if (blob.getAttachmentPoints(@aps))
			{
				bool has_free_slot = false;
				bool has_occupied_slot = false;

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
							
							if (gunner !is null) has_occupied_slot = true;
							else has_free_slot = true;
						}
					}
					else if (name == "DRIVER" || name.find("PASSENGER") != -1)
					{
						if (occ !is null) has_occupied_slot = true;
						else has_free_slot = true;
					}
				}

				if (has_occupied_slot && has_free_slot)
				{
					respawns.push_back(blob);
				}
			}
		}
	}
}
