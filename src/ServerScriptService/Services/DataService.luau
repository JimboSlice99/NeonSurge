--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))

type PlayerData = Types.PlayerData

local DataService = {}

local store: DataStore? = nil
local cache: { [Player]: PlayerData } = {}
local dirty: { [Player]: boolean } = {}

local function plotKey(zoneId: string, plotIndex: number): string
	return zoneId .. "_" .. tostring(plotIndex)
end

local function emptyPlotsForZones(unlocked: { [string]: boolean }): { [string]: Types.PlotSave }
	local plots = {}
	for zoneId, zone in Config.Zones do
		if unlocked[zoneId] then
			for i = 1, zone.plotCount do
				plots[plotKey(zoneId, i)] = {
					seedId = nil,
					plantedAt = 0,
				}
			end
		end
	end
	return plots
end

local function utcDay(): number
	return math.floor(os.time() / 86400)
end

function DataService.DefaultData(): PlayerData
	local unlocked = {
		Homestead = true,
		Riverbend = false,
		Orchard = false,
		SkyTerrace = false,
	}
	return {
		coins = Config.StartingCoins,
		ownedSeeds = {
			Wheat = Config.StartingWheat,
			Carrot = 0,
			Tomato = 0,
			Berry = 0,
			Corn = 0,
			Melon = 0,
			Moonbloom = 0,
			Crystal = 0,
		},
		ownedTools = {
			Basic = true,
			IronSpade = false,
			GoldShears = false,
			DiamondScythe = false,
		},
		equippedTool = "Basic",
		unlockedZones = unlocked,
		plots = emptyPlotsForZones(unlocked),
		ownedPasses = { VIP = false, DoubleSpeed = false, AutoCollect = false },
		rebirths = 0,
		lastDailyDay = 0,
		tutorialDone = false,
		stats = { planted = 0, harvested = 0, earned = 0 },
	}
end

function DataService.Start()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[SurgeGarden] DataStores unavailable — session memory only (enable API Services)")
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.Save(player)
		cache[player] = nil
		dirty[player] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			DataService.Save(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(35)
			for _, player in Players:GetPlayers() do
				DataService.Save(player)
			end
		end
	end)
end

function DataService.Load(player: Player): PlayerData
	local data = DataService.DefaultData()
	if store then
		local ok, result = pcall(function()
			return (store :: DataStore):GetAsync("p_" .. tostring(player.UserId))
		end)
		if ok and typeof(result) == "table" then
			data.coins = math.max(0, math.floor(tonumber(result.coins) or data.coins))
			data.rebirths = math.max(0, math.floor(tonumber(result.rebirths) or 0))
			data.lastDailyDay = math.max(0, math.floor(tonumber(result.lastDailyDay) or 0))
			data.tutorialDone = result.tutorialDone == true
			if typeof(result.ownedSeeds) == "table" then
				for seedId, count in result.ownedSeeds do
					if typeof(seedId) == "string" and typeof(count) == "number" then
						data.ownedSeeds[seedId] = math.max(0, math.floor(count))
					end
				end
			end
			if typeof(result.ownedTools) == "table" then
				for toolId, owned in result.ownedTools do
					if typeof(toolId) == "string" then
						data.ownedTools[toolId] = owned == true
					end
				end
			end
			data.ownedTools.Basic = true
			if typeof(result.equippedTool) == "string" and Config.Tools[result.equippedTool] then
				data.equippedTool = result.equippedTool
			end
			if typeof(result.unlockedZones) == "table" then
				for zoneId, unlocked in result.unlockedZones do
					if typeof(zoneId) == "string" and Config.Zones[zoneId] then
						data.unlockedZones[zoneId] = unlocked == true
					end
				end
			end
			if typeof(result.unlockedZones) == "table" and result.unlockedZones.Starter == true then
				data.unlockedZones.Homestead = true
			end
			data.unlockedZones.Homestead = true
			if typeof(result.ownedPasses) == "table" then
				for passKey, owned in result.ownedPasses do
					if typeof(passKey) == "string" then
						data.ownedPasses[passKey] = owned == true
					end
				end
			end
			if typeof(result.stats) == "table" then
				data.stats.planted = math.floor(tonumber(result.stats.planted) or 0)
				data.stats.harvested = math.floor(tonumber(result.stats.harvested) or 0)
				data.stats.earned = math.floor(tonumber(result.stats.earned) or 0)
			end

			data.plots = emptyPlotsForZones(data.unlockedZones)
			if typeof(result.plots) == "table" then
				for key, saved in result.plots do
					if typeof(key) == "string" and typeof(saved) == "table" and data.plots[key] then
						local seedId = saved.seedId
						if typeof(seedId) == "string" and Config.Seeds[seedId] then
							data.plots[key].seedId = seedId
							data.plots[key].plantedAt = tonumber(saved.plantedAt) or 0
						end
					end
				end
			end
		end
	end
	cache[player] = data
	dirty[player] = false
	DataService.SyncLeaderstats(player)
	return data
end

function DataService.Get(player: Player): PlayerData?
	return cache[player]
end

function DataService.MarkDirty(player: Player)
	dirty[player] = true
end

function DataService.Save(player: Player)
	local data = cache[player]
	if not data or not dirty[player] then
		return
	end
	if not store then
		dirty[player] = false
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync("p_" .. tostring(player.UserId), data)
	end)
	if not ok then
		warn("[SurgeGarden] Save failed:", err)
	else
		dirty[player] = false
	end
end

function DataService.AddCoins(player: Player, amount: number)
	local data = cache[player]
	if not data then
		return
	end
	data.coins = math.max(0, data.coins + math.floor(amount))
	DataService.MarkDirty(player)
	DataService.SyncLeaderstats(player)
end

function DataService.SpendCoins(player: Player, amount: number): boolean
	local data = cache[player]
	if not data or data.coins < amount then
		return false
	end
	data.coins -= amount
	DataService.MarkDirty(player)
	DataService.SyncLeaderstats(player)
	return true
end

function DataService.EnsureZonePlots(player: Player, zoneId: string)
	local data = cache[player]
	local zone = Config.Zones[zoneId]
	if not data or not zone then
		return
	end
	for i = 1, zone.plotCount do
		local key = plotKey(zoneId, i)
		if not data.plots[key] then
			data.plots[key] = { seedId = nil, plantedAt = 0 }
		end
	end
	DataService.MarkDirty(player)
end

function DataService.PlotKey(zoneId: string, plotIndex: number): string
	return plotKey(zoneId, plotIndex)
end

function DataService.RebirthCost(rebirths: number): number
	return math.floor(Config.Rebirth.baseCost * (Config.Rebirth.costGrowth ^ rebirths))
end

function DataService.CoinMultiplier(data: PlayerData): number
	return 1 + data.rebirths * Config.Rebirth.coinBonusPerRebirth
end

function DataService.DailyAmount(data: PlayerData): number
	return Config.DailyReward.baseCoins + data.rebirths * Config.DailyReward.rebirthBonus
end

function DataService.IsDailyReady(data: PlayerData): boolean
	return data.lastDailyDay < utcDay()
end

function DataService.ClaimDaily(player: Player): (boolean, string, number)
	local data = cache[player]
	if not data then
		return false, "No data", 0
	end
	if not DataService.IsDailyReady(data) then
		return false, "Daily already claimed — come back tomorrow!", 0
	end
	local amount = DataService.DailyAmount(data)
	data.lastDailyDay = utcDay()
	DataService.AddCoins(player, amount)
	return true, "Daily reward +" .. tostring(amount) .. " coins!", amount
end

function DataService.SyncLeaderstats(player: Player)
	local data = cache[player]
	if not data then
		return
	end
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end
	local coins = folder:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = folder
	end
	local rebirths = folder:FindFirstChild("Rebirths")
	if not rebirths then
		rebirths = Instance.new("IntValue")
		rebirths.Name = "Rebirths"
		rebirths.Parent = folder
	end
	if coins:IsA("IntValue") then
		coins.Value = math.floor(data.coins)
	end
	if rebirths:IsA("IntValue") then
		rebirths.Value = math.floor(data.rebirths)
	end
end

return DataService
