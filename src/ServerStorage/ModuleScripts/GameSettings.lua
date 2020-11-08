local GameSettings = {}
 
-- Game Variables
GameSettings.intermissionDuration = 10
GameSettings.matchDuration = 164
GameSettings.minimumPlayers = 1
GameSettings.transitionTime = 10

-- Possible ways that the game can end.
GameSettings.endStates = {
	TimerUp = "TimerUp",
	FoundWinner = "FoundWinner",
	AllDied = "AllDied"
}

return GameSettings
