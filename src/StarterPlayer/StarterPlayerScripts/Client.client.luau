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

type HudSnapshot = Types.HudSnapshot

Remotes.init()
Hud.mount()
InputController.start()
FxController.start()

Remotes.get("HudUpdate").OnClientEvent:Connect(function(snapshot: any)
	if typeof(snapshot) == "table" then
		Hud.apply(snapshot :: HudSnapshot)
	end
end)

print("[NeonSurge] Client ready — dash with Q, survive the surge")
