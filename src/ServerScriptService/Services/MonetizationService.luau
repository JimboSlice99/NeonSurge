--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local ownedCache: { [Player]: { [string]: boolean } } = {}

local function passId(key: string): number
	return Config.Monetization.Gamepasses[key] or 0
end

local function productId(key: string): number
	return Config.Monetization.DevProducts[key] or 0
end

local function refreshOwns(player: Player)
	ownedCache[player] = {
		DoubleCredits = false,
		VipTrail = false,
		ExtraDash = false,
	}
	for key, id in Config.Monetization.Gamepasses do
		if typeof(id) == "number" and id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok and owns then
				ownedCache[player][key] = true
			end
		end
	end
end

function MonetizationService.init()
	Players.PlayerAdded:Connect(function(player)
		refreshOwns(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		ownedCache[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(refreshOwns, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _id, wasPurchased)
		if wasPurchased then
			refreshOwns(player)
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local small = productId("CreditPackSmall")
		local large = productId("CreditPackLarge")
		if receipt.ProductId == small and small > 0 then
			DataService.addCredits(player, Config.Monetization.PackCredits.Small)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		elseif receipt.ProductId == large and large > 0 then
			DataService.addCredits(player, Config.Monetization.PackCredits.Large)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function MonetizationService.owns(player: Player, key: string): boolean
	local bag = ownedCache[player]
	if not bag then
		refreshOwns(player)
		bag = ownedCache[player]
	end
	return bag[key] == true
end

function MonetizationService.promptGamepass(player: Player, key: string)
	local id = passId(key)
	if id <= 0 then
		warn(("[NeonSurge] Gamepass '%s' ID not set in Config"):format(key))
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

function MonetizationService.promptProduct(player: Player, key: string)
	local id = productId(key)
	if id <= 0 then
		warn(("[NeonSurge] DevProduct '%s' ID not set in Config"):format(key))
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end

function MonetizationService.creditMultiplier(player: Player): number
	return if MonetizationService.owns(player, "DoubleCredits") then 2 else 1
end

return MonetizationService
