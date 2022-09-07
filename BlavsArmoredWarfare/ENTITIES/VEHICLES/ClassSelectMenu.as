//stuff for building respawn menus

#include "RespawnCommandCommon.as"

//class for getting everything needed for swapping to a class at a building

shared class PlayerClass
{
	string name;
	string iconFilename;
	string iconName;
	string configFilename;
	string description;
};

const f32 CLASS_BUTTON_SIZE = 2;

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

//helper for building menus of classes

void addClassesToMenu(CBlob@ this, CGridMenu@ menu, u16 callerID)
{
	PlayerClass[]@ classes;

	if (this.get("playerclasses", @classes))
	{
		AddIconToken("$locked_class_icon$", "ClassIcon.png", Vec2f(48, 48), 8);
		AddIconToken("$unav_class_icon$", "ClassIcon.png", Vec2f(48, 48), 9);

		for (uint i = 0 ; i < classes.length; i++)
		{
			CBlob@ callerblob = getBlobByNetworkID(callerID);
			CPlayer@ player = callerblob.getPlayer();

			if (i == 0 && getMap().getMapName() == "KAWWTraining.png")
			{
				PlayerClass @pclass = classes[i];

				CBitStream params;
				write_classchange(params, callerID, pclass.configFilename);

				CGridButton@ button = menu.AddButton("$unav_class_icon$", getTranslatedString("LOCKED"), SpawnCmd::lockedClass, Vec2f(CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE), params);
				button.SetHoverText( "This class is unavaliable\nwhile in bootcamp." + "\n" );
			}
			else
			{
				if (true)
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

					CGridButton@ button = menu.AddButton("$locked_class_icon$", getTranslatedString("LOCKED"), SpawnCmd::lockedClass, Vec2f(CLASS_BUTTON_SIZE, CLASS_BUTTON_SIZE), params);
					button.SetHoverText( "This class must be\nunlocked at bootcamp." + "\n" );
				}
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
