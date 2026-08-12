--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local FxController = {}

local player = Players.LocalPlayer

local function orb(position: Vector3, color: Color3, scale: number)
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
	TweenService:Create(part, TweenInfo.new(0.3), {
		Size = Vector3.new(scale * 3, scale * 3, scale * 3),
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, 0.35)
end

function FxController.start()
	Remotes.get("FxBurst").OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		local color = if typeof(payload.color) == "Color3" then payload.color else Config.Palette.Cyan
		if payload.kind == "hit" or payload.kind == "kill" or payload.kind == "dash" then
			if typeof(payload.position) == "Vector3" then
				orb(payload.position, color, if payload.kind == "kill" then 1.3 else 0.7)
			end
		elseif payload.kind == "hurt" then
			local gui = player:FindFirstChild("PlayerGui")
			if not gui then
				return
			end
			local flash = Instance.new("ScreenGui")
			flash.IgnoreGuiInset = true
			flash.Parent = gui
			local frame = Instance.new("Frame")
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundColor3 = Config.Palette.Danger
			frame.BackgroundTransparency = 0.55
			frame.BorderSizePixel = 0
			frame.Parent = flash
			TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			Debris:AddItem(flash, 0.35)
		end
	end)
end

return FxController
