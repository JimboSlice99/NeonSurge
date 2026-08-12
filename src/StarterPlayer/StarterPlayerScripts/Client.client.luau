--!strict
-- Neon Surge client bootstrap

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local root = script.Parent
local Controllers = root:WaitForChild("Controllers")
local UI = root:WaitForChild("UI")

local InputController = require(Controllers:WaitForChild("InputController"))
local FxController = require(Controllers:WaitForChild("FxController"))
local Hud = require(UI:WaitForChild("Hud"))
local Lobby = require(UI:WaitForChild("Lobby"))
local UpgradePicker = require(UI:WaitForChild("UpgradePicker"))

type HudSnapshot = Types.HudSnapshot
type LobbySnapshot = Types.LobbySnapshot
type UpgradeOption = Types.UpgradeOption

Remotes.init()
Hud.mount()
UpgradePicker.mount()
Lobby.mount(function()
	Lobby.setVisible(false)
	Hud.setVisible(true)
	InputController.setArmed(true)
end)
InputController.start()
FxController.start()

Hud.setVisible(true)
Lobby.setVisible(true)
InputController.setArmed(false)

Remotes.get("HudUpdate").OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then
		return
	end
	local data = snapshot :: HudSnapshot
	Hud.apply(data)
	if data.phase == "Lobby" then
		Lobby.setVisible(true)
		InputController.setArmed(false)
		UpgradePicker.hide()
	elseif data.phase == "GameOver" then
		InputController.setArmed(false)
		UpgradePicker.hide()
		Lobby.setVisible(true)
	elseif data.phase == "LevelUp" then
		InputController.setArmed(false)
	else
		Lobby.setVisible(false)
		InputController.setArmed(true)
	end
end)

Remotes.get("LobbyUpdate").OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) == "table" then
		Lobby.apply(snapshot :: LobbySnapshot)
	end
end)

Remotes.get("UpgradeChoices").OnClientEvent:Connect(function(options: any)
	if typeof(options) == "table" then
		UpgradePicker.show(options :: { UpgradeOption })
	end
end)

print("[NeonSurge] Client ready — lobby live")
