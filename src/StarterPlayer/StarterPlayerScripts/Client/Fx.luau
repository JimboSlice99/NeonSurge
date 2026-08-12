--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local Fx = {}

local player = Players.LocalPlayer

function Fx.Init()
	Audio.Init()
end

local function burst(at: Vector3, color: Color3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(at + Vector3.new(0, 2.5, 0))
	part.Parent = Workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberSequence.new(0, 1)
	emitter.Lifetime = NumberRange.new(18, 28)
	emitter.Speed = NumberRange.new(3, 7)
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.LightEmission = 0.4
	emitter.Parent = attachment
	emitter:Emit(16)

	task.delay(1.2, function()
		part:Destroy()
	end)
end

function Fx.Harvest(payload: Types.HarvestFxPayload)
	burst(payload.position, payload.color)
	if payload.sound then
		Audio.Play(payload.sound, 0.55)
	else
		Audio.Play("Harvest", 0.55)
	end

	local part = Instance.new("Part")
	part.Name = "HarvestBurst"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.CFrame = CFrame.new(payload.position + Vector3.new(0, 3.2, 0))
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 52)
	bb.AlwaysOnTop = true
	bb.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = payload.color
	label.TextStrokeTransparency = 0.25
	label.Text = "+" .. tostring(payload.amount)
	label.Parent = bb

	TweenService:Create(part, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = part.CFrame + Vector3.new(0, 4.5, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.85), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		part:Destroy()
	end)

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local old = humanoid.CameraOffset
		humanoid.CameraOffset = old + Vector3.new(0, 0.4, 0)
		task.delay(0.1, function()
			humanoid.CameraOffset = old
		end)
	end
end

return Fx
