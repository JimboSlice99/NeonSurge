--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)

export type CombatProfile = {
	damage: number,
	fireRate: number,
	projectileSpeed: number,
	projectileCount: number,
	pierce: number,
	dashCooldown: number,
}

local CombatService = {}

local fireClock: { [Player]: number } = {}
local dashClock: { [Player]: number } = {}
local profiles: { [Player]: CombatProfile } = {}
local folder: Folder? = nil

local function projFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local existing = Workspace:FindFirstChild("NeonProjectiles")
	if existing and existing:IsA("Folder") then
		folder = existing
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "NeonProjectiles"
	created.Parent = Workspace
	folder = created
	return created
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function nearestEnemyDir(from: Vector3): Vector3?
	local enemies = Workspace:FindFirstChild("NeonEnemies")
	if not enemies then
		return nil
	end
	local best: Vector3? = nil
	local bestDist = Config.Player.MaxRange
	for _, model in enemies:GetChildren() do
		if model:IsA("Model") and model.PrimaryPart then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local offset = model.PrimaryPart.Position - from
				local dist = offset.Magnitude
				if dist < bestDist and dist > 1 then
					bestDist = dist
					best = Vector3.new(offset.X, 0, offset.Z).Unit
				end
			end
		end
	end
	return best
end

function CombatService.init()
	projFolder()
	Remotes.get("RequestFire").OnServerEvent:Connect(function(player, aim)
		CombatService.tryFire(player, aim)
	end)
	Remotes.get("RequestDash").OnServerEvent:Connect(function(player, dir)
		CombatService.tryDash(player, dir)
	end)
	Players.PlayerRemoving:Connect(function(player)
		fireClock[player] = nil
		dashClock[player] = nil
		profiles[player] = nil
	end)
end

function CombatService.setProfile(player: Player, profile: CombatProfile)
	profiles[player] = profile
end

function CombatService.getProfile(player: Player): CombatProfile
	return profiles[player] or {
		damage = Config.Player.BaseDamage,
		fireRate = Config.Player.BaseFireRate,
		projectileSpeed = Config.Player.BaseProjectileSpeed,
		projectileCount = 1,
		pierce = 0,
		dashCooldown = Config.Player.DashCooldown,
	}
end

local function spawnBolt(player: Player, origin: Vector3, direction: Vector3, profile: CombatProfile)
	local bolt = Instance.new("Part")
	bolt.Name = "SurgeBolt"
	bolt.Shape = Enum.PartType.Ball
	local r = Config.Player.ProjectileRadius * 2
	bolt.Size = Vector3.new(r, r, r)
	bolt.Color = Config.Palette.Cyan
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Massless = true
	bolt.CFrame = CFrame.new(origin + direction * 2.4 + Vector3.new(0, 1.3, 0))
	bolt.Parent = projFolder()

	local light = Instance.new("PointLight")
	light.Color = Config.Palette.Cyan
	light.Brightness = 2.2
	light.Range = 10
	light.Parent = bolt

	local att = Instance.new("Attachment")
	att.Parent = bolt
	local vel = Instance.new("LinearVelocity")
	vel.Attachment0 = att
	vel.MaxForce = math.huge
	vel.VectorVelocity = direction * profile.projectileSpeed
	vel.Parent = bolt

	local pierced: { [Model]: boolean } = {}
	local pierceLeft = profile.pierce
	local conn: RBXScriptConnection
	conn = bolt.Touched:Connect(function(hit)
		if player.Character and hit:IsDescendantOf(player.Character) then
			return
		end
		local enemy = EnemyService.getEnemyFromPart(hit)
		if not enemy or pierced[enemy] then
			return
		end
		pierced[enemy] = true
		EnemyService.applyDamage(enemy, profile.damage, player)
		Remotes.get("FxBurst"):FireAllClients({
			kind = "hit",
			position = bolt.Position,
			color = Config.Palette.Lime,
		})
		if pierceLeft <= 0 then
			bolt:Destroy()
			conn:Disconnect()
		else
			pierceLeft -= 1
		end
	end)

	Debris:AddItem(bolt, Config.Player.ProjectileLifetime)
end

function CombatService.tryFire(player: Player, aim: any)
	local profile = CombatService.getProfile(player)
	local now = os.clock()
	if now - (fireClock[player] or 0) < 1 / math.max(profile.fireRate, 0.5) then
		return
	end

	local root = rootOf(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("RunActive") ~= true then
		return
	end

	local direction: Vector3
	if typeof(aim) == "Vector3" and Vector3.new(aim.X, 0, aim.Z).Magnitude > 0.05 then
		direction = Vector3.new(aim.X, 0, aim.Z).Unit
	else
		direction = nearestEnemyDir(root.Position)
			or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if direction.Magnitude < 0.05 then
			direction = Vector3.new(0, 0, -1)
		else
			direction = direction.Unit
		end
	end

	fireClock[player] = now

	local count = math.clamp(profile.projectileCount, 1, 7)
	local spread = if count == 1 then 0 else math.rad(10 + count * 2)
	for i = 1, count do
		local t = if count == 1 then 0 else (i - 1) / (count - 1) - 0.5
		local dir = (CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(0, t * spread, 0)).LookVector
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		spawnBolt(player, root.Position, dir, profile)
	end
end

function CombatService.tryDash(player: Player, dir: any)
	local profile = CombatService.getProfile(player)
	local now = os.clock()
	if now - (dashClock[player] or 0) < profile.dashCooldown then
		return
	end
	if player:GetAttribute("RunActive") ~= true then
		return
	end

	local character = player.Character
	local root = rootOf(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local direction: Vector3
	if typeof(dir) == "Vector3" and Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.1 then
		direction = Vector3.new(dir.X, 0, dir.Z).Unit
	elseif humanoid.MoveDirection.Magnitude > 0.1 then
		direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z).Unit
	else
		direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	end

	dashClock[player] = now
	character:SetAttribute("IFrames", true)

	local attachment = root:FindFirstChild("DashAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = root
	end

	local linear = Instance.new("LinearVelocity")
	linear.Attachment0 = attachment
	linear.MaxForce = math.huge
	linear.VectorVelocity = direction * Config.Player.DashSpeed
	linear.Parent = root

	Remotes.get("FxBurst"):FireAllClients({
		kind = "dash",
		position = root.Position,
		color = Config.Palette.Magenta,
	})

	task.delay(Config.Player.DashDuration, function()
		if linear.Parent then
			linear:Destroy()
		end
	end)
	task.delay(Config.Player.DashIFrames, function()
		if character.Parent then
			character:SetAttribute("IFrames", false)
		end
	end)
end

return CombatService
