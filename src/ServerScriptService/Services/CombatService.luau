--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)

local CombatService = {}

local fireClock: { [Player]: number } = {}
local dashClock: { [Player]: number } = {}
local projectilesFolder: Folder? = nil

local function folder(): Folder
	if projectilesFolder and projectilesFolder.Parent then
		return projectilesFolder
	end
	local existing = Workspace:FindFirstChild("NeonProjectiles")
	if existing and existing:IsA("Folder") then
		projectilesFolder = existing
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "NeonProjectiles"
	created.Parent = Workspace
	projectilesFolder = created
	return created
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function nearestEnemyDirection(from: Vector3): Vector3?
	local best: Vector3? = nil
	local bestDist = Config.Combat.MaxRange
	local enemies = Workspace:FindFirstChild("NeonEnemies")
	if not enemies then
		return nil
	end
	for _, model in enemies:GetChildren() do
		if model:IsA("Model") and model.PrimaryPart then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local offset = model.PrimaryPart.Position - from
				local dist = offset.Magnitude
				if dist < bestDist and dist > 1 then
					bestDist = dist
					best = offset.Unit
				end
			end
		end
	end
	return best
end

function CombatService.init()
	folder()

	Remotes.get("RequestFire").OnServerEvent:Connect(function(player: Player, aim: any)
		CombatService.tryFire(player, aim)
	end)

	Remotes.get("RequestDash").OnServerEvent:Connect(function(player: Player, dir: any)
		CombatService.tryDash(player, dir)
	end)

	Players.PlayerRemoving:Connect(function(player)
		fireClock[player] = nil
		dashClock[player] = nil
	end)
end

function CombatService.tryFire(player: Player, aim: any)
	local now = os.clock()
	local last = fireClock[player] or 0
	if now - last < 1 / Config.Combat.FireRate then
		return
	end

	local root = getRoot(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local direction: Vector3
	if typeof(aim) == "Vector3" and aim.Magnitude > 0.05 then
		direction = Vector3.new(aim.X, 0, aim.Z)
		if direction.Magnitude < 0.05 then
			direction = root.CFrame.LookVector
		else
			direction = direction.Unit
		end
	elseif Config.Combat.AutoAim then
		direction = nearestEnemyDirection(root.Position) or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if direction.Magnitude < 0.05 then
			direction = Vector3.new(0, 0, -1)
		else
			direction = direction.Unit
		end
	else
		direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	end

	fireClock[player] = now

	local bolt = Instance.new("Part")
	bolt.Name = "SurgeBolt"
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.new(Config.Combat.ProjectileRadius * 2, Config.Combat.ProjectileRadius * 2, Config.Combat.ProjectileRadius * 2)
	bolt.Color = Config.Palette.Cyan
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Anchored = false
	bolt.Massless = true
	bolt.CFrame = CFrame.new(root.Position + direction * 2.5 + Vector3.new(0, 1.2, 0))
	bolt.Parent = folder()

	local light = Instance.new("PointLight")
	light.Color = Config.Palette.Cyan
	light.Brightness = 2.5
	light.Range = 10
	light.Parent = bolt

	local attachment = Instance.new("Attachment")
	attachment.Parent = bolt

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = direction * Config.Combat.ProjectileSpeed
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = bolt

	local hitOnce = false
	local conn: RBXScriptConnection
	conn = bolt.Touched:Connect(function(hit)
		if hitOnce then
			return
		end
		if hit:IsDescendantOf(player.Character :: Model) then
			return
		end
		local enemy = EnemyService.getEnemyFromPart(hit)
		if enemy then
			hitOnce = true
			EnemyService.applyDamage(enemy, Config.Combat.ProjectileDamage, player)
			Remotes.get("FxBurst"):FireAllClients({
				kind = "hit",
				position = bolt.Position,
				color = Config.Palette.Lime,
			})
			bolt:Destroy()
			conn:Disconnect()
		end
	end)

	Debris:AddItem(bolt, Config.Combat.ProjectileLifetime)
	task.delay(Config.Combat.ProjectileLifetime, function()
		if conn.Connected then
			conn:Disconnect()
		end
	end)
end

function CombatService.tryDash(player: Player, dir: any)
	local now = os.clock()
	local last = dashClock[player] or 0
	if now - last < Config.Player.DashCooldown then
		return
	end

	local character = player.Character
	local root = getRoot(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local direction: Vector3
	if typeof(dir) == "Vector3" and Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.1 then
		direction = Vector3.new(dir.X, 0, dir.Z).Unit
	else
		local move = humanoid.MoveDirection
		if move.Magnitude > 0.1 then
			direction = Vector3.new(move.X, 0, move.Z).Unit
		else
			direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
		end
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
	linear.Name = "DashVelocity"
	linear.Attachment0 = attachment
	linear.MaxForce = math.huge
	linear.VectorVelocity = direction * Config.Player.DashSpeed
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	linear.Parent = root

	Remotes.get("FxBurst"):FireAllClients({
		kind = "dash",
		position = root.Position,
		color = Config.Palette.Magenta,
		playerId = player.UserId,
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

function CombatService.isDashReady(player: Player): boolean
	local last = dashClock[player] or 0
	return os.clock() - last >= Config.Player.DashCooldown
end

return CombatService
