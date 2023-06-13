// CommonBuilderBlocks.as

//////////////////////////////////////
// Builder menu documentation
//////////////////////////////////////

// To add a new page;

// 1) initialize a new BuildBlock array,
// example:
// BuildBlock[] my_page;
// blocks.push_back(my_page);

// 2)
// Add a new string to PAGE_NAME in
// BuilderInventory.as
// this will be what you see in the caption
// box below the menu

// 3)
// Extend BuilderPageIcons.png with your new
// page icon, do note, frame index is the same
// as array index

// To add new blocks to a page, push_back
// in the desired order to the desired page
// example:
// BuildBlock b(0, "name", "icon", "description");
// blocks[3].push_back(b);

#include "BuildBlock.as"
#include "Requirements.as"
#include "Costs.as"
#include "CustomBlocks.as";

const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addCommonBuilderBlocks(CBlob@ this, BuildBlock[][]@ blocks, const string&in gamemode_override = "")
{
	InitCosts();
	CRules@ rules = getRules();

	string gamemode = rules.gamemode_name;
	if (gamemode_override != "")
	{
		gamemode = gamemode_override;

	}

	const bool CTF = gamemode == "CTF";
	const bool SCTF = gamemode == "SmallCTF";
	const bool TTH = gamemode == "TTH";
	const bool SBX = gamemode == "Sandbox";

	AddIconToken("$cdirt_block$", "World.png", Vec2f(8, 8), CMap::tile_cdirt);
	AddIconToken("$scrap_block$", "World.png", Vec2f(8, 8), CMap::tile_scrap);

	BuildBlock[] page_0;
	blocks.push_back(page_0);
	{
		BuildBlock b(CMap::tile_castle, "stone_block", "$stone_block$", "Stone Block\nBasic building block\n");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_back, "back_stone_block", "$back_stone_block$", "Back Stone Wall\nExtra support\n");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "trap_block", "$trap_block$", "Trap Block\nOnly enemies can pass\n");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 25);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_door", "$stone_door$", "Stone Door\nPlace next to walls\n");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 60);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood, "wood_block", "$wood_block$", "Wood Block\nCheap block\nwatch out for fire!\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood_back, "back_wood_block", "$back_wood_block$", "Back Wood Wall\nCheap extra support\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_platform", "$wooden_platform$", "Wooden Platform\nOne way platform\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 15);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_door", "$wooden_door$", "Wooden Door\nPlace next to walls\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 20);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_scrap, "scrap_block", "$scrap_block$", "Scrap block\nReinforced block of stone, resistable to explosions and direct hits.\n");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
		AddRequirement(b.reqs, "blob", "mat_scrap", "Scrap", 2);
		blocks[0].push_back(b);
	}
	{ // TILEINDEX IN BLOCKPLACEMENT.AS IS SET MANUALLY TO THE INDEX OF THIS BLOCK!
		BuildBlock b(CMap::tile_cdirt, "cdirt_block", "$cdirt_block$", "Compacted dirt\nReinforced block of dirt, almost immune to explosions\nand bullets, can be built only on dirt walls.\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_scrap", "Scrap", 1);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "ladder", "$ladder$", "Ladder\nAnyone can climb it\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[0].push_back(b);
	}
	{
		AddIconToken("$barbedwire_icon$", "BarbedWire.png", Vec2f(16, 16), 0);
		BuildBlock b(0, "barbedwire", "$barbedwire_icon$", "Barbed Wire\nHard to pass through. Breaks on impact with vehicles.\nRequires to be next to solid blocks.");
		AddRequirement(b.reqs, "blob", "mat_scrap", "Scrap", 1);
		AddRequirement(b.reqs, "blob", "chest", "Sorry, but this item is temporarily\n\ndisabled!\n", 1);
		blocks[0].push_back(b);
	}
	{
		AddIconToken("$construction_yard_icon$", "CYardIcon.png", Vec2f(16, 16), 2);
		BuildBlock b(0, "constructionyard", "$construction_yard_icon$", "Construction Yard\nStand in an open space\nand tap this button.\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 50);
		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[0].push_back(b);
	}
	//{
	//	BuildBlock b(0, "spikes", "$spikes$", "Spikes\nPlace on Stone Block\nfor Retracting Trap");
	//	AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
	//	blocks[0].push_back(b);
	//}
	{
		AddIconToken("$sandbags_icon$", "SandbagIcon.png", Vec2f(16, 16), 0);
		BuildBlock b(0, "sandbags", "$sandbags_icon$", "Sandbags\nBags densely filled with sand, great for stopping bullets\n");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		b.buildOnGround = true;
		b.size.Set(24, 8);
		blocks[0].push_back(b);
	}
	{
		AddIconToken("$bush_icon$", "BushIcon.png", Vec2f(16, 16), 0);
		BuildBlock b(0, "bush", "$bush_icon$", "Bush\nDisguises small area\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 15);
		blocks[0].push_back(b);
	}
	{
		AddIconToken("$wooden_gate$", "WoodenGate.png", Vec2f(22, 16), 0, 0);
		BuildBlock b(0, "woodengate", "$wooden_gate$", "Wooden Gate\nGate for vehicles. Face the direction you want to rotate it.\n");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		AddRequirement(b.reqs, "blob", "mat_scrap", "Scrap", 2);
		b.buildOnGround = true;
		b.size.Set(8, 40);
		blocks[0].push_back(b);
	}
}

ConfigFile@ openBlockBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/BlockBindings.cfg"))
	{
		// write EmoteBinding.cfg to Cache
		cfg.saveFile("BlockBindings.cfg");

	}

	return cfg;
}

u8 read_block(ConfigFile@ cfg, string name, u8 default_value)
{
	u8 read_val = cfg.read_u8(name, default_value);
	return read_val;
}
