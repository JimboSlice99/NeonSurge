--!strict

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Audio = {}

local folder: Folder

function Audio.Init()
	local existing = SoundService:FindFirstChild("SurgeGardenAudio")
	if existing and existing:IsA("Folder") then
		folder = existing
		return
	end
	folder = Instance.new("Folder")
	folder.Name = "SurgeGardenAudio"
	folder.Parent = SoundService
end

function Audio.Play(name: string, volume: number?)
	if not folder then
		Audio.Init()
	end
	local id = Config.Audio[name]
	if typeof(id) ~= "string" or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.45
	sound.PlaybackSpeed = 0.95 + math.random() * 0.1
	sound.Parent = folder
	local ok = pcall(function()
		sound:Play()
	end)
	if ok then
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
		task.delay(3, function()
			if sound.Parent then
				sound:Destroy()
			end
		end)
	else
		sound:Destroy()
	end
end

return Audio
