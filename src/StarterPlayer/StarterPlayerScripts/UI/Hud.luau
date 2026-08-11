--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

type HudSnapshot = Types.HudSnapshot

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local titleLabel: TextLabel
local messageLabel: TextLabel
local waveLabel: TextLabel
local scoreLabel: TextLabel
local comboLabel: TextLabel
local healthFill: Frame
local killsLabel: TextLabel
local enemiesLabel: TextLabel

local function makeLabel(parent: Instance, name: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = ""
	label.Parent = parent
	return label
end

function Hud.mount()
	local playerGui = player:WaitForChild("PlayerGui")

	local existing = playerGui:FindFirstChild("NeonSurgeHud")
	if existing then
		existing:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "NeonSurgeHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	titleLabel = makeLabel(gui, "Title", UDim2.fromOffset(420, 42), UDim2.new(0, 28, 0, 24), 30)
	titleLabel.Text = Config.GameName
	titleLabel.TextColor3 = Config.Palette.Cyan

	messageLabel = makeLabel(gui, "Message", UDim2.new(1, -56, 0, 36), UDim2.new(0, 28, 0, 66), 22)
	messageLabel.TextColor3 = Config.Palette.Magenta
	messageLabel.Text = Config.Tagline

	waveLabel = makeLabel(gui, "Wave", UDim2.fromOffset(220, 28), UDim2.new(0, 28, 0, 112), 20)
	scoreLabel = makeLabel(gui, "Score", UDim2.fromOffset(260, 28), UDim2.new(0, 28, 0, 140), 20)
	comboLabel = makeLabel(gui, "Combo", UDim2.fromOffset(220, 28), UDim2.new(0, 28, 0, 168), 20)
	comboLabel.TextColor3 = Config.Palette.Lime
	killsLabel = makeLabel(gui, "Kills", UDim2.fromOffset(220, 28), UDim2.new(0, 28, 0, 196), 18)
	enemiesLabel = makeLabel(gui, "Enemies", UDim2.fromOffset(220, 28), UDim2.new(0, 28, 0, 220), 18)

	local healthFrame = Instance.new("Frame")
	healthFrame.Name = "HealthFrame"
	healthFrame.Size = UDim2.fromOffset(280, 18)
	healthFrame.Position = UDim2.new(0, 28, 1, -48)
	healthFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
	healthFrame.BorderSizePixel = 0
	healthFrame.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.Palette.Cyan
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = healthFrame

	healthFill = Instance.new("Frame")
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Config.Palette.Cyan
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthFrame

	local hint = makeLabel(gui, "Hint", UDim2.fromOffset(420, 24), UDim2.new(1, -448, 1, -48), 16)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "Q / Shift dash · R reboot · auto-fire on"
	hint.TextTransparency = 0.15
end

function Hud.apply(snapshot: HudSnapshot)
	if not gui then
		return
	end

	waveLabel.Text = ("WAVE %d"):format(snapshot.wave)
	scoreLabel.Text = ("SCORE  %d"):format(snapshot.score)
	comboLabel.Text = if snapshot.combo > 1 then ("COMBO  x%d"):format(snapshot.combo) else ""
	killsLabel.Text = ("KILLS  %d"):format(snapshot.kills)
	enemiesLabel.Text = ("HOSTILES  %d"):format(snapshot.enemiesAlive)

	local ratio = 0
	if snapshot.maxHealth > 0 then
		ratio = math.clamp(snapshot.health / snapshot.maxHealth, 0, 1)
	end
	TweenService:Create(healthFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(ratio, 1),
		BackgroundColor3 = if ratio < 0.3 then Config.Palette.Magenta else Config.Palette.Cyan,
	}):Play()

	local msg = snapshot.message
	if snapshot.countdown and snapshot.countdown > 0 then
		msg = ("%s  %d"):format(snapshot.message or "SURGE", snapshot.countdown)
	end
	if msg and msg ~= "" then
		messageLabel.Text = msg
		messageLabel.TextTransparency = 0
		TweenService:Create(messageLabel, TweenInfo.new(0.8), { TextTransparency = 0.15 }):Play()
	end

	if snapshot.phase == "GameOver" then
		titleLabel.TextColor3 = Config.Palette.Magenta
	else
		titleLabel.TextColor3 = Config.Palette.Cyan
	end
end

return Hud
