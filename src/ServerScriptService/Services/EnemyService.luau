--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local ArenaBuilder = require(script.Parent.ArenaBuilder)

type EnemyKind = Types.EnemyKind

local DEFS = {
	Wisp = {
		Health = 26,
		Speed = 17,
		Damage = 7,
		Color = Color3.fromRGB(60, 190, 185),
		Score = 16,
		Xp = 6,
		Credits = 1,
		Shape = "Ball",
		Size = Vector3.new(1.7, 1.7, 1.7),
	},
	Skitter = {
		Health = 34,
		Speed = 20,
		Damage = 6,
		Color = Color3.fromRGB(90, 210, 120),
		Score = 22,
		Xp = 8,
		Credits = 1,
		Shape = "Block",
		Size = Vector3.new(2.2, 1.2, 2.8),
	},
	Gunner = {
		Health = 48,
		Speed = 11,
		Damage = 8,
		Color = Color3.fromRGB(220, 170, 70),
		Score = 34,
		Xp = 12,
		Credits = 2,
		Shape = "Tower",
		Size = Vector3.new(1.8, 3.4, 1.8),
		Range = 34,
		ShootCd = 1.35,
	},
	Bruiser = {
		Health = 140,
		Speed = 9,
		Damage = 18,
		Color = Color3.fromRGB(210, 70, 130),
		Score = 60,
		Xp = 18,
		Credits = 3,
		Shape = "Heavy",
		Size = Vector3.new(3.4, 3.4, 3.4),
		ChargeCd = 3.2,
	},
	Elite = {
		Health = 900,
		Speed = 12,
		Damage = 22,
		Color = Color3.fromRGB(150, 100, 230),
		Score = 600,
		Xp = 100,
		Credits = 40,
		Shape = "Boss",
		Size = Vector3.new(6, 6, 6),
		Range = 40,
		ShootCd = 1.1,
	},
}

local EnemyService = {}

local folder: Folder? = nil
local alive: { [Model]: boolean } = {}
local touchClock: { [Model]: number } = {}
local abilityClock: { [Model]: number } = {}
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
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and player:GetAttribute("RunActive") == true then
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

local function fireBolt(from: Vector3, toward: Vector3, damage: number, color: Color3, speed: number)
	local dir = toward - from
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then
		return
	end
	dir = dir.Unit
	local bolt = Instance.new("Part")
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.new(0.85, 0.85, 0.85)
	bolt.Color = color
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Massless = true
	bolt.CastShadow = false
	bolt.CFrame = CFrame.new(from + dir * 2 + Vector3.new(0, 1.4, 0))
	bolt.Parent = Workspace
	local att = Instance.new("Attachment")
	att.Parent = bolt
	local vel = Instance.new("LinearVelocity")
	vel.Attachment0 = att
	vel.MaxForce = math.huge
	vel.VectorVelocity = dir * speed
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
	Debris:AddItem(bolt, 2.5)
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
			local kind = model:GetAttribute("Kind") :: EnemyKind
			local def = DEFS[kind]
			local target = nearestPlayer(root.Position)
			if not target then
				continue
			end

			local offset = target.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			local dist = flat.Magnitude
			local dir = if dist > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
			local now = os.clock()

			if kind == "Gunner" or kind == "Elite" then
				local ideal = if kind == "Elite" then 22 else 26
				if dist < ideal - 4 then
					humanoid:Move(-dir, false)
				elseif dist > ideal + 6 then
					humanoid:Move(dir, false)
				else
					-- strafe
					local side = Vector3.new(-dir.Z, 0, dir.X)
					humanoid:Move(side * (if math.floor(now * 2) % 2 == 0 then 1 else -1), false)
				end
				local cd = def.ShootCd :: number
				if dist < (def.Range :: number) and now - (abilityClock[model] or 0) >= cd then
					abilityClock[model] = now
					fireBolt(root.Position, target.Position, def.Damage, def.Color, if kind == "Elite" then 70 else 58)
					if kind == "Elite" then
						fireBolt(root.Position, target.Position + Vector3.new(6, 0, 0), def.Damage * 0.7, def.Color, 65)
						fireBolt(root.Position, target.Position + Vector3.new(-6, 0, 0), def.Damage * 0.7, def.Color, 65)
					end
				end
			elseif kind == "Skitter" then
				local side = Vector3.new(-dir.Z, 0, dir.X)
				local weave = dir + side * math.sin(now * 6) * 0.8
				if weave.Magnitude > 0.1 then
					humanoid:Move(weave.Unit, false)
				end
			elseif kind == "Bruiser" then
				local charging = model:GetAttribute("Charging") == true
				if charging then
					humanoid.WalkSpeed = def.Speed * 2.3
					humanoid:Move(dir, false)
					if now - (abilityClock[model] or 0) > 0.85 then
						model:SetAttribute("Charging", false)
						humanoid.WalkSpeed = def.Speed
					end
				else
					humanoid:Move(dir, false)
					if dist < 28 and now - (abilityClock[model] or 0) >= (def.ChargeCd :: number) then
						abilityClock[model] = now
						model:SetAttribute("Charging", true)
						-- telegraph flash
						local body = model:FindFirstChild("Body")
						if body and body:IsA("BasePart") then
							local old = body.Color
							body.Color = Color3.new(1, 1, 1)
							task.delay(0.2, function()
								if body.Parent then
									body.Color = old
								end
							end)
						end
					end
				end
			else
				humanoid:Move(dir, false)
			end

			root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
		end
	end)
end

function EnemyService.clear()
	for model in pairs(alive) do
		model:Destroy()
	end
	table.clear(alive)
	table.clear(touchClock)
	table.clear(abilityClock)
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

function EnemyService.spawn(kind: EnemyKind, intensity: number): Model
	local def = DEFS[kind]
	local model = Instance.new("Model")
	model.Name = kind

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CFrame = ArenaBuilder.spawnPoint(kind == "Gunner" or kind == "Elite")
	root.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = def.Size
	body.Color = Color3.fromRGB(
		math.floor(def.Color.R * 255 * 0.4),
		math.floor(def.Color.G * 255 * 0.4),
		math.floor(def.Color.B * 255 * 0.4)
	)
	body.Material = Enum.Material.SmoothPlastic
	if def.Shape == "Ball" or def.Shape == "Boss" then
		body.Shape = Enum.PartType.Ball
	elseif def.Shape == "Heavy" then
		body.Shape = Enum.PartType.Cylinder
	end
	body.CFrame = root.CFrame
	body.Parent = model

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = def.Size * 0.32
	core.Color = def.Color
	core.Material = Enum.Material.Neon
	core.CanCollide = false
	core.Massless = true
	core.CastShadow = false
	core.Transparency = 0.12
	core.CFrame = root.CFrame
	core.Parent = model

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = root
	w1.Part1 = body
	w1.Parent = root
	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = root
	w2.Part1 = core
	w2.Parent = root

	local hl = Instance.new("Highlight")
	hl.FillColor = def.Color
	hl.OutlineColor = def.Color
	hl.FillTransparency = 0.88
	hl.OutlineTransparency = 0.4
	hl.Parent = model

	if kind == "Elite" then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(140, 12)
		billboard.StudsOffset = Vector3.new(0, 4.5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = body
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
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
	humanoid.MaxHealth = def.Health * (1 + intensity * 0.8)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = def.Speed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	if kind == "Elite" then
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
	model:SetAttribute("Credits", def.Credits)
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
			onEnemyDied(killer, kind, def.Score, def.Xp, def.Credits, pos)
		end
		Remotes.get("FxBurst"):FireAllClients({ kind = "kill", position = pos, color = def.Color })
		Debris:AddItem(model, 0.05)
	end)

	body.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player or character:GetAttribute("IFrames") == true then
			return
		end
		local now = os.clock()
		if now - (touchClock[model] or 0) < 0.7 then
			return
		end
		touchClock[model] = now
		if onPlayerDamaged then
			local dmg = def.Damage
			if model:GetAttribute("Charging") == true then
				dmg *= 1.5
			end
			onPlayerDamaged(player, dmg)
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
	local before = humanoid.Health
	humanoid:TakeDamage(amount)
	return before > 0
end

function EnemyService.blast(origin: Vector3, radius: number, damage: number, attacker: Player?): number
	local hits = 0
	for model in pairs(alive) do
		if model.PrimaryPart and (model.PrimaryPart.Position - origin).Magnitude <= radius then
			if EnemyService.applyDamage(model, damage, attacker) then
				hits += 1
			end
		end
	end
	return hits
end

function EnemyService.getEnemyFromPart(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if model and alive[model] and CollectionService:HasTag(model, "NeonEnemy") then
		return model
	end
	return nil
end

return EnemyService
