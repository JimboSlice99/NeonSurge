--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Tutorial = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local onDone: (() -> ())?

local STEPS = {
	"Welcome to SURGE GARDEN! Walk through the arch to your fields.",
	"Tap a dirt plot → Plant. Pick seeds on the bottom bar.",
	"When a crop shows !, Harvest for coins. Use Plant All / Harvest All.",
	"Open SHOP to buy better seeds, tools, and new farm zones. Rebirth for power!",
}

function Tutorial.Init(doneCallback: () -> ())
	onDone = doneCallback
end

function Tutorial.TryShow(tutorialDone: boolean)
	if tutorialDone then
		return
	end
	if playerGui:FindFirstChild("SurgeGardenTutorial") then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SurgeGardenTutorial"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Parent = playerGui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -110)
	card.Size = UDim2.new(0.92, 0, 0, 120)
	card.BackgroundColor3 = Config.Palette.Panel
	card.BorderSizePixel = 0
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(560, 140)
	constraint.Parent = card

	local step = 1
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 14, 0, 10)
	label.Size = UDim2.new(1, -28, 0, 62)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = Config.Palette.Text
	label.Text = STEPS[1]
	label.Parent = card

	local nextBtn = Instance.new("TextButton")
	nextBtn.AnchorPoint = Vector2.new(1, 1)
	nextBtn.Position = UDim2.new(1, -12, 1, -12)
	nextBtn.Size = UDim2.new(0, 120, 0, 36)
	nextBtn.BackgroundColor3 = Config.Palette.Button
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.TextSize = 15
	nextBtn.TextColor3 = Config.Palette.TextLight
	nextBtn.Text = "Next"
	nextBtn.Parent = card
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = nextBtn

	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(0, 1)
	skip.Position = UDim2.new(0, 12, 1, -12)
	skip.Size = UDim2.new(0, 90, 0, 36)
	skip.BackgroundTransparency = 1
	skip.Font = Enum.Font.Gotham
	skip.TextSize = 14
	skip.TextColor3 = Config.Palette.Muted
	skip.Text = "Skip"
	skip.Parent = card

	local function finish()
		TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		task.delay(0.25, function()
			gui:Destroy()
		end)
		if onDone then
			onDone()
		end
	end

	nextBtn.MouseButton1Click:Connect(function()
		step += 1
		if step > #STEPS then
			finish()
			return
		end
		label.Text = STEPS[step]
		nextBtn.Text = if step == #STEPS then "Let's grow!" else "Next"
	end)
	skip.MouseButton1Click:Connect(finish)
end

return Tutorial
