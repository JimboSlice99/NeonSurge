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

local function btn(parent: Instance, text: string, size: UDim2, pos: UDim2, bg: Color3, fg: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bg
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = fg
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
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
	panel.Size = UDim2.fromOffset(400, 560)
	panel.Position = UDim2.new(0, 24, 0.5, -280)
	panel.BackgroundColor3 = Config.Palette.Panel
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 55, 70)
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -28, 0, 32)
	title.Position = UDim2.fromOffset(14, 16)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Config.Palette.Cyan
	title.Text = Config.GameName
	title.Parent = panel

	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Size = UDim2.new(1, -28, 0, 40)
	tag.Position = UDim2.fromOffset(14, 50)
	tag.Font = Enum.Font.Gotham
	tag.TextSize = 13
	tag.TextWrapped = true
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.TextColor3 = Config.Palette.Muted
	tag.Text = "Tower defense. Place neon nodes on the conduit path. Keep hostiles from breaching the Surge Core."
	tag.Parent = panel

	creditsLabel = Instance.new("TextLabel")
	creditsLabel.BackgroundTransparency = 1
	creditsLabel.Size = UDim2.new(1, -28, 0, 20)
	creditsLabel.Position = UDim2.fromOffset(14, 100)
	creditsLabel.Font = Enum.Font.GothamBold
	creditsLabel.TextSize = 15
	creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
	creditsLabel.TextColor3 = Config.Palette.Gold
	creditsLabel.Text = "Credits 0"
	creditsLabel.Parent = panel

	bestLabel = Instance.new("TextLabel")
	bestLabel.BackgroundTransparency = 1
	bestLabel.Size = UDim2.new(1, -28, 0, 18)
	bestLabel.Position = UDim2.fromOffset(14, 122)
	bestLabel.Font = Enum.Font.Gotham
	bestLabel.TextSize = 13
	bestLabel.TextXAlignment = Enum.TextXAlignment.Left
	bestLabel.TextColor3 = Config.Palette.Muted
	bestLabel.Text = "Best wave 0"
	bestLabel.Parent = panel

	local play = btn(panel, "START DEFENSE", UDim2.new(1, -28, 0, 48), UDim2.fromOffset(14, 152), Config.Palette.Cyan, Color3.fromRGB(8, 14, 20))
	play.TextSize = 18
	play.Font = Enum.Font.GothamBlack
	play.MouseButton1Click:Connect(function()
		if onPlay then
			onPlay()
		end
		Remotes.get("RequestStartRun"):FireServer()
	end)

	local shop = Instance.new("TextLabel")
	shop.BackgroundTransparency = 1
	shop.Size = UDim2.new(1, -28, 0, 18)
	shop.Position = UDim2.fromOffset(14, 216)
	shop.Font = Enum.Font.GothamBold
	shop.TextSize = 12
	shop.TextXAlignment = Enum.TextXAlignment.Left
	shop.TextColor3 = Config.Palette.Text
	shop.Text = "PERMANENT OPS"
	shop.Parent = panel

	metaFrame = Instance.new("Frame")
	metaFrame.BackgroundTransparency = 1
	metaFrame.Size = UDim2.new(1, -28, 0, 210)
	metaFrame.Position = UDim2.fromOffset(14, 238)
	metaFrame.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = metaFrame

	local pass = Instance.new("TextLabel")
	pass.BackgroundTransparency = 1
	pass.Size = UDim2.new(1, -28, 0, 16)
	pass.Position = UDim2.fromOffset(14, 460)
	pass.Font = Enum.Font.GothamBold
	pass.TextSize = 11
	pass.TextXAlignment = Enum.TextXAlignment.Left
	pass.TextColor3 = Config.Palette.Muted
	pass.Text = "BOOSTS"
	pass.Parent = panel

	local products = {
		{ "2× Credits", "DoubleCredits" },
		{ "Cash Bundle", "StarterCash" },
		{ "VIP Skin", "VipSkin" },
		{ "+500", "CreditPackSmall" },
	}
	for i, row in products do
		local b = btn(panel, row[1], UDim2.fromOffset(86, 30), UDim2.fromOffset(14 + (i - 1) * 92, 484), Color3.fromRGB(20, 26, 40), Config.Palette.Text)
		b.TextSize = 11
		b.MouseButton1Click:Connect(function()
			Remotes.get("RequestBuyProduct"):FireServer(row[2])
		end)
	end
end

function Lobby.setVisible(v: boolean)
	if gui then
		gui.Enabled = v
	end
end

function Lobby.apply(snapshot: LobbySnapshot)
	if not gui then
		return
	end
	creditsLabel.Text = ("Credits  %d"):format(snapshot.credits)
	bestLabel.Text = ("Best wave %d  ·  High score %d"):format(snapshot.bestWave, snapshot.highScore)
	for _, child in metaFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, item in snapshot.meta do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
		row.BorderSizePixel = 0
		row.AutoButtonColor = item.affordable
		row.Font = Enum.Font.Gotham
		row.TextSize = 13
		row.TextColor3 = if item.affordable then Config.Palette.Text else Config.Palette.Muted
		row.TextXAlignment = Enum.TextXAlignment.Left
		local cost = if item.level >= item.maxLevel then "MAX" else (tostring(item.cost) .. " cr")
		row.Text = ("  %s   %d/%d     %s"):format(item.name, item.level, item.maxLevel, cost)
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
