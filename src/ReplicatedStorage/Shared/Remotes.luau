--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Config)

local Remotes = {}

local NAMES = {
	"RequestStartRun",
	"RequestRestart",
	"RequestPlaceTower",
	"RequestUpgradeTower",
	"RequestSellTower",
	"RequestSelectBuild",
	"RequestStartWave",
	"RequestBuyMeta",
	"RequestBuyProduct",
	"HudUpdate",
	"LobbyUpdate",
	"FxBurst",
}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Config.RemotesFolderName)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = Config.RemotesFolderName
	created.Parent = ReplicatedStorage
	return created
end

local function ensure(name: string): RemoteEvent
	local parent = folder()
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function Remotes.init()
	for _, name in NAMES do
		ensure(name)
	end
end

function Remotes.get(name: string): RemoteEvent
	return ensure(name)
end

return Remotes
