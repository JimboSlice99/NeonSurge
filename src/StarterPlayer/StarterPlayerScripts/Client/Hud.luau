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
local multLabel: TextLabel
local toolLabel: TextLabel
local goalLabel: TextLabel
local seedRow: ScrollingFrame
local toastLabel: TextLabel
local rebirthBtn: TextButton
local onOpenShop: (() -> ())?
local onRebirth: (() -> ())?
local displayedCoins = 0

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1.5
	s.Transparency = 0.35
	s.Parent = parent
end

local function pad(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

local function formatCoins(n: number): string
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n))
end

local function tweenCoins(target: number)
	local start = displayedCoins
	local anim = Instance.new("NumberValue")
	anim.Value = start
	anim.Changed:Connect(function(v)
		displayedCoins = v
		coinsLabel.Text = formatCoins(v)
	end)
	TweenService:Create(anim, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target }):Play()
	task.delay(0.4, function()
		anim:Destroy()
		displayedCoins = target
		coinsLabel.Text = formatCoins(target)
	end)
end

function Hud.Init(handlers: { openShop: () -> (), rebirth: () -> () })
	onOpenShop = handlers.openShop
	onRebirth = handlers.rebirth

	gui = Instance.new("ScreenGui")
	gui.Name = "SurgeGardenHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- Top brand + stats
	local top = Instance.new("Frame")
	top.Name = "TopBar"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 10)
	top.Size = UDim2.new(0.94, 0, 0, 64)
	top.BackgroundColor3 = Config.Palette.Panel
	top.BackgroundTransparency = 0.04
	top.BorderSizePixel = 0
	top.Parent = gui
	corner(top, 16)
	stroke(top, Color3.fromRGB(200, 190, 160), 2)
	pad(top, 10)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(920, 80)
	sizeConstraint.Parent = top

	local brand = Instance.new("TextLabel")
	brand.BackgroundTransparency = 1
	brand.Size = UDim2.new(0.34, 0, 1, 0)
	brand.Font = Enum.Font.FredokaOne
	brand.TextXAlignment = Enum.TextXAlignment.Left
	brand.TextScaled = true
	brand.TextColor3 = Config.Palette.ButtonDark
	brand.Text = Config.GameName
	brand.Parent = top

	local coinBox = Instance.new("Frame")
	coinBox.Size = UDim2.new(0.28, 0, 1, 0)
	coinBox.Position = UDim2.new(0.34, 0, 0, 0)
	coinBox.BackgroundColor3 = Config.Palette.PanelAccent
	coinBox.BorderSizePixel = 0
	coinBox.Parent = top
	corner(coinBox, 12)

	coinsLabel = Instance.new("TextLabel")
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Size = UDim2.new(1, -8, 0.62, 0)
	coinsLabel.Position = UDim2.new(0, 4, 0, 2)
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextScaled = true
	coinsLabel.TextColor3 = Config.Palette.Gold
	coinsLabel.Text = "0"
	coinsLabel.Parent = coinBox

	multLabel = Instance.new("TextLabel")
	multLabel.BackgroundTransparency = 1
	multLabel.Size = UDim2.new(1, -8, 0.38, 0)
	multLabel.Position = UDim2.new(0, 4, 0.58, 0)
	multLabel.Font = Enum.Font.Gotham
	multLabel.TextScaled = true
	multLabel.TextColor3 = Config.Palette.Muted
	multLabel.Text = "x1.00 coins"
	multLabel.Parent = coinBox

	local shopButton = Instance.new("TextButton")
	shopButton.AnchorPoint = Vector2.new(1, 0.5)
	shopButton.Position = UDim2.new(1, -4, 0.5, 0)
	shopButton.Size = UDim2.new(0.2, 0, 0, 44)
	shopButton.BackgroundColor3 = Config.Palette.Button
	shopButton.Font = Enum.Font.GothamBold
	shopButton.TextScaled = true
	shopButton.TextColor3 = Config.Palette.TextLight
	shopButton.Text = "SHOP"
	shopButton.AutoButtonColor = true
	shopButton.Parent = top
	corner(shopButton, 12)
	stroke(shopButton, Color3.fromRGB(40, 90, 50), 1.5)
	shopButton.MouseButton1Click:Connect(function()
		if onOpenShop then
			onOpenShop()
		end
	end)

	-- Goal strip
	local goal = Instance.new("Frame")
	goal.AnchorPoint = Vector2.new(0.5, 0)
	goal.Position = UDim2.new(0.5, 0, 0, 82)
	goal.Size = UDim2.new(0.9, 0, 0, 34)
	goal.BackgroundColor3 = Config.Palette.ButtonDark
	goal.BackgroundTransparency = 0.15
	goal.BorderSizePixel = 0
	goal.Parent = gui
	corner(goal, 10)
	local goalConstraint = Instance.new("UISizeConstraint")
	goalConstraint.MaxSize = Vector2.new(720, 40)
	goalConstraint.Parent = goal

	goalLabel = Instance.new("TextLabel")
	goalLabel.BackgroundTransparency = 1
	goalLabel.Size = UDim2.fromScale(1, 1)
	goalLabel.Font = Enum.Font.GothamMedium
	goalLabel.TextScaled = true
	goalLabel.TextColor3 = Config.Palette.TextLight
	goalLabel.Text = "Walk to a dirt plot and Plant!"
	goalLabel.Parent = goal
	pad(goal, 6)

	toolLabel = Instance.new("TextLabel")
	toolLabel.BackgroundTransparency = 1
	toolLabel.AnchorPoint = Vector2.new(0, 0)
	toolLabel.Position = UDim2.new(0.03, 0, 0, 124)
	toolLabel.Size = UDim2.new(0.45, 0, 0, 22)
	toolLabel.Font = Enum.Font.Gotham
	toolLabel.TextSize = 14
	toolLabel.TextXAlignment = Enum.TextXAlignment.Left
	toolLabel.TextColor3 = Config.Palette.TextLight
	toolLabel.TextStrokeTransparency = 0.45
	toolLabel.Text = "Tool: Worn Gloves"
	toolLabel.Parent = gui

	rebirthBtn = Instance.new("TextButton")
	rebirthBtn.AnchorPoint = Vector2.new(1, 0)
	rebirthBtn.Position = UDim2.new(0.97, 0, 0, 120)
	rebirthBtn.Size = UDim2.new(0, 130, 0, 36)
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 180)
	rebirthBtn.Font = Enum.Font.GothamBold
	rebirthBtn.TextSize = 14
	rebirthBtn.TextColor3 = Config.Palette.TextLight
	rebirthBtn.Text = "Rebirth"
	rebirthBtn.Parent = gui
	corner(rebirthBtn, 10)
	rebirthBtn.MouseButton1Click:Connect(function()
		if onRebirth then
			onRebirth()
		end
	end)

	-- Seed tray
	seedRow = Instance.new("ScrollingFrame")
	seedRow.Name = "SeedRow"
	seedRow.AnchorPoint = Vector2.new(0.5, 1)
	seedRow.Position = UDim2.new(0.5, 0, 1, -14)
	seedRow.Size = UDim2.new(0.96, 0, 0, 86)
	seedRow.BackgroundColor3 = Config.Palette.Panel
	seedRow.BackgroundTransparency = 0.02
	seedRow.BorderSizePixel = 0
	seedRow.ScrollBarThickness = 4
	seedRow.ScrollingDirection = Enum.ScrollingDirection.X
	seedRow.CanvasSize = UDim2.new(0, 0, 0, 0)
	seedRow.AutomaticCanvasSize = Enum.AutomaticSize.X
	seedRow.Parent = gui
	corner(seedRow, 16)
	stroke(seedRow, Color3.fromRGB(200, 190, 160), 2)
	pad(seedRow, 10)

	local seedConstraint = Instance.new("UISizeConstraint")
	seedConstraint.MaxSize = Vector2.new(900, 100)
	seedConstraint.Parent = seedRow

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = seedRow

	toastLabel = Instance.new("TextLabel")
	toastLabel.AnchorPoint = Vector2.new(0.5, 0)
	toastLabel.Position = UDim2.new(0.5, 0, 0, 128)
	toastLabel.Size = UDim2.new(0.7, 0, 0, 30)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.TextSize = 18
	toastLabel.TextColor3 = Config.Palette.TextLight
	toastLabel.TextStrokeTransparency = 0.35
	toastLabel.Text = ""
	toastLabel.TextTransparency = 1
	toastLabel.Parent = gui

	-- Subtle tip pulse on first load
	task.delay(0.6, function()
		local tip = Instance.new("TextLabel")
		tip.Name = "WelcomeTip"
		tip.AnchorPoint = Vector2.new(0.5, 0.5)
		tip.Position = UDim2.fromScale(0.5, 0.42)
		tip.Size = UDim2.new(0.7, 0, 0, 40)
		tip.BackgroundTransparency = 1
		tip.Font = Enum.Font.FredokaOne
		tip.TextScaled = true
		tip.TextColor3 = Config.Palette.TextLight
		tip.TextStrokeTransparency = 0.3
		tip.Text = "Head through the arch → plant your fields!"
		tip.Parent = gui
		TweenService:Create(tip, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
		task.delay(4, function()
			TweenService:Create(tip, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
			task.wait(0.9)
			tip:Destroy()
		end)
	end)
end

function Hud.Toast(kind: string, message: string)
	toastLabel.Text = message
	toastLabel.TextColor3 = if kind == "err" then Config.Palette.Danger else Color3.fromRGB(220, 255, 220)
	toastLabel.TextTransparency = 0
	task.delay(2.4, function()
		TweenService:Create(toastLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	end)
end

function Hud.Update(payload: Types.HudPayload, onSelectSeed: (string) -> ())
	tweenCoins(payload.coins)
	multLabel.Text = string.format("x%.2f · R%d", payload.coinMult, payload.rebirths)
	local tool = Config.Tools[payload.equippedTool]
	toolLabel.Text = "Tool: " .. (if tool then tool.name else payload.equippedTool)
	goalLabel.Text = "Next: " .. payload.goalText
	rebirthBtn.Text = "Rebirth\n" .. formatCoins(payload.rebirthCost) .. "c"

	for _, child in seedRow:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, seedId in Config.SeedOrder do
		local count = payload.ownedSeeds[seedId] or 0
		local def = Config.Seeds[seedId]
		local btn = Instance.new("TextButton")
		btn.Name = seedId
		btn.Size = UDim2.fromOffset(78, 64)
		btn.AutoButtonColor = true
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextWrapped = true
		local selected = payload.selectedSeed == seedId
		btn.BackgroundColor3 = if selected then Config.Palette.Button else Color3.fromRGB(236, 232, 222)
		btn.TextColor3 = if selected then Config.Palette.TextLight else Config.Palette.Text
		btn.Text = (def and def.name or seedId) .. "\nx" .. tostring(count)
		btn.Parent = seedRow
		corner(btn, 12)
		if def then
			local pip = Instance.new("Frame")
			pip.Size = UDim2.new(1, 0, 0, 5)
			pip.BackgroundColor3 = def.color
			pip.BorderSizePixel = 0
			pip.Parent = btn
			corner(pip, 3)
		end
		btn.MouseButton1Click:Connect(function()
			if count > 0 then
				onSelectSeed(seedId)
			else
				Hud.Toast("err", "Buy " .. seedId .. " in the Shop")
			end
		end)
	end
end

return Hud
