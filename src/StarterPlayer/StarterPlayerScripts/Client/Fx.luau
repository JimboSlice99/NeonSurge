--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

local Fx = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui: ScreenGui

function Fx.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "SurgeGardenFx"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20
	gui.Parent = playerGui
end

function Fx.Harvest(payload: Types.HarvestFxPayload)
	-- Floating world coins
	local part = Instance.new("Part")
	part.Name = "HarvestBurst"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.CFrame = CFrame.new(payload.position + Vector3.new(0, 3, 0))
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 48)
	bb.AlwaysOnTop = true
	bb.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = payload.color
	label.TextStrokeTransparency = 0.3
	label.Text = "+" .. tostring(payload.amount)
	label.Parent = bb

	TweenService:Create(part, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = part.CFrame + Vector3.new(0, 4, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		part:Destroy()
	end)

	-- Soft camera punch
	local cam = Workspace.CurrentCamera
	if cam then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local old = humanoid.CameraOffset
			humanoid.CameraOffset = old + Vector3.new(0, 0.35, 0)
			task.delay(0.08, function()
				humanoid.CameraOffset = old
			end)
		end
	end
end

return Fx
