--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

type UpgradeOption = Types.UpgradeOption

local UpgradePicker = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: Frame

local RARITY = {
	Common = Config.Palette.Cyan,
	Rare = Config.Palette.Violet,
	Epic = Config.Palette.Gold,
}

function UpgradePicker.mount()
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("NeonSurgeUpgrades")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "NeonSurgeUpgrades"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.55
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 36)
	title.Position = UDim2.new(0, 0, 0.24, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 24
	title.TextColor3 = Config.Palette.Text
	title.Text = "SYSTEM UPGRADE"
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Position = UDim2.new(0, 0, 0.24, 34)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 14
	sub.TextColor3 = Config.Palette.Muted
	sub.Text = "Choose one protocol"
	sub.Parent = gui

	list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromOffset(700, 170)
	list.Position = UDim2.new(0.5, -350, 0.36, 0)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 14)
	layout.Parent = list
end

function UpgradePicker.show(options: { UpgradeOption })
	if not gui then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, opt in options do
		local color = RARITY[opt.rarity] or Config.Palette.Cyan
		local card = Instance.new("TextButton")
		card.Size = UDim2.fromOffset(210, 155)
		card.BackgroundColor3 = Config.Palette.Panel
		card.BorderSizePixel = 0
		card.AutoButtonColor = true
		card.Text = ""
		card.Parent = list
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 1.5
		stroke.Transparency = 0.25
		stroke.Parent = card

		local rarity = Instance.new("TextLabel")
		rarity.BackgroundTransparency = 1
		rarity.Size = UDim2.new(1, -18, 0, 18)
		rarity.Position = UDim2.fromOffset(10, 14)
		rarity.Font = Enum.Font.GothamBold
		rarity.TextSize = 12
		rarity.TextXAlignment = Enum.TextXAlignment.Left
		rarity.TextColor3 = color
		rarity.Text = string.upper(opt.rarity)
		rarity.Parent = card

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -18, 0, 28)
		name.Position = UDim2.fromOffset(10, 40)
		name.Font = Enum.Font.GothamBlack
		name.TextSize = 20
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Config.Palette.Text
		name.Text = opt.name
		name.Parent = card

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Size = UDim2.new(1, -18, 0, 55)
		desc.Position = UDim2.fromOffset(10, 78)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 14
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextColor3 = Config.Palette.Muted
		desc.Text = opt.desc
		desc.Parent = card

		card.MouseButton1Click:Connect(function()
			gui.Enabled = false
			Remotes.get("ChooseUpgrade"):FireServer(opt.id)
		end)
	end
	gui.Enabled = true
end

function UpgradePicker.hide()
	if gui then
		gui.Enabled = false
	end
end

return UpgradePicker
