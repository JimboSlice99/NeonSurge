--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

type LobbySnapshot = Types.LobbySnapshot

local Lobby = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local creditsLabel: TextLabel
local bestLabel: TextLabel
local metaFrame: Frame
local onPlay: (() -> ())? = nil

local function textButton(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color
	b.Text = text
	b.Font = Enum.Font.GothamBlack
	b.TextSize = 20
	b.TextColor3 = Color3.new(1, 1, 1)
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	return b
end

function Lobby.mount(playCallback: () -> ())
	onPlay = playCallback
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("NeonSurgeLobby")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "NeonSurgeLobby"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = pg

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(420, 560)
	panel.Position = UDim2.new(1, -444, 0.5, -280)
	panel.BackgroundColor3 = Color3.fromRGB(8, 12, 28)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.Palette.Cyan
	stroke.Thickness = 2
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -24, 0, 40)
	title.Position = UDim2.fromOffset(12, 12)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Config.Palette.Cyan
	title.Text = Config.GameName
	title.Parent = panel

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Size = UDim2.new(1, -24, 0, 22)
	tag.Position = UDim2.fromOffset(12, 50)
	tag.Font = Enum.Font.Gotham
	tag.TextSize = 16
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.TextColor3 = Config.Palette.Magenta
	tag.Text = "Roguelite arena shooter · bank credits · get stronger"
	tag.Parent = panel

	creditsLabel = Instance.new("TextLabel")
	creditsLabel.BackgroundTransparency = 1
	creditsLabel.Size = UDim2.new(1, -24, 0, 24)
	creditsLabel.Position = UDim2.fromOffset(12, 84)
	creditsLabel.Font = Enum.Font.GothamBold
	creditsLabel.TextSize = 18
	creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
	creditsLabel.TextColor3 = Config.Palette.Gold
	creditsLabel.Text = "CREDITS 0"
	creditsLabel.Parent = panel

	bestLabel = Instance.new("TextLabel")
	bestLabel.BackgroundTransparency = 1
	bestLabel.Size = UDim2.new(1, -24, 0, 22)
	bestLabel.Position = UDim2.fromOffset(12, 110)
	bestLabel.Font = Enum.Font.Gotham
	bestLabel.TextSize = 15
	bestLabel.TextXAlignment = Enum.TextXAlignment.Left
	bestLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
	bestLabel.Text = "Best score 0 · Best wave 0"
	bestLabel.Parent = panel

	local play = textButton(panel, "PLAY RUN", UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 150), Config.Palette.Cyan)
	play.TextColor3 = Color3.fromRGB(10, 20, 40)
	play.MouseButton1Click:Connect(function()
		if onPlay then
			onPlay()
		end
		Remotes.get("RequestStartRun"):FireServer()
	end)

	local shopTitle = Instance.new("TextLabel")
	shopTitle.BackgroundTransparency = 1
	shopTitle.Size = UDim2.new(1, -24, 0, 24)
	shopTitle.Position = UDim2.fromOffset(12, 214)
	shopTitle.Font = Enum.Font.GothamBlack
	shopTitle.TextSize = 16
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.TextColor3 = Color3.new(1, 1, 1)
	shopTitle.Text = "PERMANENT UPGRADES"
	shopTitle.Parent = panel

	metaFrame = Instance.new("Frame")
	metaFrame.BackgroundTransparency = 1
	metaFrame.Size = UDim2.new(1, -24, 0, 200)
	metaFrame.Position = UDim2.fromOffset(12, 242)
	metaFrame.Parent = panel

	local passTitle = Instance.new("TextLabel")
	passTitle.BackgroundTransparency = 1
	passTitle.Size = UDim2.new(1, -24, 0, 22)
	passTitle.Position = UDim2.fromOffset(12, 450)
	passTitle.Font = Enum.Font.GothamBlack
	passTitle.TextSize = 15
	passTitle.TextXAlignment = Enum.TextXAlignment.Left
	passTitle.TextColor3 = Color3.new(1, 1, 1)
	passTitle.Text = "GAMEPASSES / PACKS"
	passTitle.Parent = panel

	local y = 478
	local products = {
		{ "2x Credits", "DoubleCredits", Config.Palette.Gold },
		{ "VIP Trail", "VipTrail", Config.Palette.Violet },
		{ "Extra Dash", "ExtraDash", Config.Palette.Magenta },
		{ "+500 Credits", "CreditPackSmall", Config.Palette.Lime },
	}
	for i, row in products do
		local b = textButton(panel, row[1], UDim2.fromOffset(90, 32), UDim2.fromOffset(12 + (i - 1) * 98, y), row[3])
		b.TextSize = 12
		b.MouseButton1Click:Connect(function()
			Remotes.get("RequestBuyProduct"):FireServer(row[2])
		end)
	end
end

function Lobby.setVisible(visible: boolean)
	if gui then
		gui.Enabled = visible
	end
end

function Lobby.apply(snapshot: LobbySnapshot)
	if not gui then
		return
	end
	creditsLabel.Text = ("CREDITS  %d"):format(snapshot.credits)
	bestLabel.Text = ("Best score %d · Best wave %d"):format(snapshot.highScore, snapshot.bestWave)

	metaFrame:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = metaFrame

	for _, item in snapshot.meta do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 34)
		row.BackgroundColor3 = if item.affordable then Color3.fromRGB(20, 30, 60) else Color3.fromRGB(16, 18, 28)
		row.AutoButtonColor = item.affordable
		row.BorderSizePixel = 0
		row.Font = Enum.Font.Gotham
		row.TextSize = 14
		row.TextColor3 = Color3.new(1, 1, 1)
		row.TextXAlignment = Enum.TextXAlignment.Left
		local costText = if item.level >= item.maxLevel then "MAX" else (tostring(item.cost) .. " cr")
		row.Text = ("  %s  Lv%d/%d  ·  %s"):format(item.name, item.level, item.maxLevel, costText)
		row.Parent = metaFrame
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = row
		if item.level < item.maxLevel then
			row.MouseButton1Click:Connect(function()
				Remotes.get("RequestBuyMeta"):FireServer(item.id)
			end)
		end
	end
end

return Lobby
