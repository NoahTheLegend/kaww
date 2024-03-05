// show menu that only allows to join spectator

#include "SwitchFromSpec.as"

const int BUTTON_SIZE = 4;

void onInit(CRules@ this)
{
	this.addCommandID("pick teams");
	this.addCommandID("pick none");

	AddIconToken("$BLUE_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 0);
	AddIconToken("$RED_TEAM$", "GUI/TeamIcons.png", Vec2f(96, 96), 1);
	AddIconToken("$TEAMGENERIC$", "GUI/TeamIcons.png", Vec2f(96, 96), 2);
}

void ShowTeamMenu(CRules@ this)
{
	if (getLocalPlayer() is null)
	{
		return;
	}

	getHUD().ClearMenus(true);

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, Vec2f((2 + 0.5f) * BUTTON_SIZE, BUTTON_SIZE), "Change team");

	if (menu !is null)
	{
		CBitStream exitParams;
		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("pick none"), exitParams);
		menu.SetDefaultCommand(this.getCommandID("pick none"), exitParams);

		string icon, name;

		for (int i = 0; i < this.getTeamsCount(); i++)
		{
			CBitStream params;
			params.write_u16(getLocalPlayer().getNetworkID());
			params.write_u8(i);

			if (i == 0)
			{
				icon = "$BLUE_TEAM$";
				name = "Left Team";
			}
			else if (i == 1)
			{
				// spectator
				{
					CBitStream params;
					params.write_u16(getLocalPlayer().getNetworkID());
					params.write_u8(this.getSpectatorTeamNum());
					CGridButton@ button2 = menu.AddButton("$SPECTATOR$", getTranslatedString("Spectator"), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE / 2, BUTTON_SIZE), params);
				}
				icon = "$RED_TEAM$";
				name = "Right Team";
			}
			else
			{
				continue;
			}

			CGridButton@ button =  menu.AddButton(icon, getTranslatedString(name), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
	}
}

// the actual team changing is done in the player management script -> onPlayerRequestTeamChange()

void ReadChangeTeam(CRules@ this, CBitStream @params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());
	u8 team = params.read_u8();

	u8 teamleft = getRules().get_u8("teamleft");
	u8 teamright = getRules().get_u8("teamright");
	
	if (team == 0) team = teamleft;
	else if (team == 1) team = teamright;

	if (player is getLocalPlayer())
	{
		if (CanSwitchFromSpec(this, player, team))
		{
			ChangeTeam(player, team);
		}
		else
		{
			client_AddToChat("Game is currently full. Please wait for a new slot before switching teams.", ConsoleColour::GAME);
			Sound::Play("NoAmmo.ogg");
		}
	}

	if (isServer() && player.getBlob() !is null && this.isMatchRunning())
	{
		int btnum = player.getBlob().getTeamNum();
		int ptnum = player.getTeamNum();

		if (btnum != team) // disables switch team ticket consumption
		{
			CBlob@[] overlapping;
			player.getBlob().getOverlapping(overlapping);

			bool skip = false;
			for (u8 i = 0; i < overlapping.size(); i++)
			{
				CBlob@ b = overlapping[i];
				if (b is null) continue;
				if (b.hasTag("respawn") && b.getTeamNum() == ptnum)
				{
					skip = true;
					break;
				}
			}

			if (!skip)
			{
				if (ptnum != getRules().getSpectatorTeamNum())
				{
					getRules().set_s8("decrement_ticket_by_team", ptnum);
				}
			}
		}
	}
}

void ChangeTeam(CPlayer@ player, u8 team)
{
	player.client_ChangeTeam(team);
	getHUD().ClearMenus();
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pick teams"))
	{
		ReadChangeTeam(this, params);
	}
	else if (cmd == this.getCommandID("pick none"))
	{
		getHUD().ClearMenus();
	}
}