--!strict

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local SoundUtil = require(game:GetService("ReplicatedStorage").Shared.SoundUtil)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

type TowerId = Types.TowerId

export type TowerState = {
	id: string,
	kind: TowerId,
	level: number,
	model: Model,
	plot: BasePart,
	owner: Player,
	lastFire: number,
}

local TowerService = {}

local towers: { [string]: TowerState } = {}
local folder: Folder? = nil
local damageMul = 1
local rangeMul = 1
local getEnemies: (() -> { Model })? = nil
local damageEnemy: ((Model, number, boolean?) -> boolean)? = nil
local heartbeat: RBXScriptConnection? = nil
local nextId = 0

local function towerFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local existing = Workspace:FindFirstChild("NeonTowers")
	if existing and existing:IsA("Folder") then
		folder = existing
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "NeonTowers"
	created.Parent = Workspace
	folder = created
	return created
end

local function defFor(kind: TowerId)
	return Config.Towers[kind]
end

local function statsFor(kind: TowerId, level: number)
	local base = defFor(kind)
	if level <= 0 then
		return {
			damage = base.damage,
			fireRate = base.fireRate,
			range = base.range,
			pierce = (base :: any).pierce or 0,
			splash = (base :: any).splash or 0,
			slow = (base :: any).slow or 0,
			color = base.color,
		}
	end
	local up = base.upgrades[level]
	return {
		damage = up.damage,
		fireRate = up.fireRate,
		range = up.range,
		pierce = (base :: any).pierce or 0,
		splash = (up :: any).splash or (base :: any).splash or 0,
		slow = (up :: any).slow or (base :: any).slow or 0,
		color = base.color,
	}
end

local function buildModel(kind: TowerId, plot: BasePart, level: number): Model
	local def = defFor(kind)
	local model = Instance.new("Model")
	model.Name = def.name

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Size = Vector3.new(4.5, 1, 4.5)
	base.CFrame = plot.CFrame * CFrame.new(0, 0.75, 0)
	base.Color = Color3.fromRGB(20, 26, 36)
	base.Material = Enum.Material.SmoothPlastic
	base.Parent = model

	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Anchored = true
	stem.Size = Vector3.new(1.6, 4 + level, 1.6)
	stem.CFrame = base.CFrame * CFrame.new(0, 2.5 + level * 0.5, 0)
	stem.Color = Color3.fromRGB(
		math.floor(def.color.R * 255 * 0.35),
		math.floor(def.color.G * 255 * 0.35),
		math.floor(def.color.B * 255 * 0.35)
	)
	stem.Material = Enum.Material.SmoothPlastic
	stem.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.2, 2.2, 2.2)
	head.CFrame = stem.CFrame * CFrame.new(0, stem.Size.Y * 0.55, 0)
	head.Color = def.color
	head.Material = Enum.Material.Neon
	head.Transparency = 0.15
	head.Parent = model

	local hl = Instance.new("Highlight")
	hl.FillColor = def.color
	hl.OutlineColor = def.color
	hl.FillTransparency = 0.9
	hl.OutlineTransparency = 0.45
	hl.Parent = model

	model.PrimaryPart = base
	model.Parent = towerFolder()
	return model
end

local function fireProjectile(from: Vector3, target: Model, damage: number, color: Color3, pierce: number, splash: number)
	local root = target.PrimaryPart
	if not root then
		return
	end
	local bolt = Instance.new("Part")
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.new(0.55, 0.55, 0.55)
	bolt.Color = color
	bolt.Material = Enum.Material.Neon
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CastShadow = false
	bolt.CFrame = CFrame.new(from)
	bolt.Parent = Workspace

	local goal = root.Position + Vector3.new(0, 1, 0)
	local dist = (goal - from).Magnitude
	local t = math.clamp(dist / 120, 0.05, 0.25)
	local alpha = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt)
		alpha += dt / t
		if alpha >= 1 or not bolt.Parent then
			conn:Disconnect()
			if bolt.Parent then
				bolt:Destroy()
			end
			if damageEnemy and target.Parent then
				damageEnemy(target, damage, false)
			end
			if splash > 0 and getEnemies and damageEnemy then
				for _, enemy in getEnemies() do
					if enemy ~= target and enemy.PrimaryPart then
						if (enemy.PrimaryPart.Position - goal).Magnitude <= splash then
							damageEnemy(enemy, damage * 0.55, false)
						end
					end
				end
			end
			Remotes.get("FxBurst"):FireAllClients({ kind = "hit", position = goal, color = color })
			return
		end
		bolt.CFrame = CFrame.new(from:Lerp(goal, alpha))
	end)
	Debris:AddItem(bolt, 1)
	local _ = pierce
end

function TowerService.init(hooks: {
	getEnemies: () -> { Model },
	damageEnemy: (Model, number, boolean?) -> boolean,
})
	getEnemies = hooks.getEnemies
	damageEnemy = hooks.damageEnemy
	towerFolder()
	if heartbeat then
		heartbeat:Disconnect()
	end
	heartbeat = RunService.Heartbeat:Connect(function()
		if not getEnemies then
			return
		end
		local enemies = getEnemies()
		local now = os.clock()
		for _, tower in towers do
			local st = statsFor(tower.kind, tower.level)
			local range = st.range * rangeMul
			local rate = st.fireRate
			if now - tower.lastFire < 1 / math.max(rate, 0.2) then
				continue
			end
			local head = tower.model:FindFirstChild("Head")
			if not head or not head:IsA("BasePart") then
				continue
			end
			local best: Model? = nil
			local bestDist = range
			for _, enemy in enemies do
				local root = enemy.PrimaryPart
				if root then
					local dist = (root.Position - head.Position).Magnitude
					if dist <= range and dist < bestDist then
						best = enemy
						bestDist = dist
					end
				end
			end
			if best then
				tower.lastFire = now
				local dmg = st.damage * damageMul
				fireProjectile(head.Position, best, dmg, st.color, st.pierce, st.splash)
				if st.slow > 0 and best.Parent then
					best:SetAttribute("Slow", math.max(tonumber(best:GetAttribute("Slow")) or 0, st.slow))
					best:SetAttribute("SlowUntil", now + 0.7)
				end
			end
		end
	end)
end

function TowerService.setMultipliers(dmg: number, range: number)
	damageMul = dmg
	rangeMul = range
end

function TowerService.clear()
	for id, tower in towers do
		tower.plot:SetAttribute("Occupied", false)
		tower.model:Destroy()
		towers[id] = nil
	end
	towerFolder():ClearAllChildren()
end

function TowerService.place(player: Player, plot: BasePart, kind: TowerId): (boolean, string?, number?)
	if plot:GetAttribute("Occupied") == true then
		return false, "Plot taken", nil
	end
	local def = defFor(kind)
	if not def then
		return false, "Unknown tower", nil
	end
	nextId += 1
	local id = ("t_%d"):format(nextId)
	local model = buildModel(kind, plot, 0)
	plot:SetAttribute("Occupied", true)
	plot:SetAttribute("TowerId", id)
	towers[id] = {
		id = id,
		kind = kind,
		level = 0,
		model = model,
		plot = plot,
		owner = player,
		lastFire = 0,
	}
	SoundUtil.play("Place", 0.35)
	Remotes.get("FxBurst"):FireAllClients({ kind = "place", position = plot.Position, color = def.color })
	return true, id, def.cost
end

function TowerService.upgrade(towerId: string): (boolean, number?)
	local tower = towers[towerId]
	if not tower then
		return false, nil
	end
	local def = defFor(tower.kind)
	local nextLevel = tower.level + 1
	local up = def.upgrades[nextLevel]
	if not up then
		return false, nil
	end
	tower.level = nextLevel
	local cf = tower.plot.CFrame
	tower.model:Destroy()
	tower.model = buildModel(tower.kind, tower.plot, tower.level)
	tower.plot.CFrame = cf
	SoundUtil.play("Place", 0.3)
	return true, up.cost
end

function TowerService.sell(towerId: string): number
	local tower = towers[towerId]
	if not tower then
		return 0
	end
	local def = defFor(tower.kind)
	local spent = def.cost
	for i = 1, tower.level do
		spent += def.upgrades[i].cost
	end
	local refund = math.floor(spent * 0.6)
	tower.plot:SetAttribute("Occupied", false)
	tower.plot:SetAttribute("TowerId", nil)
	tower.model:Destroy()
	towers[towerId] = nil
	return refund
end

function TowerService.get(towerId: string): TowerState?
	return towers[towerId]
end

function TowerService.getByPlot(plot: BasePart): TowerState?
	local id = plot:GetAttribute("TowerId")
	if typeof(id) == "string" then
		return towers[id]
	end
	return nil
end

return TowerService
