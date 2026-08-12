--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

local ShopUi = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui: ScreenGui
local root: Frame
local list: ScrollingFrame
local titleCoins: TextLabel
local visible = false
local tab = "Farm"

local buyCoinItem: ((string) -> ())?
local buyPass: ((string) -> ())?
local buyProduct: ((string) -> ())?
local latest: Types.HudPayload?

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
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

local function sectionLabel(text: string, parent: Instance)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 0, 30)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Config.Palette.ButtonDark
	label.Text = text
	label.Parent = parent
end

local function makeRow(parent: Instance, title: string, desc: string, buttonText: string, color: Color3, onClick: () -> (), accent: Color3?)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 84)
	row.BackgroundColor3 = Color3.fromRGB(240, 236, 226)
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 14)
	pad(row, 12)

	if accent then
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 6, 1, 8)
		bar.Position = UDim2.new(0, -6, 0, -4)
		bar.BackgroundColor3 = accent
		bar.BorderSizePixel = 0
		bar.Parent = row
		corner(bar, 4)
	end

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(0.6, 0, 0, 26)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 17
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Config.Palette.Text
	name.Text = title
	name.Parent = row

	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.new(0, 0, 0, 28)
	detail.Size = UDim2.new(0.6, 0, 0, 40)
	detail.Font = Enum.Font.Gotham
	detail.TextSize = 13
	detail.TextWrapped = true
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextYAlignment = Enum.TextYAlignment.Top
	detail.TextColor3 = Config.Palette.Muted
	detail.Text = desc
	detail.Parent = row

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, 0, 0.5, 0)
	btn.Size = UDim2.new(0, 118, 0, 48)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.TextColor3 = Config.Palette.TextLight
	btn.Text = buttonText
	btn.AutoButtonColor = true
	btn.Parent = row
	corner(btn, 12)
	btn.MouseButton1Click:Connect(onClick)
end

local function rebuild()
	if not latest then
		return
	end
	local payload = latest
	titleCoins.Text = tostring(payload.coins) .. " coins"

	for _, child in list:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if tab == "Farm" then
		sectionLabel("Seeds", list)
		for _, itemId in Config.ShopOrder do
			local item = Config.ShopItems[itemId]
			if item and item.kind == "Seed" then
				local seed = item.seedId and Config.Seeds[item.seedId]
				local desc = item.desc .. "  (own " .. tostring(payload.ownedSeeds[item.seedId or ""] or 0) .. ")"
				makeRow(list, item.label, desc, tostring(item.price) .. "c", Config.Palette.Button, function()
					if buyCoinItem then
						buyCoinItem(itemId)
					end
				end, seed and seed.color)
			end
		end
		sectionLabel("Tools", list)
		for _, itemId in Config.ShopOrder do
			local item = Config.ShopItems[itemId]
			if item and item.kind == "Tool" and item.toolId then
				local owned = payload.ownedTools[item.toolId] == true
				makeRow(list, item.label, item.desc, if owned then "Owned" else (tostring(item.price) .. "c"), if owned then Config.Palette.Muted else Config.Palette.Button, function()
					if not owned and buyCoinItem then
						buyCoinItem(itemId)
					end
				end)
			end
		end
		sectionLabel("Farm Zones", list)
		for _, itemId in Config.ShopOrder do
			local item = Config.ShopItems[itemId]
			if item and item.kind == "Zone" and item.zoneId then
				local owned = payload.unlockedZones[item.zoneId] == true
				makeRow(list, item.label, item.desc, if owned then "Owned" else (tostring(item.price) .. "c"), if owned then Config.Palette.Muted else Config.Palette.ButtonDark, function()
					if not owned and buyCoinItem then
						buyCoinItem(itemId)
					end
				end)
			end
		end
	else
		sectionLabel("Game Passes", list)
		makeRow(list, "VIP Farmer", "+50% coins on every harvest", if payload.ownedPasses.VIP then "Owned" else "Robux", Config.Palette.ButtonRobux, function()
			if not payload.ownedPasses.VIP and buyPass then
				buyPass("VIP")
			end
		end)
		makeRow(list, "2x Grow Speed", "Crops grow twice as fast", if payload.ownedPasses.DoubleSpeed then "Owned" else "Robux", Config.Palette.ButtonRobux, function()
			if not payload.ownedPasses.DoubleSpeed and buyPass then
				buyPass("DoubleSpeed")
			end
		end)
		makeRow(list, "Auto Collect", "Auto-harvest ready plots", if payload.ownedPasses.AutoCollect then "Owned" else "Robux", Config.Palette.ButtonRobux, function()
			if not payload.ownedPasses.AutoCollect and buyPass then
				buyPass("AutoCollect")
			end
		end)
		sectionLabel("Coin & Boost Packs", list)
		makeRow(list, "Small Coin Pack", "+" .. tostring(Config.DevProductRewards.CoinsSmall) .. " coins", "Robux", Config.Palette.ButtonRobux, function()
			if buyProduct then
				buyProduct("CoinsSmall")
			end
		end)
		makeRow(list, "Big Coin Pack", "+" .. tostring(Config.DevProductRewards.CoinsBig) .. " coins", "Robux", Config.Palette.ButtonRobux, function()
			if buyProduct then
				buyProduct("CoinsBig")
			end
		end)
		makeRow(list, "Rare Seed Crate", "Crystal, Moonbloom, Melon, Corn", "Robux", Config.Palette.ButtonRobux, function()
			if buyProduct then
				buyProduct("RareSeedPack")
			end
		end)
		makeRow(list, "Zone Skip", "Unlock the next locked farm zone", "Robux", Config.Palette.ButtonRobux, function()
			if buyProduct then
				buyProduct("ZoneSkip")
			end
		end)
	end
end

function ShopUi.Init(handlers: {
	buyCoinItem: (string) -> (),
	buyPass: (string) -> (),
	buyProduct: (string) -> (),
})
	buyCoinItem = handlers.buyCoinItem
	buyPass = handlers.buyPass
	buyProduct = handlers.buyProduct

	gui = Instance.new("ScreenGui")
	gui.Name = "SurgeGardenShop"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.4
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Parent = gui
	dim.MouseButton1Click:Connect(function()
		ShopUi.SetOpen(false)
	end)

	root = Instance.new("Frame")
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.52)
	root.Size = UDim2.new(0.94, 0, 0.84, 0)
	root.BackgroundColor3 = Config.Palette.Panel
	root.BorderSizePixel = 0
	root.Parent = gui
	corner(root, 20)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(560, 760)
	sizeConstraint.Parent = root

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundTransparency = 1
	header.Parent = root
	pad(header, 14)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(0.55, 0, 1, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Config.Palette.ButtonDark
	title.Text = "Farm Market"
	title.Parent = header

	titleCoins = Instance.new("TextLabel")
	titleCoins.BackgroundTransparency = 1
	titleCoins.AnchorPoint = Vector2.new(1, 0.5)
	titleCoins.Position = UDim2.new(1, -52, 0.5, 0)
	titleCoins.Size = UDim2.new(0, 150, 0, 28)
	titleCoins.Font = Enum.Font.GothamBold
	titleCoins.TextSize = 16
	titleCoins.TextXAlignment = Enum.TextXAlignment.Right
	titleCoins.TextColor3 = Config.Palette.Gold
	titleCoins.Text = "0 coins"
	titleCoins.Parent = header

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, 0, 0.5, 0)
	close.Size = UDim2.fromOffset(40, 40)
	close.BackgroundColor3 = Config.Palette.Danger
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Config.Palette.TextLight
	close.Text = "X"
	close.Parent = header
	corner(close, 12)
	close.MouseButton1Click:Connect(function()
		ShopUi.SetOpen(false)
	end)

	local tabs = Instance.new("Frame")
	tabs.Position = UDim2.new(0, 12, 0, 64)
	tabs.Size = UDim2.new(1, -24, 0, 40)
	tabs.BackgroundTransparency = 1
	tabs.Parent = root
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabs

	local function makeTab(name: string)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.BackgroundColor3 = if tab == name then Config.Palette.Button else Color3.fromRGB(220, 215, 205)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 16
		btn.TextColor3 = if tab == name then Config.Palette.TextLight else Config.Palette.Text
		btn.Text = name
		btn.Parent = tabs
		corner(btn, 10)
		btn.MouseButton1Click:Connect(function()
			tab = name
			for _, child in tabs:GetChildren() do
				if child:IsA("TextButton") then
					local active = child.Text == tab
					child.BackgroundColor3 = if active then Config.Palette.Button else Color3.fromRGB(220, 215, 205)
					child.TextColor3 = if active then Config.Palette.TextLight else Config.Palette.Text
				end
			end
			rebuild()
		end)
	end
	makeTab("Farm")
	makeTab("Robux")

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 0, 0, 112)
	list.Size = UDim2.new(1, 0, 1, -112)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = root
	pad(list, 12)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = list
end

function ShopUi.SetOpen(open: boolean)
	visible = open
	gui.Enabled = open
	if open then
		root.Position = UDim2.fromScale(0.5, 0.58)
		root.BackgroundTransparency = 0.2
		TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 0,
		}):Play()
		rebuild()
	end
end

function ShopUi.IsOpen(): boolean
	return visible
end

function ShopUi.Toggle()
	ShopUi.SetOpen(not visible)
end

function ShopUi.Refresh(payload: Types.HudPayload)
	latest = payload
	if visible then
		rebuild()
	end
end

return ShopUi
