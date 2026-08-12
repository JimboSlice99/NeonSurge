--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local GardenService = require(script.Parent:WaitForChild("GardenService"))
local RateLimiter = require(script.Parent:WaitForChild("RateLimiter"))

local MonetizationService = {}

local processedReceipts: { [string]: boolean } = {}

local function passKeyFromId(id: number): string?
	for key, passId in Config.GamePassIds do
		if type(passId) == "number" and passId == id and passId > 0 then
			return key
		end
	end
	return nil
end

local function grantPass(player: Player, passKey: string, silent: boolean?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if data.ownedPasses[passKey] then
		return
	end
	data.ownedPasses[passKey] = true
	DataService.MarkDirty(player)
	if passKey == "DoubleSpeed" then
		GardenService.RecalcGrowth(player)
	end
	GardenService.PushHud(player)
	if not silent then
		Remotes.Get().Notify:FireClient(player, "ok", "Game Pass unlocked: " .. passKey)
	end
end

function MonetizationService.WarnMissingIds()
	local missing = {}
	for key, id in Config.GamePassIds do
		if type(id) ~= "number" or id <= 0 then
			table.insert(missing, "GamePass:" .. key)
		end
	end
	for key, id in Config.DevProductIds do
		if type(id) ~= "number" or id <= 0 then
			table.insert(missing, "DevProduct:" .. key)
		end
	end
	if #missing > 0 then
		warn("[SurgeGarden] Monetization IDs still placeholder (0). Coin shop works. Paste IDs in Config.luau before going live:\n - " .. table.concat(missing, "\n - "))
	else
		print("[SurgeGarden] All monetization IDs set")
	end
end

function MonetizationService.RefreshPasses(player: Player)
	if RunService:IsStudio() and Config.Monetization.StudioMockPasses then
		-- Studio-only convenience so VIP/speed/auto can be playtested
		grantPass(player, "VIP", true)
		grantPass(player, "DoubleSpeed", true)
		grantPass(player, "AutoCollect", true)
		return
	end

	for passKey, passId in Config.GamePassIds do
		if type(passId) == "number" and passId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				grantPass(player, passKey, true)
			end
		end
	end
end

function MonetizationService.PromptGamePass(player: Player, passKey: string)
	local passId = Config.GamePassIds[passKey]
	if type(passId) ~= "number" or passId <= 0 then
		if RunService:IsStudio() then
			grantPass(player, passKey, false)
			Remotes.Get().Notify:FireClient(player, "ok", "[Studio] Granted " .. passKey .. " (set real ID before publish)")
			return
		end
		Remotes.Get().Notify:FireClient(player, "err", "Set Game Pass ID in Config.luau, then republish")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, passId)
end

function MonetizationService.PromptProduct(player: Player, productKey: string)
	local productId = Config.DevProductIds[productKey]
	if type(productId) ~= "number" or productId <= 0 then
		if RunService:IsStudio() then
			local data = DataService.Get(player)
			if not data then
				return
			end
			if productKey == "CoinsSmall" then
				DataService.AddCoins(player, Config.DevProductRewards.CoinsSmall)
			elseif productKey == "CoinsBig" then
				DataService.AddCoins(player, Config.DevProductRewards.CoinsBig)
			elseif productKey == "RareSeedPack" then
				GardenService.GrantSeedPack(player)
			elseif productKey == "ZoneSkip" then
				GardenService.UnlockNextZone(player)
			end
			GardenService.PushHud(player)
			Remotes.Get().Notify:FireClient(player, "ok", "[Studio] Mock purchase: " .. productKey)
			return
		end
		Remotes.Get().Notify:FireClient(player, "err", "Set Dev Product ID in Config.luau, then republish")
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

local function fulfillProduct(player: Player, productId: number): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end

	if productId == Config.DevProductIds.CoinsSmall and productId > 0 then
		DataService.AddCoins(player, Config.DevProductRewards.CoinsSmall)
		GardenService.PushHud(player)
		Remotes.Get().Notify:FireClient(player, "ok", "+" .. tostring(Config.DevProductRewards.CoinsSmall) .. " coins")
		return true
	elseif productId == Config.DevProductIds.CoinsBig and productId > 0 then
		DataService.AddCoins(player, Config.DevProductRewards.CoinsBig)
		GardenService.PushHud(player)
		Remotes.Get().Notify:FireClient(player, "ok", "+" .. tostring(Config.DevProductRewards.CoinsBig) .. " coins")
		return true
	elseif productId == Config.DevProductIds.RareSeedPack and productId > 0 then
		GardenService.GrantSeedPack(player)
		Remotes.Get().Notify:FireClient(player, "ok", "Rare seed pack received!")
		return true
	elseif productId == Config.DevProductIds.ZoneSkip and productId > 0 then
		GardenService.UnlockNextZone(player)
		Remotes.Get().Notify:FireClient(player, "ok", "Next zone unlocked!")
		return true
	end

	return false
end

function MonetizationService.Start()
	local remotes = Remotes.Get()
	MonetizationService.WarnMissingIds()

	remotes.PromptGamePass.OnServerEvent:Connect(function(player: Player, passKey: unknown)
		if typeof(passKey) ~= "string" then
			return
		end
		if not RateLimiter.Allow(player, "PromptPass", Config.RateLimits.Prompt) then
			return
		end
		MonetizationService.PromptGamePass(player, passKey)
	end)

	remotes.PromptProduct.OnServerEvent:Connect(function(player: Player, productKey: unknown)
		if typeof(productKey) ~= "string" then
			return
		end
		if not RateLimiter.Allow(player, "PromptProduct", Config.RateLimits.Prompt) then
			return
		end
		MonetizationService.PromptProduct(player, productKey)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
		if not wasPurchased then
			return
		end
		local key = passKeyFromId(passId)
		if key then
			grantPass(player, key, false)
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local key = tostring(receiptInfo.PurchaseId)
		if processedReceipts[key] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local data = DataService.Get(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local ok = fulfillProduct(player, receiptInfo.ProductId)
		if ok then
			processedReceipts[key] = true
			DataService.Save(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return MonetizationService
