const string[] messages = {
	"We have official Discord server! (link in TAB menu)",
	"Spotted a bug? Game broke? Report it to Discord server! (link in TAB menu)",
	"Enjoying mod? You can support the developer on Patreon! (link in TAB menu)",
	"Did you know? There are tens of built-in custom music tracks. Enable in-game music through your settings",
	"Laggy? Check out the instruction in TAB menu in the top left corner"
};

void onTick(CRules@ this)
{
    if (getGameTime() % 9000 == 0)
    {
		if (isClient() && getLocalPlayer() !is null && XORRandom(5) == 0)
		{
            client_AddToChat("[SV] "+messages[XORRandom(messages.size())], SColor(255,0,0,0));
		}
    }
}