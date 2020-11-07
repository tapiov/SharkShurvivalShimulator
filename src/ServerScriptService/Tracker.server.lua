-- Services
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

-- Variables
local players = {}

-- Local functions

-- This function is called once when a player character respawns
local function onCharacterSpawn(character)

	print(player.Name .. " joined.")
	local char = player.Character

	if not char then
		char = player.CharacterAdded:wait()
		player.CharacterAdded(onCharacterSpawn)
	end
	players[player] = char
end

-- This function is called once for all Player objects
local function onPlayerAdded(player)
	print(player.Name .. " joined.")
	local char = player.Character

	if not char then
		char = player.CharacterAdded:wait()
		--player.CharacterAdded(onCharacterSpawn)
	end
	players[player] = char
end

-- Print pretty V3s
local function prettyPrintV3(v3)
	return (" X = " .. math.floor(v3.X) .. " Y = " .. math.floor(v3.Y) .. " Z = " .. math.floor(v3.Z))
end

local function findDistance(start, destination)
	local d = math.sqrt((start.X - destination.X) ^ 2 + (start.Y - destination.Y) ^ 2 + (start.Z - destination.Z) ^ 2)
	return d
end

local function turnShark(player)
	local shark = script.Parent
	if shark then
		local sharkmouth = shark:FindFirstChild("SharkMouth")
		local char = player.Character

		-- Create a Vector3 for both the start position and target position
		local startPosition = sharkmouth.CFrame.Position
		local targetPosition = char.HumanoidRootPart.Position

		-- Put the Shark at 'startPosition' and point its front surface at 'targetPosition'
		shark.SharkMouth.Anchored = false
		sharkmouth.CFrame = CFrame.new(startPosition, targetPosition)
	-- shark.SharkMouth.Anchored = true
	end
end

local function findPath(start, destination)
	-- Create the path object

	-- These are for shark
	local agentParams = {
		AgentRadius = 8.0,
		AgentHeight = 20.0,
		AgentWalkableClimb = 2.0,
		AgentCollisionGroupName = "RedPlayers",
		CollectionWeights = {Bridge = 2.5, Minefield = math.huge},
		MaterialWeights = {Water = 1.5},
		AgentCanJump = true
	}

	local path = PathfindingService:CreatePath(agentParams)

	-- Compute the path
	path:ComputeAsync(start, destination)
	print("Path from " .. prettyPrintV3(start) .. " to " .. prettyPrintV3(destination))

	local waypoints = path:GetWaypoints()
	print("Path has " .. #waypoints .. " waypoints.")

	-- Loop through waypoints
	for _, waypoint in pairs(waypoints) do
		local part = Instance.new("Part")
		part.Shape = "Ball"
		part.Material = "Neon"
		part.Size = Vector3.new(0.6, 0.6, 0.6)
		part.Position = waypoint.Position
		part.Anchored = true
		part.CanCollide = false
		part.Parent = game.Workspace
	end
	return path
end

local function thrustShark(sharkPart, dirShark, turnPercentage, riseFallPercentage, thrustForce, thrustDuration)

	local thrust = dirShark.Unit * thrustForce

	-- X component will be capped with turnPercentage of Z
	local thrustX = thrust.X

	if (math.abs(thrustX) > turnPercentage * math.abs(thrust.Z)) then
		thrustX = turnPercentage * math.sign(thrustX) * math.abs(thrust.Z)
	end

	-- Y component will be capped with riseFallPercentage of Z
	local thrustY = thrust.Y

	if (math.abs(thrustY) > riseFallPercentage * math.abs(thrust.Z)) then
		thrustY = riseFallPercentage * math.sign(thrustY) * math.abs(thrust.Z)
	end

	-- Z component is calculated with X, Y and thrustForce
	local thrustZ = math.sqrt(thrustForce ^ 2 - thrustX ^ 2)

	-- Compose final force vector
	local finalThrustForce = Vector3.new(thrustX, 0 * thrustY, -1 * thrustZ)
	print("Final thrust vector is " .. prettyPrintV3(finalThrustForce))

	local thrustLocation = Vector3.new(0, 0, -18 / 2)

	sharkPart.BodyThrust.Location = thrustLocation
	sharkPart.BodyThrust.Force = finalThrustForce

	wait(thrustDuration)

	print("Thrusting ... ")
end

local function nullGravity(part)
	local antiGravity = Instance.new("BodyForce")
	antiGravity.Name = "AntiGravity"
	antiGravity.Archivable = false
	antiGravity.Parent = part
	-- antiGravity.Force = Vector3.new(0, part:GetMass() * 196.2, 0)
end

for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Process Player objects that are being added to the game
Players.PlayerAdded:Connect(onPlayerAdded)

-- Main

-- Variables for the shark and player
local sharkModel = workspace:FindFirstChild("RealShark")
local sharkPart, bodyThrust, rocketPropulsion

for i, d in pairs(sharkModel:GetDescendants()) do
	print(d.Name)
	if (d.Name == "WeightFront") then
		sharkPart = d
		bodyThrust = sharkPart.BodyThrust
		rocketPropulsion = sharkPart.RocketPropulsion
	end
end

-- Initial Thrust properties
local thrustForce = 50000
local turnPercentage = 0.005
local riseFallPercentage = 0.01
local thrustDuration = 0.1

-- Create a list of players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

local function onTouched(Obj)
	local h = Obj.Parent:FindFirstChild("Humanoid")
	if h then
		h.Health = 0
		players[Obj] = nil
	end
end

-- Events
Players.PlayerAdded:Connect(onPlayerAdded)
sharkPart.Touched:Connect(onTouched)

-- Game loop
while true do
	for p, c in pairs(players) do
		print("Looking at player " .. p.Name)
		if (p ~= nil) then

			-- Turn and move shark towards the player
			-- moveShark(player, sharkPart)

			local plrCF = c.HumanoidRootPart.CFrame
			local sharkHeadCF = sharkPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -18 / 2))

			local dist = findDistance(sharkHeadCF, plrCF)
			print("--------------------------------------------------------------")
			print("player is at " .. prettyPrintV3(plrCF.Position))
			print("Shark is at " .. prettyPrintV3(sharkHeadCF.Position))
			print("The distance is " .. dist)

			local dirWorld = plrCF.Position - sharkHeadCF.Position
			local dirShark = sharkHeadCF:VectorToObjectSpace(dirWorld)

			if (dist < 20) then
				-- Close enough to attack, calculate path to player
				-- local path = findPath(sharkHeadCF.Position, plrCF.Position)
				rocketPropulsion.Target = c.HumanoidRootPart
				rocketPropulsion.CartoonFactor = 0.7
				rocketPropulsion.TargetOffset = Vector3.new(0,0,0)
				rocketPropulsion.TargetRadius = 4
				rocketPropulsion:Fire()
				wait(0.1)
				rocketPropulsion:Abort()

			elseif (dist < 100) then
				-- Start closing distance faster
				-- Initial Thrust properties
				thrustForce = 50000
				turnPercentage = 0.005
				riseFallPercentage = 0.01
				thrustDuration = 0.1
				thrustShark(sharkPart, dirShark, turnPercentage, riseFallPercentage, thrustForce, thrustDuration)

			
			elseif (dist < 300) then
				-- Start closing distance slowly
				thrustForce = 20000
				turnPercentage = 0.01
				riseFallPercentage = 0.01
				thrustDuration = 0.5
				thrustShark(sharkPart, dirShark, turnPercentage, riseFallPercentage, thrustForce, thrustDuration)

			else 
				-- Turn around 
				thrustForce = 5000
				turnPercentage = 1
				riseFallPercentage = 1
				thrustDuration = 0.1
				thrustShark(sharkPart, dirShark, turnPercentage, riseFallPercentage, thrustForce, thrustDuration)
			end
		end
		--wait(1)
	end
	wait(0.1)
end
