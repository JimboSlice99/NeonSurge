--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

local Hud = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui: ScreenGui
local coinsLabel: TextLabel
local toolLabel: TextLabel
local seedRow: Frame
local toastLabel: TextLabel
local shopButton: TextButton
local onOpenShop: (() -> ())?

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

local function pad(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

function Hud.Init(openShop: () -> ())
	onOpenShop = openShop

	gui = Instance.new("ScreenGui")
	gui.Name = "SurgeGardenHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local top = Instance.new("Frame")
	top.Name = "TopBar"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.new(0.92, 0, 0, 56)
	top.BackgroundColor3 = Config.Palette.Panel
	top.BackgroundTransparency = 0.08
	top.BorderSizePixel = 0
	top.Parent = gui
	corner(top, 14)
	pad(top, 8)

	local brand = Instance.new("TextLabel")
	brand.BackgroundTransparency = 1
	brand.Size = UDim2.new(0.38, 0, 1, 0)
	brand.Font = Enum.Font.GothamBold
	brand.TextXAlignment = Enum.TextXAlignment.Left
	brand.TextSize = 18
	brand.TextColor3 = Config.Palette.Text
	brand.Text = Config.GameName
	brand.Parent = top

	coinsLabel = Instance.new("TextLabel")
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Position = UDim2.new(0.38, 0, 0, 0)
	coinsLabel.Size = UDim2.new(0.34, 0, 1, 0)
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextSize = 18
	coinsLabel.TextColor3 = Config.Palette.Gold
	coinsLabel.Text = "Coins: 0"
	coinsLabel.Parent = top

	shopButton = Instance.new("TextButton")
	shopButton.AnchorPoint = Vector2.new(1, 0.5)
	shopButton.Position = UDim2.new(1, -4, 0.5, 0)
	shopButton.Size = UDim2.new(0, 96, 0, 40)
	shopButton.BackgroundColor3 = Config.Palette.Button
	shopButton.Font = Enum.Font.GothamBold
	shopButton.TextSize = 16
	shopButton.TextColor3 = Config.Palette.TextLight
	shopButton.Text = "Shop"
	shopButton.AutoButtonColor = true
	shopButton.Parent = top
	corner(shopButton, 10)
	shopButton.MouseButton1Click:Connect(function()
		if onOpenShop then
			onOpenShop()
		end
	end)

	toolLabel = Instance.new("TextLabel")
	toolLabel.BackgroundTransparency = 1
	toolLabel.AnchorPoint = Vector2.new(0.5, 0)
	toolLabel.Position = UDim2.new(0.5, 0, 0, 76)
	toolLabel.Size = UDim2.new(0.9, 0, 0, 22)
	toolLabel.Font = Enum.Font.Gotham
	toolLabel.TextSize = 14
	toolLabel.TextColor3 = Config.Palette.TextLight
	toolLabel.TextStrokeTransparency = 0.5
	toolLabel.Text = "Tool: Basic Hands"
	toolLabel.Parent = gui

	seedRow = Instance.new("Frame")
	seedRow.Name = "SeedRow"
	seedRow.AnchorPoint = Vector2.new(0.5, 1)
	seedRow.Position = UDim2.new(0.5, 0, 1, -18)
	seedRow.Size = UDim2.new(0.96, 0, 0, 72)
	seedRow.BackgroundColor3 = Config.Palette.Panel
	seedRow.BackgroundTransparency = 0.05
	seedRow.BorderSizePixel = 0
	seedRow.Parent = gui
	corner(seedRow, 14)
	pad(seedRow, 8)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = seedRow

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 0)
	toastLabel.Position = UDim2.new(0.5, 0, 0, 108)
	toastLabel.Size = UDim2.new(0.8, 0, 0, 28)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.TextSize = 16
	toastLabel.TextColor3 = Config.Palette.TextLight
	toastLabel.TextStrokeTransparency = 0.4
	toastLabel.Text = ""
	toastLabel.TextTransparency = 1
	toastLabel.Parent = gui
end

function Hud.Toast(kind: string, message: string)
	toastLabel.Text = message
	toastLabel.TextColor3 = if kind == "err" then Config.Palette.Danger else Config.Palette.TextLight
	toastLabel.TextTransparency = 0
	task.delay(2.2, function()
		TweenService:Create(toastLabel, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
	end)
end

function Hud.Update(payload: Types.HudPayload, onSelectSeed: (string) -> ())
	coinsLabel.Text = "Coins: " .. tostring(payload.coins)
	local tool = Config.Tools[payload.equippedTool]
	toolLabel.Text = "Tool: " .. (if tool then tool.name else payload.equippedTool)

	for _, child in seedRow:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local order = { "Wheat", "Carrot", "Berry", "Melon", "Crystal" }
	for _, seedId in order do
		local count = payload.ownedSeeds[seedId] or 0
		local btn = Instance.new("TextButton")
		btn.Name = seedId
		btn.Size = UDim2.new(0, 68, 0, 56)
		btn.AutoButtonColor = true
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextWrapped = true
		local selected = payload.selectedSeed == seedId
		btn.BackgroundColor3 = if selected then Config.Palette.Button else Color3.fromRGB(230, 228, 220)
		btn.TextColor3 = if selected then Config.Palette.TextLight else Config.Palette.Text
		btn.Text = seedId .. "\n" .. tostring(count)
		btn.Parent = seedRow
		corner(btn, 10)
		btn.MouseButton1Click:Connect(function()
			if count > 0 then
				onSelectSeed(seedId)
			else
				Hud.Toast("err", "Buy " .. seedId .. " seeds in the shop")
			end
		end)
	end
end

return Hud
