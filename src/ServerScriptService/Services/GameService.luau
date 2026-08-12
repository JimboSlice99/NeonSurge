--!strict
-- Tower defense director.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)
local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local SoundUtil = require(game:GetService("ReplicatedStorage").Shared.SoundUtil)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local MapBuilder = require(script.Parent.MapBuilder)
local MonetizationService = require(script.Parent.MonetizationService)
local TowerService = require(script.Parent.TowerService)

type GamePhase = Types.GamePhase
type HudSnapshot = Types.HudSnapshot
type TowerId = Types.TowerId
type EnemyKind = Types.EnemyKind
type LobbySnapshot = Types.LobbySnapshot

local GameService = {}

type RunState = {
	active: boolean,
	phase: GamePhase,
	wave: number,
	lives: number,
	cash: number,
	selectedBuild: TowerId,
	token: number,
	owner: Player,
}

local mapData: MapBuilder.MapData
local run: RunState? = nil

local function metaLevel(player: Player, id: string): number
	return DataService.getMetaLevel(player, id)
end

local function buildLobby(player: Player): LobbySnapshot
	local data = DataService.get(player)
	local meta = {}
	for _, def in Config.MetaUpgrades do
		local level = data.meta[def.id] or 0
		local cost = math.floor(def.baseCost * (def.costGrowth ^ level))
		table.insert(meta, {
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
		ownsStarterCash = MonetizationService.owns(player, "StarterCash"),
		ownsVipSkin = MonetizationService.owns(player, "VipSkin"),
		meta = meta,
	}
end

local function pushLobby(player: Player)
	Remotes.get("LobbyUpdate"):FireClient(player, buildLobby(player))
end

local function hud(message: string?, countdown: number?): HudSnapshot
	local state = run
	local player = state and state.owner or Players:GetPlayers()[1]
	local bank = if player then DataService.get(player).credits else 0
	local high = if player then DataService.get(player).highScore else 0
	return {
		phase = if state then state.phase else "Lobby",
		wave = if state then state.wave else 0,
		maxWaves = Config.Waves.Count,
		lives = if state then state.lives else Config.Core.MaxLives,
		cash = if state then state.cash else 0,
		creditsBank = bank,
		enemiesAlive = EnemyService.count(),
		selectedTower = if state then state.selectedBuild else "Pulse",
		message = message,
		countdown = countdown,
		highScore = high,
	}
end

local function pushHud(message: string?, countdown: number?)
	local snapshot = hud(message, countdown)
	for _, player in Players:GetPlayers() do
		Remotes.get("HudUpdate"):FireClient(player, snapshot)
	end
end

local function applyMetaMultipliers(player: Player)
	local dmg = 1 + metaLevel(player, "towerDmg") * 0.08
	local range = 1 + metaLevel(player, "towerRange") * 0.05
	TowerService.setMultipliers(dmg, range)
end

local function endRun(won: boolean)
	local state = run
	if not state then
		return
	end
	state.active = false
	state.phase = "Results"
	local player = state.owner
	local mul = MonetizationService.creditMultiplier(player)
	local credits = state.wave * Config.Economy.CreditPerWave
	credits += if won then Config.Economy.CreditWinBonus else Config.Economy.CreditLossBonus
	credits = math.floor(credits * mul)
	local beat = DataService.noteScore(player, state.wave * 100 + state.cash, state.wave)
	if beat then
		credits += Config.Economy.HighScoreBonus
	end
	DataService.addCredits(player, credits)
	DataService.save(player)
	EnemyService.clear()
	TowerService.clear()
	local msg = if won then ("SECTOR SECURE · +%d cr"):format(credits) else ("CORE BREACHED · +%d cr"):format(credits)
	if won then
		SoundUtil.play("Win", 0.45)
	end
	pushHud(msg)
	pushLobby(player)
	run = nil
end

local function waveComposition(wave: number): { EnemyKind }
	local list: { EnemyKind } = {}
	local count = 6 + wave * 2
	for _ = 1, count do
		local roll = math.random()
		if wave >= 8 and roll < 0.2 then
			table.insert(list, "Tank")
		elseif wave >= 4 and roll < 0.45 then
			table.insert(list, "Swift")
		else
			table.insert(list, "Runner")
		end
	end
	if wave % Config.Waves.BossEvery == 0 then
		table.insert(list, "Boss")
	end
	return list
end

local function runMatch(player: Player)
	local token = (run and run.token or 0) + 1
	EnemyService.clear()
	TowerService.clear()
	applyMetaMultipliers(player)

	local lives = Config.Core.MaxLives + metaLevel(player, "coreHp")
	local cash = Config.Core.StartingCash + metaLevel(player, "startCash") * 25
	if MonetizationService.owns(player, "StarterCash") then
		cash += 150
	end

	run = {
		active = true,
		phase = "Prep",
		wave = 0,
		lives = lives,
		cash = cash,
		selectedBuild = "Pulse",
		token = token,
		owner = player,
	}

	pushHud("BUILD DEFENSES", Config.Waves.PrepSeconds)
	for i = Config.Waves.PrepSeconds, 1, -1 do
		if not run or run.token ~= token then
			return
		end
		pushHud("BUILD DEFENSES", i)
		task.wait(1)
	end

	for wave = 1, Config.Waves.Count do
		if not run or run.token ~= token or not run.active then
			return
		end
		run.wave = wave
		run.phase = "Wave"
		SoundUtil.play("Wave", 0.35)
		pushHud(("WAVE %d"):format(wave))

		local composition = waveComposition(wave)
		for _, kind in composition do
			if not run or run.token ~= token or not run.active then
				return
			end
			EnemyService.spawn(kind, wave)
			pushHud()
			task.wait(0.55 - math.min(wave * 0.01, 0.25))
		end

		while EnemyService.count() > 0 do
			if not run or run.token ~= token or not run.active then
				return
			end
			task.wait(0.2)
			pushHud()
		end

		if not run or not run.active then
			return
		end

		-- wave clear income
		run.cash += 25 + wave * 2 + metaLevel(player, "interest") * 3
		if wave >= Config.Waves.Count then
			endRun(true)
			return
		end

		run.phase = "Prep"
		pushHud("UPGRADE / REBUILD", 8)
		for i = 8, 1, -1 do
			if not run or run.token ~= token or not run.active then
				return
			end
			pushHud("UPGRADE / REBUILD", i)
			task.wait(1)
		end
	end
end

function GameService.start()
	print("[NeonSurge] Building conduit map...")
	mapData = MapBuilder.build()
	EnemyService.setPath(mapData.waypoints)
	print("[NeonSurge] Map ready")

	Remotes.init()
	DataService.init()
	MonetizationService.init()

	EnemyService.init({
		onLeak = function(amount)
			local state = run
			if not state or not state.active then
				return
			end
			state.lives -= amount
			SoundUtil.play("Hurt", 0.35)
			Remotes.get("FxBurst"):FireAllClients({ kind = "leak", color = Config.Palette.Danger })
			pushHud(("CORE HIT · %d"):format(state.lives))
			if state.lives <= 0 then
				endRun(false)
			end
		end,
		onDeath = function(reward, _position)
			local state = run
			if not state or not state.active then
				return
			end
			state.cash += reward
			pushHud()
		end,
	})

	TowerService.init({
		getEnemies = function()
			return EnemyService.list()
		end,
		damageEnemy = function(model, amount, slow)
			return EnemyService.damage(model, amount, slow)
		end,
	})

	Remotes.get("RequestStartRun").OnServerEvent:Connect(function(player)
		if run and run.active then
			return
		end
		task.spawn(runMatch, player)
	end)

	Remotes.get("RequestRestart").OnServerEvent:Connect(function(player)
		if run then
			run.active = false
			run.token += 1
		end
		EnemyService.clear()
		TowerService.clear()
		run = nil
		pushLobby(player)
		pushHud("READY")
	end)

	Remotes.get("RequestSelectBuild").OnServerEvent:Connect(function(player, towerId)
		if typeof(towerId) ~= "string" then
			return
		end
		if not Config.Towers[towerId] then
			return
		end
		if run and run.owner == player then
			run.selectedBuild = towerId :: TowerId
			pushHud(("SELECTED %s"):format(Config.Towers[towerId].name))
		end
	end)

	Remotes.get("RequestPlaceTower").OnServerEvent:Connect(function(player, plotId)
		local state = run
		if not state or not state.active or state.owner ~= player then
			return
		end
		if typeof(plotId) ~= "number" then
			return
		end
		local plot: BasePart? = nil
		for _, p in mapData.plots do
			if p:GetAttribute("PlotId") == plotId then
				plot = p
				break
			end
		end
		if not plot then
			return
		end
		local def = Config.Towers[state.selectedBuild]
		if state.cash < def.cost then
			pushHud("NOT ENOUGH CASH")
			return
		end
		local ok, _id, cost = TowerService.place(player, plot, state.selectedBuild)
		if ok and cost then
			state.cash -= cost
			pushHud(("PLACED %s"):format(def.name))
		end
	end)

	Remotes.get("RequestUpgradeTower").OnServerEvent:Connect(function(player, plotId)
		local state = run
		if not state or not state.active or state.owner ~= player then
			return
		end
		if typeof(plotId) ~= "number" then
			return
		end
		local plot: BasePart? = nil
		for _, p in mapData.plots do
			if p:GetAttribute("PlotId") == plotId then
				plot = p
				break
			end
		end
		if not plot then
			return
		end
		local tower = TowerService.getByPlot(plot)
		if not tower then
			return
		end
		local def = Config.Towers[tower.kind]
		local nextUp = def.upgrades[tower.level + 1]
		if not nextUp then
			pushHud("MAX LEVEL")
			return
		end
		if state.cash < nextUp.cost then
			pushHud("NOT ENOUGH CASH")
			return
		end
		local ok, cost = TowerService.upgrade(tower.id)
		if ok and cost then
			state.cash -= cost
			pushHud("TOWER UPGRADED")
		end
	end)

	Remotes.get("RequestSellTower").OnServerEvent:Connect(function(player, plotId)
		local state = run
		if not state or not state.active or state.owner ~= player then
			return
		end
		if typeof(plotId) ~= "number" then
			return
		end
		local plot: BasePart? = nil
		for _, p in mapData.plots do
			if p:GetAttribute("PlotId") == plotId then
				plot = p
				break
			end
		end
		if not plot then
			return
		end
		local tower = TowerService.getByPlot(plot)
		if not tower then
			return
		end
		local refund = TowerService.sell(tower.id)
		state.cash += refund
		pushHud(("SOLD +%d"):format(refund))
	end)

	Remotes.get("RequestBuyMeta").OnServerEvent:Connect(function(player, id)
		if typeof(id) ~= "string" then
			return
		end
		if run and run.active then
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
		if key == "DoubleCredits" or key == "StarterCash" or key == "VipSkin" then
			MonetizationService.promptGamepass(player, key)
		elseif key == "CreditPackSmall" or key == "CreditPackLarge" then
			MonetizationService.promptProduct(player, key)
		end
		task.delay(1, function()
			pushLobby(player)
		end)
	end)

	local function setup(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.2)
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				root.CFrame = CFrame.new(0, 20, 70)
			end
			pushLobby(player)
			pushHud(if run and run.active then nil else "START DEFENSE")
		end)
		task.defer(function()
			pushLobby(player)
			pushHud("START DEFENSE")
		end)
	end

	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
end

return GameService
