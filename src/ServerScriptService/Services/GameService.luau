--!strict
-- Mission director: timed surge, style ranks, weapon unlocks, vertical combat.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Upgrades = require(game:GetService("ReplicatedStorage").Shared.Upgrades)
local SoundUtil = require(game:GetService("ReplicatedStorage").Shared.SoundUtil)
local ArenaBuilder = require(script.Parent.ArenaBuilder)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local MonetizationService = require(script.Parent.MonetizationService)
local PickupService = require(script.Parent.PickupService)

type GamePhase = Types.GamePhase
type HudSnapshot = Types.HudSnapshot
type EnemyKind = Types.EnemyKind
type RunStats = Types.RunStats
type StyleRank = Types.StyleRank
type LobbySnapshot = Types.LobbySnapshot

local GameService = {}

type RunState = {
	active: boolean,
	phase: GamePhase,
	timeLeft: number,
	score: number,
	style: number,
	kills: number,
	combo: number,
	comboExpire: number,
	xp: number,
	level: number,
	creditsRun: number,
	health: number,
	maxHealth: number,
	stats: RunStats,
	leech: boolean,
	ownedUnlocks: { [string]: boolean },
	pendingUpgrades: { Types.UpgradeOption }?,
	token: number,
	spawnAcc: number,
	nextElite: number,
}

local runs: { [Player]: RunState } = {}

local function xpNeed(level: number): number
	return math.floor(Config.Combat.XpBase * (Config.Combat.XpGrowth ^ (level - 1)))
end

local function metaLevel(player: Player, id: string): number
	return DataService.getMetaLevel(player, id)
end

local function styleRank(style: number): StyleRank
	if style >= 6000 then
		return "SS"
	elseif style >= 3500 then
		return "S"
	elseif style >= 2000 then
		return "A"
	elseif style >= 1000 then
		return "B"
	elseif style >= 400 then
		return "C"
	end
	return "D"
end

local function buildLobby(player: Player): LobbySnapshot
	local data = DataService.get(player)
	local metaViews = {}
	for _, def in Config.MetaUpgrades do
		local level = data.meta[def.id] or 0
		local cost = math.floor(def.baseCost * (def.costGrowth ^ level))
		table.insert(metaViews, {
			id = def.id,
			name = def.name,
			desc = def.desc,
			level = level,
			maxLevel = def.maxLevel,
			cost = cost,
			affordable = data.credits >= cost and level < def.maxLevel,
		})
	end
	return {
		credits = data.credits,
		highScore = data.highScore,
		bestWave = data.bestWave,
		bestRank = tostring(data.meta.bestRank or "D"),
		ownsDoubleCredits = MonetizationService.owns(player, "DoubleCredits"),
		ownsVipTrail = MonetizationService.owns(player, "VipTrail"),
		ownsExtraDash = MonetizationService.owns(player, "ExtraDash"),
		meta = metaViews,
	}
end

local function pushLobby(player: Player)
	Remotes.get("LobbyUpdate"):FireClient(player, buildLobby(player))
end

local function ensureRun(player: Player): RunState
	local existing = runs[player]
	if existing then
		return existing
	end
	local state: RunState = {
		active = false,
		phase = "Lobby",
		timeLeft = Config.Director.MissionSeconds,
		score = 0,
		style = 0,
		kills = 0,
		combo = 0,
		comboExpire = 0,
		xp = 0,
		level = 1,
		creditsRun = 0,
		health = 100,
		maxHealth = 100,
		stats = Upgrades.defaultRunStats(),
		leech = false,
		ownedUnlocks = {},
		pendingUpgrades = nil,
		token = 0,
		spawnAcc = 0,
		nextElite = Config.Director.EliteEvery,
	}
	runs[player] = state
	return state
end

local function applyProfile(player: Player, state: RunState)
	local damageMeta = 1 + metaLevel(player, "damage") * 0.12
	local moveMeta = 1 + metaLevel(player, "mobility") * 0.06
	local dashMeta = (1 - metaLevel(player, "mobility") * 0.05) * state.stats.dashCooldownMul
	if MonetizationService.owns(player, "ExtraDash") then
		dashMeta *= 0.75
	end
	CombatService.setProfile(player, {
		damageMul = state.stats.damageMul * damageMeta,
		fireRateMul = state.stats.fireRateMul,
		dashCooldown = Config.Movement.DashCooldown * math.max(dashMeta, 0.4),
		weapons = state.stats.weapons,
		activeWeapon = state.stats.activeWeapon,
	})
	PickupService.setMagnetMul(player, state.stats.pickupMul * (1 + metaLevel(player, "magnet") * 0.2))

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.Movement.WalkSpeed * state.stats.moveMul * moveMeta
		humanoid.JumpPower = Config.Movement.JumpPower
		humanoid.MaxHealth = state.maxHealth
		humanoid.Health = math.min(state.health, state.maxHealth)
	end
end

local function hudFor(player: Player, message: string?, countdown: number?): HudSnapshot
	local state = ensureRun(player)
	local data = DataService.get(player)
	local weaponName = Config.Weapons[state.stats.activeWeapon].name
	return {
		phase = state.phase,
		timeLeft = math.max(0, state.timeLeft),
		score = state.score,
		style = math.floor(state.style),
		styleRank = styleRank(state.style),
		level = state.level,
		xp = state.xp,
		xpNeed = xpNeed(state.level),
		creditsRun = state.creditsRun,
		creditsBank = data.credits,
		kills = state.kills,
		health = state.health,
		maxHealth = state.maxHealth,
		enemiesAlive = EnemyService.count(),
		weapon = weaponName,
		combo = state.combo,
		message = message,
		countdown = countdown,
		highScore = data.highScore,
	}
end

local function pushHud(player: Player, message: string?, countdown: number?)
	Remotes.get("HudUpdate"):FireClient(player, hudFor(player, message, countdown))
end

local function computeMaxHealth(player: Player, state: RunState): number
	return math.max(25, 100 + metaLevel(player, "maxHp") * 15 + state.stats.maxHealthBonus)
end

local function teleportSpawn(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(0, Config.Arena.FloorY + 5, 20)
	end
end

local function addStyle(player: Player, amount: number, label: string)
	local state = ensureRun(player)
	if not state.active then
		return
	end
	local styleMeta = 1 + metaLevel(player, "style") * 0.1
	local gained = amount * state.stats.styleMul * styleMeta * (1 + math.min(state.combo, 20) * 0.04)
	state.style += gained
	state.score += math.floor(gained * 0.35)
	Remotes.get("StylePop"):FireClient(player, { label = label, rank = styleRank(state.style), amount = math.floor(gained) })
end

local function endRun(player: Player, survived: boolean)
	local state = ensureRun(player)
	if not state.active and state.phase == "Lobby" then
		return
	end
	state.active = false
	state.phase = "Results"
	player:SetAttribute("RunActive", false)

	local mul = MonetizationService.creditMultiplier(player)
	local styleBonus = math.floor(state.style * Config.Economy.StyleCreditBonus)
	local banked = math.floor((state.creditsRun + styleBonus) * Config.Economy.CreditKeepRatio * mul)
	if survived then
		banked = math.floor(banked * 1.35)
	end
	local beat = DataService.noteScore(player, state.score, math.floor(Config.Director.MissionSeconds - state.timeLeft))
	if beat then
		banked += Config.Economy.HighScoreBonus
	end
	local rank = styleRank(state.style)
	local data = DataService.get(player)
	local order = { D = 1, C = 2, B = 3, A = 4, S = 5, SS = 6 }
	local prev = tostring(data.meta.bestRank or "D")
	if (order[rank] or 0) > (order[prev] or 0) then
		data.meta.bestRank = rank
		DataService.markDirty(player)
	end
	DataService.addCredits(player, banked)
	DataService.save(player)

	EnemyService.clear()
	PickupService.clear()
	local msg = if survived
		then ("EXTRACTED · %s · +%d cr"):format(rank, banked)
		else ("DOWNED · %s · +%d cr"):format(rank, banked)
	pushHud(player, msg)
	pushLobby(player)
end

local function damagePlayer(player: Player, amount: number)
	local state = ensureRun(player)
	if not state.active or state.phase == "LevelUp" or state.phase == "Results" then
		return
	end
	local character = player.Character
	if character and character:GetAttribute("IFrames") == true then
		return
	end
	state.health = math.max(0, state.health - amount)
	state.combo = 0
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = state.health
	end
	Remotes.get("FxBurst"):FireClient(player, { kind = "hurt", color = Config.Palette.Danger })
	pushHud(player)
	if state.health <= 0 then
		endRun(player, false)
	end
end

local function offerLevelUp(player: Player)
	local state = ensureRun(player)
	state.phase = "LevelUp"
	state.pendingUpgrades = Upgrades.rollOptions(3, state.ownedUnlocks)
	SoundUtil.play("LevelUp", 0.4)
	Remotes.get("UpgradeChoices"):FireClient(player, state.pendingUpgrades)
	pushHud(player, "CHOOSE A PROTOCOL")
end

local function grantXp(player: Player, amount: number)
	local state = ensureRun(player)
	state.xp += amount
	local need = xpNeed(state.level)
	if state.xp >= need then
		state.xp -= need
		state.level += 1
		offerLevelUp(player)
	end
end

local function onEnemyDied(player: Player?, kind: EnemyKind, score: number, xp: number, credits: number, position: Vector3)
	if not player then
		return
	end
	local state = ensureRun(player)
	if not state.active then
		return
	end
	local now = os.clock()
	if now <= state.comboExpire then
		state.combo += 1
	else
		state.combo = 1
	end
	state.comboExpire = now + 2.6
	state.kills += 1
	local mult = 1 + math.min(state.combo, 18) * 0.1
	state.score += math.floor(score * mult)
	state.creditsRun += credits
	PickupService.spawnXp(position, xp)
	addStyle(player, if kind == "Elite" then 120 else 20 + state.combo * 2, if kind == "Elite" then "ELITE DOWN" else "KILL")
	if state.leech then
		state.health = math.min(state.maxHealth, state.health + 3)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = state.health
		end
	end
	pushHud(player)
end

local function pickKind(intensity: number, forceElite: boolean): EnemyKind
	if forceElite then
		return "Elite"
	end
	local roll = math.random()
	if intensity > 0.55 and roll < 0.12 then
		return "Bruiser"
	end
	if intensity > 0.25 and roll < 0.35 then
		return "Gunner"
	end
	if roll < 0.55 then
		return "Skitter"
	end
	return "Wisp"
end

local function startRun(player: Player)
	local state = ensureRun(player)
	state.token += 1
	local token = state.token

	EnemyService.clear()
	PickupService.clear()
	state.active = true
	state.phase = "Countdown"
	state.timeLeft = Config.Director.MissionSeconds
	state.score = 0
	state.style = 0
	state.kills = 0
	state.combo = 0
	state.xp = 0
	state.level = 1
	state.creditsRun = 0
	state.stats = Upgrades.defaultRunStats()
	state.leech = false
	state.ownedUnlocks = {}
	state.pendingUpgrades = nil
	state.spawnAcc = 0
	state.nextElite = Config.Director.EliteEvery
	state.maxHealth = computeMaxHealth(player, state)
	state.health = state.maxHealth
	player:SetAttribute("RunActive", true)

	teleportSpawn(player)
	applyProfile(player, state)

	for i = Config.Director.Countdown, 1, -1 do
		if state.token ~= token or not state.active then
			return
		end
		pushHud(player, "DISTRICT SURGE", i)
		task.wait(1)
	end

	state.phase = "Mission"
	pushHud(player, "CLEAR THE DISTRICT")
	SoundUtil.play("Style", 0.3)

	while state.active and state.token == token and state.phase ~= "Results" do
		local dt = 0.2
		task.wait(dt)
		if state.phase == "LevelUp" then
			continue
		end
		if not state.active or state.token ~= token then
			break
		end

		state.timeLeft -= dt
		local elapsed = Config.Director.MissionSeconds - state.timeLeft
		local intensity = math.clamp(elapsed * Config.Director.IntensityRamp, 0, 1.4)

		state.spawnAcc += dt
		local interval = math.max(0.28, 0.85 - intensity * 0.45)
		if state.spawnAcc >= interval and EnemyService.count() < Config.Director.MaxAlive then
			state.spawnAcc = 0
			local elite = elapsed >= state.nextElite
			if elite then
				state.nextElite = elapsed + Config.Director.EliteEvery
			end
			EnemyService.spawn(pickKind(intensity, elite), intensity)
		end

		if state.combo > 0 and os.clock() > state.comboExpire then
			state.combo = 0
		end
		pushHud(player)

		if state.timeLeft <= 0 then
			endRun(player, true)
			break
		end
	end
end

function GameService.start()
	print("[NeonSurge] Building district...")
	ArenaBuilder.build()
	print("[NeonSurge] District online")

	Remotes.init()
	DataService.init()
	MonetizationService.init()
	CombatService.init({
		onStyle = function(player, amount, label)
			addStyle(player, amount, label)
			pushHud(player)
		end,
	})
	PickupService.init({
		onCollect = function(player, amount)
			local state = ensureRun(player)
			if not state.active then
				return
			end
			if state.phase == "LevelUp" then
				state.xp += amount
			else
				grantXp(player, amount)
			end
			addStyle(player, 4, "GEM")
			pushHud(player)
		end,
	})
	EnemyService.init({
		onEnemyDied = onEnemyDied,
		onPlayerDamaged = damagePlayer,
	})

	-- Jump pads
	task.spawn(function()
		local arena = Workspace:WaitForChild("NeonArena", 10)
		if not arena then
			return
		end
		local padClock: { [Player]: number } = {}
		for _, inst in arena:GetDescendants() do
			if inst:IsA("BasePart") and inst:GetAttribute("JumpPad") == true then
				inst.Touched:Connect(function(hit)
					local character = hit:FindFirstAncestorOfClass("Model")
					local player = character and Players:GetPlayerFromCharacter(character)
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if not player or not root or not root:IsA("BasePart") then
						return
					end
					if player:GetAttribute("RunActive") ~= true then
						return
					end
					local now = os.clock()
					if now - (padClock[player] or 0) < 0.6 then
						return
					end
					padClock[player] = now
					local boost = tonumber(inst:GetAttribute("Boost")) or 90
					root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, boost, root.AssemblyLinearVelocity.Z)
					addStyle(player, 6, "PAD")
				end)
			end
		end
	end)

	Remotes.get("RequestStartRun").OnServerEvent:Connect(function(player)
		local state = ensureRun(player)
		if state.active then
			return
		end
		task.spawn(startRun, player)
	end)

	Remotes.get("RequestRestart").OnServerEvent:Connect(function(player)
		local state = ensureRun(player)
		state.active = false
		state.phase = "Lobby"
		player:SetAttribute("RunActive", false)
		EnemyService.clear()
		PickupService.clear()
		pushLobby(player)
		pushHud(player, Config.Tagline)
	end)

	Remotes.get("ChooseUpgrade").OnServerEvent:Connect(function(player, upgradeId)
		local state = ensureRun(player)
		if state.phase ~= "LevelUp" or typeof(upgradeId) ~= "string" then
			return
		end
		local valid = false
		if state.pendingUpgrades then
			for _, opt in state.pendingUpgrades do
				if opt.id == upgradeId then
					valid = true
					break
				end
			end
		end
		if not valid then
			return
		end
		local heal, unlocked
		state.stats, heal, unlocked = Upgrades.apply(state.stats, upgradeId)
		if Upgrades.isVamp(upgradeId) then
			state.leech = true
		end
		if upgradeId == "shatter" then
			state.ownedUnlocks.shatter = true
		elseif upgradeId == "rail" then
			state.ownedUnlocks.rail = true
		end
		state.maxHealth = computeMaxHealth(player, state)
		if heal then
			state.health = math.min(state.maxHealth, state.health + heal)
		else
			state.health = math.min(state.health, state.maxHealth)
		end
		state.pendingUpgrades = nil
		state.phase = "Mission"
		applyProfile(player, state)
		if unlocked then
			pushHud(player, "WEAPON ONLINE")
		else
			pushHud(player)
		end
		local need = xpNeed(state.level)
		if state.xp >= need then
			state.xp -= need
			state.level += 1
			offerLevelUp(player)
		end
	end)

	Remotes.get("RequestBuyMeta").OnServerEvent:Connect(function(player, id)
		if typeof(id) ~= "string" then
			return
		end
		local state = ensureRun(player)
		if state.active then
			return
		end
		local def = nil
		for _, item in Config.MetaUpgrades do
			if item.id == id then
				def = item
				break
			end
		end
		if not def then
			return
		end
		local level = metaLevel(player, id)
		if level >= def.maxLevel then
			return
		end
		local cost = math.floor(def.baseCost * (def.costGrowth ^ level))
		if DataService.spendCredits(player, cost) then
			DataService.setMetaLevel(player, id, level + 1)
			DataService.save(player)
			pushLobby(player)
		end
	end)

	Remotes.get("RequestBuyProduct").OnServerEvent:Connect(function(player, key)
		if typeof(key) ~= "string" then
			return
		end
		if key == "DoubleCredits" or key == "VipTrail" or key == "ExtraDash" then
			MonetizationService.promptGamepass(player, key)
		elseif key == "CreditPackSmall" or key == "CreditPackLarge" then
			MonetizationService.promptProduct(player, key)
		end
		task.delay(1, function()
			pushLobby(player)
		end)
	end)

	local function setupPlayer(player: Player)
		ensureRun(player)
		player:SetAttribute("RunActive", false)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			local state = ensureRun(player)
			teleportSpawn(player)
			if state.active then
				applyProfile(player, state)
			else
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.Movement.WalkSpeed
					humanoid.JumpPower = Config.Movement.JumpPower
				end
			end
			pushLobby(player)
			pushHud(player, if state.active then nil else "START MISSION")
		end)
		task.defer(function()
			pushLobby(player)
			pushHud(player, "START MISSION")
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
	end)
end

return GameService
