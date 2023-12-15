#include "PlayerRankInfo.as";
#include "TeamColorCollections.as";
#define CLIENT_ONLY

// code by GoldenGuy

float max_radius = 24.0f; // screenspace distance for logic and alpha
float max_distance = 32.0f;
uint16[] blob_ids;

const Vec2f sc_pos = getDriver().getScreenCenterPos();

void onTick(CRules@ this)
{
	if(g_videorecording)
		return;
	
	blob_ids.clear();
	CControls@ c = getControls();
	Vec2f mouse_pos = c.getMouseWorldPos();

	uint8 team = this.getSpectatorTeamNum();
	CBlob@ my_blob = getLocalPlayerBlob();
	if(my_blob !is null) // dont change team if we are dead, so that we can see everyone names
		team = my_blob.getTeamNum();

	f32 processed_dist = 8;
	CCamera@ camera = getCamera();
	if (camera !is null)
		processed_dist = 8*camera.targetDistance;

	CMap@ map = getMap();
	for(int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		CBlob@ blob = player.getBlob();
		if(blob is null || blob is my_blob)
			continue;

		Vec2f bpos = blob.getPosition();
		if ((u_shownames && team == this.getSpectatorTeamNum() && (mouse_pos - bpos).Length() <= max_radius)
			|| (u_shownames && (mouse_pos - bpos).Length() <= max_radius && map.getColorLight(bpos).getLuminance() > 50
			&& (blob.getScreenPos()-sc_pos).Length()/processed_dist < max_distance))
		{
			blob_ids.push_back(blob.getNetworkID());
		}
	}
}

void onRender(CRules@ this)
{
	if(g_videorecording)
		return;
	
	CControls@ c = getControls();
	Vec2f mouse_screen_pos = c.getInterpMouseScreenPos();

	for(int i = 0; i < blob_ids.size(); i++)
	{
		CBlob@ blob = getBlobByNetworkID(blob_ids[i]);
		if(blob !is null) // you never know...
		{
			CPlayer@ player = blob.getPlayer();
			if(player !is null) // you never know...
			{
				Vec2f draw_pos = blob.getInterpolatedPosition() + Vec2f(0.0f, blob.getRadius());
				draw_pos = getDriver().getScreenPosFromWorldPos(draw_pos);

				// change alpha depending on distance between mouse and player
                float dist = Maths::Min(max_radius, (mouse_screen_pos - blob.getInterpolatedScreenPos()).Length());
				float alpha = Maths::Min(1.0f, 1.7f-(dist / max_radius)); // min 0.4, max 1

				// now draw nickname
				string name = player.getCharacterName();

				Vec2f text_dim;
				GUI::SetFont("menu");
				GUI::GetTextDimensions(name, text_dim);
				Vec2f text_dim_half = Vec2f(text_dim.x/2.0f, text_dim.y/2.0f);

				SColor text_color = SColor(255, 200, 200, 200);

				u8 teamnum = blob.getTeamNum();
				if (teamnum != 6) // violet is black here so keep the text white
					text_color = getNeonColor(teamnum, 0);
				
				
                text_color.setAlpha(255 * alpha);

				SColor rect_color = SColor(80 * alpha, 0, 0, 0);
                
                int level = getRankId(blob.getPlayer());
				GUI::DrawRectangle(draw_pos - text_dim_half, draw_pos + text_dim_half + Vec2f(5.0f, 3.0f), rect_color);

                GUI::DrawIcon("Ranks", level, Vec2f(32, 32), draw_pos-text_dim_half-Vec2f(38,20), 0.66f, 0);
				GUI::DrawText(name, draw_pos - text_dim_half, text_color);
			}
		}
	}
}