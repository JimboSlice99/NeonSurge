--!strict

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Config = require(script.Parent.Config)

local SoundUtil = {}

function SoundUtil.play(key: string, volume: number?, parent: Instance?)
	local id = Config.Sounds[key]
	if typeof(id) ~= "string" or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.35
	sound.PlaybackSpeed = 0.95 + math.random() * 0.1
	sound.Parent = parent or SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

return SoundUtil
