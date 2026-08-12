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
local wave: TextLabel
local lives: TextLabel
local cash: TextLabel
local selected: TextLabel
local livesFill: Frame

local function label(parent: Instance, size: UDim2, pos: UDim2, textSize: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = Enum.Font.GothamMedium
	l.TextSize = textSize
	l.TextColor3 = color
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = parent
	return l
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

	brand = label(gui, UDim2.fromOffset(260, 26), UDim2.fromOffset(24, 18), 18, Config.Palette.Cyan)
	brand.Font = Enum.Font.GothamBlack
	brand.Text = Config.GameName

	message = label(gui, UDim2.new(1, -48, 0, 20), UDim2.fromOffset(24, 46), 14, Config.Palette.Muted)
	wave = label(gui, UDim2.fromOffset(220, 20), UDim2.fromOffset(24, 78), 15, Config.Palette.Text)
	lives = label(gui, UDim2.fromOffset(180, 20), UDim2.fromOffset(24, 100), 15, Config.Palette.Danger)
	cash = label(gui, UDim2.fromOffset(220, 20), UDim2.fromOffset(24, 122), 15, Config.Palette.Gold)
	selected = label(gui, UDim2.fromOffset(320, 20), UDim2.fromOffset(24, 144), 14, Config.Palette.Cyan)

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromOffset(240, 8)
	bg.Position = UDim2.new(0, 24, 1, -40)
	bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	livesFill = Instance.new("Frame")
	livesFill.Size = UDim2.fromScale(1, 1)
	livesFill.BackgroundColor3 = Config.Palette.Violet
	livesFill.BorderSizePixel = 0
	livesFill.Parent = bg

	local hint = label(gui, UDim2.fromOffset(520, 16), UDim2.new(1, -544, 1, -40), 12, Config.Palette.Muted)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "1-4 select tower · LMB place/upgrade · RMB sell · R lobby"
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
	wave.Text = ("Wave %d / %d   ·   Hostiles %d"):format(s.wave, s.maxWaves, s.enemiesAlive)
	lives.Text = ("Core integrity  %d"):format(s.lives)
	cash.Text = ("Cash  $%d   ·   Bank %d cr"):format(s.cash, s.creditsBank)
	selected.Text = ("Build: %s"):format(s.selectedTower or "Pulse")

	local ratio = math.clamp(s.lives / Config.Core.MaxLives, 0, 1)
	TweenService:Create(livesFill, TweenInfo.new(0.15), {
		Size = UDim2.fromScale(ratio, 1),
		BackgroundColor3 = if ratio < 0.3 then Config.Palette.Danger else Config.Palette.Violet,
	}):Play()

	local msg = s.message
	if s.countdown and s.countdown > 0 then
		msg = ("%s   %d"):format(s.message or "", s.countdown)
	end
	if msg then
		message.Text = msg
	end
end

return Hud
