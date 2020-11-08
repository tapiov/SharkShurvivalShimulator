-- Services
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
 
-- Module Scripts
local moduleScripts = ServerStorage:WaitForChild("ModuleScripts")
local matchManager = require(moduleScripts:WaitForChild("MatchManager"))
local playerManager = require(moduleScripts:WaitForChild("PlayerManager"))
local gameSettings = require(moduleScripts:WaitForChild("GameSettings"))
local displayManager = require(moduleScripts:WaitForChild("DisplayManager"))
local randomMapPicker = require(moduleScripts:WaitForChild("RandomMapPicker"))
local endMatch = require(moduleScripts:WaitForChild("EndMatch"))

-- Events
local events = ServerStorage:WaitForChild("Events")
local matchEnd = events:WaitForChild("MatchEnd")

local mapStart = events:WaitForChild("MapStart")
local mapStop = events:WaitForChild("MapStop")

-- Test comment

-- Main game loop
while true do
	
	displayManager.updateStatus("Choosing next map")
	randomMapPicker.PickAMap()
	
	repeat
		print("GameManager: Starting intermission...")
		displayManager.updateStatus("Waiting for players...")
		wait(gameSettings.intermissionDuration)
		local afkPlayersNumber = playerManager.getAFKPlayersNumber()
	until Players.NumPlayers >= gameSettings.minimumPlayers + afkPlayersNumber
	
	print("GameManager: Intermission over")
	
	displayManager.updateStatus("Get ready!")
    wait(gameSettings.transitionTime)
 
	matchManager.prepareGame()
	-- Placeholder wait for the length of the game.
	local endState = matchEnd.Event:Wait()
	print("GameManager: Game ended with: " .. endState)
	mapStop:Fire()
	local endStatus = matchManager.getEndStatus(endState)
	displayManager.updateStatus(endStatus)
	
	matchManager.cleanupMatch()
	randomMapPicker.deleteMap()
	wait(gameSettings.transitionTime)
	
	matchManager.resetMatch()
	
end
