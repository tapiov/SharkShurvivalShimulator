local PlayerManager = {}
 
-- Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataStoreService = game:GetService("DataStoreService")

-- DataStores
local leaderBoardStore = dataStoreService:GetOrderedDataStore("Leaderboard")
local pointsStore = dataStoreService:GetOrderedDataStore("PointsStore")

-- Modules
local moduleScripts = ServerStorage:WaitForChild("ModuleScripts")
local gameSettings = require(moduleScripts:WaitForChild("GameSettings"))

 
-- Map Variables
local lobbySpawn = workspace.Lobby.StartSpawn
local arena = workspace:WaitForChild("Arena")

-- Values
local displayValues = ReplicatedStorage:WaitForChild("DisplayValues")
local playersLeft = displayValues:WaitForChild("PlayersLeft")
local winnerName = displayValues:WaitForChild("WinnerName")
 
-- Events
local events = ServerStorage:WaitForChild("Events")
local clientEvents = ReplicatedStorage:WaitForChild("Events")

local mapStart = events:WaitForChild("MapStart")
local mapStop = events:WaitForChild("MapStop")
local matchEnd = events:WaitForChild("MatchEnd")
local playerAFKToggle = clientEvents:WaitForChild("PlayerAFKToggle")

-- Player Variables
local activePlayers = { }
local afkPlayers = { }
 
-- Local Functions
local function changePlayerAFK(player)
	if (afkPlayers[player] == true) then
		afkPlayers[player] = false
	else 
		afkPlayers[player] = true
	end
	local s = "AFK list is now "
	for k,v in pairs(afkPlayers) do
		if (v == true) then
			s = s .. k.Name .. " "
		end
	end
	print(s)
end


local function respawnPlayerInLobby(player)
	player.RespawnLocation = lobbySpawn
	player:LoadCharacter()
end

local function checkPlayerCount()
	if #activePlayers == 0 then
		matchEnd:Fire(gameSettings.endStates.FoundWinner)
	end
end

local function removeActivePlayer(player)
	for playerKey, whichPlayer in pairs(activePlayers) do
		if whichPlayer == player then
			table.remove(activePlayers, playerKey)
			playersLeft.Value = #activePlayers
			checkPlayerCount()
		end
	end
end


local function awardPoints(player, points)
	
	local success, currentPoints = pcall(function()
		return pointsStore:GetAsync(player.UserId)
	end)
 	
	local success, newPoints = pcall(function()
		return pointsStore:IncrementAsync(player.UserId, points)
	end)
 
	if success then
		print("PlayerManager: Player " .. player.Name .. " ", currentPoints .. " ===> " .. newPoints .. " points")
	end
end	

local function onPlayerJoin(player)
	player.RespawnLocation = lobbySpawn
	afkPlayers[player] = false
	-- Make sure player has points
	awardPoints(player, 0)
end

local function preparePlayer(player, whichSpawn)
	player.RespawnLocation = whichSpawn
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	-- local sword = playerWeapon:Clone()
	-- sword.Parent = character
	
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		respawnPlayerInLobby(player)
		removeActivePlayer(player)
	end)
end

-- Local Functions
function onTouched(hit)
	-- endPart.TouchEnded:wait()
	print(hit)
	if(hit.Parent:FindFirstChild("Humanoid"))then
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		winnerName.Value = winnerName.Value .. " " .. player.Name
		
		awardPoints(player, 50)
				
		respawnPlayerInLobby(player)
		removeActivePlayer(player)
	end
end

function debounce(func)
    local isRunning = false    -- Create a local debounce variable
    return function(...)       -- Return a new function
        if not isRunning then
            isRunning = true
 
            func(...)          -- Call it with the original arguments
 
            isRunning = false
        end
    end
end

local function len(t)
    local n = 0
	for k,v in pairs(t) do
		if (v == true) then
			n = n + 1
		end
	end
    return n
end

-- Module Functions
function PlayerManager.sendPlayersToMatch()
	print("PlayerManager: Sending players to match")
	local arenaMap = arena:WaitForChild("CurrentMap")
	local spawnLocations = arenaMap:WaitForChild("SpawnLocations")
	local arenaSpawns = spawnLocations:GetChildren()
	
	local endPart = arenaMap:WaitForChild("End")
	endPart.Touched:connect(debounce(onTouched))
	
	for playerKey, whichPlayer in pairs(Players:GetPlayers()) do
		if (afkPlayers[whichPlayer] == false) then
			table.insert(activePlayers,whichPlayer)
			local spawnLocation = arenaSpawns[1]
			preparePlayer(whichPlayer, spawnLocation)
			-- awardPoints(whichPlayer, 50)
		end
	end
	winnerName.Value = ""
	playersLeft.Value = #activePlayers
end

function PlayerManager.getWinnerName()
	if (not(winnerName.Value == "")) then
		local returnString = "Winner(s): " .. winnerName.Value
		return returnString
	else
		return "Nobody survived!"
	end	
end

function PlayerManager.resetPlayers()
	for playerKey, whichPlayer in pairs(activePlayers) do
		respawnPlayerInLobby(whichPlayer)
	end
	activePlayers = {}
end

function PlayerManager.getAFKPlayersNumber()
	if (afkPlayers == nil) then
		return 0
	end
	local n = len(afkPlayers)
	return n
end

-- Events
Players.PlayerAdded:Connect(onPlayerJoin)
playerAFKToggle.OnServerEvent:Connect(changePlayerAFK)
 
return PlayerManager
