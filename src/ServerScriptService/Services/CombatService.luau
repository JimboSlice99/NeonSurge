--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local SoundUtil = require(game:GetService("ReplicatedStorage").Shared.SoundUtil)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local EnemyService = require(script.Parent.EnemyService)

type WeaponId = Types.WeaponId

export type CombatProfile = {
	damageMul: number,
	fireRateMul: number,
	dashCooldown: number,
	weapons: { WeaponId },
	activeWeapon: WeaponId,
}

local CombatService = {}

local fireClock: { [Player]: number } = {}
local dashClock: { [Player]: number } = {}
local slamClock: { [Player]: number } = {}
local profiles: { [Player]: CombatProfile } = {}
local folder: Folder? = nil
local onStyle: ((Player, number, string) -> ())? = nil

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
	local bestDist = Config.Combat.MaxRange
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

local function addTrail(part: BasePart, color: Color3)
	local a0 = Instance.new("Attachment")
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, -0.25)
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.16
	trail.LightEmission = 0.35
	trail.FaceCamera = true
	trail.Parent = part
end

function CombatService.init(hooks: { onStyle: (Player, number, string) -> () })
	onStyle = hooks.onStyle
	projFolder()

	Remotes.get("RequestFire").OnServerEvent:Connect(function(player, aim)
		CombatService.tryFire(player, aim)
	end)
	Remotes.get("RequestDash").OnServerEvent:Connect(function(player, dir)
		CombatService.tryDash(player, dir)
	end)
	Remotes.get("RequestSlam").OnServerEvent:Connect(function(player)
		CombatService.trySlam(player)
	end)
	Remotes.get("RequestWeapon").OnServerEvent:Connect(function(player, weaponId)
		CombatService.setWeapon(player, weaponId)
	end)
	Players.PlayerRemoving:Connect(function(player)
		fireClock[player] = nil
		dashClock[player] = nil
		slamClock[player] = nil
		profiles[player] = nil
	end)
end

function CombatService.setProfile(player: Player, profile: CombatProfile)
	profiles[player] = profile
end

function CombatService.getProfile(player: Player): CombatProfile
	return profiles[player]
		or {
			damageMul = 1,
			fireRateMul = 1,
			dashCooldown = Config.Movement.DashCooldown,
			weapons = { "Pulse" },
			activeWeapon = "Pulse",
		}
end

function CombatService.setWeapon(player: Player, weaponId: any)
	if typeof(weaponId) ~= "string" then
		return
	end
	local profile = CombatService.getProfile(player)
	if table.find(profile.weapons, weaponId :: WeaponId) then
		profile.activeWeapon = weaponId :: WeaponId
		profiles[player] = profile
	end
end

local function weaponDef(id: WeaponId)
	return Config.Weapons[id]
end

local function spawnBolt(player: Player, origin: Vector3, direction: Vector3, damage: number, speed: number, pierce: number, color: Color3)
	local bolt = Instance.new("Part")
	bolt.Name = "Bolt"
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.new(0.7, 0.7, 0.7)
	bolt.Color = color
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Massless = true
	bolt.CastShadow = false
	bolt.CFrame = CFrame.new(origin + direction * 2.2 + Vector3.new(0, 1.2, 0), origin + direction * 5)
	bolt.Parent = projFolder()
	addTrail(bolt, color)

	local att = Instance.new("Attachment")
	att.Parent = bolt
	local vel = Instance.new("LinearVelocity")
	vel.Attachment0 = att
	vel.MaxForce = math.huge
	vel.VectorVelocity = direction * speed
	vel.Parent = bolt

	local pierced: { [Model]: boolean } = {}
	local left = pierce
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
		local killed = EnemyService.applyDamage(enemy, damage, player)
		Remotes.get("FxBurst"):FireAllClients({ kind = "hit", position = bolt.Position, color = color })
		if killed and onStyle then
			onStyle(player, 8, "HIT")
		end
		if left <= 0 then
			bolt:Destroy()
			conn:Disconnect()
		else
			left -= 1
		end
	end)
	Debris:AddItem(bolt, 1.2)
end

function CombatService.tryFire(player: Player, aim: any)
	local profile = CombatService.getProfile(player)
	local def = weaponDef(profile.activeWeapon)
	local rate = def.fireRate * profile.fireRateMul
	local now = os.clock()
	if now - (fireClock[player] or 0) < 1 / math.max(rate, 0.4) then
		return
	end
	if player:GetAttribute("RunActive") ~= true then
		return
	end
	local root = rootOf(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
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
	SoundUtil.play("Shoot", 0.1, root)

	local damage = def.damage * profile.damageMul
	local count = def.count
	local spread = math.rad(def.spread)
	for i = 1, count do
		local t = if count == 1 then 0 else (i - 1) / (count - 1) - 0.5
		local dir = (CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(0, t * spread, 0)).LookVector
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		spawnBolt(player, root.Position, dir, damage, def.speed, def.pierce, def.color)
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
	SoundUtil.play("Dash", 0.28, root)

	local attachment = root:FindFirstChild("DashAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = root
	end
	local linear = Instance.new("LinearVelocity")
	linear.Attachment0 = attachment
	linear.MaxForce = math.huge
	linear.VectorVelocity = direction * Config.Movement.DashSpeed + Vector3.new(0, 12, 0)
	linear.Parent = root

	Remotes.get("FxBurst"):FireAllClients({ kind = "dash", position = root.Position, color = Config.Palette.Magenta })
	if onStyle then
		onStyle(player, 12, "DASH")
	end

	task.delay(Config.Movement.DashDuration, function()
		if linear.Parent then
			linear:Destroy()
		end
	end)
	task.delay(Config.Movement.DashIFrames, function()
		if character.Parent then
			character:SetAttribute("IFrames", false)
		end
	end)
end

function CombatService.trySlam(player: Player)
	local now = os.clock()
	if now - (slamClock[player] or 0) < Config.Movement.SlamCooldown then
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
	-- Must be airborne-ish
	if humanoid.FloorMaterial ~= Enum.Material.Air and root.AssemblyLinearVelocity.Y > -5 then
		-- allow if somewhat above ground via ray
		local ray = Workspace:Raycast(root.Position, Vector3.new(0, -6, 0))
		if ray then
			return
		end
	end

	slamClock[player] = now
	character:SetAttribute("IFrames", true)
	SoundUtil.play("Slam", 0.4, root)

	local attachment = root:FindFirstChild("DashAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = root
	end
	local linear = Instance.new("LinearVelocity")
	linear.Attachment0 = attachment
	linear.MaxForce = math.huge
	linear.VectorVelocity = Vector3.new(0, -Config.Movement.SlamSpeed, 0)
	linear.Parent = root

	Remotes.get("FxBurst"):FireClient(player, { kind = "slam", color = Config.Palette.Orange })

	task.delay(0.35, function()
		if linear.Parent then
			linear:Destroy()
		end
		local profile = CombatService.getProfile(player)
		local hits = EnemyService.blast(root.Position, Config.Movement.SlamRadius, Config.Movement.SlamDamage * profile.damageMul, player)
		Remotes.get("FxBurst"):FireAllClients({
			kind = "slamImpact",
			position = root.Position,
			color = Config.Palette.Orange,
		})
		if onStyle and hits > 0 then
			onStyle(player, 25 + hits * 10, "SLAM")
		end
		if character.Parent then
			character:SetAttribute("IFrames", false)
		end
	end)
end

return CombatService
