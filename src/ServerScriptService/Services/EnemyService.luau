--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local ArenaBuilder = require(script.Parent.ArenaBuilder)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)

type EnemyKind = Types.EnemyKind

local DEFS = {
	Runner = {
		Name = "Pulse Runner",
		Health = 30,
		Speed = 15,
		Damage = 8,
		TouchCooldown = 0.65,
		Color = Color3.fromRGB(0, 255, 200),
		Size = Vector3.new(2.1, 2.1, 2.1),
		Score = 20,
		Xp = 8,
		Credits = 1,
	},
	Shooter = {
		Name = "Arc Spitter",
		Health = 40,
		Speed = 10,
		Damage = 6,
		TouchCooldown = 0.8,
		Color = Color3.fromRGB(255, 200, 60),
		Size = Vector3.new(2.4, 2.4, 2.4),
		Score = 35,
		Xp = 12,
		Credits = 2,
		Range = 28,
		ShootCd = 1.6,
	},
	Bruiser = {
		Name = "Volt Bruiser",
		Health = 110,
		Speed = 9,
		Damage = 16,
		TouchCooldown = 0.85,
		Color = Color3.fromRGB(255, 70, 180),
		Size = Vector3.new(3.4, 3.4, 3.4),
		Score = 60,
		Xp = 20,
		Credits = 3,
	},
	Boss = {
		Name = "Neon Overlord",
		Health = 700,
		Speed = 11,
		Damage = 22,
		TouchCooldown = 0.7,
		Color = Color3.fromRGB(170, 90, 255),
		Size = Vector3.new(6.5, 6.5, 6.5),
		Score = 500,
		Xp = 80,
		Credits = 25,
	},
}

local EnemyService = {}

local folder: Folder? = nil
local alive: { [Model]: boolean } = {}
local touchClock: { [Model]: number } = {}
local shootClock: { [Model]: number } = {}
local onEnemyDied: ((Player?, EnemyKind, number, number, number) -> ())? = nil
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
	bolt.Size = Vector3.new(1.1, 1.1, 1.1)
	bolt.Color = Config.Palette.Gold
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Massless = true
	bolt.CFrame = CFrame.new(from + dir * 2 + Vector3.new(0, 1.5, 0))
	bolt.Parent = Workspace

	local att = Instance.new("Attachment")
	att.Parent = bolt
	local vel = Instance.new("LinearVelocity")
	vel.Attachment0 = att
	vel.MaxForce = math.huge
	vel.VectorVelocity = dir * 55
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

	Debris:AddItem(bolt, 3)
end

function EnemyService.init(hooks: {
	onEnemyDied: (Player?, EnemyKind, number, number, number) -> (),
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
					-- Shooters kite a bit
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
					local last = shootClock[model] or 0
					if dist <= (def.Range :: number) and now - last >= (def.ShootCd :: number) then
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
	local hpScale = 1 + (wave - 1) * 0.12
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
	body.Shape = Enum.PartType.Ball
	body.Size = def.Size
	body.Color = def.Color
	body.Material = Enum.Material.Neon
	body.CFrame = root.CFrame
	body.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = root

	local light = Instance.new("PointLight")
	light.Color = def.Color
	light.Brightness = if kind == "Boss" then 5 else 2.2
	light.Range = if kind == "Boss" then 30 else 14
	light.Parent = body

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = def.Health * hpScale
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = def.Speed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

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
		if onEnemyDied then
			onEnemyDied(killer, kind, def.Score, def.Xp, model:GetAttribute("Credits") :: number)
		end
		Remotes.get("FxBurst"):FireAllClients({
			kind = "kill",
			position = root.Position,
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
