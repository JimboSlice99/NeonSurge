--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local FxController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function spawnOrb(position: Vector3, color: Color3, scale: number)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.new(scale, scale, scale)
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 3
	light.Range = 12
	light.Parent = part

	TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(scale * 3.5, scale * 3.5, scale * 3.5),
		Transparency = 1,
	}):Play()
	TweenService:Create(light, TweenInfo.new(0.35), { Brightness = 0 }):Play()
	Debris:AddItem(part, 0.4)
end

local function shake(intensity: number)
	if not camera then
		return
	end
	local original = camera.CFrame
	for _ = 1, 4 do
		camera.CFrame = original * CFrame.new((math.random() - 0.5) * intensity, (math.random() - 0.5) * intensity, 0)
		task.wait(0.02)
	end
	camera.CFrame = original
end

local function flashHurt()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then
		return
	end
	local overlay = Instance.new("ScreenGui")
	overlay.Name = "HurtFlash"
	overlay.IgnoreGuiInset = true
	overlay.Parent = gui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Config.Palette.Magenta
	frame.BackgroundTransparency = 0.55
	frame.BorderSizePixel = 0
	frame.Parent = overlay

	TweenService:Create(frame, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	Debris:AddItem(overlay, 0.4)
end

function FxController.start()
	Remotes.get("FxBurst").OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local kind = payload.kind
		local color = payload.color
		if typeof(color) ~= "Color3" then
			color = Config.Palette.Cyan
		end

		if kind == "hit" or kind == "kill" then
			local position = payload.position
			if typeof(position) == "Vector3" then
				spawnOrb(position, color, if kind == "kill" then 1.4 else 0.7)
			end
			if kind == "kill" then
				task.spawn(shake, 0.25)
			end
		elseif kind == "dash" then
			local position = payload.position
			if typeof(position) == "Vector3" then
				spawnOrb(position, color, 1.1)
			end
		elseif kind == "hurt" then
			flashHurt()
			task.spawn(shake, 0.45)
		end
	end)
end

return FxController
