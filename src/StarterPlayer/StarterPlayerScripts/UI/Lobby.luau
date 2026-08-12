--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

local function stylePanel(frame: Frame)
	frame.BackgroundColor3 = Config.Palette.Panel
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 55, 70)
	stroke.Thickness = 1
	stroke.Transparency = 0.2
	stroke.Parent = frame
end

local function btn(parent: Instance, text: string, size: UDim2, pos: UDim2, bg: Color3, fg: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bg
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.TextColor3 = fg
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 7)
	c.Parent = b
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
	panel.Size = UDim2.fromOffset(380, 540)
	panel.Position = UDim2.new(1, -404, 0.5, -270)
	panel.Parent = gui
	stylePanel(panel)

	local brand = Instance.new("TextLabel")
	brand.BackgroundTransparency = 1
	brand.Size = UDim2.new(1, -28, 0, 34)
	brand.Position = UDim2.fromOffset(14, 16)
	brand.Font = Enum.Font.GothamBlack
	brand.TextSize = 26
	brand.TextXAlignment = Enum.TextXAlignment.Left
	brand.TextColor3 = Config.Palette.Cyan
	brand.Text = Config.GameName
	brand.Parent = panel

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Size = UDim2.new(1, -28, 0, 20)
	tag.Position = UDim2.fromOffset(14, 50)
	tag.Font = Enum.Font.Gotham
	tag.TextSize = 14
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.TextColor3 = Config.Palette.Muted
	tag.Text = "Dark arena roguelite · bank power between runs"
	tag.Parent = panel

	creditsLabel = Instance.new("TextLabel")
	creditsLabel.BackgroundTransparency = 1
	creditsLabel.Size = UDim2.new(1, -28, 0, 22)
	creditsLabel.Position = UDim2.fromOffset(14, 84)
	creditsLabel.Font = Enum.Font.GothamBold
	creditsLabel.TextSize = 16
	creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
	creditsLabel.TextColor3 = Config.Palette.Gold
	creditsLabel.Text = "Credits 0"
	creditsLabel.Parent = panel

	bestLabel = Instance.new("TextLabel")
	bestLabel.BackgroundTransparency = 1
	bestLabel.Size = UDim2.new(1, -28, 0, 20)
	bestLabel.Position = UDim2.fromOffset(14, 108)
	bestLabel.Font = Enum.Font.Gotham
	bestLabel.TextSize = 13
	bestLabel.TextXAlignment = Enum.TextXAlignment.Left
	bestLabel.TextColor3 = Config.Palette.Muted
	bestLabel.Text = "Best 0 · Wave 0"
	bestLabel.Parent = panel

	local play = btn(panel, "START RUN", UDim2.new(1, -28, 0, 46), UDim2.fromOffset(14, 142), Config.Palette.Cyan, Color3.fromRGB(8, 16, 22))
	play.TextSize = 18
	play.Font = Enum.Font.GothamBlack
	play.MouseButton1Click:Connect(function()
		TweenService:Create(panel, TweenInfo.new(0.2), { BackgroundTransparency = 0.4 }):Play()
		if onPlay then
			onPlay()
		end
		Remotes.get("RequestStartRun"):FireServer()
	end)

	local shopTitle = Instance.new("TextLabel")
	shopTitle.BackgroundTransparency = 1
	shopTitle.Size = UDim2.new(1, -28, 0, 20)
	shopTitle.Position = UDim2.fromOffset(14, 206)
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.TextSize = 13
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.TextColor3 = Config.Palette.Text
	shopTitle.Text = "LOADOUT"
	shopTitle.Parent = panel

	metaFrame = Instance.new("Frame")
	metaFrame.BackgroundTransparency = 1
	metaFrame.Size = UDim2.new(1, -28, 0, 210)
	metaFrame.Position = UDim2.fromOffset(14, 230)
	metaFrame.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = metaFrame

	local passTitle = Instance.new("TextLabel")
	passTitle.BackgroundTransparency = 1
	passTitle.Size = UDim2.new(1, -28, 0, 18)
	passTitle.Position = UDim2.fromOffset(14, 448)
	passTitle.Font = Enum.Font.GothamBold
	passTitle.TextSize = 12
	passTitle.TextXAlignment = Enum.TextXAlignment.Left
	passTitle.TextColor3 = Config.Palette.Muted
	passTitle.Text = "SUPPORT / BOOSTS"
	passTitle.Parent = panel

	local products = {
		{ "2× Credits", "DoubleCredits" },
		{ "VIP Aura", "VipTrail" },
		{ "Dash+", "ExtraDash" },
		{ "+500", "CreditPackSmall" },
	}
	for i, row in products do
		local b = btn(
			panel,
			row[1],
			UDim2.fromOffset(82, 30),
			UDim2.fromOffset(14 + (i - 1) * 88, 474),
			Color3.fromRGB(22, 28, 42),
			Config.Palette.Text
		)
		b.TextSize = 11
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
	creditsLabel.Text = ("Credits  %d"):format(snapshot.credits)
	bestLabel.Text = ("Best %d  ·  Wave %d"):format(snapshot.highScore, snapshot.bestWave)

	for _, child in metaFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, item in snapshot.meta do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
		row.AutoButtonColor = item.affordable
		row.BorderSizePixel = 0
		row.Font = Enum.Font.Gotham
		row.TextSize = 13
		row.TextColor3 = if item.affordable then Config.Palette.Text else Config.Palette.Muted
		row.TextXAlignment = Enum.TextXAlignment.Left
		local costText = if item.level >= item.maxLevel then "MAX" else (tostring(item.cost) .. " cr")
		row.Text = ("  %s   %d/%d     %s"):format(item.name, item.level, item.maxLevel, costText)
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
