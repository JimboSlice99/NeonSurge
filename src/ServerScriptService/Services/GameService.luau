--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local ArenaBuilder = require(script.Parent.ArenaBuilder)
local CombatService = require(script.Parent.CombatService)
local EnemyService = require(script.Parent.EnemyService)

type GamePhase = Types.GamePhase
type HudSnapshot = Types.HudSnapshot
type EnemyKind = Types.EnemyKind

local GameService = {}

local phase: GamePhase = "Lobby"
local wave = 0
local running = false
local playerState: {
	[Player]: {
		score: number,
		combo: number,
		comboExpire: number,
		kills: number,
		health: number,
		lastDamageAt: number,
		alive: boolean,
	},
} = {}

local function ensureState(player: Player)
	if not playerState[player] then
		playerState[player] = {
			score = 0,
			combo = 0,
			comboExpire = 0,
			kills = 0,
			health = Config.Player.MaxHealth,
			lastDamageAt = 0,
			alive = true,
		}
	end
	return playerState[player]
end

local function snapshotFor(player: Player, message: string?, countdown: number?): HudSnapshot
	local state = ensureState(player)
	return {
		phase = phase,
		wave = wave,
		score = state.score,
		combo = state.combo,
		kills = state.kills,
		health = state.health,
		maxHealth = Config.Player.MaxHealth,
		enemiesAlive = EnemyService.count(),
		countdown = countdown,
		message = message,
	}
end

local function pushHud(player: Player?, message: string?, countdown: number?)
	local remote = Remotes.get("HudUpdate")
	if player then
		remote:FireClient(player, snapshotFor(player, message, countdown))
		return
	end
	for _, p in Players:GetPlayers() do
		remote:FireClient(p, snapshotFor(p, message, countdown))
	end
end

local function resetPlayer(player: Player)
	local state = ensureState(player)
	state.score = 0
	state.combo = 0
	state.comboExpire = 0
	state.kills = 0
	state.health = Config.Player.MaxHealth
	state.lastDamageAt = 0
	state.alive = true

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid then
		humanoid.MaxHealth = Config.Player.MaxHealth
		humanoid.Health = Config.Player.MaxHealth
		humanoid.WalkSpeed = Config.Player.WalkSpeed
	end
	if root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(0, Config.Arena.FloorY + 5, 0)
	end
end

local function damagePlayer(player: Player, amount: number)
	local state = ensureState(player)
	if not state.alive or phase == "GameOver" then
		return
	end
	local character = player.Character
	if character and character:GetAttribute("IFrames") == true then
		return
	end

	state.health = math.max(0, state.health - amount)
	state.lastDamageAt = os.clock()
	state.combo = 0

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = state.health
	end

	Remotes.get("FxBurst"):FireClient(player, {
		kind = "hurt",
		color = Config.Palette.Magenta,
	})

	pushHud(player, if state.health <= 0 then "SYSTEM FAILURE" else nil)

	if state.health <= 0 then
		state.alive = false
		phase = "GameOver"
		pushHud(nil, ("Wave %d · Score %d"):format(wave, state.score))
	end
end

local function onEnemyDied(player: Player?, kind: EnemyKind, score: number)
	if not player then
		pushHud(nil)
		return
	end
	local state = ensureState(player)
	if not state.alive then
		return
	end

	local now = os.clock()
	if now <= state.comboExpire then
		state.combo += 1
	else
		state.combo = 1
	end
	state.comboExpire = now + 2.2
	state.kills += 1

	local multiplier = 1 + math.min(state.combo, 12) * 0.15
	local gained = math.floor(score * multiplier)
	state.score += gained

	Remotes.get("FxBurst"):FireClient(player, {
		kind = "kill",
		color = if kind == "Boss" then Config.Palette.Violet else Config.Palette.Cyan,
		points = gained,
	})
	pushHud(player)
end

local function pickEnemyKind(currentWave: number, index: number, total: number): EnemyKind
	if currentWave > 0 and currentWave % Config.Waves.BossEvery == 0 and index == total then
		return "Boss"
	end
	if currentWave >= 3 and math.random() < math.clamp(0.15 + currentWave * 0.03, 0, 0.45) then
		return "Bruiser"
	end
	return "Runner"
end

local function runWave(currentWave: number)
	phase = "Wave"
	pushHud(nil, ("WAVE %d"):format(currentWave))

	local total = Config.Waves.BaseEnemyCount + (currentWave - 1) * Config.Waves.EnemiesPerWave
	for i = 1, total do
		if phase == "GameOver" or not running then
			return
		end
		while EnemyService.count() >= Config.Waves.MaxAlive do
			task.wait(0.25)
			if phase == "GameOver" or not running then
				return
			end
		end
		EnemyService.spawn(pickEnemyKind(currentWave, i, total))
		pushHud(nil)
		task.wait(math.max(0.25, Config.Waves.SpawnInterval - currentWave * 0.02))
	end

	while EnemyService.count() > 0 and phase ~= "GameOver" and running do
		task.wait(0.2)
		pushHud(nil)
	end
end

local function gameLoop()
	running = true
	wave = 0
	phase = "Countdown"
	EnemyService.clear()

	for _, player in Players:GetPlayers() do
		resetPlayer(player)
	end

	for i = Config.Waves.Countdown, 1, -1 do
		if not running then
			return
		end
		pushHud(nil, "SURGE INCOMING", i)
		task.wait(1)
	end

	while running do
		wave += 1
		runWave(wave)
		if phase == "GameOver" or not running then
			break
		end
		phase = "Intermission"
		pushHud(nil, "SYSTEM REBOOT", Config.Waves.Intermission)
		task.wait(Config.Waves.Intermission)
	end

	phase = "GameOver"
	pushHud(nil, "PRESS R TO REBOOT")
end

function GameService.start()
	ArenaBuilder.build()
	Remotes.init()
	CombatService.init()
	EnemyService.init({
		onEnemyDied = onEnemyDied,
		onPlayerDamaged = damagePlayer,
	})

	Players.PlayerAdded:Connect(function(player)
		ensureState(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			resetPlayer(player)
			pushHud(player, if phase == "GameOver" then "PRESS R TO REBOOT" else Config.Tagline)
		end)
		pushHud(player, Config.Tagline)
	end)

	for _, player in Players:GetPlayers() do
		ensureState(player)
		if player.Character then
			resetPlayer(player)
		end
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			resetPlayer(player)
			pushHud(player)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		playerState[player] = nil
	end)

	Remotes.get("RequestRestart").OnServerEvent:Connect(function(player)
		if phase ~= "GameOver" and phase ~= "Lobby" then
			return
		end
		running = false
		EnemyService.clear()
		phase = "Lobby"
		pushHud(player, "REBOOTING...")
		task.defer(function()
			if not running then
				task.spawn(gameLoop)
			end
		end)
	end)

	-- Passive regen + combo expiry HUD refresh
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			for player, state in playerState do
				if state.alive and phase ~= "GameOver" and phase ~= "Lobby" then
					if now - state.lastDamageAt >= Config.Player.RegenDelay and state.health < Config.Player.MaxHealth then
						state.health = math.min(Config.Player.MaxHealth, state.health + Config.Player.RegenPerSecond * 0.25)
						local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid.Health = state.health
						end
					end
					if state.combo > 0 and now > state.comboExpire then
						state.combo = 0
					end
					pushHud(player)
				end
			end
		end
	end)

	phase = "Lobby"
	task.delay(1, function()
		if not running then
			task.spawn(gameLoop)
		end
	end)
end

return GameService
