#include "HoverMessage.as";
#include "PlayerRankInfo.as";

void onStateChange( CRules@ this, const u8 oldState )
{
	if (this.getTeamWon() >= 0)
	{
		// play fanfare on end
		// only play for winners
		CPlayer@ localplayer = getLocalPlayer();
		if (localplayer !is null)
		{
			CBlob@ playerBlob = getLocalPlayerBlob();
			int teamNum = playerBlob !is null ? playerBlob.getTeamNum() : localplayer.getTeamNum() ; // bug fix (cause in singleplayer player team is 255)
			if (teamNum == this.getTeamWon())
			{
				Sound::Play("/WinSound.ogg");
			}
			else
			{
				Sound::Play("/LoseSound.ogg");
			}
		}

		// award exp for winners
		if (getPlayerCount() > 3)
		{
			CBlob@[] players;
			getBlobsByTag("player", @players);
			for (uint i = 0; i < players.length; i++)
			{
				CPlayer@ player = players[i].getPlayer();
				if (player !is null)
				{
					if (player.getTeamNum() == this.getTeamWon())
					{
						// winning team
						if (players[i] !is null)
						{
							server_DropCoins(players[i].getPosition(), 30);

							// give exp to winners
							int exp_reward = 50; // death incarnate does not apply here
							this.add_u32(player.getUsername() + "_exp", exp_reward);	
							this.Sync(player.getUsername() + "_exp", true);

							add_message(ExpMessage(exp_reward));

							CheckRankUps(this, // do reward coins and sfx
										this.get_u32(player.getUsername() + "_exp"), // player new exp
										players[i]);	
							
						}		
					}
				}
			}
		}
	}
}