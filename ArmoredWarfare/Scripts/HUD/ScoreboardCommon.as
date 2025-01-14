#include "ColoredNameToggleCommon.as"

const string[] descriptions = {
	"A chance to receive extra ore or wood (+33%, +2)",
	"Shorter respawn time, longer spawn protection, more heal (-1s, +1.5s, +10%)",
	"Faster constructing, less constraining building (+33%, -50% lock radius)",
	"Cheaper and stronger molotovs (-25%-33%, more liquid)",
	"Faster vehicle capture, faster C-4 activation, better grenades (+50%, -2.5s, +10% radius)",
	"A chance to receive more coins in an income (33%, +1)",
	"Increased damage resist for infantry, mines activate faster (+5%, -2s)"
};

f32 getKDR(CPlayer@ p)
{
	return p.getKills() / Maths::Max(f32(p.getDeaths()), 1.0f);
}

const int[] unique = {
	"NoahTheLegend".getHash(), // dev
	"gusblatnoj".getHash() // boosty
};

const SColor[] colors_unique = {
	SColor(0xff66ff66),
	SColor(255,128,64,48)
};

const int[] rainbow = {
	//"NoahTheLegend".getHash(), // dev
	"Nevrotik".getHash(), // helper
	"Yeti5000707".getHash(), // creator
	"MasterOfCockFights".getHash(), // patreon
	"Froghead48".getHash(), // patreon
	"kongo73".getHash()
};

const int[] shadow = {
	//"NoahTheLegend".getHash(), // dev
	"LorderPlay".getHash() // spriter
};

SColor getNameColour(CPlayer@ p)
{
	SColor c;
	CPlayer@ localplayer = getLocalPlayer();
	bool showColor = (p !is localplayer && isSpecial(localplayer)) || coloredNameEnabled(getRules(), p);

	if (p.isDev() && showColor) {
		c = SColor(0xffb400ff); //dev
	} else if (p.isGuard() && showColor) {
		c = SColor(0xffa0ffa0); //guard
	} else if (isAdmin(p) && showColor) {
		c = SColor(0xfffa5a00); //admin
	} else if (p.getOldGold() && !p.isBot()) {
		c = SColor(0xffffEE44); //my player
	} else {
		c = SColor(0xffffffff); //normal
	}

	int hash = p.getUsername().getHash();
	int found = unique.find(hash);

	if (found != -1)
		c = colors_unique[found];
	
	if (rainbow.find(hash) != -1)
		c = rgb(p.getNetworkID());
	
	if (shadow.find(hash) != -1)
	{
		f32 grayscale = Maths::Clamp(0, 255, Maths::Sin((getGameTime()+p.getNetworkID())*0.1f)*(Maths::Cos(getGameTime()*0.025f)*250.0f));
		SColor temp = SColor(255, 255, 255, 255);
		temp.setRed(grayscale);
		temp.setGreen(grayscale);
		temp.setBlue(grayscale);

		c = temp;
	}
	
	if (p.getBlob() is null && p.getTeamNum() != getRules().getSpectatorTeamNum())
	{
		uint b = c.getBlue();
		uint g = c.getGreen();
		uint r = c.getRed();

		b -= 75;
		g -= 75;
		r -= 75;

		b = Maths::Max(b, 25);
		g = Maths::Max(g, 25);
		r = Maths::Max(r, 25);
		
		c.setBlue(b);
		c.setGreen(g);
		c.setRed(r);

	}

	return c;

}

void setSpectatePlayer(string username)
{
	CPlayer@ player = getLocalPlayer();
	CPlayer@ target = getPlayerByUsername(username);
	if((player.getBlob() is null || player.getBlob().hasTag("dead")) && player !is target && target !is null)
	{
		CRules@ rules = getRules();
		rules.set_bool("set new target", true);
		rules.set_string("new target", username);

	}

}

float drawServerInfo(float y)
{
	GUI::SetFont("menu");

	Vec2f pos(getScreenWidth()/2, y);
	float width = 200;


	CNet@ net = getNet();
	CMap@ map = getMap();
	CRules@ rules = getRules();

	string info = getTranslatedString(rules.gamemode_name) + ": " + getTranslatedString(rules.gamemode_info);
	SColor white(0xffffffff);
	string mapName = getTranslatedString("Map name : ")+rules.get_string("map_name");
	Vec2f dim;
	GUI::GetTextDimensions(info, dim);
	if(dim.x + 15 > width)
		width = dim.x + 15;

	GUI::GetTextDimensions(net.joined_servername, dim);
	if(dim.x + 15 > width)
		width = dim.x + 15;

	GUI::GetTextDimensions(mapName, dim);
	if(dim.x + 15 > width)
		width = dim.x + 15;


	pos.x -= width/2;
	Vec2f bot = pos;
	bot.x += width;
	bot.y += 95;

	Vec2f mid(getScreenWidth()/2, y);


	GUI::DrawPane(pos, bot, SColor(0xffcccccc));

	mid.y += 15;
	GUI::DrawTextCentered(net.joined_servername, mid, white);
	mid.y += 15;
	GUI::DrawTextCentered(info, mid, white);
	mid.y += 15;
	GUI::DrawTextCentered(net.joined_ip, mid, white);
	mid.y += 17;
	GUI::DrawTextCentered(mapName, mid, white);
	mid.y += 17;
	GUI::DrawTextCentered(getTranslatedString("Match time: {TIME}").replace("{TIME}", "" + timestamp((getRules().exists("match_time") ? getRules().get_u32("match_time") : getGameTime())/getTicksASecond())), mid, white);


	return bot.y;

}

string timestamp(uint s)
{
	string ret;
	int hours = s/60/60;
	if (hours > 0)
		ret += hours + getTranslatedString("h ");

	int minutes = s/60%60;
	if (minutes < 10)
		ret += "0";

	ret += minutes + getTranslatedString("m ");

	int seconds = s%60;
	if (seconds < 10)
		ret += "0";

	ret += seconds + getTranslatedString("s ");

	return ret;
}

void drawPlayerCard(CPlayer@ player, Vec2f pos)
{
	/*
	if(player!is null)
	{
		GUI::SetFont("menu");

		f32 stepheight = 8;
		Vec2f atopleft = pos;
		atopleft.x -= stepheight;
		atopleft.y -= stepheight*2;
		Vec2f abottomright = atopleft;
		abottomright.y += 96 + 16 + 48;
		abottomright.x += 96 + 16;

		//int namecolour = getNameColour(player);
		GUI::DrawIconDirect("playercard.png", atopleft, Vec2f(0, 0), Vec2f(60, 94));
		GUI::DrawText(player.getUsername(), Vec2f(pos.x + 2, atopleft.y+10), SColor(0xffffffff));
		player.drawAvatar(Vec2f(atopleft.x+6*2, atopleft.y+16*2), 1.0f);
		atopleft.y += 96 + 30;
		atopleft.x += 8;
		GUI::DrawIconDirect("playercardicons.png", Vec2f(atopleft.x, atopleft.y), Vec2f(16*2, 0), Vec2f(16, 16));
		GUI::DrawText("9600", Vec2f(atopleft.x+32, atopleft.y+6), SColor(0xffffffff));
		atopleft.y += 23;
		GUI::DrawIconDirect("playercardicons", Vec2f(atopleft.x, atopleft.y), Vec2f(16*3, 0), Vec2f(16, 16));
		GUI::DrawText("450", Vec2f(atopleft.x+32, atopleft.y+6), SColor(0xffffffff));

	}
	*/

}

SColor rgb(u16 id)
{
	f32 hue = (getGameTime()+id) % 360;
	f32 saturation = 1.0f;
	f32 value = 1.0f;
			
	f32 hh = hue / 60.0f;
	u32 i = hh;
	f32 ff = hh - i;
	
	f32 p = (1.0f - saturation);
	f32 q =	(1.0f - (saturation * ff));
	f32 t = (1.0f - (saturation * (1.0f - ff)));

	f32 r;
	f32 g;
	f32 b;
	
	if(i == 0)
	{
		r = value;
		g = t;
		b = p;
	}
	else if(i == 1)
	{
		r = q;
		g = value;
		b = p;
	}
	else if(i == 2)
	{
		r = p;
		g = value;
		b = t;
	}
	else if(i == 3)
	{
		r = p;
		g = q;
		b = value;
	}
	else if(i == 4)
	{
		r = t;
		g = p;
		b = value;
	}
	else
	{
		r = value;
		g = p;
		b = q;
	}

	return SColor(255, uint(r * 255.0f), uint(g * 255.0f), uint(b * 255.0f));	
}

void SyncAllScrapUsed(CRules@ this)
{
	if (!isServer()) return;
	
	string[]@ scrap_used_username;
	if (!this.get("scrap_used_username", @scrap_used_username)) return;

	int[]@ scrap_used_amount;
	if (!this.get("scrap_used_amount", @scrap_used_amount)) return;

	CBitStream params;
	params.write_bool(false);
	params.write_s32(scrap_used_username.size());

	for (uint i = 0; i < scrap_used_username.size(); i++)
	{
		params.write_string(scrap_used_username[i]);
		params.write_s32(scrap_used_amount[i]);
	}

	this.SendCommand(this.getCommandID("scrap_used"), params);
}