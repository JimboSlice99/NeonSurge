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

local RARITY_COLOR = {
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
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0.22, 0)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 30
	title.TextColor3 = Config.Palette.Cyan
	title.Text = "LEVEL UP — PICK ONE"
	title.Parent = gui

	list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromOffset(720, 180)
	list.Position = UDim2.new(0.5, -360, 0.35, 0)
	list.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 16)
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
		local card = Instance.new("TextButton")
		card.Size = UDim2.fromOffset(220, 160)
		card.BackgroundColor3 = Color3.fromRGB(12, 16, 36)
		card.BorderSizePixel = 0
		card.AutoButtonColor = true
		card.Text = ""
		card.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = RARITY_COLOR[opt.rarity] or Config.Palette.Cyan
		stroke.Parent = card

		local rarity = Instance.new("TextLabel")
		rarity.BackgroundTransparency = 1
		rarity.Size = UDim2.new(1, -16, 0, 22)
		rarity.Position = UDim2.fromOffset(8, 12)
		rarity.Font = Enum.Font.GothamBold
		rarity.TextSize = 14
		rarity.TextXAlignment = Enum.TextXAlignment.Left
		rarity.TextColor3 = stroke.Color
		rarity.Text = string.upper(opt.rarity)
		rarity.Parent = card

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -16, 0, 30)
		name.Position = UDim2.fromOffset(8, 40)
		name.Font = Enum.Font.GothamBlack
		name.TextSize = 22
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = opt.name
		name.Parent = card

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Size = UDim2.new(1, -16, 0, 60)
		desc.Position = UDim2.fromOffset(8, 80)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 16
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextColor3 = Color3.fromRGB(210, 220, 255)
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
