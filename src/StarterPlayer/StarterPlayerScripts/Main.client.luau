--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local Client = script.Parent:WaitForChild("Client")
local Hud = require(Client:WaitForChild("Hud"))
local ShopUi = require(Client:WaitForChild("ShopUi"))

local player = Players.LocalPlayer
local remotes = Remotes.Get()

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local latest: Types.HudPayload? = nil

Hud.Init(function()
	ShopUi.Toggle()
	if latest then
		ShopUi.Refresh(latest)
	end
end)

ShopUi.Init({
	buyCoinItem = function(itemId: string)
		remotes.BuyShopItem:FireServer(itemId)
	end,
	buyPass = function(passKey: string)
		remotes.PromptGamePass:FireServer(passKey)
	end,
	buyProduct = function(productKey: string)
		remotes.PromptProduct:FireServer(productKey)
	end,
})

local function selectSeed(seedId: string)
	remotes.SelectSeed:FireServer(seedId)
end

remotes.HudUpdate.OnClientEvent:Connect(function(payload: Types.HudPayload)
	latest = payload
	Hud.Update(payload, selectSeed)
	if ShopUi.IsOpen() then
		ShopUi.Refresh(payload)
	end
end)

remotes.Notify.OnClientEvent:Connect(function(kind: string, message: string)
	Hud.Toast(kind, message)
end)

-- Soft camera feel
local function tuneCamera(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.CameraOffset = Vector3.new(0, 1.5, 0)
	end
end

if player.Character then
	tuneCamera(player.Character)
end
player.CharacterAdded:Connect(tuneCamera)

task.defer(function()
	remotes.RequestHud:FireServer()
end)

print("[SurgeGarden] Client ready — walk to a dirt plot and hold the prompt")
