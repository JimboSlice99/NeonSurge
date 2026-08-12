--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Config)

local Remotes = {}

export type RemoteBag = {
	SelectSeed: RemoteEvent,
	BuyShopItem: RemoteEvent,
	PromptGamePass: RemoteEvent,
	PromptProduct: RemoteEvent,
	RequestHud: RemoteEvent,
	RequestRebirth: RemoteEvent,
	HudUpdate: RemoteEvent,
	Notify: RemoteEvent,
	HarvestFx: RemoteEvent,
}

local NAMES = {
	"SelectSeed",
	"BuyShopItem",
	"PromptGamePass",
	"PromptProduct",
	"RequestHud",
	"RequestRebirth",
	"HudUpdate",
	"Notify",
	"HarvestFx",
}

local cached: RemoteBag? = nil

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

function Remotes.Get(): RemoteBag
	if cached then
		return cached
	end
	local bag = {}
	for _, name in NAMES do
		bag[name] = ensure(name)
	end
	cached = bag :: RemoteBag
	return cached
end

return Remotes
