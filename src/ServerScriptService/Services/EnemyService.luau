--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local ArenaBuilder = require(script.Parent.ArenaBuilder)

type EnemyKind = Types.EnemyKind

local EnemyService = {}

local folder: Folder? = nil
local alive: { [Model]: boolean } = {}
local touchClock: { [Model]: number } = {}
local onEnemyDied: ((player: Player?, kind: EnemyKind, score: number) -> ())? = nil
local onPlayerDamaged: ((player: Player, amount: number) -> ())? = nil
local heartbeatConn: RBXScriptConnection? = nil

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

local function getDefinition(kind: EnemyKind)
	if kind == "Boss" then
		return Config.Enemies.Boss
	elseif kind == "Bruiser" then
		return Config.Enemies.Bruiser
	end
	return Config.Enemies.Runner
end

local function nearestPlayerRoot(from: Vector3): (BasePart?, Player?)
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

function EnemyService.init(hooks: {
	onEnemyDied: (player: Player?, kind: EnemyKind, score: number) -> (),
	onPlayerDamaged: (player: Player, amount: number) -> (),
})
	onEnemyDied = hooks.onEnemyDied
	onPlayerDamaged = hooks.onPlayerDamaged
	enemyFolder()

	if heartbeatConn then
		heartbeatConn:Disconnect()
	end

	heartbeatConn = RunService.Heartbeat:Connect(function()
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

			local target = nearestPlayerRoot(root.Position)
			if target then
				local look = Vector3.new(target.Position.X - root.Position.X, 0, target.Position.Z - root.Position.Z)
				if look.Magnitude > 0.1 then
					local dir = look.Unit
					humanoid:Move(dir, false)
					root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
				end
			end

			-- Soft keep-in-arena
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
			if flat.Magnitude > Config.Arena.Radius - 2 then
				local push = flat.Unit * (Config.Arena.Radius - 4)
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
	local f = enemyFolder()
	f:ClearAllChildren()
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

function EnemyService.spawn(kind: EnemyKind): Model
	local def = getDefinition(kind)
	local model = Instance.new("Model")
	model.Name = def.Name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = false
	root.CFrame = ArenaBuilder.randomSpawnCFrame()
	root.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = def.Size
	body.Color = def.Color
	body.Material = Enum.Material.Neon
	body.CanCollide = true
	body.Massless = false
	body.CFrame = root.CFrame
	body.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = root

	local light = Instance.new("PointLight")
	light.Color = def.Color
	light.Brightness = if kind == "Boss" then 4 else 2
	light.Range = if kind == "Boss" then 28 else 14
	light.Parent = body

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = def.Health
	humanoid.Health = def.Health
	humanoid.WalkSpeed = def.Speed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Score", def.Score)
	model:SetAttribute("Damage", def.Damage)
	model:SetAttribute("TouchCooldown", def.TouchCooldown)
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
		if onEnemyDied then
			onEnemyDied(killer, kind, def.Score)
		end

		-- Death burst placeholder part for client FX hook
		local burst = Instance.new("Part")
		burst.Name = "DeathBurst"
		burst.Anchored = true
		burst.CanCollide = false
		burst.Transparency = 1
		burst.Size = Vector3.new(1, 1, 1)
		burst.CFrame = root.CFrame
		burst.Parent = Workspace
		burst:SetAttribute("Color", def.Color:ToHex())
		Debris:AddItem(burst, 0.5)
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
		local last = touchClock[model] or 0
		if now - last < def.TouchCooldown then
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
