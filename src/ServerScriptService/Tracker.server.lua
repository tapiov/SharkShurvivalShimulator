-- Services
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

-- Variables
local players = {}

-- Local functions

-- This function is called once for all Player objects
local function onPlayerAdded(player)
	print(player.Name .. " joined.")
	local char = player.Character

	if not char then
		char = player.CharacterAdded:wait()
	end
	players[player] = char
end

-- Print pretty V3s
local function prettyPrintV3(v3)
	return (" X = " .. math.floor(v3.X) .. " Y = " .. math.floor(v3.Y) .. " Z = " .. math.floor(v3.Z))
end

local function characterPos(player)
	local char = player.Character
	if not char then
		char = player.CharacterAdded:wait()
	end
	local pos = char.HumanoidRootPart.Position
	print("Player " .. player.Name .. " is at " .. prettyPrintV3(pos))
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

local function moveShark(player, sharkPart)
	local char = player.Character
	print("Shark is at " .. sharkPart.Position.X .. " " .. sharkPart.Position.Y .. " " .. sharkPart.Position.Z)

	-- Solving for shark head location, i.e weightFront front side
	-- Thrust part is 3 x 1 x 18
	local CenterOfSharkHeadFaceCF = sharkPart.CFrame + Vector3.new(0, 0, -18 / 2)

	local plrCF = char.HumanoidRootPart.CFrame

	-- Relative to shark
	-- local dirCF = wrldSpaceCenterOfSharkHeadCF:ToObjectSpace(plrCF)
	local dirCF = plrCF:ToObjectSpace(CenterOfSharkHeadFaceCF)

	-- Create direction vector from player to shark mouth
	-- local dir = char.HumanoidRootPart.Position - wrldSpaceCenterOfSharkHeadCF.Position
	local dir = dirCF.Position

	-- Direction vector determines the body thrust vector direction on weight part
	-- Thrust surface is 3 x 1
	print("Direction vector is " .. dir.X .. " " .. dir.Y .. " " .. dir.Z)

	-- Vector lenght
	local dirLen = math.sqrt((dir.X) ^ 2 + (dir.Z) ^ 2)

	-- Component ratios
	local ratioX = dir.X / dirLen
	local ratioZ = dir.Z / dirLen

	-- local thrustLocation = CFrame.new():ToObjectSpace(wrldSpaceCenterOfSharkHeadCF).Position

	local thrustLocation = Vector3.new(0, 0, -18 / 2)
	local thrustForce = Vector3.new(10000 * (1 / dir.X), 0.0 * dir.Y, -100000 * (1 / dir.Z))

	sharkPart.BodyThrust.Location = thrustLocation
	sharkPart.BodyThrust.Force = thrustForce
	print("Pushing ... force = " .. math.floor(thrustForce.X) .. " " .. thrustForce.Y .. " " .. math.floor(thrustForce.Z))

	-- And move the shark

	-- print(sharkmouth.CFrame.Position)
	-- sharkmouth.CFrame = sharkmouth.CFrame + move
	-- print(sharkmouth.CFrame.Position)
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
local sharkPart, bodyThrust

for i, d in pairs(sharkModel:GetDescendants()) do
	print(d.Name)
	if (d.Name == "WeightFront") then
		sharkPart = d
		bodyThrust = sharkPart.BodyThrust
	end
end

-- Initial Thrust properties
local thrustForce = 50000
local turnPercentage = 0.005
local riseFallPercentage = 0.01

-- Create a list of players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Game loop
while true do
	for p, c in pairs(players) do
		print("Looking at player " .. p.Name)
		if (p ~= nil) then
			characterPos(p)

			-- Turn and move shark towards the player
			-- moveShark(player, sharkPart)

			local plrCF = c.HumanoidRootPart.CFrame
			local sharkHeadCF = sharkPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -18 / 2))

			local dist = findDistance(sharkHeadCF, plrCF)
			print("--------------------------------------------------------------")
			print("player is at " .. prettyPrintV3(plrCF.Position))
			print("Shark is at " .. prettyPrintV3(sharkHeadCF.Position))
			print("The distance is " .. dist)

			if (dist < 20) then
				-- Close enough to attack, calculate path to player
				local path = findPath(sharkHeadCF.Position, plrCF.Position)

			elseif (dist < 100) then
				-- Start closing distance faster
				-- Initial Thrust properties
				thrustForce = 50000
				turnPercentage = 0.005
				riseFallPercentage = 0.01

			
			elseif (dist < 300) then
				-- Start closing distance slowly
				thrustForce = 20000
				turnPercentage = 0.01
				riseFallPercentage = 0.01
			else 
				-- Set random course, slow cruise

			end


			local dirWorld = plrCF.Position - sharkHeadCF.Position
			local dirShark = sharkHeadCF:VectorToObjectSpace(dirWorld)

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

			print("Pushing ... ")
		--wait(1)

		--local thrustForce = Vector3.new(0, 0, 0)

		-- sharkPart.BodyThrust.Location = thrustLocation
		-- sharkPart.BodyThrust.Force = thrustForce

		-- wait(1)
		end
		--wait(1)
	end
	wait(0.1)
end
