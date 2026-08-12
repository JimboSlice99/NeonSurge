--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))

local GardenService = {}

local plotsByPlayer: { [Player]: { [string]: Types.PlotRuntime } } = {}
local selectedSeed: { [Player]: string } = {}
local autoAccum: { [Player]: number } = {}
local lastVisual: { [Player]: { [string]: number } } = {}

local function now(): number
	return os.time()
end

local function toolStats(player: Player): (number, number)
	local data = DataService.Get(player)
	if not data then
		return 1, 1
	end
	local tool = Config.Tools[data.equippedTool]
	if not tool then
		return 1, 1
	end
	return tool.speedMult, tool.coinMult
end

local function vipMult(player: Player): number
	local data = DataService.Get(player)
	if data and data.ownedPasses.VIP then
		return Config.PassEffects.VIP.coinMult
	end
	return 1
end

local function growSpeed(player: Player): number
	local speed = toolStats(player)
	local data = DataService.Get(player)
	if data and data.ownedPasses.DoubleSpeed then
		speed *= Config.PassEffects.DoubleSpeed.growMult
	end
	return speed
end

local function pushHud(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local remotes = Remotes.Get()
	remotes.HudUpdate:FireClient(player, {
		coins = data.coins,
		ownedSeeds = data.ownedSeeds,
		ownedTools = data.ownedTools,
		unlockedZones = data.unlockedZones,
		equippedTool = data.equippedTool,
		selectedSeed = selectedSeed[player] or "Wheat",
		ownedPasses = data.ownedPasses,
		stats = data.stats,
	} :: Types.HudPayload)
end

function GardenService.PushHud(player: Player)
	pushHud(player)
end

local function setPlantVisual(plot: Types.PlotRuntime, seedId: string?, progress: number, ready: boolean)
	MapBuilder.SetPlantVisual(plot.model, seedId, progress, ready)
	local base = plot.base
	local prompt = base:FindFirstChild("Prompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		if not seedId then
			prompt.ActionText = "Plant"
			prompt.ObjectText = "Empty plot"
			prompt.Enabled = true
		elseif ready then
			prompt.ActionText = "Harvest"
			prompt.ObjectText = seedId
			prompt.Enabled = true
		else
			prompt.ActionText = "Growing..."
			prompt.ObjectText = string.format("%s %d%%", seedId, math.floor(progress * 100))
			prompt.Enabled = false
		end
	end
end

local function syncPlotFromData(player: Player, plotId: string)
	local data = DataService.Get(player)
	local runtime = plotsByPlayer[player] and plotsByPlayer[player][plotId]
	if not data or not runtime then
		return
	end

	local unlocked = data.unlockedZones[runtime.zoneId] == true
	for _, desc in runtime.model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Transparency = if unlocked then (if desc.Name == "Base" then 0 else desc.Transparency) else 1
			if desc.Name == "Base" then
				desc.CanCollide = unlocked
			end
		end
	end
	local prompt = runtime.base:FindFirstChild("Prompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = unlocked
	end

	local saved = data.plots[plotId]
	if not saved or not saved.seedId or not unlocked then
		runtime.seedId = nil
		runtime.plantedAt = 0
		runtime.readyAt = 0
		if unlocked then
			setPlantVisual(runtime, nil, 0, false)
		else
			MapBuilder.SetPlantVisual(runtime.model, nil, 0, false)
		end
		return
	end

	local seed = Config.Seeds[saved.seedId]
	if not seed then
		return
	end

	runtime.seedId = saved.seedId
	runtime.plantedAt = saved.plantedAt
	local duration = seed.growTime / growSpeed(player)
	runtime.readyAt = saved.plantedAt + duration

	local t = now()
	local progress = math.clamp((t - runtime.plantedAt) / duration, 0, 1)
	local ready = t >= runtime.readyAt
	setPlantVisual(runtime, saved.seedId, progress, ready)
end

local function bindPlot(player: Player, plotModel: Model)
	local plotId = plotModel:GetAttribute("PlotId")
	if typeof(plotId) ~= "string" then
		return
	end

	local base = plotModel:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		return
	end

	local runtime: Types.PlotRuntime = {
		id = plotId,
		zoneId = plotModel:GetAttribute("ZoneId") :: string,
		model = plotModel,
		base = base,
		seedId = nil,
		plantedAt = 0,
		readyAt = 0,
	}

	plotsByPlayer[player] = plotsByPlayer[player] or {}
	plotsByPlayer[player][plotId] = runtime

	local prompt = base:FindFirstChild("Prompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(who: Player)
			if who ~= player then
				return
			end
			GardenService.InteractPlot(player, plotId)
		end)
	end

	syncPlotFromData(player, plotId)
end

function GardenService.SetupPlayer(player: Player)
	selectedSeed[player] = "Wheat"
	autoAccum[player] = 0
	lastVisual[player] = {}

	local folder = MapBuilder.EnsurePlayerPlots(player)
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			bindPlot(player, child)
		end
	end

	local data = DataService.Get(player)
	if data then
		MapBuilder.UpdateZoneLocks(data.unlockedZones)
	end
	pushHud(player)
end

function GardenService.CleanupPlayer(player: Player)
	plotsByPlayer[player] = nil
	selectedSeed[player] = nil
	autoAccum[player] = nil
	lastVisual[player] = nil
	MapBuilder.ClearPlayerPlots(player)
end

function GardenService.SetSelectedSeed(player: Player, seedId: string)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if not Config.Seeds[seedId] then
		return
	end
	if (data.ownedSeeds[seedId] or 0) <= 0 then
		return
	end
	selectedSeed[player] = seedId
	pushHud(player)
end

function GardenService.InteractPlot(player: Player, plotId: string)
	local data = DataService.Get(player)
	local runtime = plotsByPlayer[player] and plotsByPlayer[player][plotId]
	if not data or not runtime then
		return
	end

	if not data.unlockedZones[runtime.zoneId] then
		return
	end

	local saved = data.plots[plotId]
	if not saved then
		return
	end

	if saved.seedId then
		local seed = Config.Seeds[saved.seedId]
		if not seed then
			return
		end
		local duration = seed.growTime / growSpeed(player)
		local readyAt = saved.plantedAt + duration
		if now() < readyAt then
			return
		end

		local _, toolCoin = toolStats(player)
		local payout = math.floor(seed.sellValue * toolCoin * vipMult(player))
		DataService.AddCoins(player, payout)
		data.stats.harvested += 1
		data.stats.earned += payout
		saved.seedId = nil
		saved.plantedAt = 0
		runtime.seedId = nil
		runtime.plantedAt = 0
		runtime.readyAt = 0
		setPlantVisual(runtime, nil, 0, false)
		DataService.MarkDirty(player)
		pushHud(player)
		return
	end

	local seedId = selectedSeed[player] or "Wheat"
	if (data.ownedSeeds[seedId] or 0) <= 0 then
		Remotes.Get().Notify:FireClient(player, "err", "No " .. seedId .. " seeds — buy more in the shop")
		return
	end
	local seed = Config.Seeds[seedId]
	if not seed then
		return
	end

	data.ownedSeeds[seedId] -= 1
	local t = now()
	saved.seedId = seedId
	saved.plantedAt = t
	runtime.seedId = seedId
	runtime.plantedAt = t
	runtime.readyAt = t + (seed.growTime / growSpeed(player))
	data.stats.planted += 1
	setPlantVisual(runtime, seedId, 0, false)
	DataService.MarkDirty(player)
	pushHud(player)
end

function GardenService.BuyShopItem(player: Player, itemId: string): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, "No data"
	end

	local item = Config.ShopItems[itemId]
	if not item then
		return false, "Unknown item"
	end

	if data.coins < item.price then
		return false, "Not enough coins"
	end

	if item.kind == "Seed" and item.seedId and item.amount then
		if not DataService.SpendCoins(player, item.price) then
			return false, "Not enough coins"
		end
		data.ownedSeeds[item.seedId] = (data.ownedSeeds[item.seedId] or 0) + item.amount
		pushHud(player)
		return true, "Bought " .. item.label
	elseif item.kind == "Tool" and item.toolId then
		if data.ownedTools[item.toolId] then
			return false, "Already owned"
		end
		if not DataService.SpendCoins(player, item.price) then
			return false, "Not enough coins"
		end
		data.ownedTools[item.toolId] = true
		data.equippedTool = item.toolId
		for plotId in data.plots do
			syncPlotFromData(player, plotId)
		end
		pushHud(player)
		return true, "Equipped " .. item.label
	elseif item.kind == "Zone" and item.zoneId then
		if data.unlockedZones[item.zoneId] then
			return false, "Already unlocked"
		end
		if not DataService.SpendCoins(player, item.price) then
			return false, "Not enough coins"
		end
		data.unlockedZones[item.zoneId] = true
		DataService.EnsureZonePlots(player, item.zoneId)
		MapBuilder.UpdateZoneLocks(data.unlockedZones)
		for plotId in data.plots do
			syncPlotFromData(player, plotId)
		end
		pushHud(player)
		return true, "Unlocked " .. item.label
	end

	return false, "Invalid item"
end

function GardenService.GrantSeedPack(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for seedId, amount in Config.DevProductRewards.RareSeedPack.seeds do
		data.ownedSeeds[seedId] = (data.ownedSeeds[seedId] or 0) + amount
	end
	DataService.MarkDirty(player)
	pushHud(player)
end

function GardenService.UnlockNextZone(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for _, zoneId in { "Meadow", "Greenhouse" } do
		if not data.unlockedZones[zoneId] then
			data.unlockedZones[zoneId] = true
			DataService.EnsureZonePlots(player, zoneId)
			MapBuilder.UpdateZoneLocks(data.unlockedZones)
			for plotId in data.plots do
				syncPlotFromData(player, plotId)
			end
			DataService.MarkDirty(player)
			pushHud(player)
			return
		end
	end
end

function GardenService.RecalcGrowth(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	for plotId in data.plots do
		syncPlotFromData(player, plotId)
	end
end

function GardenService.Start()
	local remotes = Remotes.Get()

	remotes.SelectSeed.OnServerEvent:Connect(function(player: Player, seedId: unknown)
		if typeof(seedId) ~= "string" then
			return
		end
		GardenService.SetSelectedSeed(player, seedId)
	end)

	remotes.BuyShopItem.OnServerEvent:Connect(function(player: Player, itemId: unknown)
		if typeof(itemId) ~= "string" then
			return
		end
		local ok, msg = GardenService.BuyShopItem(player, itemId)
		remotes.Notify:FireClient(player, if ok then "ok" else "err", msg)
	end)

	remotes.RequestHud.OnServerEvent:Connect(function(player: Player)
		pushHud(player)
	end)

	local accum = 0
	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < 0.35 then
			return
		end
		accum = 0

		for player, plots in plotsByPlayer do
			local data = DataService.Get(player)
			if not data then
				continue
			end

			local speed = growSpeed(player)
			local visuals = lastVisual[player]
			if not visuals then
				visuals = {}
				lastVisual[player] = visuals
			end

			for plotId, runtime in plots do
				local saved = data.plots[plotId]
				if saved and saved.seedId and data.unlockedZones[runtime.zoneId] then
					local seed = Config.Seeds[saved.seedId]
					if seed then
						local duration = seed.growTime / speed
						local progress = math.clamp((now() - saved.plantedAt) / duration, 0, 1)
						local ready = progress >= 1
						local bucket = math.floor(progress * 10)
						if ready or visuals[plotId] ~= bucket then
							visuals[plotId] = bucket
							setPlantVisual(runtime, saved.seedId, progress, ready)
						end
					end
				end
			end

			if data.ownedPasses.AutoCollect then
				autoAccum[player] = (autoAccum[player] or 0) + 0.35
				if (autoAccum[player] or 0) >= Config.PassEffects.AutoCollect.interval then
					autoAccum[player] = 0
					for plotId, _runtime in plots do
						local saved = data.plots[plotId]
						if saved and saved.seedId then
							local seed = Config.Seeds[saved.seedId]
							if seed then
								local duration = seed.growTime / speed
								if now() >= saved.plantedAt + duration then
									GardenService.InteractPlot(player, plotId)
								end
							end
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		GardenService.CleanupPlayer(player)
	end)
end

return GardenService
