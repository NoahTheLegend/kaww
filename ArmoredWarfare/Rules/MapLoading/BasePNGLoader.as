// BasePNGLoader.as
// NSFL if you don't unzoom it out in your editor

// Note for modders upgrading their mod, handlePixel's signature has changed recently!

#include "LoaderColors.as";
#include "LoaderUtilities.as";
#include "CustomBlocks.as";
#include "MakeCrate.as";
#include "LoadPNGMap.as";
#include "VehiclesParams.as";

enum WAROffset
{
	autotile_offset = 0,
	tree_offset,
	bush_offset,
	grain_offset,
	spike_offset,
	ladder_offset,
	offsets_count
};

//global
Random@ map_random = Random();

class PNGLoader
{
	PNGLoader()
	{
		offsets = int[][](offsets_count, int[](0));
	}

	CFileImage@ image;
	CMap@ map;

	int[][] offsets;

	int current_offset_count;
	int _teamleft;
	int _teamright;

	void SetTeams()
	{
		if (!isServer()) return;

		u8 prevteamleft = getRules().get_u8("teamleft");
		u8 prevteamright = getRules().get_u8("teamright");
		if (!getRules().hasTag("first init teams")) // first match always sets same teams (6 and 1)
		{
			getRules().Tag("first init teams");
			u8 teamleft = (Time_Local()%(XORRandom(4)+1));
			while (teamleft == prevteamleft)
			{
				teamleft = (Time_Local()%(XORRandom(4)+1));
			}
			u8 teamright = (Time_Local()%(XORRandom(4)+1));
			while (teamright == teamleft || teamright == prevteamright)
			{
				teamright = (Time_Local()%(XORRandom(4)+1));
			}

			CRules@ rules = getRules();

			rules.set_u8("oldteamleft", teamleft);
			rules.set_u8("oldteamright", teamright);
			rules.set_u8("teamleft", teamleft);
			rules.set_u8("teamright", teamright);

			rules.Sync("oldteamleft", true);
			rules.Sync("oldteamright", true);
			rules.Sync("teamleft", true);
			rules.Sync("teamright", true);

			printf("SET TEAMS INIT "+teamleft+" : "+teamright);

    		_teamleft = teamleft;
    		_teamright = teamright;
		}
		else
		{
			u8 teamleft = XORRandom(3);
			while (teamleft == prevteamleft)
			{
				teamleft = XORRandom(3);
			}
			u8 teamright = XORRandom(3);
			while (teamright == teamleft || teamright == prevteamright)
			{
				teamright = XORRandom(3);
			}

			CRules@ rules = getRules();

			rules.set_u8("oldteamleft", getRules().get_u8("teamleft"));
			rules.set_u8("oldteamright", getRules().get_u8("teamright"));
			rules.set_u8("teamleft", teamleft);
			rules.set_u8("teamright", teamright);

			rules.Sync("oldteamleft", true);
			rules.Sync("oldteamright", true);
			rules.Sync("teamleft", true);
			rules.Sync("teamright", true);

			printf("SET TEAMS "+teamleft+" : "+teamright);

    		_teamleft = teamleft;
    		_teamright = teamright;
		}
	}

	void ResetPTB()
	{
		CRules@ rules = getRules();
		rules.set_bool("ptb", false);
		Vec2f[] empty;
		rules.set("core_zones", @empty);
		rules.set_s8("ptb side", -1);
	}

	bool loadMap(CMap@ _map, const string& in filename)
	{
		@map = _map;
		@map_random = Random();

		CRules@ this = getRules();
		this.set_u8("map_type", 0); // reset type

		this.set_bool("allowclouds", false);
		this.set_u8("brightmod", 50); // 50 default

		if(!getNet().isServer())
		{
			SetupMap(0, 0);
			SetupBackgrounds();

			return true;
		}

		@image = CFileImage( filename );

		if(image.isLoaded())
		{
			SetupMap(image.getWidth(), image.getHeight());

			while(image.nextPixel())
			{
				const SColor pixel = image.readPixel();
				const int offset = image.getPixelOffset();

				// Optimization: check if the pixel color is the sky color
				// We do this before calling handlePixel because it is overriden, and to avoid a SColor copy
				if (pixel.color != map_colors::sky)
				{
					handlePixel(pixel, offset);
				}

				getNet().server_KeepConnectionsAlive();
			}

			SetupBackgrounds();

			// late load - after placing tiles
			for(uint i = 0; i < offsets.length; ++i)
			{
				int[]@ offset_set = offsets[i];
				current_offset_count = offset_set.length;
				for(uint step = 0; step < current_offset_count; ++step)
				{
					handleOffset(i, offset_set[step], step, current_offset_count);
					getNet().server_KeepConnectionsAlive();
				}
			}
			return true;
		}
		return false;
	}

	// Queue an offset to be autotiled
	void autotile(int offset)
	{
		offsets[autotile_offset].push_back(offset);
	}

	void handlePixel(const SColor &in pixel, int offset)
	{
		int teamleft = _teamleft;
		int teamright = _teamright;
		u8 alpha = pixel.getAlpha();

		if(alpha < 255)
		{
			alpha &= ~0x80;
			const Vec2f position = getSpawnPosition(map, offset);

			//print("ARGB = "+alpha+", "+pixel.getRed()+", "+pixel.getGreen()+", "+pixel.getBlue());

			// TODO future reader, if the new angelscript release has arrived; consider using named arguments for spawnBlob etc if it doesn't clutter the lines too much.
			// It might be nice for things like the static argument.

			// Test color with alpha 255
			switch (pixel.color | 0xFF000000)
			{
			// Alpha various structures
			case map_colors::alpha_stalagmite:      autotile(offset); spawnBlob(map, "stalagmite",                            255, position, getAngleFromChannel(alpha), true).set_u8("state", 1); /*stabbing*/ break;
			case map_colors::alpha_ladder:          autotile(offset); spawnBlob(map, "ladder",          getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_spikes:          autotile(offset); spawnBlob(map, "spikes",          getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_stone_door:      autotile(offset); spawnBlob(map, "stone_door",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_trap_block:      autotile(offset); spawnBlob(map, "trap_block",      getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_wooden_door:     autotile(offset); spawnBlob(map, "wooden_door",     getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_wooden_platform: autotile(offset); spawnBlob(map, "wooden_platform", getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;

			// Mechanisms
			case map_colors::alpha_pressure_plate:  autotile(offset); spawnBlob(map, "pressure_plate",                        255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_push_button:     autotile(offset); spawnBlob(map, "push_button",     getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_coin_slot:       autotile(offset); spawnBlob(map, "coin_slot",       getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_sensor:          autotile(offset); spawnBlob(map, "sensor",          getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_diode:           autotile(offset); spawnBlob(map, "diode",           getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_elbow:           autotile(offset); spawnBlob(map, "elbow",           getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_emitter:         autotile(offset); spawnBlob(map, "emitter",         getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_inverter:        autotile(offset); spawnBlob(map, "inverter",        getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_junction:        autotile(offset); spawnBlob(map, "junction",        getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_oscillator:      autotile(offset); spawnBlob(map, "oscillator",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_randomizer:      autotile(offset); spawnBlob(map, "randomizer",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_receiver:        autotile(offset); spawnBlob(map, "receiver",        getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_resistor:        autotile(offset); spawnBlob(map, "resistor",        getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_tee:             autotile(offset); spawnBlob(map, "tee",             getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_toggle:          autotile(offset); spawnBlob(map, "toggle",          getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_transistor:      autotile(offset); spawnBlob(map, "transistor",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_wire:            autotile(offset); spawnBlob(map, "wire",            getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_bolter:          autotile(offset); spawnBlob(map, "bolter",                                255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_dispenser:       autotile(offset); spawnBlob(map, "dispenser",                             255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_lamp:            autotile(offset); spawnBlob(map, "lamp",                                  255, position,                             true); break;
			case map_colors::alpha_obstructor:      autotile(offset); spawnBlob(map, "obstructor",                            255, position,                             true); break;
			case map_colors::alpha_spiker:          autotile(offset); spawnBlob(map, "spiker",                                255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_lever:
			{
				autotile(offset);
				CBlob@ blob = spawnBlob(map, "lever", getTeamFromChannel(alpha), position, true);

				// | state          | binary    | hex  | dec |
				// ---------------------vv--------------------
				// | off            | 0000 0000 | 0x00 |   0 |
				// | on             | 0001 0000 | 0x10 |  16 |
				// | random         | 0010 0000 | 0x20 |  32 |

				/*if(alpha & 0x10 != 0 || alpha & 0x20 != 0 && XORRandom(2) == 0) // not implemented at the moment
				{
					blob.SendCommand(blob.getCommandID("toggle"));
				}*/
			}
			break;
			case map_colors::alpha_magazine:
			{
				autotile(offset);
				CBlob@ blob = spawnBlob(map, "magazine", 255, position, true);

				const string[] items = {
				"mat_bombs",       // 0
				"mat_waterbombs",  // 1
				"mat_arrows",      // 2
				"mat_waterarrows", // 3
				"mat_firearrows",  // 4
				"mat_bombarrows",  // 5
				"food"};           // 6
				// RANDOM             7

				if(alpha >= items.length + 1) break;

				string name;
				if(alpha == items.length) // random
				{
					name = items[XORRandom(items.length - 1)];
				}
				else
				{
					name = items[alpha];
				}

				CBlob@ item = server_CreateBlob(name, 255, position);
				blob.server_PutInInventory(item);
			}
			break;
			};
		}
		else
		{
			switch (pixel.color)
			{
			// Tiles
			case map_colors::tile_ground:           map.SetTile(offset, CMap::tile_ground);           break;
			case map_colors::tile_ground_back:      map.SetTile(offset, CMap::tile_ground_back);      break;
			case map_colors::tile_stone:            map.SetTile(offset, CMap::tile_stone);            break;
			case map_colors::tile_thickstone:       map.SetTile(offset, CMap::tile_thickstone);       break;
			case map_colors::tile_bedrock:          map.SetTile(offset, CMap::tile_bedrock);          break;
			case map_colors::tile_gold:             map.SetTile(offset, CMap::tile_gold);             break;
			case map_colors::tile_castle:           map.SetTile(offset, CMap::tile_castle);           break;
			case map_colors::tile_castle_back:      map.SetTile(offset, CMap::tile_castle_back);      break;
			case map_colors::tile_castle_moss:      map.SetTile(offset, CMap::tile_castle_moss);      break;
			case map_colors::tile_castle_back_moss: map.SetTile(offset, CMap::tile_castle_back_moss); break;
			case map_colors::tile_wood:             map.SetTile(offset, CMap::tile_wood);             break;
			case map_colors::tile_wood_back:        map.SetTile(offset, CMap::tile_wood_back);        break;
			case map_colors::tile_grass:            map.SetTile(offset, CMap::tile_grass + map_random.NextRanged(3)); break;
			case map_colors::tile_cdirt:            map.SetTile(offset, CMap::tile_cdirt); break;
			case map_colors::tile_scrap:            map.SetTile(offset, CMap::tile_scrap); break;
			case map_colors::tile_metal:			map.SetTile(offset, CMap::tile_metal); break;
			case map_colors::tile_metal_back:		map.SetTile(offset, CMap::tile_metal_back); break;
			case map_colors::tile_ice:              map.SetTile(offset, CMap::tile_ice);              break;

			// Water
			case map_colors::water_air:
				map.server_setFloodWaterOffset(offset, true);
			break;
			case map_colors::water_backdirt:
				map.server_setFloodWaterOffset(offset, true);
				map.SetTile(offset, CMap::tile_ground_back);
			break;

			// Princess & necromancer
			case map_colors::princess:             autotile(offset); spawnBlob(map, "princess",    offset, 6); break;
			case map_colors::necromancer:          autotile(offset); spawnBlob(map, "necromancer", offset, 3); break;
			case map_colors::necromancer_teleport: autotile(offset); AddMarker(map, offset, "necromancer teleport"); break;

			// Main spawns
			case map_colors::blue_main_spawn:   autotile(offset); AddMarker(map, offset, "blue main spawn"); break;
			case map_colors::red_main_spawn:    autotile(offset); AddMarker(map, offset, "red main spawn");  break;
			case map_colors::green_main_spawn:  autotile(offset); spawnHall(map, offset, 2); break;
			case map_colors::purple_main_spawn: autotile(offset); spawnHall(map, offset, 3); break;
			case map_colors::orange_main_spawn: autotile(offset); spawnHall(map, offset, 4); break;
			case map_colors::aqua_main_spawn:   autotile(offset); spawnHall(map, offset, 5); break;
			case map_colors::teal_main_spawn:   autotile(offset); spawnHall(map, offset, 6); break;
			case map_colors::gray_main_spawn:   autotile(offset); spawnHall(map, offset, 7); break;

			// Red Barrier
			case map_colors::redbarrier:     autotile(offset); AddMarker(map, offset, "red barrier");  break;
			// Normal spawns
			//case map_colors::blue_transporttruck:     autotile(offset); spawnBlob(map, "transporttruck",  offset, 0); break;
			//case map_colors::red_transporttruck:      autotile(offset); spawnBlob(map, "transporttruck",  offset, 1); break;
			/*case map_colors::green_spawn:  autotile(offset); AddMarker(map, offset, "green spawn");  break;*/ // same as grass...?
			case map_colors::purple_spawn:   autotile(offset); AddMarker(map, offset, "purple spawn"); break;
			/*case map_colors::orange_spawn: autotile(offset); AddMarker(map, offset, "orange spawn"); break;*/ // same as dirt...?
			case map_colors::aqua_spawn:     autotile(offset); AddMarker(map, offset, "aqua spawn");   break;
			case map_colors::teal_spawn:     autotile(offset); AddMarker(map, offset, "teal spawn");   break;
			case map_colors::gray_spawn:     autotile(offset); AddMarker(map, offset, "gray spawn");   break;

			// Workshops
			case map_colors::knight_shop:     autotile(offset); spawnBlob(map, "knightshop",  offset); break;
			case map_colors::builder_shop:    autotile(offset); spawnBlob(map, "buildershop", offset); break;
			case map_colors::archer_shop:     autotile(offset); spawnBlob(map, "archershop",  offset); break;
			case map_colors::boat_shop:       autotile(offset); spawnBlob(map, "boatshop",    offset); break;
			case map_colors::vehicle_shop:    autotile(offset); spawnBlob(map, "vehicleshop", offset); break;
			case map_colors::quarters:        autotile(offset); spawnBlob(map, "quarters",    offset); break;
			case map_colors::storage_noteam:  autotile(offset); spawnBlob(map, "storage",     offset); break;
			case map_colors::barracks_noteam: autotile(offset); spawnBlob(map, "barracks",    offset); break;
			case map_colors::factory_noteam:  autotile(offset); spawnBlob(map, "factory",     offset); break;
			case map_colors::tunnel_blue:     autotile(offset); spawnBlob(map, "tunnel",      offset, teamleft); break;
			case map_colors::tunnel_red:      autotile(offset); spawnBlob(map, "tunnel",      offset, teamright); break;
			case map_colors::tunnel_noteam:   autotile(offset); spawnBlob(map, "tunnel",      offset); break;
			case map_colors::kitchen:         autotile(offset); spawnBlob(map, "kitchen",     offset); break;
			case map_colors::nursery:         autotile(offset); spawnBlob(map, "nursery",     offset); break;
			case map_colors::research:        autotile(offset); spawnBlob(map, "research",    offset); break;

			case map_colors::workbench:       autotile(offset); spawnBlob(map, "workbench",   offset, 255, true); break;
			case map_colors::campfire:        autotile(offset); spawnBlob(map, "fireplace",   offset, 255); break;
			case map_colors::saw:             autotile(offset); spawnBlob(map, "saw",         offset); break;
			case map_colors::shooting_target:             autotile(offset); spawnBlob(map, "shootingtarget",         offset); break;

			// Flora
			case map_colors::tree:
			case map_colors::tree + (1 << 4):
			case map_colors::tree + (2 << 4):
			case map_colors::tree + (3 << 4):
				autotile(offset);
				offsets[tree_offset].push_back(offset);
			break;
			case map_colors::bush:    autotile(offset); offsets[bush_offset].push_back(offset); break;
			case map_colors::grain:   autotile(offset); offsets[grain_offset].push_back(offset); break;
			case map_colors::flowers: autotile(offset); spawnBlob(map, "flowers", offset); break;
			case map_colors::log:     autotile(offset); spawnBlob(map, "log",     offset); break;

			// Fauna
			case map_colors::shark:   autotile(offset); spawnBlob(map, "shark",   offset); break;
			case map_colors::fish:    autotile(offset); spawnBlob(map, "fishy",   offset).set_u8("age", (offset * 997) % 4); break;
			case map_colors::bison:   autotile(offset); spawnBlob(map, "bison",   offset); break;
			case map_colors::chicken: autotile(offset); spawnBlob(map, "chicken", offset, 255, false, Vec2f(0,-8)); break;

			// Ladders
			case map_colors::ladder:
			//case map_colors::tile_ladder_ground: // same as map_colors::ladder
			case map_colors::tile_ladder_castle:
			case map_colors::tile_ladder_wood:
				autotile(offset);
				offsets[ladder_offset].push_back( offset );
			break;

			// Platforms
			case map_colors::platform_up:    autotile(offset); spawnBlob(map, "wooden_platform", offset, 255, true); break;
			case map_colors::platform_right: autotile(offset); spawnBlob(map, "wooden_platform", offset, 255, true, Vec2f_zero,  90); break;
			case map_colors::platform_down:  autotile(offset); spawnBlob(map, "wooden_platform", offset, 255, true, Vec2f_zero, 180); break;
			case map_colors::platform_left:  autotile(offset); spawnBlob(map, "wooden_platform", offset, 255, true, Vec2f_zero, -90); break;

			// Doors
			case map_colors::wooden_door_h_blue:   autotile(offset); spawnBlob(map, "wooden_door", offset,   teamleft, true); break;
			case map_colors::wooden_door_v_blue:   autotile(offset); spawnBlob(map, "wooden_door", offset,   teamleft, true, Vec2f_zero, 90); break;
			case map_colors::wooden_door_h_red:    autotile(offset); spawnBlob(map, "wooden_door", offset,   teamright, true); break;
			case map_colors::wooden_door_v_red:    autotile(offset); spawnBlob(map, "wooden_door", offset,   teamright, true, Vec2f_zero, 90); break;
			case map_colors::wooden_door_h_noteam: autotile(offset); spawnBlob(map, "wooden_door", offset, 255, true); break;
			case map_colors::wooden_door_v_noteam: autotile(offset); spawnBlob(map, "wooden_door", offset, 255, true, Vec2f_zero, 90); break;
			case map_colors::stone_door_h_blue:    autotile(offset); spawnBlob(map, "stone_door",  offset,   teamleft, true); break;
			case map_colors::stone_door_v_blue:    autotile(offset); spawnBlob(map, "stone_door",  offset,   teamleft, true, Vec2f_zero, 90); break;
			case map_colors::stone_door_h_red:     autotile(offset); spawnBlob(map, "stone_door",  offset,   teamright, true); break;
			case map_colors::stone_door_v_red:     autotile(offset); spawnBlob(map, "stone_door",  offset,   teamright, true, Vec2f_zero, 90); break;
			case map_colors::stone_door_h_noteam:  autotile(offset); spawnBlob(map, "stone_door",  offset, 255, true); break;
			case map_colors::stone_door_v_noteam:  autotile(offset); spawnBlob(map, "stone_door",  offset, 255, true, Vec2f_zero, 90); break;

			// Trapblocks
			case map_colors::trapblock_blue:   autotile(offset); spawnBlob(map, "trap_block", offset,   0, true); break;
			case map_colors::trapblock_red:    autotile(offset); spawnBlob(map, "trap_block", offset,   1, true); break;
			case map_colors::trapblock_noteam: autotile(offset); spawnBlob(map, "trap_block", offset, 255, true); break;

			// Spikes
			case map_colors::spikes:  offsets[spike_offset].push_back(offset); break;
			case map_colors::spikes_ground: offsets[spike_offset].push_back(offset); map.SetTile(offset, CMap::tile_ground_back); break;
			case map_colors::spikes_castle: offsets[spike_offset].push_back(offset); map.SetTile(offset, CMap::tile_castle_back); break;
			case map_colors::spikes_wood:   offsets[spike_offset].push_back(offset); map.SetTile(offset, CMap::tile_wood_back);   break;

			// Misc stuff
			case map_colors::drill: autotile(offset); spawnBlob(map, "drill", offset, -1); break;
			case map_colors::trampoline:
			{
				autotile(offset);
				CBlob@ trampoline = server_CreateBlobNoInit("trampoline");
				if (trampoline !is null)
				{
					trampoline.Tag("invincible");
					trampoline.Tag("static");
					trampoline.Tag("no pickup");
					trampoline.setPosition(getSpawnPosition(map, offset));
					trampoline.Init();
				}
			}
			break;
			case map_colors::lantern:     autotile(offset); spawnBlob(map, "lantern", offset, 255, true); break;
			case map_colors::ledlight:    autotile(offset); spawnBlob(map, "ledlight", offset); break;
			case map_colors::ledlighthalfoffset:
			{
				autotile(offset);
				CBlob@ led = spawnBlob(map, "ledlight", offset);
				if (led !is null) led.setPosition(led.getPosition() + Vec2f(4, 0));
				break;
			}
			case map_colors::fan:    	autotile(offset); spawnBlob(map, "fan", offset); break;
			case map_colors::glass:    	autotile(offset); spawnBlob(map, "glass", offset); break;
			case map_colors::door:    	autotile(offset); spawnBlob(map, "door", offset); break;
			case map_colors::crate:       autotile(offset); spawnBlob(map, "crate",   offset); break;
			case map_colors::bucket:      autotile(offset); spawnBlob(map, "bucket",  offset); break;
			case map_colors::sponge:
			{
				autotile(offset);
				CBlob@ rounds = server_CreateBlobNoInit("ammo");
				if (rounds !is null)
				{
					rounds.setPosition(getSpawnPosition(map, offset));
					rounds.Init();
				}
			}
			break;
			case map_colors::alpha_chest:
			case map_colors::chest:       autotile(offset); spawnBlob(map, "chest",   offset); break;

			// Food
			case map_colors::steak:       autotile(offset); spawnBlob(map, "steak", offset); break;
			case map_colors::burger:      autotile(offset); spawnBlob(map, "food",  offset); break;
			case map_colors::heart:       autotile(offset); spawnBlob(map, "heart", offset); break;

			// Spawn truck
			case map_colors::alpha_spawn: autotile(offset); AddMarker(map, offset, (alpha & 0x01 == 0 ? "blue main spawn" : "red main spawn")); break;
			case map_colors::alpha_flag:  autotile(offset); AddMarker(map, offset, (alpha & 0x01 == 0 ? "blue spawn"      : "red spawn"));      break;

			case map_colors::blue_transporttruck:     autotile(offset); AddMarker(map, offset, "blue main spawn"); break;
			case map_colors::red_transporttruck:     autotile(offset); AddMarker(map, offset, "red main spawn"); break;
			case map_colors::training_main_spawn:     autotile(offset); AddMarker(map, offset, "training main spawn"); break;

			case map_colors::npc_bootcamp:  autotile(offset); spawnBlob(map, "ranger", offset, 2); break;

			// Ground siege
			case map_colors::catapult:    autotile(offset); spawnVehicle(map, "catapult", offset, teamleft); break; // HACK: team for Challenge
			case map_colors::ballista:    autotile(offset); spawnVehicle(map, "m60", offset); break;
			case map_colors::mountedbow:  autotile(offset); spawnBlob(map, "mounted_bow", offset, 255, true, Vec2f(0.0f, 4.0f)); break;

			// Water/air vehicles
			case map_colors::longboat:    autotile(offset); spawnVehicle(map, "longboat", offset); break;
			case map_colors::warboat:     autotile(offset); spawnVehicle(map, "warboat",  offset); break;
			case map_colors::dinghy:      autotile(offset); spawnVehicle(map, "dinghy",   offset); break;
			case map_colors::raft:        autotile(offset); spawnVehicle(map, "raft",     offset); break;
			case map_colors::airship:     autotile(offset); spawnVehicle(map, "airship",  offset); break;
			case map_colors::bomber:      autotile(offset); spawnVehicle(map, "bomber",   offset); break;

			// AW
			case map_colors::faction_blue_transport:    autotile(offset); spawnFactionVehicle(offset, VehicleType::transport, teamleft); break;
			case map_colors::faction_red_transport:     autotile(offset); spawnFactionVehicle(offset, VehicleType::transport, teamright); break;
			case map_colors::faction_blue_armedtransport: autotile(offset); spawnFactionVehicle(offset, VehicleType::armedtransport, teamleft); break;
			case map_colors::faction_red_armedtransport: autotile(offset); spawnFactionVehicle(offset, VehicleType::armedtransport, teamright); break;
			case map_colors::faction_blue_apc: autotile(offset); spawnFactionVehicle(offset, VehicleType::apc, teamleft); break;
			case map_colors::faction_red_apc: autotile(offset); spawnFactionVehicle(offset, VehicleType::apc, teamright); break;
			case map_colors::faction_blue_mediumtank: autotile(offset); spawnFactionVehicle(offset, VehicleType::mediumtank, teamleft); break;
			case map_colors::faction_red_mediumtank: autotile(offset); spawnFactionVehicle(offset, VehicleType::mediumtank, teamright); break;
			case map_colors::faction_blue_heavytank: autotile(offset); spawnFactionVehicle(offset, VehicleType::heavytank, teamleft); break;
			case map_colors::faction_red_heavytank: autotile(offset); spawnFactionVehicle(offset, VehicleType::heavytank, teamright); break;
			case map_colors::faction_blue_superheavytank: autotile(offset); spawnFactionVehicle(offset, VehicleType::superheavytank, teamleft); break;
			case map_colors::faction_red_superheavytank: autotile(offset); spawnFactionVehicle(offset, VehicleType::superheavytank, teamright); break;
			case map_colors::faction_blue_artillery: autotile(offset); spawnFactionVehicle(offset, VehicleType::artillery, teamleft); break;
			case map_colors::faction_red_artillery: autotile(offset); spawnFactionVehicle(offset, VehicleType::artillery, teamright); break;
			case map_colors::faction_blue_fighterplane: autotile(offset); spawnFactionVehicle(offset, VehicleType::fighterplane, teamleft); break;
			case map_colors::faction_red_fighterplane: autotile(offset); spawnFactionVehicle(offset, VehicleType::fighterplane, teamright); break;
			case map_colors::faction_blue_bomberplane: autotile(offset); spawnFactionVehicle(offset, VehicleType::bomberplane, teamleft); break;
			case map_colors::faction_red_bomberplane: autotile(offset); spawnFactionVehicle(offset, VehicleType::bomberplane, teamright); break;
			case map_colors::faction_blue_helicopter: autotile(offset); spawnFactionVehicle(offset, VehicleType::helicopter, teamleft); break;
			case map_colors::faction_red_helicopter: autotile(offset); spawnFactionVehicle(offset, VehicleType::helicopter, teamright); break;
			case map_colors::faction_blue_machinegun: autotile(offset); spawnFactionVehicle(offset, VehicleType::machinegun, teamleft); break;
			case map_colors::faction_red_machinegun: autotile(offset); spawnFactionVehicle(offset, VehicleType::machinegun, teamright); break;
			case map_colors::faction_blue_weapons1: autotile(offset); spawnFactionVehicle(offset, VehicleType::weapons1, teamleft); break;
			case map_colors::faction_red_weapons1: autotile(offset); spawnFactionVehicle(offset, VehicleType::weapons1, teamright); break;
			case map_colors::faction_blue_specialvehicle1: autotile(offset); spawnFactionVehicle(offset, VehicleType::special1, teamleft); break;
			case map_colors::faction_red_specialvehicle1: autotile(offset); spawnFactionVehicle(offset, VehicleType::special1, teamright); break;

			case map_colors::refinery:    autotile(offset); spawnBlob(map, "refinery", offset, -1); break;
			case map_colors::advrefinery: autotile(offset); spawnBlob(map, "advancedrefinery", offset, -1); break;

			case map_colors::red_turret:       autotile(offset); spawnVehicle(map, "defenseturret",   offset, teamright); break;
			case map_colors::blue_turret:      autotile(offset); spawnVehicle(map, "defenseturret",   offset, teamleft); break;

			case map_colors::blue_motorcycle:   autotile(offset); spawnVehicle(map, "motorcycle",   offset, teamleft); break;
			case map_colors::red_motorcycle:   autotile(offset); spawnVehicle(map, "motorcycle",   offset, teamright); break;
			case map_colors::blue_armedmotorcycle:   autotile(offset); spawnVehicle(map, "armedmotorcycle",   offset, teamleft); break;
			case map_colors::red_armedmotorcycle:   autotile(offset); spawnVehicle(map, "armedmotorcycle",   offset, teamright); break;

			case map_colors::blue_barge:   autotile(offset); spawnVehicle(map, "barge",   offset, teamleft); break;
			case map_colors::red_barge:   autotile(offset); spawnVehicle(map, "barge",   offset, teamright); break;

			case map_colors::blue_techtruck:   autotile(offset); spawnVehicle(map, "techtruck",   offset, teamleft); break;
			case map_colors::blue_humvee:   autotile(offset); spawnVehicle(map, "humvee",   offset, teamleft); break;
			case map_colors::blue_btr82a:      autotile(offset); spawnVehicle(map, "btr82a",   offset, teamleft); break;
			case map_colors::blue_bmp: 	   autotile(offset); spawnVehicle(map, "bmp",   offset, teamleft); break;
			case map_colors::blue_radarapc: autotile(offset); spawnVehicle(map, "radarapc",   offset, teamleft); break;
			case map_colors::blue_t10:       autotile(offset); spawnVehicle(map, "t10",   offset, teamleft); break;
			case map_colors::blue_m60:         autotile(offset); spawnVehicle(map, "m60",   offset, teamleft); break;
			case map_colors::blue_e50:         autotile(offset); spawnVehicle(map, "e50",   offset, teamleft); break;
			case map_colors::blue_obj430:		 autotile(offset); spawnVehicle(map, "obj430",   offset, teamleft); break;
			case map_colors::blue_kingtiger:         autotile(offset); spawnVehicle(map, "kingtiger",   offset, teamleft); break;
			case map_colors::blue_bc25t:         autotile(offset); spawnVehicle(map, "bc25t",   offset, teamleft); break;
			case map_colors::blue_maus:       autotile(offset); spawnVehicle(map, "maus",   offset, teamleft); break;
			case map_colors::blue_is7:       autotile(offset); spawnVehicle(map, "is7",   offset, teamleft); break;
			case map_colors::blue_m1abrams:       autotile(offset); spawnVehicle(map, "m1abrams",   offset, teamleft); break;
			case map_colors::blue_artillery:       autotile(offset); spawnVehicle(map, "artillery",   offset, teamleft); break;
			case map_colors::blue_m40:       autotile(offset); spawnVehicle(map, "m40",   offset, teamleft); break;
			case map_colors::blue_grad: 	 autotile(offset); spawnVehicle(map, "grad",   offset, teamleft); break;
			case map_colors::blue_bf109:         autotile(offset); spawnVehicle(map, "bf109",   offset, teamleft); break;
			case map_colors::blue_bomberplane:         autotile(offset); spawnVehicle(map, "bomberplane",   offset, teamleft); break;
			case map_colors::blue_uh1:       autotile(offset); spawnVehicle(map, "uh1",   offset, teamleft); break;
			case map_colors::blue_ah1:       autotile(offset); spawnVehicle(map, "ah1",   offset, teamleft); break;
			case map_colors::blue_mi24:       autotile(offset); spawnVehicle(map, "mi24",   offset, teamleft); break;
			case map_colors::blue_nh90:       autotile(offset); spawnVehicle(map, "nh90",   offset, teamleft); break;
			case map_colors::blue_tanktrap:    autotile(offset); spawnVehicle(map, "tanktrap",   offset, teamleft); break;
			case map_colors::blue_cruiser:     autotile(offset); spawnVehicle(map, "cruiser",   offset, teamleft); break;
			case map_colors::blue_scoutboat:     autotile(offset); spawnVehicle(map, "scoutboat",   offset, teamleft); break;
			case map_colors::blue_mortar:     autotile(offset); spawnVehicle(map, "mortar",   offset, teamleft); break;
			case map_colors::red_techtruck:    autotile(offset); spawnVehicle(map, "techtruck",   offset, teamright); break;
			case map_colors::red_humvee:    autotile(offset); spawnVehicle(map, "humvee",   offset, teamright); break;
			case map_colors::red_btr82a:       autotile(offset); spawnVehicle(map, "btr82a",   offset, teamright); break;
			case map_colors::red_radarapc:       autotile(offset); spawnVehicle(map, "radarapc",   offset, teamright); break;
			case map_colors::red_bmp: 	   autotile(offset); spawnVehicle(map, "bmp",   offset, teamright); break;
			case map_colors::red_t10:        autotile(offset); spawnVehicle(map, "t10",   offset, teamright); break;
			case map_colors::red_m60:          autotile(offset); spawnVehicle(map, "m60",   offset, teamright); break;
			case map_colors::red_e50:          autotile(offset); spawnVehicle(map, "e50",   offset, teamright); break;
			case map_colors::red_obj430:          autotile(offset); spawnVehicle(map, "obj430",   offset, teamright); break;
			case map_colors::red_kingtiger:          autotile(offset); spawnVehicle(map, "kingtiger",   offset, teamright); break;
			case map_colors::red_bc25t:          autotile(offset); spawnVehicle(map, "bc25t",   offset, teamright); break;
			case map_colors::red_maus:       autotile(offset); spawnVehicle(map, "maus",   offset, teamright); break;
			case map_colors::red_is7:       autotile(offset); spawnVehicle(map, "is7",   offset, teamright); break;
			case map_colors::red_m1abrams:       autotile(offset); spawnVehicle(map, "m1abrams",   offset, teamright); break;
			case map_colors::red_artillery:       autotile(offset); spawnVehicle(map, "artillery",   offset, teamright); break;
			case map_colors::red_grad: 	 autotile(offset); spawnVehicle(map, "grad",   offset, teamright); break;
			case map_colors::red_m40:       autotile(offset); spawnVehicle(map, "m40",   offset, teamright); break;
			case map_colors::red_bf109:        autotile(offset); spawnVehicle(map, "bf109",   offset, teamright); break;
			case map_colors::red_bomberplane:        autotile(offset); spawnVehicle(map, "bomberplane",   offset, teamright); break;
			case map_colors::red_uh1:          autotile(offset); spawnVehicle(map, "uh1",   offset, teamright); break;
			case map_colors::red_ah1:          autotile(offset); spawnVehicle(map, "ah1",   offset, teamright); break;
			case map_colors::red_mi24:          autotile(offset); spawnVehicle(map, "mi24",   offset, teamright); break;
			case map_colors::red_nh90:          autotile(offset); spawnVehicle(map, "nh90",   offset, teamright); break;
			case map_colors::blue_outpost:          autotile(offset); spawnVehicle(map, "outpost",   offset, teamleft); break;
			case map_colors::red_outpost:          autotile(offset); spawnVehicle(map, "outpost",   offset, teamright); break;
			case map_colors::blue_armory:          autotile(offset); spawnVehicle(map, "armory",   offset, teamleft); break;
			case map_colors::red_armory:          autotile(offset); spawnVehicle(map, "armory",   offset, teamright); break;
			case map_colors::blue_iarmory:          autotile(offset); spawnVehicle(map, "importantarmory",   offset, teamleft); break;
			case map_colors::red_iarmory:          autotile(offset); spawnVehicle(map, "importantarmory",   offset, teamright); break;
			case map_colors::red_tanktrap:     autotile(offset); spawnVehicle(map, "tanktrap",   offset, teamright); break;
			case map_colors::red_cruiser:     autotile(offset); spawnVehicle(map, "cruiser",   offset, teamright); break;
			case map_colors::red_scoutboat:     autotile(offset); spawnVehicle(map, "scoutboat",   offset, teamright); break;
			case map_colors::red_mortar:     autotile(offset); spawnVehicle(map, "mortar",   offset, teamright);	break;
			case map_colors::sign:     autotile(offset); spawnBlob(map, "sign",   offset, teamright);	break;
			case map_colors::sign2:    autotile(offset); spawnBlob(map, "sign2",   offset, teamright);	break;
			case map_colors::sign3:    autotile(offset); spawnBlob(map, "sign3",   offset, teamright);	break;
			case map_colors::sign4:    autotile(offset); spawnBlob(map, "sign4",   offset, teamright);	break;

			case map_colors::civcar:           autotile(offset); spawnVehicle(map, "civcar", offset, 7); break;
			case map_colors::lada:           autotile(offset); spawnVehicle(map, "lada", offset, 7); break;
			case map_colors::arabicspeaker:    autotile(offset); spawnVehicle(map, "boombox", offset); break;
			case map_colors::russianspeaker:    
			{
				autotile(offset); 
				CBlob@ boombox = server_CreateBlobNoInit("boombox");
				if (boombox !is null)
				{
					boombox.set_u8("radio channel", 1);
					boombox.setPosition(map.getTileWorldPosition(offset));
					boombox.Init();
				}
			}
			break;

			case map_colors::chair:         autotile(offset); spawnBlob(map, "chair", offset, 7); break;
			case map_colors::camp:         autotile(offset); spawnBlob(map, "camp", offset, 7); break;

			//zambis
			case map_colors::gate0:         autotile(offset); spawnBlob(map, "gate", offset, teamleft); break;
			case map_colors::gate1:         autotile(offset); spawnBlob(map, "gate", offset, teamright); break;
			case map_colors::gate2:         autotile(offset); spawnBlob(map, "gate", offset, 2); break;
			case map_colors::gate3:         autotile(offset); spawnBlob(map, "gate", offset, 3); break;
			case map_colors::gate4:         autotile(offset); spawnBlob(map, "gate", offset, 4); break;
			case map_colors::zspawn:         autotile(offset); spawnBlob(map, "zspawn", offset, teamleft); break;

			case map_colors::sandbags:    autotile(offset); spawnBlob(map, "sandbags", offset-map.tilemapwidth); break;
			case map_colors::redbarrel:    autotile(offset); spawnBlob(map, "redbarrel", offset-map.tilemapwidth); break;
			case map_colors::pointflag:    autotile(offset); spawnBlob(map, "pointflag", offset); break;
			case map_colors::pointflagt2:	autotile(offset); spawnBlob(map, "pointflagt2", offset); break;
			case map_colors::core_blue:    autotile(offset); spawnBlob(map, "core", offset, teamleft); break;
			case map_colors::core_red:     autotile(offset); spawnBlob(map, "core", offset, teamright); break;
			case map_colors::blue_core_gamemode : 	autotile(offset); AddMarkerPTB(map, offset, "ptb blue");       break;
			case map_colors::red_core_gamemode : 	autotile(offset); AddMarkerPTB(map, offset, "ptb red");       break;
			case map_colors::core_zone:         	autotile(offset); AddMarkerPTB(map, offset, "core zone");       break;
			case map_colors::cobweb:        autotile(offset); spawnBlob(map, "cobweb", offset); break;
			case map_colors::deadbush:      autotile(offset); spawnBlob(map, "deadbush", offset); break;
			case map_colors::cacti:    		autotile(offset); spawnBlob(map, "cacti", offset); break;

			case map_colors::hanginglantern:    autotile(offset); spawnBlob(map, "hanginglantern", offset); break;
			case map_colors::bonepile:    autotile(offset); spawnBlob(map, "bonepile", offset); break;
			case map_colors::crashedheli:    autotile(offset); spawnBlob(map, "crashedheli", offset); break;

			case map_colors::blue_munitionsshop:        autotile(offset); spawnBlob(map, "munitionsshop", offset, teamleft); break;
			case map_colors::red_munitionsshop:         autotile(offset); spawnBlob(map, "munitionsshop", offset, teamright); break;
			case map_colors::blue_munitionsyard:        autotile(offset); spawnBlob(map, "munitionsyard", offset, teamleft); break;
			case map_colors::red_munitionsyard:         autotile(offset); spawnBlob(map, "munitionsyard", offset, teamright); break;

			case map_colors::blue_russianshop:        autotile(offset); spawnBlob(map, "russianshop", offset, teamleft); break;
			case map_colors::red_russianshop:         autotile(offset); spawnBlob(map, "russianshop", offset, teamright); break;

			case map_colors::m2browning:         		autotile(offset); spawnVehicle(map, "m2browning", offset); break;
			case map_colors::cratem2browning:    		autotile(offset); server_MakeCrate("m2browning", "Crate with M2 Browning", 0, -1, getSpawnPosition(map, offset)); break;
			case map_colors::mg42:         				autotile(offset); spawnVehicle(map, "mg42", offset); break;
			case map_colors::cratemg42:    				autotile(offset); server_MakeCrate("mg42", "Crate with MG42", 0, -1, getSpawnPosition(map, offset)); break;
			case map_colors::apsniper: 					autotile(offset); spawnVehicle(map, "apsniper", offset); break;
			case map_colors::mortar: 					autotile(offset); spawnVehicle(map, "mortar", offset); break;
			case map_colors::javelin_launcher: 			autotile(offset); spawnVehicle(map, "javelin_launcher", offset); break;
			case map_colors::pak38: 					autotile(offset); spawnVehicle(map, "pak38", offset); break;

			case map_colors::heats:       			 	autotile(offset); spawnBlob(map, "mat_heatwarhead", offset); break;
			case map_colors::ammocrate:        			autotile(offset); spawnBlob(map, "ammocrate", offset); break;
			case map_colors::repairstation:        		autotile(offset); spawnBlob(map, "repairstation", offset); break;
			case map_colors::blue_bunker:        		autotile(offset); spawnBlob(map, "bunker", offset, teamleft); break;
			case map_colors::red_bunker:        		autotile(offset); spawnBlob(map, "bunker", offset, teamright); break;
			case map_colors::blue_heavybunker:        	autotile(offset); spawnBlob(map, "heavybunker", offset, teamleft); break;
			case map_colors::red_heavybunker:       	autotile(offset); spawnBlob(map, "heavybunker", offset, teamright); break;
			case map_colors::stairs:        			autotile(offset); spawnBlob(map, "stairs", offset); break;
			case map_colors::minesign:       	 		autotile(offset); spawnBlob(map, "minesign", offset); break;

			case map_colors::tickets10:        autotile(offset); spawnBlob(map, "ticket_10", offset); break;
			case map_colors::tickets25:        autotile(offset); spawnBlob(map, "ticket_25", offset); break;
			case map_colors::tickets35:        autotile(offset); spawnBlob(map, "ticket_35", offset); break;
			case map_colors::tickets50:        autotile(offset); spawnBlob(map, "ticket_50", offset); break;
			case map_colors::tickets75:        autotile(offset); spawnBlob(map, "ticket_75", offset); break;
			case map_colors::tickets90:        autotile(offset); spawnBlob(map, "ticket_90", offset); break;
			case map_colors::tickets115:       autotile(offset); spawnBlob(map, "ticket_115", offset); break;
			case map_colors::tickets130:       autotile(offset); spawnBlob(map, "ticket_130", offset); break;
			case map_colors::tickets150:       autotile(offset); spawnBlob(map, "ticket_150", offset); break;
			
			case map_colors::barbedwire:        autotile(offset); spawnBlob(map, "barbedwire", offset, -1); break;
			case map_colors::blue_barbedwire:        autotile(offset); spawnBlob(map, "barbedwire", offset, teamleft); break;
			case map_colors::red_barbedwire:        autotile(offset); spawnBlob(map, "barbedwire", offset, teamright); break;

			case map_colors::constructionyard:     autotile(offset); spawnBlob(map, "constructionyard", offset); break;
			case map_colors::baseconstructionyard:     autotile(offset); spawnBlob(map, "baseconstructionyard", offset); break;

			case map_colors::b_vehiclebuilder:     autotile(offset); spawnBlob(map, "vehiclebuilder", offset, teamleft); break;
			case map_colors::r_vehiclebuilder:     autotile(offset); spawnBlob(map, "vehiclebuilder", offset, teamright); break;
			case map_colors::b_vehiclebuildert2:    autotile(offset); spawnBlob(map, "vehiclebuildert2", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2:    autotile(offset); spawnBlob(map, "vehiclebuildert2", offset, teamright); break;
			case map_colors::b_vehiclebuildert3:    autotile(offset); spawnBlob(map, "vehiclebuildert3", offset, teamleft); break;
			case map_colors::r_vehiclebuildert3:    autotile(offset); spawnBlob(map, "vehiclebuildert3", offset, teamright); break;

			case map_colors::b_vehiclebuilderconst:     autotile(offset); spawnBlob(map, "vehiclebuilderconst", offset, teamleft); break;
			case map_colors::r_vehiclebuilderconst:     autotile(offset); spawnBlob(map, "vehiclebuilderconst", offset, teamright); break;
			case map_colors::b_vehiclebuildert2const:    autotile(offset); spawnBlob(map, "vehiclebuildert2const", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2const:    autotile(offset); spawnBlob(map, "vehiclebuildert2const", offset, teamright); break;

			case map_colors::b_vehiclebuilderground:     autotile(offset); spawnBlob(map, "vehiclebuilderground", offset, teamleft); break;
			case map_colors::r_vehiclebuilderground:     autotile(offset); spawnBlob(map, "vehiclebuilderground", offset, teamright); break;
			case map_colors::b_vehiclebuildert2ground:    autotile(offset); spawnBlob(map, "vehiclebuildert2ground", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2ground:    autotile(offset); spawnBlob(map, "vehiclebuildert2ground", offset, teamright); break;
			case map_colors::b_vehiclebuildert3ground:    autotile(offset); spawnBlob(map, "vehiclebuildert3ground", offset, teamleft); break;
			case map_colors::r_vehiclebuildert3ground:    autotile(offset); spawnBlob(map, "vehiclebuildert3ground", offset, teamright); break;

			case map_colors::b_vehiclebuildergroundconst:     autotile(offset); spawnBlob(map, "vehiclebuildergroundconst", offset, teamleft); break;
			case map_colors::r_vehiclebuildergroundconst:     autotile(offset); spawnBlob(map, "vehiclebuildergroundconst", offset, teamright); break;
			case map_colors::b_vehiclebuildert2groundconst:    autotile(offset); spawnBlob(map, "vehiclebuildert2groundconst", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2groundconst:    autotile(offset); spawnBlob(map, "vehiclebuildert2groundconst", offset, teamright); break;
			case map_colors::b_vehiclebuildert3groundconst:    autotile(offset); spawnBlob(map, "vehiclebuildert3groundconst", offset, teamleft); break;
			case map_colors::r_vehiclebuildert3groundconst:    autotile(offset); spawnBlob(map, "vehiclebuildert3groundconst", offset, teamright); break;

			case map_colors::b_vehiclebuilderair:     autotile(offset); spawnBlob(map, "vehiclebuilderair", offset, teamleft); break;
			case map_colors::r_vehiclebuilderair:     autotile(offset); spawnBlob(map, "vehiclebuilderair", offset, teamright); break;
			case map_colors::b_vehiclebuildert2air:    autotile(offset); spawnBlob(map, "vehiclebuildert2air", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2air:    autotile(offset); spawnBlob(map, "vehiclebuildert2air", offset, teamright); break;

			case map_colors::b_vehiclebuilderairconst:     autotile(offset); spawnBlob(map, "vehiclebuilderairconst", offset, teamleft); break;
			case map_colors::r_vehiclebuilderairconst:     autotile(offset); spawnBlob(map, "vehiclebuilderairconst", offset, teamright); break;
			case map_colors::b_vehiclebuildert2airconst:    autotile(offset); spawnBlob(map, "vehiclebuildert2airconst", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2airconst:    autotile(offset); spawnBlob(map, "vehiclebuildert2airconst", offset, teamright); break;

			case map_colors::b_vehiclebuilderdefense:     autotile(offset); spawnBlob(map, "vehiclebuilderdefense", offset, teamleft); break;
			case map_colors::r_vehiclebuilderdefense:     autotile(offset); spawnBlob(map, "vehiclebuilderdefense", offset, teamright); break;
			case map_colors::b_vehiclebuildert2defense:    autotile(offset); spawnBlob(map, "vehiclebuildert2defense", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2defense:    autotile(offset); spawnBlob(map, "vehiclebuildert2defense", offset, teamright); break;
			case map_colors::b_vehiclebuilderdefenseconst:     autotile(offset); spawnBlob(map, "vehiclebuilderdefenseconst", offset, teamleft); break;
			case map_colors::r_vehiclebuilderdefenseconst:     autotile(offset); spawnBlob(map, "vehiclebuilderdefenseconst", offset, teamright); break;
			case map_colors::b_vehiclebuildert2defenseconst:    autotile(offset); spawnBlob(map, "vehiclebuildert2defenseconst", offset, teamleft); break;
			case map_colors::r_vehiclebuildert2defenseconst:    autotile(offset); spawnBlob(map, "vehiclebuildert2defenseconst", offset, teamright); break;

			case map_colors::jourcop: 			   autotile(offset); spawnBlob(map, "jourcop", offset, 100); break;

			// Ammo
			case map_colors::bombs:       autotile(offset); AddMarker(map, offset, "mat_bombs"); break;
			case map_colors::waterbombs:  autotile(offset); spawnBlob(map, "mat_waterbombs",  offset); break;
			case map_colors::arrows:      autotile(offset); spawnBlob(map, "mat_arrows",      offset); break;
			case map_colors::bombarrows:  autotile(offset); spawnBlob(map, "mat_bombarrows",  offset); break;
			case map_colors::waterarrows: autotile(offset); spawnBlob(map, "mat_waterarrows", offset); break;
			case map_colors::firearrows:  autotile(offset); spawnBlob(map, "mat_firearrows",  offset); break;
			case map_colors::bolts:       autotile(offset); spawnBlob(map, "mat_bolts",       offset); break;

			// Mines, explosives
			case map_colors::blue_mine:   autotile(offset); spawnBlob(map, "mine", offset, teamleft); break;
			case map_colors::red_mine:    autotile(offset); spawnBlob(map, "mine", offset, teamright); break;
			case map_colors::mine_noteam: autotile(offset); spawnBlob(map, "mine", offset); break;
			case map_colors::boulder:     autotile(offset); spawnBlob(map, "boulder", offset, -1, false, Vec2f(8.0f, -8.0f)); break;
			case map_colors::satchel:     autotile(offset); spawnBlob(map, "satchel", offset); break;
			case map_colors::keg:         autotile(offset); spawnBlob(map, "keg", offset); break;

			// Materials
			case map_colors::gold:        autotile(offset); spawnBlob(map, "mat_gold", offset); break;
			case map_colors::stone:       autotile(offset); spawnBlob(map, "mat_stone", offset); break;
			case map_colors::wood:        autotile(offset); spawnBlob(map, "mat_wood", offset); break;

			// Mooks
			case map_colors::mook_knight:     autotile(offset); AddMarker(map, offset, "mook knight"); break;
			case map_colors::mook_archer:     autotile(offset); AddMarker(map, offset, "mook archer"); break;
			case map_colors::mook_spawner:    autotile(offset); AddMarker(map, offset, "mook spawner"); break;
			case map_colors::mook_spawner_10: autotile(offset); AddMarker(map, offset, "mook spawner 10"); break;
			case map_colors::dummy:           autotile(offset); spawnBlob(map, "dummy", offset, 1, true); break;

			// Backgrounds
			case map_colors::map_desert: autotile(offset); spawnBlob(map, "info_desert", offset); break;
			case map_colors::map_grim: autotile(offset); spawnBlob(map, "info_grim", offset); break;
			case map_colors::map_snow: autotile(offset); spawnBlob(map, "info_snow", offset); break;

			default:
				//HandleCustomTile( map, offset, pixel );
			};
		}
	}

	//override this to add post-load offset types.
	void handleOffset(int type, int offset, int position, int count)
	{
		switch (type)
		{
		case autotile_offset:
			PlaceMostLikelyTile(map, offset);
		break;
		case tree_offset:
		{
			// load trees only at the ground
			if(!map.isTileSolid(map.getTile(offset + map.tilemapwidth))) return;

			CBlob@ tree = server_CreateBlobNoInit( map_random.NextRanged(35) < 21 ? "tree_pine" : "tree_bushy" );
			if(tree !is null)
			{
				tree.Tag("startbig");
				tree.setPosition( getSpawnPosition( map, offset ) );
				tree.Init();
				if (map.getTile(offset).type == CMap::tile_empty)
				{
					map.SetTile(offset, CMap::tile_grass + map_random.NextRanged(3) );
				}
			}
		}
		break;
		case bush_offset:
			server_CreateBlob("bush", -1, map.getTileWorldPosition(offset) + Vec2f(4, 4));
		break;
		case grain_offset:
		{
			CBlob@ grain = server_CreateBlobNoInit("grain_plant");
			if(grain !is null)
			{
				grain.Tag("instant_grow");
				grain.setPosition( map.getTileWorldPosition(offset) + Vec2f(4, 4));
				grain.Init();
			}
		}
		break;
		case spike_offset:
			spawnBlob(map, "spikes", -1, map.getTileWorldPosition(offset) + Vec2f(4, 4), true);
		break;
		case ladder_offset:
			spawnLadder(map, offset);
		break; //h12
		};
	}

	void SetupMap(int width, int height)
	{
		map.CreateTileMap(width, height, 8.0f, "Tilesets/world.png");
		/*
		if (map_type == 0)
		{
			map.CreateTileMap(width, height, 8.0f, "Tilesets/world.png");
		}
		else
		{
			map.CreateTileMap(width, height, 8.0f, "Tilesets/worlddesert.png");
		}*/
	}

	void SetupBackgrounds()
	{
		CRules@ thisrules = getRules();

		switch (thisrules.get_u8("map_type"))
		{
			// Tiles
			case 0: //default
			{
				map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
				map.CreateSkyGradient("Sprites/skygradient.png"); // override sky color with gradient
				thisrules.set_bool("allowclouds", true);
				thisrules.set_u8("brightmod", 50);

				map.AddBackground("Backgrounds/BackgroundPlains.png", Vec2f(0.0f, -38.0f), Vec2f(0.2f, 0.2f), color_white);
				map.AddBackground("Backgrounds/BackgroundCastle.png", Vec2f(0.0f, -120.0f), Vec2f(0.35f, 0.35f), color_white);
				map.AddBackground("Backgrounds/BackgroundTrees.png", Vec2f(0.0f,  -35.0f), Vec2f(0.4f, 0.4f), color_white);
				map.AddBackground("Backgrounds/BackgroundIsland.png", Vec2f(0.0f, 40.0f), Vec2f(0.5f, 0.5f), color_white);

				SetScreenFlash(255,   0,   0,   0,   1.75);
				break;
			}
			case 1: //desert
			{
				map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
				map.CreateSkyGradient("Sprites/skygradientdesert.png"); // override sky color with gradient
				thisrules.set_bool("allowclouds", false);
				thisrules.set_u8("brightmod", 100);

				map.AddBackground("Backgrounds/BackgroundDesertDetail.png", Vec2f(0.0f, -15.0f), Vec2f(0.055f, 0.5f), color_white);
				map.AddBackground("Backgrounds/BackgroundDesertRocky.png",  Vec2f(27.0f, -20.0f), Vec2f(0.12f, 0.5f), color_white);
				map.AddBackground("Backgrounds/BackgroundDesert.png",       Vec2f(5.0f, -8.0f), Vec2f(0.25f, 2.0f), color_white);
				map.AddBackground("Backgrounds/BackgroundDunes.png",        Vec2f(0.0f,  -7.0f), Vec2f(0.5f, 2.5f), color_white);

				SetScreenFlash(255,   0,   0,   0,   1.75);
				break;
			}
			case 2: //grim
			{
				map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
				map.CreateSkyGradient("Sprites/skygradient.png"); // override sky color with gradient
				thisrules.set_bool("allowclouds", true);
				thisrules.set_u8("brightmod", 0); //100
				
				map.AddBackground("Backgrounds/BackgroundTrees.png", Vec2f(0.0f,  -35.0f), Vec2f(0.4f, 0.4f), color_white);
				map.AddBackground("Backgrounds/City.png", Vec2f(0.0f, -38.0f), Vec2f(0.2f, 0.2f), color_white);
				map.AddBackground("Backgrounds/Forest.png", Vec2f(0.0f, -120.0f), Vec2f(0.35f, 0.35f), color_white);

				SetScreenFlash(255,   0,   0,   0,   6.5);
				break;
			}
			case 3: //snow
			{
				map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0); // sky
				map.CreateSkyGradient("Sprites/skygradient.png"); // override sky color with gradient
				thisrules.set_bool("allowclouds", true);
				thisrules.set_u8("brightmod", 50);
				
				map.AddBackground("Backgrounds/Snow_BackgroundPlains.png", Vec2f(0.0f, -38.0f), Vec2f(0.2f, 0.2f), color_white);
				map.AddBackground("Backgrounds/Snow_BackgroundTrees.png", Vec2f(0.0f,  -35.0f), Vec2f(0.4f, 0.4f), color_white);
				
				SetScreenFlash(255,   0,   0,   0,   1.75);
				break;
			}
		}
	}

	CBlob@ spawnLadder(CMap@ map, int offset)
	{
		bool up = false, down = false, right = false, left = false;
		int[]@ ladders = offsets[ladder_offset];
		for (uint step = 0; step < ladders.length; ++step)
		{
			const int lof = ladders[step];
			if (lof == offset-map.tilemapwidth) {
				up = true;
			}
			if (lof == offset+map.tilemapwidth) {
				down = true;
			}
			if (lof == offset+1) {
				right = true;
			}
			if (lof == offset-1) {
				left = true;
			}
		}
		if ( offset % 2 == 0 && ((left && right) || (up && down)) )
		{
			return null;
		}

		CBlob@ blob = server_CreateBlob( "ladder", -1, getSpawnPosition( map, offset) );
		if (blob !is null)
		{
			// check for horizontal placement
			for (uint step = 0; step < ladders.length; ++step)
			{
				if (ladders[step] == offset-1 || ladders[step] == offset+1)
				{
					blob.setAngleDegrees( 90.0f );
					break;
				}
			}
			blob.getShape().SetStatic( true );
			blob.server_setTeamNum(-1);
		}
		return blob;
	}
}

void PlaceMostLikelyTile(CMap@ map, int offset)
{
	const TileType up = map.getTile(offset - map.tilemapwidth).type;
	const TileType down = map.getTile(offset + map.tilemapwidth).type;
	const TileType left = map.getTile(offset - 1).type;
	const TileType right = map.getTile(offset + 1).type;

	if (up != CMap::tile_empty)
	{
		const TileType[] neighborhood = { up, down, left, right };

		if ((neighborhood.find(CMap::tile_castle) != -1) ||
		    (neighborhood.find(CMap::tile_castle_back) != -1))
		{
			map.SetTile(offset, CMap::tile_castle_back);
		}
		else if ((neighborhood.find(CMap::tile_wood) != -1) ||
		         (neighborhood.find(CMap::tile_wood_back) != -1))
		{
			map.SetTile(offset, CMap::tile_wood_back );
		}
		else if ((neighborhood.find(CMap::tile_ground) != -1) ||
		         (neighborhood.find(CMap::tile_ground_back) != -1))
		{
			map.SetTile(offset, CMap::tile_ground_back);
		}
	}
	else if(map.isTileSolid(down) && (map.isTileGrass(left) || map.isTileGrass(right)))
	{
		map.SetTile(offset, CMap::tile_grass + 2 + map_random.NextRanged(2));
	}
}

CBlob@ spawnHall(CMap@ map, int offset, u8 team)
{
	CBlob@ hall = spawnBlob(map, "hall", offset, team);
	if (hall !is null) // add research to first hall
	{
		hall.AddScript("Researching.as");
		hall.Tag("script added");
	}
	return @hall;
}

CBlob@ spawnVehicle(CMap@ map, const string& in name, int offset, int team = -1)
{
	CBlob@ blob = server_CreateBlob(name, team, getSpawnPosition( map, offset));
	if(blob !is null)
	{
		blob.RemoveScript("DecayIfLeftAlone.as");
	}
	return blob;
}

void AddMarker(CMap@ map, int offset, const string& in name)
{
	map.AddMarker(map.getTileWorldPosition(offset), name);
}

void AddMarkerPTB(CMap@ map, int offset, const string& in name)
{
	AddMarker(map, offset, name);
	
	CRules@ rules = getRules();
	if (rules !is null)
	{
		rules.set_bool("ptb", true);

		bool ptb_blue = name == "ptb blue";
		bool ptb_red = name == "ptb red";
		if (ptb_blue || ptb_red) 
			rules.set_s8("ptb side", ptb_blue ? 0 : 1);
		
		Vec2f[]@ core_zones;
		if (!rules.get("core_zones", @core_zones))
		{
			Vec2f[] core_zones_new;

			core_zones_new.push_back(map.getTileWorldPosition(offset));
			rules.set("core_zones", @core_zones_new);
		}
		else 
		{
			core_zones.push_back(map.getTileWorldPosition(offset));
		}
	}
}

void SaveMap(CMap@ map, const string &in fileName)
{
	const u32 width = map.tilemapwidth;
	const u32 height = map.tilemapheight;
	const u32 space = width * height;

	CFileImage image(width, height, true);
	image.setFilename(fileName, IMAGE_FILENAME_BASE_MAPS);

	// image starts at -1, 0
	image.nextPixel();

	// iterate through tiles
	for(uint i = 0; i < space; i++)
	{
		SColor color = getColorFromTileType(map.getTile(i).type);
		if(map.isInWater(map.getTileWorldPosition(i)))
		{
			if(color == map_colors::sky)
			{
				color = map_colors::water_air;
			}
			else
			{
				color = map_colors::water_backdirt;
			}
		}
		image.setPixelAndAdvance(color);
	}

	// iterate through blobs
	CBlob@[] blobs;
	getBlobs(@blobs);
	for(uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if(blob.getShape() is null) continue;

		SColor color;
		Vec2f offset;

		getInfoFromBlob(blob, color, offset);
		if(color == map_colors::unused) continue;

		const Vec2f position = map.getTileSpacePosition(blob.getPosition() + offset);

		image.setPixelAtPosition(position.x, position.y, color, false);
	}

	// iterate through markers
	const array<string> TEAM_NAME =
	{
		"blue",
		"red",
		"green",
		"purple",
		"orange",
		"aqua",
		"teal",
		"gray"
	};

	for(u8 i = 0; i < TEAM_NAME.length; i++)
	{
		array<Vec2f> position;

		SColor color;

		if(map.getMarkers(TEAM_NAME[i]+" main spawn", @position))
		{
			for(u8 j = 0; j < position.length; j++)
			{
				color = map_colors::alpha_spawn;
				color.setAlpha(0x80 | getChannelFromTeam(i));
				position[j] = map.getTileSpacePosition(position[j]);

				image.setPixelAtPosition(position[j].x, position[j].y, color, false);
			}
		}

		position.clear();
		if(map.getMarkers(TEAM_NAME[i]+" spawn", @position))
		{
			for(u8 j = 0; j < position.length; j++)
			{
				color = map_colors::alpha_flag;
				color.setAlpha(0x80 | getChannelFromTeam(i));
				position[j] = map.getTileSpacePosition(position[j]);

				image.setPixelAtPosition(position[j].x, position[j].y, color, false);
			}
		}
	}

	image.Save();
}

void getInfoFromBlob(CBlob@ this, SColor &out color, Vec2f &out offset)
{
	const string name = this.getName();

	// declare some default values
	color = map_colors::unused;
	offset = Vec2f_zero;

	// BLOCKS
	if(this.getShape().isStatic())
	{
		if(name == "ladder")
		{
			color = map_colors::alpha_ladder;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "spikes")
		{
			color = map_colors::alpha_spikes;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "stone_door")
		{
			color = map_colors::alpha_stone_door;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "trap_block")
		{
			color = map_colors::alpha_trap_block;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "wooden_door")
		{
			color = map_colors::alpha_wooden_door;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "wooden_platform")
		{
			color = map_colors::alpha_wooden_platform;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		// MECHANISMS
		else if(name == "coin_slot")
		{
			color = map_colors::alpha_coin_slot;
			color.setAlpha(getChannelFromTeam(255));
		}
		else if(name == "lever")
		{
			color = map_colors::alpha_lever;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "pressure_plate")
		{
			color = map_colors::alpha_pressure_plate;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
		}
		else if(name == "push_button")
		{
			color = map_colors::alpha_push_button;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "sensor")
		{
			color = map_colors::alpha_sensor;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "diode")
		{
			color = map_colors::alpha_diode;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "elbow")
		{
			color = map_colors::alpha_elbow;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "emitter")
		{
			color = map_colors::alpha_emitter;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "inverter")
		{
			color = map_colors::alpha_inverter;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "junction")
		{
			color = map_colors::alpha_junction;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "magazine")
		{
			color = map_colors::alpha_magazine;

			const string[] MAGAZINE_ITEM = {
			"mat_bombs",
			"mat_waterbombs",
			"mat_arrows",
			"mat_waterarrows",
			"mat_firearrows",
			"mat_bombarrows",
			"food"};

			u8 alpha = MAGAZINE_ITEM.length;

			CInventory@ inventory = this.getInventory();
			if(inventory.isFull())
			{
				CBlob@ blob = inventory.getItem(0);

				s8 element = MAGAZINE_ITEM.find(blob.getName());
				if(element != -1)
				{
					alpha = element;
				}
			}
			color.setAlpha(alpha);
		}
		else if(name == "oscillator")
		{
			color = map_colors::alpha_oscillator;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "randomizer")
		{
			color = map_colors::alpha_randomizer;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "receiver")
		{
			color = map_colors::alpha_receiver;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "resistor")
		{
			color = map_colors::alpha_resistor;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "tee")
		{
			color = map_colors::alpha_tee;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "toggle")
		{
			color = map_colors::alpha_toggle;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "transistor")
		{
			color = map_colors::alpha_transistor;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "wire")
		{
			color = map_colors::alpha_wire;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "bolter")
		{
			color = map_colors::alpha_bolter;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
		}
		else if(name == "dispenser")
		{
			color = map_colors::alpha_dispenser;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
		}
		else if(name == "lamp")
		{
			color = map_colors::alpha_lamp;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "obstructor")
		{
			color = map_colors::alpha_obstructor;
			color.setAlpha(getChannelFromTeam(this.getTeamNum()));
		}
		else if(name == "spiker")
		{
			color = map_colors::alpha_spiker;
			color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
		}
	}

	// FLORA
	if(name == "bush")
	{
		color = map_colors::bush;
	}
	else if(name == "flowers")
	{
		color = map_colors::flowers;
	}
	else if(name == "grain_plant")
	{
		color = map_colors::grain;
	}
	else if(name == "tree_pine" || name == "tree_bushy")
	{
		color = map_colors::tree;
	}
	// FAUNA
	else if(name == "bison")
	{
		color = map_colors::bison;
	}
	else if(name == "chicken")
	{
		color = map_colors::chicken;
	}
	else if(name == "fishy")
	{
		color = map_colors::fish;
	}
	else if(name == "shark")
	{
		color = map_colors::shark;
	}

	// set last bit to true so the minimum alpha is 128
	u8 alpha = color.getAlpha();
	if(alpha != 0xFF)
	{
		color.setAlpha(0x80 | alpha);
	}
}

SColor getColorFromTileType(TileType tile)
{
	if(tile >= TILE_LUT.length)
	{
		return map_colors::unused;
	}
	return TILE_LUT[tile];
}

const SColor[] TILE_LUT = {
map_colors::unused,                // |   0 |
map_colors::unused,                // |   1 |
map_colors::unused,                // |   2 |
map_colors::unused,                // |   3 |
map_colors::unused,                // |   4 |
map_colors::unused,                // |   5 |
map_colors::unused,                // |   6 |
map_colors::unused,                // |   7 |
map_colors::unused,                // |   8 |
map_colors::unused,                // |   9 |
map_colors::unused,                // |  10 |
map_colors::unused,                // |  11 |
map_colors::unused,                // |  12 |
map_colors::unused,                // |  13 |
map_colors::unused,                // |  14 |
map_colors::unused,                // |  15 |
map_colors::tile_ground,           // |  16 |
map_colors::tile_ground,           // |  17 |
map_colors::tile_ground,           // |  18 |
map_colors::tile_ground,           // |  19 |
map_colors::tile_ground,           // |  20 |
map_colors::tile_ground,           // |  21 |
map_colors::tile_ground,           // |  22 |
map_colors::tile_ground,           // |  23 |
map_colors::tile_ground,           // |  24 |
map_colors::tile_grass,            // |  25 |
map_colors::tile_grass,            // |  26 |
map_colors::tile_grass,            // |  27 |
map_colors::tile_grass,            // |  28 |
map_colors::tile_ground,           // |  29 | damaged
map_colors::tile_ground,           // |  30 | damaged
map_colors::tile_ground,           // |  31 | damaged
map_colors::tile_ground_back,      // |  32 |
map_colors::tile_ground_back,      // |  33 |
map_colors::tile_ground_back,      // |  34 |
map_colors::tile_ground_back,      // |  35 |
map_colors::tile_ground_back,      // |  36 |
map_colors::tile_ground_back,      // |  37 |
map_colors::tile_ground_back,      // |  38 |
map_colors::tile_ground_back,      // |  39 |
map_colors::tile_ground_back,      // |  40 |
map_colors::tile_ground_back,      // |  41 |
map_colors::unused,                // |  42 |
map_colors::unused,                // |  43 |
map_colors::unused,                // |  44 |
map_colors::unused,                // |  45 |
map_colors::unused,                // |  46 |
map_colors::unused,                // |  47 |
map_colors::tile_castle,           // |  48 |
map_colors::tile_castle,           // |  49 |
map_colors::tile_castle,           // |  50 |
map_colors::tile_castle,           // |  51 |
map_colors::tile_castle,           // |  52 |
map_colors::tile_castle,           // |  53 |
map_colors::tile_castle,           // |  54 |
map_colors::unused,                // |  55 |
map_colors::unused,                // |  56 |
map_colors::unused,                // |  57 |
map_colors::tile_castle,           // |  58 | damaged
map_colors::tile_castle,           // |  59 | damaged
map_colors::tile_castle,           // |  60 | damaged
map_colors::tile_castle,           // |  61 | damaged
map_colors::tile_castle,           // |  62 | damaged
map_colors::tile_castle,           // |  63 | damaged
map_colors::tile_castle_back,      // |  64 |
map_colors::tile_castle_back,      // |  65 |
map_colors::tile_castle_back,      // |  66 |
map_colors::tile_castle_back,      // |  67 |
map_colors::tile_castle_back,      // |  68 |
map_colors::tile_castle_back,      // |  69 |
map_colors::unused,                // |  70 |
map_colors::unused,                // |  71 |
map_colors::unused,                // |  72 |
map_colors::unused,                // |  73 |
map_colors::unused,                // |  74 |
map_colors::unused,                // |  75 |
map_colors::tile_castle_back,      // |  76 | damaged
map_colors::tile_castle_back,      // |  77 | damaged
map_colors::tile_castle_back,      // |  78 | damaged
map_colors::tile_castle_back,      // |  79 | damaged
map_colors::tile_gold,             // |  80 |
map_colors::tile_gold,             // |  81 |
map_colors::tile_gold,             // |  82 |
map_colors::tile_gold,             // |  83 |
map_colors::tile_gold,             // |  84 |
map_colors::tile_gold,             // |  85 |
map_colors::unused,                // |  86 |
map_colors::unused,                // |  87 |
map_colors::unused,                // |  88 |
map_colors::unused,                // |  89 |
map_colors::tile_gold,             // |  90 | damaged
map_colors::tile_gold,             // |  91 | damaged
map_colors::tile_gold,             // |  92 | damaged
map_colors::tile_gold,             // |  93 | damaged
map_colors::tile_gold,             // |  94 | damaged
map_colors::unused,                // |  95 |
map_colors::tile_stone,            // |  96 |
map_colors::tile_stone,            // |  97 |
map_colors::unused,                // |  98 |
map_colors::unused,                // |  99 |
map_colors::tile_stone,            // | 100 | damaged
map_colors::tile_stone,            // | 101 | damaged
map_colors::tile_stone,            // | 102 | damaged
map_colors::tile_stone,            // | 103 | damaged
map_colors::tile_stone,            // | 104 | damaged
map_colors::unused,                // | 105 |
map_colors::tile_bedrock,          // | 106 |
map_colors::tile_bedrock,          // | 107 |
map_colors::tile_bedrock,          // | 108 |
map_colors::tile_bedrock,          // | 109 |
map_colors::tile_bedrock,          // | 110 |
map_colors::tile_bedrock,          // | 111 |
map_colors::unused,                // | 112 |
map_colors::unused,                // | 113 |
map_colors::unused,                // | 114 |
map_colors::unused,                // | 115 |
map_colors::unused,                // | 116 |
map_colors::unused,                // | 117 |
map_colors::unused,                // | 118 |
map_colors::unused,                // | 119 |
map_colors::unused,                // | 120 |
map_colors::unused,                // | 121 |
map_colors::unused,                // | 122 |
map_colors::unused,                // | 123 |
map_colors::unused,                // | 124 |
map_colors::unused,                // | 125 |
map_colors::unused,                // | 126 |
map_colors::unused,                // | 127 |
map_colors::unused,                // | 128 |
map_colors::unused,                // | 129 |
map_colors::unused,                // | 130 |
map_colors::unused,                // | 131 |
map_colors::unused,                // | 132 |
map_colors::unused,                // | 133 |
map_colors::unused,                // | 134 |
map_colors::unused,                // | 135 |
map_colors::unused,                // | 136 |
map_colors::unused,                // | 137 |
map_colors::unused,                // | 138 |
map_colors::unused,                // | 139 |
map_colors::unused,                // | 140 |
map_colors::unused,                // | 141 |
map_colors::unused,                // | 142 |
map_colors::unused,                // | 143 |
map_colors::unused,                // | 144 |
map_colors::unused,                // | 145 |
map_colors::unused,                // | 146 |
map_colors::unused,                // | 147 |
map_colors::unused,                // | 148 |
map_colors::unused,                // | 149 |
map_colors::unused,                // | 150 |
map_colors::unused,                // | 151 |
map_colors::unused,                // | 152 |
map_colors::unused,                // | 153 |
map_colors::unused,                // | 154 |
map_colors::unused,                // | 155 |
map_colors::unused,                // | 156 |
map_colors::unused,                // | 157 |
map_colors::unused,                // | 158 |
map_colors::unused,                // | 159 |
map_colors::unused,                // | 160 |
map_colors::unused,                // | 161 |
map_colors::unused,                // | 162 |
map_colors::unused,                // | 163 |
map_colors::unused,                // | 164 |
map_colors::unused,                // | 165 |
map_colors::unused,                // | 166 |
map_colors::unused,                // | 167 |
map_colors::unused,                // | 168 |
map_colors::unused,                // | 169 |
map_colors::unused,                // | 170 |
map_colors::unused,                // | 171 |
map_colors::unused,                // | 172 |
map_colors::tile_wood_back,        // | 173 |
map_colors::unused,                // | 174 |
map_colors::unused,                // | 175 |
map_colors::unused,                // | 176 |
map_colors::unused,                // | 177 |
map_colors::unused,                // | 178 |
map_colors::unused,                // | 179 |
map_colors::unused,                // | 180 |
map_colors::unused,                // | 181 |
map_colors::unused,                // | 182 |
map_colors::unused,                // | 183 |
map_colors::unused,                // | 184 |
map_colors::unused,                // | 185 |
map_colors::unused,                // | 186 |
map_colors::unused,                // | 187 |
map_colors::unused,                // | 188 |
map_colors::unused,                // | 189 |
map_colors::unused,                // | 190 |
map_colors::unused,                // | 191 |
map_colors::unused,                // | 192 |
map_colors::unused,                // | 193 |
map_colors::unused,                // | 194 |
map_colors::unused,                // | 195 |
map_colors::tile_wood,             // | 196 |
map_colors::tile_wood,             // | 197 |
map_colors::tile_wood,             // | 198 |
map_colors::unused,                // | 199 |
map_colors::tile_wood,             // | 200 | damaged
map_colors::tile_wood,             // | 201 | damaged
map_colors::tile_wood,             // | 202 | damaged
map_colors::tile_wood,             // | 203 | damaged
map_colors::tile_wood,             // | 204 | damaged
map_colors::tile_wood_back,        // | 205 |
map_colors::tile_wood_back,        // | 206 |
map_colors::tile_wood_back,        // | 207 | damaged
map_colors::tile_thickstone,       // | 208 |
map_colors::tile_thickstone,       // | 209 |
map_colors::unused,                // | 210 |
map_colors::unused,                // | 211 |
map_colors::unused,                // | 212 |
map_colors::unused,                // | 213 |
map_colors::tile_thickstone,       // | 214 | damaged
map_colors::tile_thickstone,       // | 215 | damaged
map_colors::tile_thickstone,       // | 216 | damaged
map_colors::tile_thickstone,       // | 217 | damaged
map_colors::tile_thickstone,       // | 218 | damaged
map_colors::unused,                // | 219 |
map_colors::unused,                // | 220 |
map_colors::unused,                // | 221 |
map_colors::unused,                // | 222 |
map_colors::unused,                // | 223 |
map_colors::tile_castle_moss,      // | 224 |
map_colors::tile_castle_moss,      // | 225 |
map_colors::tile_castle_moss,      // | 226 |
map_colors::tile_castle_back_moss, // | 227 |
map_colors::tile_castle_back_moss, // | 228 |
map_colors::tile_castle_back_moss, // | 229 |
map_colors::tile_castle_back_moss, // | 230 |
map_colors::tile_castle_back_moss, // | 231 |
map_colors::unused,                // | 232 |
map_colors::unused,                // | 233 |
map_colors::unused,                // | 234 |
map_colors::unused,                // | 235 |
map_colors::unused,                // | 236 |
map_colors::unused,                // | 237 |
map_colors::unused,                // | 238 |
map_colors::unused,                // | 239 |
map_colors::unused,                // | 240 |
map_colors::unused,                // | 241 |
map_colors::unused,                // | 242 |
map_colors::unused,                // | 243 |
map_colors::unused,                // | 244 |
map_colors::unused,                // | 245 |
map_colors::unused,                // | 246 |
map_colors::unused,                // | 247 |
map_colors::unused,                // | 248 |
map_colors::unused,                // | 249 |
map_colors::unused,                // | 250 |
map_colors::unused,                // | 251 |
map_colors::unused,                // | 252 |
map_colors::unused,                // | 253 |
map_colors::unused,                // | 254 |
map_colors::unused};               // | 255 |
