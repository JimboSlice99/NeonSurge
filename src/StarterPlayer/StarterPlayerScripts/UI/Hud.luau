--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

type HudSnapshot = Types.HudSnapshot

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local brand: TextLabel
local message: TextLabel
local metaLeft: TextLabel
local metaRight: TextLabel
local combo: TextLabel
local hpFill: Frame
local xpFill: Frame
local vignette: Frame

local function makeLabel(parent: Instance, size: UDim2, pos: UDim2, textSize: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = Enum.Font.GothamMedium
	l.TextSize = textSize
	l.TextColor3 = color
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Text = ""
	l.Parent = parent
	return l
end

local function makeBar(parent: Instance, pos: UDim2, width: number, height: number, fillColor: Color3): Frame
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromOffset(width, height)
	bg.Position = pos
	bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = bg
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = bg
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill
	return fill
end

function Hud.mount()
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("NeonSurgeHud")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "NeonSurgeHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	vignette = Instance.new("Frame")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.new(0, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 1
	vignette.Parent = gui

	brand = makeLabel(gui, UDim2.fromOffset(280, 28), UDim2.fromOffset(28, 22), 18, Config.Palette.Cyan)
	brand.Font = Enum.Font.GothamBlack
	brand.Text = Config.GameName
	brand.ZIndex = 2

	message = makeLabel(gui, UDim2.new(1, -56, 0, 24), UDim2.fromOffset(28, 50), 16, Config.Palette.Muted)
	message.ZIndex = 2

	metaLeft = makeLabel(gui, UDim2.fromOffset(320, 20), UDim2.fromOffset(28, 86), 14, Config.Palette.Text)
	metaLeft.ZIndex = 2
	metaRight = makeLabel(gui, UDim2.fromOffset(280, 20), UDim2.fromOffset(28, 108), 14, Config.Palette.Gold)
	metaRight.ZIndex = 2

	combo = makeLabel(gui, UDim2.fromOffset(200, 22), UDim2.fromOffset(28, 132), 15, Config.Palette.Lime)
	combo.Font = Enum.Font.GothamBold
	combo.ZIndex = 2

	hpFill = makeBar(gui, UDim2.new(0, 28, 1, -54), 260, 10, Config.Palette.Cyan)
	xpFill = makeBar(gui, UDim2.new(0, 28, 1, -36), 260, 6, Config.Palette.Violet)
	hpFill.Parent.ZIndex = 2
	xpFill.Parent.ZIndex = 2

	local hint = makeLabel(gui, UDim2.fromOffset(360, 18), UDim2.new(1, -388, 1, -40), 13, Config.Palette.Muted)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "Q dash · gems level you up"
	hint.ZIndex = 2
end

function Hud.setVisible(visible: boolean)
	if gui then
		gui.Enabled = visible
	end
end

function Hud.apply(snapshot: HudSnapshot)
	if not gui then
		return
	end
	metaLeft.Text = ("Wave %d   ·   Score %d   ·   Lv %d"):format(snapshot.wave, snapshot.score, snapshot.level)
	metaRight.Text = ("Run %d cr   ·   Bank %d"):format(snapshot.creditsRun, snapshot.creditsBank)
	combo.Text = if snapshot.combo > 1 then ("x%d"):format(snapshot.combo) else ""

	local hp = if snapshot.maxHealth > 0 then snapshot.health / snapshot.maxHealth else 0
	local xp = if snapshot.xpNeed > 0 then snapshot.xp / snapshot.xpNeed else 0
	TweenService:Create(hpFill, TweenInfo.new(0.12), {
		Size = UDim2.fromScale(math.clamp(hp, 0, 1), 1),
		BackgroundColor3 = if hp < 0.28 then Config.Palette.Danger else Config.Palette.Cyan,
	}):Play()
	TweenService:Create(xpFill, TweenInfo.new(0.12), {
		Size = UDim2.fromScale(math.clamp(xp, 0, 1), 1),
	}):Play()

	local msg = snapshot.message
	if snapshot.countdown and snapshot.countdown > 0 then
		msg = ("%s   %d"):format(snapshot.message or "", snapshot.countdown)
	end
	if msg then
		message.Text = msg
	end

	if snapshot.phase == "GameOver" then
		TweenService:Create(vignette, TweenInfo.new(0.35), { BackgroundTransparency = 0.55 }):Play()
	else
		TweenService:Create(vignette, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	end
end

return Hud
