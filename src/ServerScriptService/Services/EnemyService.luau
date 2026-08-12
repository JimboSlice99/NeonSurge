--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local ArenaBuilder = require(script.Parent.ArenaBuilder)

type EnemyKind = Types.EnemyKind

local DEFS = {
	Runner = {
		Name = "Wisp",
		Health = 28,
		Speed = 16,
		Damage = 7,
		TouchCooldown = 0.6,
		Color = Color3.fromRGB(60, 200, 190),
		Size = Vector3.new(1.8, 1.8, 1.8),
		Score = 18,
		Xp = 7,
		Credits = 1,
	},
	Shooter = {
		Name = "Spire",
		Health = 42,
		Speed = 10,
		Damage = 6,
		TouchCooldown = 0.8,
		Color = Color3.fromRGB(210, 160, 70),
		Size = Vector3.new(1.6, 3.2, 1.6),
		Score = 32,
		Xp = 11,
		Credits = 2,
		Range = 30,
		ShootCd = 1.5,
	},
	Bruiser = {
		Name = "Bulwark",
		Health = 120,
		Speed = 8.5,
		Damage = 15,
		TouchCooldown = 0.85,
		Color = Color3.fromRGB(200, 70, 140),
		Size = Vector3.new(3.1, 3.1, 3.1),
		Score = 55,
		Xp = 18,
		Credits = 3,
	},
	Boss = {
		Name = "Overlord",
		Health = 780,
		Speed = 10.5,
		Damage = 20,
		TouchCooldown = 0.7,
		Color = Color3.fromRGB(140, 90, 220),
		Size = Vector3.new(5.8, 5.8, 5.8),
		Score = 520,
		Xp = 90,
		Credits = 30,
	},
}

local EnemyService = {}

local folder: Folder? = nil
local alive: { [Model]: boolean } = {}
local touchClock: { [Model]: number } = {}
local shootClock: { [Model]: number } = {}
local onEnemyDied: ((Player?, EnemyKind, number, number, number, Vector3) -> ())? = nil
local onPlayerDamaged: ((Player, number) -> ())? = nil
local heartbeat: RBXScriptConnection? = nil

local function enemyFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local existing = Workspace:FindFirstChild("NeonEnemies")
	if existing and existing:IsA("Folder") then
		folder = existing
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "NeonEnemies"
	created.Parent = Workspace
	folder = created
	return created
end

local function nearestPlayer(from: Vector3): (BasePart?, Player?)
	local bestDist = math.huge
	local bestRoot: BasePart? = nil
	local bestPlayer: Player? = nil
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
			local dist = (root.Position - from).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestRoot = root
				bestPlayer = player
			end
		end
	end
	return bestRoot, bestPlayer
end

local function fireEnemyBolt(from: Vector3, toward: Vector3, damage: number)
	local dir = Vector3.new(toward.X - from.X, 0, toward.Z - from.Z)
	if dir.Magnitude < 0.1 then
		return
	end
	dir = dir.Unit

	local bolt = Instance.new("Part")
	bolt.Name = "EnemyBolt"
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.new(0.9, 0.9, 0.9)
	bolt.Color = Config.Palette.Gold
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Massless = true
	bolt.CastShadow = false
	bolt.Transparency = 0.1
	bolt.CFrame = CFrame.new(from + dir * 2 + Vector3.new(0, 1.5, 0))
	bolt.Parent = Workspace

	local att = Instance.new("Attachment")
	att.Parent = bolt
	local vel = Instance.new("LinearVelocity")
	vel.Attachment0 = att
	vel.MaxForce = math.huge
	vel.VectorVelocity = dir * 58
	vel.Parent = bolt

	local hit = false
	local conn: RBXScriptConnection
	conn = bolt.Touched:Connect(function(other)
		if hit then
			return
		end
		local model = other:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if player and onPlayerDamaged then
			if model and model:GetAttribute("IFrames") == true then
				return
			end
			hit = true
			onPlayerDamaged(player, damage)
			bolt:Destroy()
			conn:Disconnect()
		end
	end)
	Debris:AddItem(bolt, 2.8)
end

function EnemyService.init(hooks: {
	onEnemyDied: (Player?, EnemyKind, number, number, number, Vector3) -> (),
	onPlayerDamaged: (Player, number) -> (),
})
	onEnemyDied = hooks.onEnemyDied
	onPlayerDamaged = hooks.onPlayerDamaged
	enemyFolder()
	if heartbeat then
		heartbeat:Disconnect()
	end
	heartbeat = RunService.Heartbeat:Connect(function()
		for model in pairs(alive) do
			if not model.Parent then
				alive[model] = nil
				continue
			end
			local root = model.PrimaryPart
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid or humanoid.Health <= 0 then
				continue
			end
			local target = nearestPlayer(root.Position)
			local kind = model:GetAttribute("Kind")
			if target then
				local offset = target.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local dist = flat.Magnitude
				if dist > 0.2 then
					local dir = flat.Unit
					if kind == "Shooter" and dist < 16 then
						humanoid:Move(-dir, false)
					else
						humanoid:Move(dir, false)
					end
					root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
				end
				if kind == "Shooter" then
					local def = DEFS.Shooter
					local now = os.clock()
					if dist <= (def.Range :: number) and now - (shootClock[model] or 0) >= (def.ShootCd :: number) then
						shootClock[model] = now
						fireEnemyBolt(root.Position, target.Position, def.Damage)
					end
				end
			end
			local flatPos = Vector3.new(root.Position.X, 0, root.Position.Z)
			if flatPos.Magnitude > Config.Arena.Radius - 2 then
				local push = flatPos.Unit * (Config.Arena.Radius - 4)
				root.CFrame = CFrame.new(push.X, root.Position.Y, push.Z)
			end
		end
	end)
end

function EnemyService.clear()
	for model in pairs(alive) do
		model:Destroy()
	end
	table.clear(alive)
	table.clear(touchClock)
	table.clear(shootClock)
	enemyFolder():ClearAllChildren()
end

function EnemyService.count(): number
	local n = 0
	for model in pairs(alive) do
		if model.Parent then
			n += 1
		else
			alive[model] = nil
		end
	end
	return n
end

function EnemyService.spawn(kind: EnemyKind, wave: number): Model
	local def = DEFS[kind]
	local hpScale = 1 + (wave - 1) * 0.13
	local model = Instance.new("Model")
	model.Name = def.Name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CFrame = ArenaBuilder.randomSpawnCFrame()
	root.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	if kind == "Shooter" then
		body.Size = def.Size
		body.Material = Enum.Material.SmoothPlastic
	elseif kind == "Bruiser" then
		body.Size = def.Size
		body.Shape = Enum.PartType.Cylinder
		body.Material = Enum.Material.SmoothPlastic
	elseif kind == "Boss" then
		body.Size = def.Size
		body.Shape = Enum.PartType.Ball
		body.Material = Enum.Material.SmoothPlastic
	else
		body.Shape = Enum.PartType.Ball
		body.Size = def.Size
		body.Material = Enum.Material.SmoothPlastic
	end
	body.Color = Color3.fromRGB(
		math.floor(def.Color.R * 255 * 0.35),
		math.floor(def.Color.G * 255 * 0.35),
		math.floor(def.Color.B * 255 * 0.35)
	)
	body.CFrame = root.CFrame
	body.Parent = model

	-- Accent core (small neon, no PointLight)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = def.Size * 0.35
	core.Color = def.Color
	core.Material = Enum.Material.Neon
	core.CanCollide = false
	core.Massless = true
	core.CastShadow = false
	core.Transparency = 0.15
	core.CFrame = root.CFrame
	core.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = root
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = root
	weld2.Part1 = core
	weld2.Parent = root

	local highlight = Instance.new("Highlight")
	highlight.FillColor = def.Color
	highlight.OutlineColor = def.Color
	highlight.FillTransparency = 0.85
	highlight.OutlineTransparency = 0.35
	highlight.Parent = model

	if kind == "Boss" then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(120, 14)
		billboard.StudsOffset = Vector3.new(0, def.Size.Y * 0.65, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = body
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
		bg.BorderSizePixel = 0
		bg.Parent = billboard
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = def.Color
		fill.BorderSizePixel = 0
		fill.Parent = bg
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = def.Health * hpScale
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = def.Speed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	if kind == "Boss" then
		humanoid.HealthChanged:Connect(function(h)
			local gui = body:FindFirstChildOfClass("BillboardGui")
			local frame = gui and gui:FindFirstChildOfClass("Frame")
			local fill = frame and frame:FindFirstChild("Fill")
			if fill and fill:IsA("Frame") then
				fill.Size = UDim2.fromScale(math.clamp(h / humanoid.MaxHealth, 0, 1), 1)
			end
		end)
	end

	model.PrimaryPart = root
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Score", def.Score)
	model:SetAttribute("Xp", def.Xp)
	model:SetAttribute("Credits", if kind == "Boss" then Config.Economy.BossCredit else def.Credits)
	model:SetAttribute("Damage", def.Damage)
	CollectionService:AddTag(model, "NeonEnemy")
	model.Parent = enemyFolder()
	alive[model] = true

	humanoid.Died:Connect(function()
		alive[model] = nil
		local killerAttr = model:GetAttribute("LastHitBy")
		local killer: Player? = nil
		if typeof(killerAttr) == "number" then
			killer = Players:GetPlayerByUserId(killerAttr)
		end
		local pos = root.Position
		if onEnemyDied then
			onEnemyDied(killer, kind, def.Score, def.Xp, model:GetAttribute("Credits") :: number, pos)
		end
		Remotes.get("FxBurst"):FireAllClients({
			kind = "kill",
			position = pos,
			color = def.Color,
		})
		Debris:AddItem(model, 0.05)
	end)

	body.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		local humanoidHit = character:FindFirstChildOfClass("Humanoid")
		if not player or not humanoidHit or humanoidHit.Health <= 0 then
			return
		end
		if character:GetAttribute("IFrames") == true then
			return
		end
		local now = os.clock()
		if now - (touchClock[model] or 0) < def.TouchCooldown then
			return
		end
		touchClock[model] = now
		if onPlayerDamaged then
			onPlayerDamaged(player, def.Damage)
		end
	end)

	return model
end

function EnemyService.applyDamage(model: Model, amount: number, attacker: Player?): boolean
	if not alive[model] then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if attacker then
		model:SetAttribute("LastHitBy", attacker.UserId)
	end
	humanoid:TakeDamage(amount)
	return true
end

function EnemyService.getEnemyFromPart(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if model and alive[model] and CollectionService:HasTag(model, "NeonEnemy") then
		return model
	end
	return nil
end

return EnemyService
