--!strict

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

type EnemyKind = Types.EnemyKind

local EnemyService = {}

local folder: Folder? = nil
local alive: { [Model]: boolean } = {}
local waypoints: { Vector3 } = {}
local onLeak: ((number) -> ())? = nil
local onDeath: ((number, Vector3) -> ())? = nil
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

function EnemyService.init(hooks: {
	onLeak: (number) -> (),
	onDeath: (reward: number, position: Vector3) -> (),
})
	onLeak = hooks.onLeak
	onDeath = hooks.onDeath
	enemyFolder()
	if heartbeat then
		heartbeat:Disconnect()
	end

	heartbeat = RunService.Heartbeat:Connect(function(dt)
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

			local index = tonumber(model:GetAttribute("WP")) or 1
			local target = waypoints[index]
			if not target then
				continue
			end

			local now = os.clock()
			local slow = tonumber(model:GetAttribute("Slow")) or 0
			local slowUntil = tonumber(model:GetAttribute("SlowUntil")) or 0
			if now > slowUntil then
				slow = 0
				model:SetAttribute("Slow", 0)
			end

			local baseSpeed = tonumber(model:GetAttribute("Speed")) or 12
			local speed = baseSpeed * (1 - math.clamp(slow, 0, 0.8))
			local pos = root.Position
			local flatTarget = Vector3.new(target.X, pos.Y, target.Z)
			local delta = flatTarget - pos
			local dist = delta.Magnitude
			if dist < 1.2 then
				index += 1
				model:SetAttribute("WP", index)
				if index > #waypoints then
					-- leaked to core
					local lives = tonumber(model:GetAttribute("Leak")) or 1
					alive[model] = nil
					model:Destroy()
					if onLeak then
						onLeak(lives)
					end
				end
			else
				local step = math.min(dist, speed * dt)
				local nextPos = pos + delta.Unit * step
				root.CFrame = CFrame.lookAt(nextPos, nextPos + delta.Unit)
			end
		end
	end)
end

function EnemyService.setPath(points: { Vector3 })
	waypoints = points
end

function EnemyService.clear()
	for model in pairs(alive) do
		model:Destroy()
	end
	table.clear(alive)
	enemyFolder():ClearAllChildren()
end

function EnemyService.list(): { Model }
	local list = {}
	for model in pairs(alive) do
		if model.Parent then
			table.insert(list, model)
		else
			alive[model] = nil
		end
	end
	return list
end

function EnemyService.count(): number
	return #EnemyService.list()
end

function EnemyService.spawn(kind: EnemyKind, wave: number): Model
	local def = Config.Enemies[kind]
	local hpScale = 1 + (wave - 1) * 0.14
	local model = Instance.new("Model")
	model.Name = kind

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.CastShadow = false
	root.Size = if kind == "Boss" then Vector3.new(4.5, 4.5, 4.5) elseif kind == "Tank" then Vector3.new(3.2, 3.2, 3.2) else Vector3.new(2, 2, 2)
	root.Color = def.color
	root.Material = Enum.Material.Neon
	root.Transparency = 0.12
	root.Shape = Enum.PartType.Ball
	root.CFrame = CFrame.new(waypoints[1] or Vector3.new(0, 2, 0))
	root.Parent = model

	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Anchored = true
	shell.CanCollide = false
	shell.Size = root.Size * 1.15
	shell.Color = Color3.fromRGB(
		math.floor(def.color.R * 255 * 0.25),
		math.floor(def.color.G * 255 * 0.25),
		math.floor(def.color.B * 255 * 0.25)
	)
	shell.Material = Enum.Material.SmoothPlastic
	shell.Transparency = 0.35
	shell.Shape = Enum.PartType.Ball
	shell.CFrame = root.CFrame
	shell.Parent = model

	local hl = Instance.new("Highlight")
	hl.FillColor = def.color
	hl.OutlineColor = def.color
	hl.FillTransparency = 0.9
	hl.OutlineTransparency = 0.45
	hl.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = def.health * hpScale
	humanoid.Health = humanoid.MaxHealth
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("WP", 1)
	model:SetAttribute("Speed", def.speed)
	model:SetAttribute("Leak", def.leak)
	model:SetAttribute("Reward", def.reward + math.floor(wave * 0.5))
	model:SetAttribute("Kind", kind)
	model.Parent = enemyFolder()
	alive[model] = true

	local sync: RBXScriptConnection
	sync = RunService.Heartbeat:Connect(function()
		if not model.Parent or not root.Parent then
			sync:Disconnect()
			return
		end
		shell.CFrame = root.CFrame
	end)

	humanoid.Died:Connect(function()
		alive[model] = nil
		local reward = tonumber(model:GetAttribute("Reward")) or 0
		local pos = root.Position
		if onDeath then
			onDeath(reward, pos)
		end
		Remotes.get("FxBurst"):FireAllClients({ kind = "kill", position = pos, color = def.color })
		Debris:AddItem(model, 0.05)
	end)

	return model
end

function EnemyService.damage(model: Model, amount: number, _slow: boolean?): boolean
	if not alive[model] then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	humanoid:TakeDamage(amount)
	return true
end

return EnemyService
