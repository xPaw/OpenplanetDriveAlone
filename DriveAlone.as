int nextDelta = 1000;
bool mapChanged = false;
string mapName = "";
auto ghostChoice = MwFastBuffer<wstring>();

void Main()
{
	ghostChoice.Add("0"); // C_GhostChoice_None

	auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);

	while (true)
	{
		Loop(app, network);
		sleep(nextDelta);
	}
}

void Loop(CTrackMania& app, CTrackManiaNetwork& network)
{
	// No map loaded - main menu
	if (app.RootMap is null)
	{
		nextDelta = 1000;
		mapName = "";
		return;
	}

	// Map change
	if (mapName != app.RootMap.IdName)
	{
		mapName = app.RootMap.IdName;
		mapChanged = true;
	}

	// If we already changed the state, wait for next map change
	// EndRound sequence is also used when you finish the round
	if (!mapChanged)
	{
		nextDelta = 1000;
		return;
	}

	auto playground = cast<CGameManiaAppPlayground>(network.ClientManiaAppPlayground);

	// In multiplayer sleep longer between checks
	if (playground is null || !playground.Playground.IsServerOrSolo)
	{
		nextDelta = 5000;
		return;
	}

	auto config = cast<CGamePlaygroundUIConfig>(playground.UI);

	// EndRound is used when map loads and it is replaying a ghost
	// RollingBackgroundIntro is just looping animation around the start block
	bool isAppropriateState =
		config.UISequence == CGamePlaygroundUIConfig::EUISequence::EndRound ||
		config.UISequence == CGamePlaygroundUIConfig::EUISequence::RollingBackgroundIntro;

	// If a map change is detected, keep waiting for the appropriate state
	if (!isAppropriateState)
	{
		nextDelta = 100;
		return;
	}

	// Send UI event that we clicked on "Drive alone" and then wait for a map change
	nextDelta = 1000;
	mapChanged = false;
	playground.SendCustomEvent("StartRaceMenuEvent_StartRace", ghostChoice);
}
