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
				Vec2f draw_pos = blob.getInterpolatedPosition() + Vec2f(0.0f, blob.getRadius() * 1.5f);
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
                
                int level = Maths::Max(1, getRankId(blob.getPlayer()))-1;
				GUI::DrawRectangle(draw_pos - text_dim_half, draw_pos + text_dim_half + Vec2f(5.0f, 3.0f), rect_color);

                GUI::DrawIcon("Ranks", level, Vec2f(32, 32), draw_pos-text_dim_half-Vec2f(38,20), 0.66f, 0);
				GUI::DrawText(name, draw_pos - text_dim_half, text_color);

				f32 segments = Maths::Ceil(blob.getInitialHealth() * 1.5f + 1); // hp bar segments

				Vec2f padding = Vec2f(3, 0);
				Vec2f dim = Vec2f(32 + segments * 8, 12) - padding;
				Vec2f hp_bar_pos = draw_pos + Vec2f(-dim.x/2, dim.y-2) + padding;
				f32 hp_ratio = Maths::Clamp(blob.getHealth()/blob.getInitialHealth(), 0.1f, 1.0f);
				u8 hp_alpha = text_color.getAlpha();

				//bg
				GUI::DrawPane(hp_bar_pos - padding, hp_bar_pos + dim + padding, SColor(hp_alpha, 55, 55, 75));

				//red
				if (hp_ratio < 1)
				{
					Vec2f hp_missing_tl = hp_bar_pos + dim * hp_ratio;
					hp_missing_tl.y = hp_bar_pos.y;
					
					GUI::DrawPane(hp_missing_tl - Vec2f(padding.x, 0), hp_bar_pos + dim, SColor(hp_alpha, 255, 75, 75));
				}

				//green
				Vec2f hp_br = hp_bar_pos + dim * hp_ratio;
				hp_br.y = hp_bar_pos.y + dim.y;

				bool saturated = blob.get_u32("regen") > getGameTime();

				GUI::DrawPane(hp_bar_pos, hp_br, SColor(hp_alpha, saturated ? 255 : 75, 225, 75));

				f32 line_h = 4;
				f32 line_th = 1;

				// decorators
				GUI::DrawRectangle(hp_bar_pos + Vec2f(Maths::Floor(padding.x*1.5f), line_h), hp_bar_pos + Vec2f(dim.x - Maths::Floor(padding.x*1.5f), line_h + line_th), SColor(text_color.getAlpha(), 255, 255 ,255));
				
				u8 sep_padding_y = 2;
				Vec2f sep_dim = Vec2f(3, dim.y - sep_padding_y*2);
				for (u8 i = 1; i < segments; i++)
				{
					SColor seg_col = SColor(255, saturated ? 85 : 25, 85, 25);
					Vec2f sep_pos = hp_bar_pos + Vec2f(dim.x * (i/segments) - sep_dim.x/2, sep_padding_y);
					if (hp_br.x < sep_pos.x + sep_dim.x/2) seg_col = SColor(255, 85, 25, 25);
					
					GUI::DrawRectangle(sep_pos, sep_pos+sep_dim, seg_col);
				}
			}
		}
	}
}