--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)

local PickupService = {}

local folder: Folder? = nil
local gems: { [BasePart]: number } = {}
local onCollect: ((Player, number) -> ())? = nil
local magnetMul: { [Player]: number } = {}
local conn: RBXScriptConnection? = nil

local function gemFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local existing = Workspace:FindFirstChild("NeonGems")
	if existing and existing:IsA("Folder") then
		folder = existing
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "NeonGems"
	created.Parent = Workspace
	folder = created
	return created
end

function PickupService.init(hooks: { onCollect: (Player, number) -> () })
	onCollect = hooks.onCollect
	gemFolder()
	if conn then
		conn:Disconnect()
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		for gem, xp in pairs(gems) do
			if not gem.Parent then
				gems[gem] = nil
				continue
			end
			local bestPlayer: Player? = nil
			local bestDist = math.huge
			local bestRoot: BasePart? = nil
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("RunActive") ~= true then
					continue
				end
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
					local dist = (root.Position - gem.Position).Magnitude
					local pull = Config.Player.MagnetRadius * (magnetMul[player] or 1)
					if dist < pull and dist < bestDist then
						bestDist = dist
						bestPlayer = player
						bestRoot = root
					end
				end
			end
			if bestPlayer and bestRoot then
				local pickupR = Config.Player.PickupRadius * (magnetMul[bestPlayer] or 1)
				if bestDist <= pickupR then
					gems[gem] = nil
					gem:Destroy()
					if onCollect then
						onCollect(bestPlayer, xp)
					end
					Remotes.get("FxBurst"):FireClient(bestPlayer, {
						kind = "pickup",
						color = Config.Palette.Violet,
					})
				else
					local dir = (bestRoot.Position + Vector3.new(0, 1.5, 0) - gem.Position)
					if dir.Magnitude > 0.05 then
						gem.CFrame = gem.CFrame + dir.Unit * math.min(dt * 55, dir.Magnitude)
					end
				end
			else
				-- idle bob
				gem.CFrame = gem.CFrame + Vector3.new(0, math.sin(os.clock() * 5 + gem.Position.X) * 0.01, 0)
			end
		end
	end)
end

function PickupService.setMagnetMul(player: Player, mul: number)
	magnetMul[player] = mul
end

function PickupService.clear()
	table.clear(gems)
	gemFolder():ClearAllChildren()
end

function PickupService.spawnXp(position: Vector3, amount: number)
	local gem = Instance.new("Part")
	gem.Name = "XpGem"
	gem.Shape = Enum.PartType.Ball
	gem.Size = Vector3.new(0.7, 0.7, 0.7)
	gem.Color = Config.Palette.Violet
	gem.Material = Enum.Material.Neon
	gem.Anchored = true
	gem.CanCollide = false
	gem.CastShadow = false
	gem.CFrame = CFrame.new(position + Vector3.new(0, 1.2, 0))
	gem.Transparency = 0.15
	gem.Parent = gemFolder()

	-- No PointLight — keeps the scene from blowing out
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Config.Palette.Violet
	highlight.OutlineColor = Config.Palette.Cyan
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0.4
	highlight.Parent = gem

	gems[gem] = amount
	Debris:AddItem(gem, 20)
end

return PickupService
