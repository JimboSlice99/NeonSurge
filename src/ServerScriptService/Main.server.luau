--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Services = script.Parent:WaitForChild("Services")
local MapBuilder = require(Services:WaitForChild("MapBuilder"))
local DataService = require(Services:WaitForChild("DataService"))
local GardenService = require(Services:WaitForChild("GardenService"))
local MonetizationService = require(Services:WaitForChild("MonetizationService"))

Remotes.Get()
MapBuilder.Build()
DataService.Start()
GardenService.Start()
MonetizationService.Start()

local function onPlayer(player: Player)
	DataService.Load(player)
	MonetizationService.RefreshPasses(player)
	GardenService.SetupPlayer(player)

	player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if hrp and hrp:IsA("BasePart") then
			local offset = MapBuilder.GetGardenOffset(player)
			hrp.CFrame = CFrame.new(0 + offset.X, 6, 10 + offset.Z)
		end
	end)

	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local offset = MapBuilder.GetGardenOffset(player)
			hrp.CFrame = CFrame.new(0 + offset.X, 6, 10 + offset.Z)
		end
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end

print("[SurgeGarden] Server ready")
