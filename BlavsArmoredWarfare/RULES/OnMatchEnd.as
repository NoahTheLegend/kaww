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
		string[] had_bonus;
		if (isServer() && getPlayerCount() > 3)
		{
			for (uint i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ player = getPlayer(i);
				if (player !is null)
				{
					if (player.getTeamNum() == this.getTeamWon())
					{
						// winning team
						//printf(""+player.getUsername());
						{
							bool cont = false;
							for (u8 j = 0; j < had_bonus.length; j++)
							{
								if (player.getUsername() == had_bonus[j]) cont = true;
							}
							if (cont) continue;

							// give exp to winners
							int exp_reward = 50; // death incarnate does not apply here
							this.add_u32(player.getUsername() + "_exp", exp_reward);	
							this.Sync(player.getUsername() + "_exp", true);
							had_bonus.push_back(player.getUsername());

							if (player.isMyPlayer()) add_message(ExpMessage(exp_reward));

							CheckRankUps(this, // do reward coins and sfx
										this.get_u32(player.getUsername() + "_exp"), // player new exp
										player.getBlob());	
							
						}		
					}
				}
			}
		}
	}
}