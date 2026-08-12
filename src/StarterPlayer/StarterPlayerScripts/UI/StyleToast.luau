--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local StyleToast = {}

local player = Players.LocalPlayer
local gui: ScreenGui

function StyleToast.mount()
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("NeonSurgeStyle")
	if old then
		old:Destroy()
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "NeonSurgeStyle"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = pg

	Remotes.get("StylePop").OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" or not gui then
			return
		end
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromOffset(280, 28)
		label.Position = UDim2.new(0.5, -140, 0.62, 0)
		label.Font = Enum.Font.GothamBlack
		label.TextSize = 20
		label.TextColor3 = Config.Palette.Gold
		label.TextTransparency = 0
		label.Text = tostring(payload.label or "STYLE")
		label.Parent = gui
		TweenService:Create(label, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -140, 0.55, 0),
			TextTransparency = 1,
		}):Play()
		Debris:AddItem(label, 0.6)
	end)
end

return StyleToast
