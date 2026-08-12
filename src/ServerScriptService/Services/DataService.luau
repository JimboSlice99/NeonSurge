--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

export type PlayerData = {
	credits: number,
	highScore: number,
	bestWave: number,
	meta: { [string]: number },
}

local DataService = {}

local store: DataStore? = nil
local cache: { [Player]: PlayerData } = {}
local dirty: { [Player]: boolean } = {}

local function defaultData(): PlayerData
	return {
		credits = 0,
		highScore = 0,
		bestWave = 0,
		meta = {},
	}
end

local function keyFor(userId: number): string
	return ("p_%d"):format(userId)
end

function DataService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[NeonSurge] DataStores unavailable — using session memory only")
	end

	Players.PlayerAdded:Connect(function(player)
		DataService.load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player)
		cache[player] = nil
		dirty[player] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			DataService.save(player)
		end
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(DataService.load, player)
	end
end

function DataService.load(player: Player)
	local data = defaultData()
	if store then
		local ok, result = pcall(function()
			return store:GetAsync(keyFor(player.UserId))
		end)
		if ok and typeof(result) == "table" then
			data.credits = tonumber(result.credits) or 0
			data.highScore = tonumber(result.highScore) or 0
			data.bestWave = tonumber(result.bestWave) or 0
			if typeof(result.meta) == "table" then
				for k, v in result.meta do
					if typeof(k) == "string" and typeof(v) == "number" then
						data.meta[k] = v
					end
				end
			end
		end
	end
	cache[player] = data
	dirty[player] = false
	return data
end

function DataService.get(player: Player): PlayerData
	return cache[player] or DataService.load(player)
end

function DataService.markDirty(player: Player)
	dirty[player] = true
end

function DataService.save(player: Player)
	local data = cache[player]
	if not data or not dirty[player] then
		return
	end
	if not store then
		dirty[player] = false
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(player.UserId), data)
	end)
	if not ok then
		warn("[NeonSurge] Save failed:", err)
	else
		dirty[player] = false
	end
end

function DataService.addCredits(player: Player, amount: number)
	local data = DataService.get(player)
	data.credits = math.max(0, data.credits + math.floor(amount))
	DataService.markDirty(player)
end

function DataService.spendCredits(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if data.credits < amount then
		return false
	end
	data.credits -= amount
	DataService.markDirty(player)
	return true
end

function DataService.getMetaLevel(player: Player, id: string): number
	return DataService.get(player).meta[id] or 0
end

function DataService.setMetaLevel(player: Player, id: string, level: number)
	DataService.get(player).meta[id] = level
	DataService.markDirty(player)
end

function DataService.noteScore(player: Player, score: number, wave: number)
	local data = DataService.get(player)
	local beat = false
	if score > data.highScore then
		data.highScore = score
		beat = true
	end
	if wave > data.bestWave then
		data.bestWave = wave
	end
	DataService.markDirty(player)
	return beat
end

return DataService
