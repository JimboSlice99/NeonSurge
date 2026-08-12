--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Upgrades = require(game:GetService("ReplicatedStorage").Shared.Upgrades)
local ArenaBuilder = require(script.Parent.ArenaBuilder)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local MonetizationService = require(script.Parent.MonetizationService)

type GamePhase = Types.GamePhase
type HudSnapshot = Types.HudSnapshot
type EnemyKind = Types.EnemyKind
type RunStats = Types.RunStats
type LobbySnapshot = Types.LobbySnapshot

local GameService = {}

type RunState = {
	active: boolean,
	phase: GamePhase,
	wave: number,
	score: number,
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
	pendingUpgrades: { Types.UpgradeOption }?,
	token: number,
}

local runs: { [Player]: RunState } = {}

local function xpNeed(level: number): number
	return math.floor(Config.Player.XpToLevelBase * (Config.Player.XpToLevelGrowth ^ (level - 1)))
end

local function metaLevel(player: Player, id: string): number
	return DataService.getMetaLevel(player, id)
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
		wave = 0,
		score = 0,
		kills = 0,
		combo = 0,
		comboExpire = 0,
		xp = 0,
		level = 1,
		creditsRun = 0,
		health = Config.Player.BaseMaxHealth,
		maxHealth = Config.Player.BaseMaxHealth,
		stats = Upgrades.defaultRunStats(),
		leech = false,
		pendingUpgrades = nil,
		token = 0,
	}
	runs[player] = state
	return state
end

local function applyCombatProfile(player: Player, state: RunState)
	local damageMeta = 1 + metaLevel(player, "damage") * 0.12
	local fireMeta = 1 + metaLevel(player, "fireRate") * 0.08
	local dashMeta = 1 - metaLevel(player, "dash") * 0.08
	if MonetizationService.owns(player, "ExtraDash") then
		dashMeta *= 0.75
	end

	CombatService.setProfile(player, {
		damage = Config.Player.BaseDamage * state.stats.damageMul * damageMeta,
		fireRate = Config.Player.BaseFireRate * state.stats.fireRateMul * fireMeta,
		projectileSpeed = Config.Player.BaseProjectileSpeed,
		projectileCount = state.stats.projectileCount,
		pierce = state.stats.pierce,
		dashCooldown = Config.Player.DashCooldown * state.stats.dashCooldownMul * math.max(dashMeta, 0.4),
	})

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local moveMeta = 1 + 0 -- reserved
		humanoid.WalkSpeed = Config.Player.BaseWalkSpeed * state.stats.moveMul * moveMeta
		humanoid.MaxHealth = state.maxHealth
		humanoid.Health = math.min(state.health, state.maxHealth)
	end
end

local function hudFor(player: Player, message: string?, countdown: number?): HudSnapshot
	local state = ensureRun(player)
	local data = DataService.get(player)
	return {
		phase = state.phase,
		wave = state.wave,
		score = state.score,
		level = state.level,
		xp = state.xp,
		xpNeed = xpNeed(state.level),
		creditsRun = state.creditsRun,
		creditsBank = data.credits,
		kills = state.kills,
		health = state.health,
		maxHealth = state.maxHealth,
		enemiesAlive = EnemyService.count(),
		combo = state.combo,
		countdown = countdown,
		message = message,
		highScore = data.highScore,
	}
end

local function pushHud(player: Player, message: string?, countdown: number?)
	Remotes.get("HudUpdate"):FireClient(player, hudFor(player, message, countdown))
end

local function computeMaxHealth(player: Player, state: RunState): number
	return math.max(
		20,
		Config.Player.BaseMaxHealth + metaLevel(player, "maxHp") * 15 + state.stats.maxHealthBonus
	)
end

local function teleportToArena(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(0, Config.Arena.FloorY + 5, 12)
	end
end

local function endRun(player: Player)
	local state = ensureRun(player)
	if not state.active and state.phase == "Lobby" then
		return
	end
	state.active = false
	state.phase = "GameOver"
	player:SetAttribute("RunActive", false)

	local mul = MonetizationService.creditMultiplier(player)
	local banked = math.floor(state.creditsRun * Config.Economy.CreditKeepRatio * mul)
	local beat = DataService.noteScore(player, state.score, state.wave)
	if beat then
		banked += Config.Economy.HighScoreBonus
	end
	DataService.addCredits(player, banked)
	DataService.save(player)

	EnemyService.clear()
	local msg = ("BANKED %d CREDITS"):format(banked)
	if beat then
		msg ..= " · NEW HIGH SCORE"
	end
	pushHud(player, msg)
	pushLobby(player)
end

local function damagePlayer(player: Player, amount: number)
	local state = ensureRun(player)
	if not state.active or state.phase == "GameOver" or state.phase == "LevelUp" then
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
		endRun(player)
	end
end

local function offerLevelUp(player: Player)
	local state = ensureRun(player)
	state.phase = "LevelUp"
	state.pendingUpgrades = Upgrades.rollOptions(3)
	Remotes.get("UpgradeChoices"):FireClient(player, state.pendingUpgrades)
	pushHud(player, "CHOOSE AN UPGRADE")
end

local function grantXp(player: Player, amount: number)
	local state = ensureRun(player)
	state.xp += amount
	local need = xpNeed(state.level)
	while state.xp >= need do
		state.xp -= need
		state.level += 1
		need = xpNeed(state.level)
		offerLevelUp(player)
		-- only one picker at a time; break and resume after choose
		break
	end
end

local function onEnemyDied(player: Player?, kind: EnemyKind, score: number, xp: number, credits: number)
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
	state.comboExpire = now + 2.4
	state.kills += 1

	local mult = 1 + math.min(state.combo, 15) * 0.12
	-- Bosses keep full score weight via credits/xp from EnemyService; kind reserved for future modifiers
	local kindMul = if kind == "Boss" then 1.15 else 1
	local gained = math.floor(score * mult * kindMul)
	state.score += gained
	state.creditsRun += credits

	if state.leech then
		state.health = math.min(state.maxHealth, state.health + 2)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = state.health
		end
	end

	if state.phase ~= "LevelUp" then
		grantXp(player, xp)
	else
		-- bank xp while choosing
		state.xp += xp
	end
	pushHud(player)
end

local function pickKind(wave: number, index: number, total: number): EnemyKind
	if wave % Config.Waves.BossEvery == 0 and index == total then
		return "Boss"
	end
	local roll = math.random()
	if wave >= 4 and roll < 0.18 + wave * 0.02 then
		return "Bruiser"
	end
	if wave >= 2 and roll < 0.45 then
		return "Shooter"
	end
	return "Runner"
end

local function runWave(player: Player, wave: number, token: number)
	local state = ensureRun(player)
	if state.token ~= token or not state.active then
		return
	end

	state.phase = "Wave"
	state.wave = wave
	pushHud(player, ("WAVE %d"):format(wave))

	local total = Config.Waves.BaseEnemyCount + (wave - 1) * Config.Waves.EnemiesPerWave
	for i = 1, total do
		if state.token ~= token or not state.active or state.phase == "GameOver" then
			return
		end
		while state.phase == "LevelUp" do
			task.wait(0.1)
			if state.token ~= token or not state.active then
				return
			end
		end
		while EnemyService.count() >= Config.Waves.MaxAlive do
			task.wait(0.2)
			if state.token ~= token or not state.active then
				return
			end
		end
		EnemyService.spawn(pickKind(wave, i, total), wave)
		pushHud(player)
		task.wait(math.max(0.22, Config.Waves.SpawnInterval - wave * 0.015))
	end

	while EnemyService.count() > 0 and state.active and state.token == token and state.phase ~= "GameOver" do
		while state.phase == "LevelUp" do
			task.wait(0.1)
			if state.token ~= token or not state.active then
				return
			end
		end
		task.wait(0.2)
		pushHud(player)
	end

	if state.active and state.token == token and state.phase ~= "GameOver" then
		state.creditsRun += Config.Economy.WaveClearBonus
		state.phase = "Intermission"
		pushHud(player, "WAVE CLEAR", Config.Waves.Intermission)
		task.wait(Config.Waves.Intermission)
	end
end

local function startRun(player: Player)
	local state = ensureRun(player)
	state.token += 1
	local token = state.token

	EnemyService.clear()
	state.active = true
	state.phase = "Countdown"
	state.wave = 0
	state.score = 0
	state.kills = 0
	state.combo = 0
	state.comboExpire = 0
	state.xp = 0
	state.level = 1
	state.creditsRun = 0
	state.stats = Upgrades.defaultRunStats()
	state.leech = false
	state.pendingUpgrades = nil
	state.maxHealth = computeMaxHealth(player, state)
	state.health = state.maxHealth
	player:SetAttribute("RunActive", true)

	teleportToArena(player)
	applyCombatProfile(player, state)

	-- VIP trail cosmetic
	local character = player.Character
	if character and MonetizationService.owns(player, "VipTrail") then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and not root:FindFirstChild("VipAura") then
			local aura = Instance.new("PointLight")
			aura.Name = "VipAura"
			aura.Color = Config.Palette.Gold
			aura.Brightness = 2.5
			aura.Range = 16
			aura.Parent = root
		end
	end

	for i = Config.Waves.Countdown, 1, -1 do
		if state.token ~= token or not state.active then
			return
		end
		pushHud(player, "SURGE INCOMING", i)
		task.wait(1)
	end

	local wave = 0
	while state.active and state.token == token and state.phase ~= "GameOver" do
		wave += 1
		runWave(player, wave, token)
		if not state.active or state.token ~= token or state.phase == "GameOver" then
			break
		end
	end
end

local function buyMeta(player: Player, id: any)
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
	if not DataService.spendCredits(player, cost) then
		return
	end
	DataService.setMetaLevel(player, id, level + 1)
	DataService.save(player)
	pushLobby(player)
end

function GameService.start()
	print("[NeonSurge] Building arena...")
	ArenaBuilder.build()
	print("[NeonSurge] Arena ready")

	Remotes.init()
	DataService.init()
	MonetizationService.init()
	CombatService.init()
	EnemyService.init({
		onEnemyDied = onEnemyDied,
		onPlayerDamaged = damagePlayer,
	})

	Remotes.get("RequestStartRun").OnServerEvent:Connect(function(player)
		local state = ensureRun(player)
		if state.active then
			return
		end
		task.spawn(startRun, player)
	end)

	Remotes.get("RequestRestart").OnServerEvent:Connect(function(player)
		local state = ensureRun(player)
		if state.phase == "GameOver" or not state.active then
			state.active = false
			state.phase = "Lobby"
			player:SetAttribute("RunActive", false)
			pushLobby(player)
			pushHud(player, Config.Tagline)
		end
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

		local heal
		state.stats, heal = Upgrades.apply(state.stats, upgradeId)
		if Upgrades.isVamp(upgradeId) then
			state.leech = true
		end
		state.maxHealth = computeMaxHealth(player, state)
		if heal then
			state.health = math.min(state.maxHealth, state.health + heal)
		else
			state.health = math.min(state.health, state.maxHealth)
		end
		state.pendingUpgrades = nil
		state.phase = "Wave"
		applyCombatProfile(player, state)

		-- chained level-ups
		local need = xpNeed(state.level)
		if state.xp >= need then
			state.xp -= need
			state.level += 1
			offerLevelUp(player)
		else
			pushHud(player)
		end
	end)

	Remotes.get("RequestBuyMeta").OnServerEvent:Connect(buyMeta)

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
			task.wait(0.25)
			local state = ensureRun(player)
			if state.active then
				applyCombatProfile(player, state)
				teleportToArena(player)
			else
				teleportToArena(player)
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.Player.BaseWalkSpeed
				end
			end
			pushLobby(player)
			pushHud(player, if state.active then nil else "PRESS PLAY")
		end)
		task.defer(function()
			pushLobby(player)
			pushHud(player, "PRESS PLAY")
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
	end)

	-- light HUD refresh / combo decay
	task.spawn(function()
		while true do
			task.wait(0.35)
			local now = os.clock()
			for player, state in runs do
				if state.active and state.phase ~= "GameOver" then
					if state.combo > 0 and now > state.comboExpire then
						state.combo = 0
					end
					pushHud(player)
				end
			end
		end
	end)
end

return GameService
