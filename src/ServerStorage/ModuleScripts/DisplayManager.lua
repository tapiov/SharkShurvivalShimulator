local DisplayManager = {}
 
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- Display Values used to update Player GUI
local displayValues = ReplicatedStorage:WaitForChild("DisplayValues")
local status = displayValues:WaitForChild("Status")

local playersLeft = displayValues:WaitForChild("PlayersLeft")
local timeLeft = displayValues:WaitForChild("TimeLeft")
 
-- Local Functions
local function updateRoundStatus()
	status.Value = "Players : (" .. playersLeft.Value .. ") / Time : (" .. timeLeft.Value .. ")"
end

-- Module Functions
function DisplayManager.updateStatus(newStatus)
	status.Value = newStatus
end

playersLeft.Changed:Connect(updateRoundStatus)
timeLeft.Changed:Connect(updateRoundStatus)
 
return DisplayManager
