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
local RateLimiter = require(script.Parent:WaitForChild("RateLimiter"))

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

local function goalText(data: Types.PlayerData): string
	for _, goal in Config.Goals do
		if goal.check == "harvested" and data.stats.harvested < (goal.need or 1) then
			return goal.text
		elseif goal.check == "ownSeed" and goal.seedId then
			if (data.ownedSeeds[goal.seedId] or 0) < (goal.need or 1) then
				return goal.text
			end
		elseif goal.check == "zone" and goal.zoneId then
			if not data.unlockedZones[goal.zoneId] then
				return goal.text
			end
		elseif goal.check == "tool" then
			if data.equippedTool == "Basic" then
				return goal.text
			end
		elseif goal.check == "rebirth" then
			if data.rebirths < (goal.need or 1) then
				return goal.text
			end
		end
	end
	return "Expand every zone, then Rebirth for permanent power"
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
		rebirths = data.rebirths,
		rebirthCost = DataService.RebirthCost(data.rebirths),
		coinMult = DataService.CoinMultiplier(data),
		goalText = goalText(data),
		dailyReady = DataService.IsDailyReady(data),
		dailyAmount = DataService.DailyAmount(data),
		tutorialDone = data.tutorialDone,
		stats = data.stats,
	} :: Types.HudPayload)
end

function GardenService.PushHud(player: Player)
	pushHud(player)
end

local function setPlantVisual(plot: Types.PlotRuntime, seedId: string?, progress: number, ready: boolean)
	MapBuilder.SetPlantVisual(plot.model, seedId, progress, ready)
	local prompt = plot.base:FindFirstChild("Prompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		if not seedId then
			prompt.ActionText = "Plant"
			prompt.ObjectText = "Empty plot"
			prompt.Enabled = true
		elseif ready then
			prompt.ActionText = "Harvest"
			prompt.ObjectText = seedId .. " READY"
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
			if not unlocked then
				desc.Transparency = 1
				desc.CanCollide = false
			elseif desc.Name == "Base" or desc.Name == "Bed" then
				desc.Transparency = 0
				desc.CanCollide = true
			end
		elseif desc:IsA("ProximityPrompt") then
			desc.Enabled = unlocked
		elseif desc:IsA("BillboardGui") and desc.Name == "ReadyMarker" then
			if not unlocked then
				desc.Enabled = false
			end
		end
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

	local data = DataService.Get(player)
	local folder = MapBuilder.EnsurePlayerPlots(player, if data then data.unlockedZones else nil)
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			bindPlot(player, child)
		end
	end

	if data then
		MapBuilder.UpdateZoneLocks(player, data.unlockedZones)
	end
	DataService.SyncLeaderstats(player)
	pushHud(player)
end

function GardenService.CleanupPlayer(player: Player)
	plotsByPlayer[player] = nil
	selectedSeed[player] = nil
	autoAccum[player] = nil
	lastVisual[player] = nil
	RateLimiter.Clear(player)
	MapBuilder.ClearPlayerPlots(player)
end

function GardenService.SetSelectedSeed(player: Player, seedId: string)
	local data = DataService.Get(player)
	if not data or not Config.Seeds[seedId] then
		return
	end
	if (data.ownedSeeds[seedId] or 0) <= 0 then
		return
	end
	selectedSeed[player] = seedId
	pushHud(player)
end

function GardenService.InteractPlot(player: Player, plotId: string, quiet: boolean?): boolean
	local data = DataService.Get(player)
	local runtime = plotsByPlayer[player] and plotsByPlayer[player][plotId]
	if not data or not runtime then
		return false
	end
	if not data.unlockedZones[runtime.zoneId] then
		return false
	end
	local saved = data.plots[plotId]
	if not saved then
		return false
	end

	if saved.seedId then
		local seed = Config.Seeds[saved.seedId]
		if not seed then
			return false
		end
		local duration = seed.growTime / growSpeed(player)
		if now() < saved.plantedAt + duration then
			return false
		end

		local _, toolCoin = toolStats(player)
		local payout = math.floor(seed.sellValue * toolCoin * vipMult(player) * DataService.CoinMultiplier(data))
		DataService.AddCoins(player, payout)
		data.stats.harvested += 1
		data.stats.earned += payout
		local color = seed.color
		saved.seedId = nil
		saved.plantedAt = 0
		runtime.seedId = nil
		runtime.plantedAt = 0
		runtime.readyAt = 0
		setPlantVisual(runtime, nil, 0, false)
		DataService.MarkDirty(player)
		if not quiet then
			Remotes.Get().HarvestFx:FireClient(player, {
				plotId = plotId,
				amount = payout,
				position = runtime.base.Position,
				color = color,
				sound = "Harvest",
			} :: Types.HarvestFxPayload)
			pushHud(player)
		end
		return true
	end

	local seedId = selectedSeed[player] or "Wheat"
	if (data.ownedSeeds[seedId] or 0) <= 0 then
		if not quiet then
			Remotes.Get().Notify:FireClient(player, "err", "Out of " .. seedId .. " seeds — open Shop")
		end
		return false
	end
	local seed = Config.Seeds[seedId]
	if not seed then
		return false
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
	if not quiet then
		pushHud(player)
	end
	return true
end

function GardenService.PlantAll(player: Player): (boolean, string)
	local data = DataService.Get(player)
	local plots = plotsByPlayer[player]
	if not data or not plots then
		return false, "No data"
	end
	local seedId = selectedSeed[player] or "Wheat"
	if (data.ownedSeeds[seedId] or 0) <= 0 then
		return false, "No " .. seedId .. " seeds left"
	end
	local planted = 0
	for plotId, runtime in plots do
		if data.unlockedZones[runtime.zoneId] then
			local saved = data.plots[plotId]
			if saved and not saved.seedId and (data.ownedSeeds[seedId] or 0) > 0 then
				if GardenService.InteractPlot(player, plotId, true) then
					planted += 1
				end
			end
		end
	end
	pushHud(player)
	if planted <= 0 then
		return false, "No empty plots (or out of seeds)"
	end
	return true, "Planted " .. tostring(planted) .. " " .. seedId
end

function GardenService.HarvestAll(player: Player): (boolean, string)
	local data = DataService.Get(player)
	local plots = plotsByPlayer[player]
	if not data or not plots then
		return false, "No data"
	end
	local harvested = 0
	local total = 0
	local lastPos: Vector3? = nil
	local lastColor = Config.Palette.Gold
	local speed = growSpeed(player)
	for plotId, runtime in plots do
		local saved = data.plots[plotId]
		if saved and saved.seedId and data.unlockedZones[runtime.zoneId] then
			local seed = Config.Seeds[saved.seedId]
			if seed and now() >= saved.plantedAt + seed.growTime / speed then
				local before = data.coins
				if GardenService.InteractPlot(player, plotId, true) then
					harvested += 1
					total += math.max(0, data.coins - before)
					lastPos = runtime.base.Position
					lastColor = seed.color
				end
			end
		end
	end
	pushHud(player)
	if harvested <= 0 then
		return false, "Nothing ready to harvest yet"
	end
	if lastPos then
		Remotes.Get().HarvestFx:FireClient(player, {
			plotId = "batch",
			amount = total,
			position = lastPos,
			color = lastColor,
			sound = "Coin",
		} :: Types.HarvestFxPayload)
	end
	return true, "Harvested " .. tostring(harvested) .. " (+" .. tostring(total) .. " coins)"
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
		MapBuilder.UpdateZoneLocks(player, data.unlockedZones)
		for plotId in data.plots do
			syncPlotFromData(player, plotId)
		end
		pushHud(player)
		return true, "Unlocked " .. item.label
	end
	return false, "Invalid item"
end

function GardenService.TryRebirth(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, "No data"
	end
	local cost = DataService.RebirthCost(data.rebirths)
	if data.coins < cost then
		return false, "Need " .. tostring(cost) .. " coins to rebirth"
	end

	data.coins = 0
	data.rebirths += 1
	data.ownedSeeds = {
		Wheat = Config.StartingWheat + data.rebirths * 4,
		Carrot = 2,
		Tomato = 0,
		Berry = 0,
		Corn = 0,
		Melon = 0,
		Moonbloom = 0,
		Crystal = 0,
	}
	for _, plot in data.plots do
		plot.seedId = nil
		plot.plantedAt = 0
	end
	DataService.MarkDirty(player)
	DataService.SyncLeaderstats(player)
	GardenService.RecalcGrowth(player)
	pushHud(player)
	return true, "Rebirth #" .. tostring(data.rebirths) .. "! Permanent coin power up"
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
	for _, zoneId in Config.ZoneOrder do
		if not data.unlockedZones[zoneId] then
			data.unlockedZones[zoneId] = true
			DataService.EnsureZonePlots(player, zoneId)
			MapBuilder.UpdateZoneLocks(player, data.unlockedZones)
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
		if not RateLimiter.Allow(player, "SelectSeed", Config.RateLimits.SelectSeed) then
			return
		end
		GardenService.SetSelectedSeed(player, seedId)
	end)

	remotes.BuyShopItem.OnServerEvent:Connect(function(player: Player, itemId: unknown)
		if typeof(itemId) ~= "string" then
			return
		end
		if not RateLimiter.Allow(player, "BuyShopItem", Config.RateLimits.BuyShopItem) then
			return
		end
		local ok, msg = GardenService.BuyShopItem(player, itemId)
		remotes.Notify:FireClient(player, if ok then "ok" else "err", msg)
	end)

	remotes.RequestRebirth.OnServerEvent:Connect(function(player: Player)
		if not RateLimiter.Allow(player, "Rebirth", Config.RateLimits.Rebirth) then
			return
		end
		local ok, msg = GardenService.TryRebirth(player)
		remotes.Notify:FireClient(player, if ok then "ok" else "err", msg)
	end)

	remotes.PlantAll.OnServerEvent:Connect(function(player: Player)
		if not RateLimiter.Allow(player, "PlantAll", Config.RateLimits.PlantAll) then
			return
		end
		local ok, msg = GardenService.PlantAll(player)
		remotes.Notify:FireClient(player, if ok then "ok" else "err", msg)
	end)

	remotes.HarvestAll.OnServerEvent:Connect(function(player: Player)
		if not RateLimiter.Allow(player, "HarvestAll", Config.RateLimits.HarvestAll) then
			return
		end
		local ok, msg = GardenService.HarvestAll(player)
		remotes.Notify:FireClient(player, if ok then "ok" else "err", msg)
	end)

	remotes.ClaimDaily.OnServerEvent:Connect(function(player: Player)
		if not RateLimiter.Allow(player, "ClaimDaily", Config.RateLimits.ClaimDaily) then
			return
		end
		local ok, msg, _amount = DataService.ClaimDaily(player)
		pushHud(player)
		remotes.Notify:FireClient(player, if ok then "ok" else "err", msg)
	end)

	remotes.TutorialDone.OnServerEvent:Connect(function(player: Player)
		local data = DataService.Get(player)
		if data and not data.tutorialDone then
			data.tutorialDone = true
			DataService.MarkDirty(player)
			pushHud(player)
		end
	end)

	remotes.RequestHud.OnServerEvent:Connect(function(player: Player)
		pushHud(player)
	end)

	local accum = 0
	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < 0.3 then
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
						local bucket = math.floor(progress * 12)
						if ready or visuals[plotId] ~= bucket then
							visuals[plotId] = bucket
							setPlantVisual(runtime, saved.seedId, progress, ready)
						end
					end
				end
			end

			if data.ownedPasses.AutoCollect then
				autoAccum[player] = (autoAccum[player] or 0) + 0.3
				if (autoAccum[player] or 0) >= Config.PassEffects.AutoCollect.interval then
					autoAccum[player] = 0
					GardenService.HarvestAll(player)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		GardenService.CleanupPlayer(player)
	end)
end

return GardenService
