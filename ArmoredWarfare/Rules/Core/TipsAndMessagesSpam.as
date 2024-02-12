const string[] messages = {
	"We have official Discord server! (link in TAB)",
	"Spotted a bug? Game broke? Report it to Discord server! (link in TAB)",
	"Enjoying mod? Support the developer on Patreon! (link in tab)"
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