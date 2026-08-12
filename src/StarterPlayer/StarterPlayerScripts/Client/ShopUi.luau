--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local buyCoinItem: ((string) -> ())?
local buyPass: ((string) -> ())?
local buyProduct: ((string) -> ())?

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
	label.Size = UDim2.new(1, -8, 0, 28)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Config.Palette.Text
	label.Text = text
	label.Parent = parent
end

local function makeRow(parent: Instance, title: string, desc: string, buttonText: string, color: Color3, onClick: () -> ())
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 78)
	row.BackgroundColor3 = Color3.fromRGB(235, 232, 224)
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 12)
	pad(row, 10)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(0.62, 0, 0, 24)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Config.Palette.Text
	name.Text = title
	name.Parent = row

	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.new(0, 0, 0, 26)
	detail.Size = UDim2.new(0.62, 0, 0, 36)
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
	btn.Size = UDim2.new(0, 110, 0, 44)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Config.Palette.TextLight
	btn.Text = buttonText
	btn.AutoButtonColor = true
	btn.Parent = row
	corner(btn, 10)
	btn.MouseButton1Click:Connect(onClick)
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
	dim.BackgroundTransparency = 0.45
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Parent = gui
	dim.MouseButton1Click:Connect(function()
		ShopUi.SetOpen(false)
	end)

	root = Instance.new("Frame")
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.new(0.92, 0, 0.82, 0)
	root.BackgroundColor3 = Config.Palette.Panel
	root.BorderSizePixel = 0
	root.Parent = gui
	corner(root, 16)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(520, 720)
	sizeConstraint.Parent = root

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundTransparency = 1
	header.Parent = root
	pad(header, 12)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(0.7, 0, 1, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Config.Palette.Text
	title.Text = "Garden Shop"
	title.Parent = header

	titleCoins = Instance.new("TextLabel")
	titleCoins.BackgroundTransparency = 1
	titleCoins.AnchorPoint = Vector2.new(1, 0.5)
	titleCoins.Position = UDim2.new(1, -48, 0.5, 0)
	titleCoins.Size = UDim2.new(0, 140, 0, 28)
	titleCoins.Font = Enum.Font.GothamBold
	titleCoins.TextSize = 16
	titleCoins.TextXAlignment = Enum.TextXAlignment.Right
	titleCoins.TextColor3 = Config.Palette.Gold
	titleCoins.Text = "0 coins"
	titleCoins.Parent = header

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, 0, 0.5, 0)
	close.Size = UDim2.fromOffset(36, 36)
	close.BackgroundColor3 = Config.Palette.Danger
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Config.Palette.TextLight
	close.Text = "X"
	close.Parent = header
	corner(close, 10)
	close.MouseButton1Click:Connect(function()
		ShopUi.SetOpen(false)
	end)

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.new(0, 0, 0, 58)
	list.Size = UDim2.new(1, 0, 1, -58)
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
end

function ShopUi.IsOpen(): boolean
	return visible
end

function ShopUi.Toggle()
	ShopUi.SetOpen(not visible)
end

function ShopUi.Refresh(payload: Types.HudPayload)
	titleCoins.Text = tostring(payload.coins) .. " coins"

	for _, child in list:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	sectionLabel("Seeds, tools & zones", list)
	for _, itemId in Config.ShopOrder do
		local item = Config.ShopItems[itemId]
		if item then
			local owned = false
			if item.kind == "Tool" and item.toolId then
				owned = payload.ownedTools[item.toolId] == true
			elseif item.kind == "Zone" and item.zoneId then
				owned = payload.unlockedZones[item.zoneId] == true
			end
			local priceText = if owned then "Owned" else (tostring(item.price) .. "c")
			local desc = item.desc
			if item.kind == "Seed" and item.seedId then
				desc = desc .. "  (own " .. tostring(payload.ownedSeeds[item.seedId] or 0) .. ")"
			end
			makeRow(list, item.label, desc, priceText, if owned then Config.Palette.Muted else Config.Palette.Button, function()
				if not owned and buyCoinItem then
					buyCoinItem(itemId)
				end
			end)
		end
	end

	sectionLabel("Game Passes (Robux)", list)
	makeRow(list, "VIP", "+50% coins on every harvest", if payload.ownedPasses.VIP then "Owned" else "Buy", Config.Palette.ButtonRobux, function()
		if not payload.ownedPasses.VIP and buyPass then
			buyPass("VIP")
		end
	end)
	makeRow(list, "2x Grow Speed", "Crops grow twice as fast", if payload.ownedPasses.DoubleSpeed then "Owned" else "Buy", Config.Palette.ButtonRobux, function()
		if not payload.ownedPasses.DoubleSpeed and buyPass then
			buyPass("DoubleSpeed")
		end
	end)
	makeRow(list, "Auto Collect", "Auto-harvest ready plots", if payload.ownedPasses.AutoCollect then "Owned" else "Buy", Config.Palette.ButtonRobux, function()
		if not payload.ownedPasses.AutoCollect and buyPass then
			buyPass("AutoCollect")
		end
	end)

	sectionLabel("Coin & boost packs (Robux)", list)
	makeRow(list, "Small Coin Pack", "+" .. tostring(Config.DevProductRewards.CoinsSmall) .. " coins", "Buy", Config.Palette.ButtonRobux, function()
		if buyProduct then
			buyProduct("CoinsSmall")
		end
	end)
	makeRow(list, "Big Coin Pack", "+" .. tostring(Config.DevProductRewards.CoinsBig) .. " coins", "Buy", Config.Palette.ButtonRobux, function()
		if buyProduct then
			buyProduct("CoinsBig")
		end
	end)
	makeRow(list, "Rare Seed Pack", "Crystal, Melon & Berry seeds", "Buy", Config.Palette.ButtonRobux, function()
		if buyProduct then
			buyProduct("RareSeedPack")
		end
	end)
	makeRow(list, "Zone Skip", "Unlock the next locked zone", "Buy", Config.Palette.ButtonRobux, function()
		if buyProduct then
			buyProduct("ZoneSkip")
		end
	end)
end

return ShopUi
