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
local timer: TextLabel
local meta: TextLabel
local weapon: TextLabel
local rank: TextLabel
local combo: TextLabel
local hpFill: Frame
local xpFill: Frame

local function label(parent: Instance, size: UDim2, pos: UDim2, textSize: number, color: Color3, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = font or Enum.Font.GothamMedium
	l.TextSize = textSize
	l.TextColor3 = color
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = parent
	return l
end

local function bar(parent: Instance, pos: UDim2, width: number, height: number, color: Color3): Frame
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromOffset(width, height)
	bg.Position = pos
	bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 3)
	c.Parent = bg
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bg
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 3)
	fc.Parent = fill
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
	gui.Parent = pg

	brand = label(gui, UDim2.fromOffset(260, 26), UDim2.fromOffset(24, 18), 18, Config.Palette.Cyan, Enum.Font.GothamBlack)
	brand.Text = Config.GameName
	message = label(gui, UDim2.new(1, -48, 0, 20), UDim2.fromOffset(24, 46), 14, Config.Palette.Muted)
	timer = label(gui, UDim2.fromOffset(160, 28), UDim2.new(0.5, -80, 0, 18), 22, Config.Palette.Text, Enum.Font.GothamBlack)
	timer.TextXAlignment = Enum.TextXAlignment.Center
	rank = label(gui, UDim2.fromOffset(120, 36), UDim2.new(1, -140, 0, 18), 28, Config.Palette.Gold, Enum.Font.GothamBlack)
	rank.TextXAlignment = Enum.TextXAlignment.Right
	meta = label(gui, UDim2.fromOffset(360, 18), UDim2.fromOffset(24, 78), 13, Config.Palette.Text)
	weapon = label(gui, UDim2.fromOffset(280, 18), UDim2.fromOffset(24, 98), 13, Config.Palette.Cyan)
	combo = label(gui, UDim2.fromOffset(160, 20), UDim2.fromOffset(24, 118), 14, Config.Palette.Lime, Enum.Font.GothamBold)

	hpFill = bar(gui, UDim2.new(0, 24, 1, -52), 250, 9, Config.Palette.Cyan)
	xpFill = bar(gui, UDim2.new(0, 24, 1, -36), 250, 5, Config.Palette.Violet)

	local hint = label(gui, UDim2.fromOffset(420, 16), UDim2.new(1, -444, 1, -38), 12, Config.Palette.Muted)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "Q dash · F slam · Space×2 · 1/2/3 weapons · pads launch"
end

function Hud.setVisible(v: boolean)
	if gui then
		gui.Enabled = v
	end
end

function Hud.apply(s: HudSnapshot)
	if not gui then
		return
	end
	local mins = math.floor(s.timeLeft / 60)
	local secs = math.floor(s.timeLeft % 60)
	timer.Text = string.format("%d:%02d", mins, secs)
	rank.Text = s.styleRank
	meta.Text = ("Score %d  ·  Style %d  ·  Lv %d  ·  Kills %d"):format(s.score, s.style, s.level, s.kills)
	weapon.Text = s.weapon
	combo.Text = if s.combo > 1 then ("x%d"):format(s.combo) else ""

	local hp = if s.maxHealth > 0 then s.health / s.maxHealth else 0
	local xp = if s.xpNeed > 0 then s.xp / s.xpNeed else 0
	TweenService:Create(hpFill, TweenInfo.new(0.1), {
		Size = UDim2.fromScale(math.clamp(hp, 0, 1), 1),
		BackgroundColor3 = if hp < 0.28 then Config.Palette.Danger else Config.Palette.Cyan,
	}):Play()
	TweenService:Create(xpFill, TweenInfo.new(0.1), { Size = UDim2.fromScale(math.clamp(xp, 0, 1), 1) }):Play()

	local msg = s.message
	if s.countdown and s.countdown > 0 then
		msg = ("%s  %d"):format(s.message or "", s.countdown)
	end
	if msg then
		message.Text = msg
	end
end

return Hud
