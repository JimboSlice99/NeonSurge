--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)

local Remotes = {}

local function ensureFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Config.RemotesFolderName)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = Config.RemotesFolderName
	folder.Parent = ReplicatedStorage
	return folder
end

local function ensureRemoteEvent(name: string): RemoteEvent
	local folder = ensureFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function Remotes.init()
	ensureRemoteEvent("RequestFire")
	ensureRemoteEvent("RequestDash")
	ensureRemoteEvent("HudUpdate")
	ensureRemoteEvent("FxBurst")
	ensureRemoteEvent("RequestRestart")
end

function Remotes.get(name: string): RemoteEvent
	local folder = ensureFolder()
	local remote = folder:WaitForChild(name, 10)
	assert(remote and remote:IsA("RemoteEvent"), ("Missing RemoteEvent %s"):format(name))
	return remote
end

return Remotes
