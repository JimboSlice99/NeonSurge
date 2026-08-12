--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))

local BuildBar = {}

local player = Players.LocalPlayer
local gui: ScreenGui

local ORDER = { "Pulse", "Beam", "Frost", "Nova" }

function BuildBar.mount()
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("NeonSurgeBuild")
	if old then
		old:Destroy()
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "NeonSurgeBuild"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = pg

	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(520, 74)
	bar.Position = UDim2.new(0.5, -260, 1, -110)
	bar.BackgroundColor3 = Config.Palette.Panel
	bar.BackgroundTransparency = 0.1
	bar.BorderSizePixel = 0
	bar.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bar

	for i, id in ORDER do
		local def = Config.Towers[id]
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(120, 58)
		b.Position = UDim2.fromOffset(10 + (i - 1) * 128, 8)
		b.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
		b.BorderSizePixel = 0
		b.AutoButtonColor = true
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.TextColor3 = Config.Palette.Text
		b.Text = ("%d  %s\n$%d"):format(i, def.name, def.cost)
		b.Parent = bar
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = b
		local stroke = Instance.new("UIStroke")
		stroke.Color = def.color
		stroke.Thickness = 1.2
		stroke.Transparency = 0.35
		stroke.Parent = b
		b.MouseButton1Click:Connect(function()
			Remotes.get("RequestSelectBuild"):FireServer(id)
		end)
	end
end

function BuildBar.setVisible(v: boolean)
	if gui then
		gui.Enabled = v
	end
end

return BuildBar
