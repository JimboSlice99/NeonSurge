--!strict

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
local BuildBar = require(UI:WaitForChild("BuildBar"))

type HudSnapshot = Types.HudSnapshot
type LobbySnapshot = Types.LobbySnapshot

Remotes.init()
Hud.mount()
BuildBar.mount()
Lobby.mount(function()
	Lobby.setVisible(false)
	Hud.setVisible(true)
	BuildBar.setVisible(true)
	InputController.setArmed(true)
end)

InputController.start()
FxController.start()

Hud.setVisible(true)
Lobby.setVisible(true)
BuildBar.setVisible(false)
InputController.setArmed(false)

Remotes.get("HudUpdate").OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) ~= "table" then
		return
	end
	local data = snapshot :: HudSnapshot
	Hud.apply(data)
	if data.phase == "Lobby" or data.phase == "Results" then
		Lobby.setVisible(true)
		BuildBar.setVisible(false)
		InputController.setArmed(data.phase == "Results")
		if data.phase == "Results" then
			BuildBar.setVisible(false)
		end
	else
		Lobby.setVisible(false)
		BuildBar.setVisible(true)
		InputController.setArmed(true)
	end
end)

Remotes.get("LobbyUpdate").OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) == "table" then
		Lobby.apply(snapshot :: LobbySnapshot)
	end
end)

print("[NeonSurge] Client ready — tower defense")
