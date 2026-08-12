--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local Client = script.Parent:WaitForChild("Client")
local Audio = require(Client:WaitForChild("Audio"))
local Hud = require(Client:WaitForChild("Hud"))
local ShopUi = require(Client:WaitForChild("ShopUi"))
local Fx = require(Client:WaitForChild("Fx"))
local Tutorial = require(Client:WaitForChild("Tutorial"))

local player = Players.LocalPlayer
local remotes = Remotes.Get()

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local latest: Types.HudPayload? = nil
local tutorialShown = false

Audio.Init()
Fx.Init()

Tutorial.Init(function()
	remotes.TutorialDone:FireServer()
end)

Hud.Init({
	openShop = function()
		ShopUi.Toggle()
		if latest then
			ShopUi.Refresh(latest)
		end
	end,
	rebirth = function()
		remotes.RequestRebirth:FireServer()
	end,
	plantAll = function()
		remotes.PlantAll:FireServer()
	end,
	harvestAll = function()
		remotes.HarvestAll:FireServer()
	end,
	claimDaily = function()
		remotes.ClaimDaily:FireServer()
	end,
})

ShopUi.Init({
	buyCoinItem = function(itemId: string)
		Audio.Play("Click", 0.35)
		remotes.BuyShopItem:FireServer(itemId)
	end,
	buyPass = function(passKey: string)
		Audio.Play("Click", 0.35)
		remotes.PromptGamePass:FireServer(passKey)
	end,
	buyProduct = function(productKey: string)
		Audio.Play("Click", 0.35)
		remotes.PromptProduct:FireServer(productKey)
	end,
})

local function selectSeed(seedId: string)
	remotes.SelectSeed:FireServer(seedId)
end

remotes.HudUpdate.OnClientEvent:Connect(function(payload: Types.HudPayload)
	latest = payload
	Hud.Update(payload, selectSeed)
	ShopUi.Refresh(payload)
	if not tutorialShown then
		tutorialShown = true
		Tutorial.TryShow(payload.tutorialDone)
	end
end)

remotes.Notify.OnClientEvent:Connect(function(kind: string, message: string)
	Hud.Toast(kind, message)
end)

remotes.HarvestFx.OnClientEvent:Connect(function(payload: Types.HarvestFxPayload)
	Fx.Harvest(payload)
end)

local function tuneCamera(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.CameraOffset = Vector3.new(0, 2.2, 0)
	end
end

if player.Character then
	tuneCamera(player.Character)
end
player.CharacterAdded:Connect(tuneCamera)

task.defer(function()
	remotes.RequestHud:FireServer()
end)

print("[SurgeGarden] Client ready")
