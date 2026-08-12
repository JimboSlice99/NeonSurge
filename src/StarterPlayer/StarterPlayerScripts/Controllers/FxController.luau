--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local SoundUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("SoundUtil"))

local FxController = {}
local player = Players.LocalPlayer

local function spark(position: Vector3, color: Color3, scale: number)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.25
	part.Size = Vector3.new(scale, scale, scale)
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace
	TweenService:Create(part, TweenInfo.new(0.2), {
		Size = Vector3.new(scale * 2.4, scale * 2.4, scale * 2.4),
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, 0.22)
end

function FxController.start()
	Remotes.get("FxBurst").OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		local color = if typeof(payload.color) == "Color3" then payload.color else Config.Palette.Cyan
		if payload.kind == "hit" and typeof(payload.position) == "Vector3" then
			spark(payload.position, color, 0.4)
		elseif payload.kind == "kill" and typeof(payload.position) == "Vector3" then
			spark(payload.position, color, 0.85)
		elseif payload.kind == "dash" and typeof(payload.position) == "Vector3" then
			spark(payload.position, color, 0.65)
		elseif payload.kind == "slamImpact" and typeof(payload.position) == "Vector3" then
			spark(payload.position, color, 1.6)
			local ring = Instance.new("Part")
			ring.Anchored = true
			ring.CanCollide = false
			ring.CastShadow = false
			ring.Material = Enum.Material.Neon
			ring.Color = color
			ring.Transparency = 0.4
			ring.Size = Vector3.new(0.3, 2, 2)
			ring.CFrame = CFrame.new(payload.position) * CFrame.Angles(0, 0, math.rad(90))
			ring.Shape = Enum.PartType.Cylinder
			ring.Parent = Workspace
			TweenService:Create(ring, TweenInfo.new(0.28), {
				Size = Vector3.new(0.2, 28, 28),
				Transparency = 1,
			}):Play()
			Debris:AddItem(ring, 0.3)
		elseif payload.kind == "pickup" then
			SoundUtil.play("Pickup", 0.18)
		elseif payload.kind == "hurt" then
			SoundUtil.play("Hurt", 0.3)
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
			frame.BackgroundTransparency = 0.82
			frame.BorderSizePixel = 0
			frame.Parent = flash
			TweenService:Create(frame, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			Debris:AddItem(flash, 0.28)
		end
	end)
end

return FxController
