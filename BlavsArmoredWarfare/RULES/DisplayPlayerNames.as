#include "FighterVarsCommon.as"
#include "TeamColour.as";

// shows indicators above clanmates and players of interest

#define CLIENT_ONLY

MarkInfo@[] marked;
bool pressed = false;

StatusInfo@[] statuses;

class MarkInfo
{
	string player_username;
	bool clanMate;
	bool active;

	MarkInfo() {};
	MarkInfo(CPlayer@ _player, bool _clanMate)
	{
		player_username = _player.getUsername();
		clanMate = _clanMate;
		active = true;
	};

	CPlayer@ player() {
		return getPlayerByUsername(player_username); 
	}
};

class StatusInfo
{
	string player_username;
	bool offScreen;

	StatusInfo() {};
	StatusInfo(CPlayer@ _player)
	{
		player_username = _player.getUsername();
		offScreen = false;
	};

	CPlayer@ player() {
		return getPlayerByUsername(player_username); 
	}
};

void onRestart(CRules@ this)
{
	updateStatuses();
}

void onInit(CRules@ this)
{
	updateStatuses();
}

void onTick(CRules@ this)
{
	doStatuses();
}

void onRender(CRules@ this)
{
	if ((getGameTime() % (5 * 30)) == 0)
	{
		updateStatuses();
	}

	CMap@ map = getMap();
	if (map is null) 
		return;

	f32 screenWidth = getScreenWidth();
	f32 screenHeight = getScreenHeight();

	for (uint i = 0; i < statuses.length; i++)
	{
		if (statuses[i].player() is null) continue;

		CBlob@ blob = statuses[i].player().getBlob();
		if (blob !is null)
		{
			Vec2f pos2d = blob.getInterpolatedScreenPos();
			//Vec2f pos2d = getDriver().getScreenPosFromWorldPos( blob.getSprite().getWorldTranslation() );
			Vec2f dim = Vec2f(24,8);
			const f32 y = blob.getHeight()*1.4f;

			if ( getLocalPlayerBlob() !is blob )
			{
				//show username
				CPlayer@ thisPlayer = blob.getPlayer();
				if ( thisPlayer !is null )
				{
					const f32 y = blob.getHeight() * 2.0f;
					string playerName = thisPlayer.getCharacterName();
					Vec2f textSize;
					GUI::GetTextDimensions("" + playerName, textSize);

					f32 screenWidth = getScreenWidth();
					f32 screenHeight = getScreenHeight();

					Vec2f nameScreenPos = Vec2f(pos2d.x, pos2d.y + y);
					// print("nameScreenPosx :" + nameScreenPos.x + " nameScreenPosY: " + nameScreenPos.y);

					f32 textHalfWidth = textSize.x/2.0f;
					f32 textHalfHeight = textSize.y/2.0f;

					// render name clamped to side of screen if player is fighter
					if (blob.hasTag("fighter"))
					{
						f32 padding = 48.0f;
						f32 leftEdgeX = textHalfWidth + padding;
						f32 rightEdgeX = screenWidth - (textHalfWidth + padding);
						f32 lowerEdgeY = textHalfHeight + padding;
						f32 upperEdgeY = screenHeight - (textHalfHeight + padding);
						if ( nameScreenPos.x < leftEdgeX || nameScreenPos.x > rightEdgeX
							|| nameScreenPos.y < lowerEdgeY || nameScreenPos.y > upperEdgeY )
						{
							if (statuses[i].offScreen == false)
							{
								statuses[i].offScreen = true;

								Sound::Play("offscreen.ogg");
							}

							nameScreenPos.x = Maths::Clamp(nameScreenPos.x, leftEdgeX, rightEdgeX);
							nameScreenPos.y = Maths::Clamp(nameScreenPos.y, lowerEdgeY, upperEdgeY);

							// render arrow if player is out of screen bounds
							if (nameScreenPos.x == leftEdgeX)
							{
								if (nameScreenPos.y == lowerEdgeY)
								{
									GUI::DrawIcon("GUI/PartyIndicator.png", 13, Vec2f(16, 16), nameScreenPos + Vec2f(-32.0f - textHalfWidth, -32.0f), 2.0f);
								}
								else if (nameScreenPos.y == upperEdgeY)
								{
									GUI::DrawIcon("GUI/PartyIndicator.png", 15, Vec2f(16, 16), nameScreenPos + Vec2f(-32.0f - textHalfWidth, -32.0f), 2.0f);
								}
								else
									GUI::DrawIcon("GUI/PartyIndicator.png", 14, Vec2f(16, 16), nameScreenPos + Vec2f(-32.0f - textHalfWidth, -32.0f), 2.0f);
							}
							else if (nameScreenPos.x == rightEdgeX)
							{
								if (nameScreenPos.y == lowerEdgeY)
								{
									GUI::DrawIcon("GUI/PartyIndicator.png", 11, Vec2f(16, 16), nameScreenPos + Vec2f(0.0f, -48.0f), 2.0f);
								}
								else if (nameScreenPos.y == upperEdgeY)
								{
									GUI::DrawIcon("GUI/PartyIndicator.png", 9, Vec2f(16, 16), nameScreenPos + Vec2f(0.0f, -16.0f), 2.0f);
								}
								else
									GUI::DrawIcon("GUI/PartyIndicator.png", 10, Vec2f(16, 16), nameScreenPos + Vec2f(0.0f, -32.0f), 2.0f);
							}
							else if (nameScreenPos.y == lowerEdgeY)
								GUI::DrawIcon("GUI/PartyIndicator.png", 12, Vec2f(16, 16), nameScreenPos + Vec2f(-32.0f, -48.0f), 2.0f);
							else if (nameScreenPos.y == upperEdgeY)
								GUI::DrawIcon("GUI/PartyIndicator.png", 8, Vec2f(16, 16), nameScreenPos + Vec2f(-32.0f, -16.0f), 2.0f);
						}
						else
							statuses[i].offScreen = false;
					}

					GUI::DrawRectangle(nameScreenPos + Vec2f(-textHalfWidth, -textHalfHeight), nameScreenPos + Vec2f(textHalfWidth, textHalfHeight) + Vec2f(4.0f, 2.0f), SColor(100, 0, 0, 0)); 
					GUI::DrawTextCentered(playerName, nameScreenPos, SColor(100, 250, 250, 250)); //getTeamColor( blob.getTeamNum() )
				}
			}
		}
	}
}

void markPlayer()
{
	CMap@ map = getMap();
	CControls@ controls = getControls();
	CPlayer@ local = getLocalPlayer();

	if (map is null || controls is null || local is null) 
		return;
	
	CBlob@[] targets;
	if (!map.getBlobsInRadius(controls.getMouseWorldPos(), 8.0f, @targets))
		return;

	for (uint i = 0; i < targets.length; i++)
	{
		CBlob@ b = targets[i];
		if (b is null || b.getPlayer() is null)
			continue;

		CPlayer@ p = b.getPlayer();
		MarkInfo@ info = getMarkInfo(p);

		if (info is null)
		{
			bool clan = isClan(p); 
			marked.push_back(MarkInfo(p, clan));
		}
		else
		{
			info.active = !info.active;
			if (!info.active)
			{
				CBlob@ blob = info.player().getBlob();
				if (blob !is null)
				{
					blob.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
				}
			}
		}
		break;
	}
}

void doStatuses()
{
	CMap@ map = getMap();
	CPlayer@ local = getLocalPlayer();

	if (map is null || local is null) 
		return;
	
	CBlob@[] targets;
	getBlobsByTag("player", @targets);
	if (!getBlobsByTag("player", @targets))
		return;

	for (uint i = 0; i < targets.length; i++)
	{
		CBlob@ b = targets[i];
		if (b is null || b.getPlayer() is null)
			continue;

		CPlayer@ p = b.getPlayer();
		StatusInfo@ info = getStatusInfo(p);

		if (info is null)
		{
			statuses.push_back(StatusInfo(p));
		}
		break;
	}
	
}

bool isClan(CPlayer@ p)
{
	return p.isMyPlayer() || p.getClantag() != "" && p.getClantag() == getLocalPlayer().getClantag(); 	
}

void updateMarked()
{
	CPlayer@ local = getLocalPlayer();
	if (local is null || !local.isMyPlayer())
		return;

	if (marked.length == 0)
	{
		marked.push_back(MarkInfo(local, true)); //push local player marker
	}

	if (local.getClantag() != "")
	{
		int count = getPlayerCount();
		for (uint i = 0; i < count; i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p.getClantag() == local.getClantag() && p !is local)
			{
				MarkInfo@ info = getMarkInfo(p);
				if (info is null)
				{
					marked.push_back(MarkInfo(p, true));
				}
			}
		}
	}

	//remove missing players and check for clantag changes
	for (uint i = 0; i < marked.length; i++)
	{
		CPlayer@ p = marked[i].player();
		if (p is null)
		{
			marked.erase(uint(i--));
		} 
		else 
		{
			marked[i].clanMate = isClan(p);
		}
	}
}

void updateStatuses()
{
	CPlayer@ local = getLocalPlayer();
	if (local is null || !local.isMyPlayer())
		return;

	int count = getPlayerCount();
	for (uint i = 0; i < count; i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p !is local)
		{
			StatusInfo@ info = getStatusInfo(p);
			if (info is null)
			{
				statuses.push_back(StatusInfo(p));
			}
		}
	}

	//remove missing players
	for (uint i = 0; i < statuses.length; i++)
	{
		CPlayer@ p = statuses[i].player();
		if (p is null)
		{
			statuses.erase(uint(i--));
		}
	}
}

MarkInfo@ getMarkInfo(CPlayer@ player)
{
	string name = player.getUsername();
	for (uint i = 0; i < marked.length; i++)
	{
		if (marked[i].player_username == name)
		{
			return marked[i];
		}
	}
	return null;
}

StatusInfo@ getStatusInfo(CPlayer@ player)
{
	string name = player.getUsername();
	for (uint i = 0; i < statuses.length; i++)
	{
		if (statuses[i].player_username == name)
		{
			return statuses[i];
		}
	}
	return null;
}
