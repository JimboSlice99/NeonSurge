--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

type HudSnapshot = Types.HudSnapshot

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local title: TextLabel
local message: TextLabel
local wave: TextLabel
local score: TextLabel
local level: TextLabel
local credits: TextLabel
local combo: TextLabel
local xpFill: Frame
local hpFill: Frame

local function label(parent: Instance, name: string, size: UDim2, pos: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = Enum.Font.GothamBlack
	l.TextSize = textSize
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.35
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = parent
	return l
end

local function bar(parent: Instance, name: string, pos: UDim2, color: Color3): Frame
	local bg = Instance.new("Frame")
	bg.Name = name
	bg.Size = UDim2.fromOffset(280, 16)
	bg.Position = pos
	bg.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
	bg.BorderSizePixel = 0
	bg.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.4
	stroke.Transparency = 0.3
	stroke.Parent = bg
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bg
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

	title = label(gui, "Title", UDim2.fromOffset(420, 40), UDim2.new(0, 24, 0, 20), 28)
	title.Text = Config.GameName
	title.TextColor3 = Config.Palette.Cyan

	message = label(gui, "Message", UDim2.new(1, -48, 0, 30), UDim2.new(0, 24, 0, 58), 20)
	message.TextColor3 = Config.Palette.Magenta

	wave = label(gui, "Wave", UDim2.fromOffset(220, 24), UDim2.new(0, 24, 0, 100), 18)
	score = label(gui, "Score", UDim2.fromOffset(260, 24), UDim2.new(0, 24, 0, 124), 18)
	level = label(gui, "Level", UDim2.fromOffset(260, 24), UDim2.new(0, 24, 0, 148), 18)
	credits = label(gui, "Credits", UDim2.fromOffset(280, 24), UDim2.new(0, 24, 0, 172), 18)
	credits.TextColor3 = Config.Palette.Gold
	combo = label(gui, "Combo", UDim2.fromOffset(220, 24), UDim2.new(0, 24, 0, 196), 18)
	combo.TextColor3 = Config.Palette.Lime

	hpFill = bar(gui, "Health", UDim2.new(0, 24, 1, -52), Config.Palette.Cyan)
	xpFill = bar(gui, "XP", UDim2.new(0, 24, 1, -28), Config.Palette.Violet)

	local hint = label(gui, "Hint", UDim2.fromOffset(460, 22), UDim2.new(1, -484, 1, -48), 15)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "Q dash · auto-fire · level up = power"
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
	wave.Text = ("WAVE %d"):format(snapshot.wave)
	score.Text = ("SCORE  %d"):format(snapshot.score)
	level.Text = ("LVL %d"):format(snapshot.level)
	credits.Text = ("RUN %d   BANK %d"):format(snapshot.creditsRun, snapshot.creditsBank)
	combo.Text = if snapshot.combo > 1 then ("COMBO x%d"):format(snapshot.combo) else ""

	local hp = if snapshot.maxHealth > 0 then snapshot.health / snapshot.maxHealth else 0
	local xp = if snapshot.xpNeed > 0 then snapshot.xp / snapshot.xpNeed else 0
	TweenService:Create(hpFill, TweenInfo.new(0.12), {
		Size = UDim2.fromScale(math.clamp(hp, 0, 1), 1),
		BackgroundColor3 = if hp < 0.3 then Config.Palette.Danger else Config.Palette.Cyan,
	}):Play()
	TweenService:Create(xpFill, TweenInfo.new(0.12), {
		Size = UDim2.fromScale(math.clamp(xp, 0, 1), 1),
	}):Play()

	local msg = snapshot.message
	if snapshot.countdown and snapshot.countdown > 0 then
		msg = ("%s  %d"):format(snapshot.message or "GO", snapshot.countdown)
	end
	if msg and msg ~= "" then
		message.Text = msg
	end
end

return Hud
