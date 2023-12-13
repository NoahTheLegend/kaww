//stuff for building respawn menus

#include "RespawnCommandCommon.as"
#include "PlayerRankInfo.as";

//class for getting everything needed for swapping to a class at a building

shared class PlayerClass
{
	string name;
	string iconFilename;
	string iconName;
	string configFilename;
	string description;
};

shared class PlayerPerk
{
	string name;
	string iconFilename;
	string iconName;
	string configFilename;
	string description;
};

const f32 CLASS_BUTTON_SIZE = 2;
const f32 PERK_BUTTON_SIZE = 1;

//adding a class to a blobs list of classes

void addPlayerClass(CBlob@ this, string name, string iconName, string configFilename, string description)
{
	if (!this.exists("playerclasses"))
	{
		PlayerClass[] classes;
		this.set("playerclasses", classes);
	}

	PlayerClass p;
	p.name = name;
	p.iconName = iconName;
	p.configFilename = configFilename;
	p.description = description;
	this.push("playerclasses", p);
}

//adding a perk to a blobs list of perk

void addPlayerPerk(CBlob@ this, string name, string iconName, string configFilename, string description)
{
	if (!this.exists("playerperks"))
	{
		PlayerPerk[] perks;
		this.set("playerperks", perks);
	}

	PlayerPerk p;
	p.name = name;
	p.iconName = iconName;
	p.configFilename = configFilename;
	p.description = description;
	this.push("playerperks", p);
}

//helper for building menus of classes

void addClassesToMenu(CBlob@ this, CGridMenu@ menu, u16 callerID)
{
	PlayerClass[]@ classes;

	if (this.get("playerclasses", @classes))
	{
		AddIconToken("$locked_class_icon$", "ClassIcon.png", Vec2f(48, 48), 10);

		for (uint i = 0 ; i < classes.length; i++)
		{
			CBlob@ callerblob = getBlobByNetworkID(callerID);
			CPlayer@ player = callerblob.getPlayer();

			float exp = 0;
			// load exp
			if (player !is null)
			{
				exp = getRules().get_u32(player.getUsername() + "_exp");
			}

			//draw rank level
			int level = 1;
			string rank = RANKS[0];

			// Calculate the exp required to reach each level
			for (int i = 1; i <= RANKS.length; i++)
			{
				if (exp >= getExpToNextLevel(level))
				{
					level = i + 1;
					rank = RANKS[Maths::Min(i, RANKS.length-1)];
				}
				else
				{
					// The current level has been reached
					break;
				}
			}

			if (level > -1 + i) //(isClient() && isServer()) || 
			{
				PlayerClass @pclass = classes[i];

				CBitStream params;
				write_classchange(params, callerID, pclass.configFilename);

				CGridButton@ button = menu.AddButton(pclass.iconName, getTranslatedString(pclass.name), SpawnCmd::changeClass, Vec2f(CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE), params);
				button.SetHoverText( pclass.description + "\n" );
			}
			else
			{
				PlayerClass @pclass = classes[i];

				CBitStream params;
				write_classchange(params, callerID, pclass.configFilename);

				CGridButton@ button = menu.AddButton("$locked_class_icon$", getTranslatedString("LOCKED"), SpawnCmd::lockedItem, Vec2f(CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE), params);
				button.SetHoverText(pclass.name + "\n\nYou need to unlock this class first." + "\n\nUnlocks at: " + getRankName(i) + "\n");
			}
		}
	}
}

PlayerClass@ getDefaultClass(CBlob@ this)
{
	PlayerClass[]@ classes;

	if (this.get("playerclasses", @classes))
	{
		return classes[0];
	}
	else
	{
		return null;
	}
}

//helper for building menus of perks

void addPerksToMenu(CBlob@ this, CGridMenu@ menu, u16 callerID)
{
	PlayerPerk[]@ perks;

	if (this.get("playerperks", @perks))
	{
		AddIconToken("$locked_perk_icon$", "PerkIcon.png", Vec2f(32, 32), 19);

		for (uint i = 0 ; i < perks.length; i++)
		{
			CBlob@ callerblob = getBlobByNetworkID(callerID);
			CPlayer@ player = callerblob.getPlayer();

			float exp = 0;
			// load exp
			if (player !is null)
			{
				exp = getRules().get_u32(player.getUsername() + "_exp");
			}

			//draw rank level
			int level = 1;
			string rank = RANKS[0];

			// Calculate the exp required to reach each level
			for (int i = 1; i <= RANKS.length; i++)
			{
				if (exp >= getExpToNextLevel(level))
				{
					level = i;
					rank = RANKS[Maths::Min(i, RANKS.length-1)];
				}
				else
				{
					// The current level has been reached
					break;
				}
			}

			if (level > 1 + (i+1) || i == 0)
			{
				PlayerPerk @pperk = perks[i];

				CBitStream params;
				write_perkchange(params, callerID, i, pperk.configFilename);

				CGridButton@ button = menu.AddButton(pperk.iconName, getTranslatedString(pperk.name), SpawnCmd::changePerk, Vec2f(PERK_BUTTON_SIZE, PERK_BUTTON_SIZE), params);
				button.SetHoverText( pperk.description + "\n" );
			}
			else
			{
				PlayerPerk @pperk = perks[i];

				CBitStream params;
				write_perkchange(params, callerID, i, pperk.configFilename);

				CGridButton@ button = menu.AddButton("$locked_perk_icon$", getTranslatedString("LOCKED"), SpawnCmd::lockedItem, Vec2f(PERK_BUTTON_SIZE, PERK_BUTTON_SIZE), params);
				button.SetHoverText(pperk.name + "\n\nYou need to unlock this perk first. " + "\n\nUnlocks at: " + getRankName((i+3)) + "\n");
			}
		}
	}
}


PlayerPerk@ getDefaultPerk(CBlob@ this)
{
	PlayerPerk[]@ perks;

	if (this.get("playerperks", @perks))
	{
		return perks[0]; // no perk
	}
	else
	{
		return null;
	}
}
