--!strict
-- Surge Garden — grow / idle simulator.
-- Paste Creator Dashboard IDs into Monetization below before publishing.

local Config = {
	GameName = "SURGE GARDEN",
	Tagline = "Plant. Harvest. Grow rich.",

	StartingCoins = 50,

	Seeds = {
		Wheat = {
			id = "Wheat",
			name = "Wheat",
			growTime = 8,
			sellValue = 18,
			color = Color3.fromRGB(220, 190, 90),
			rarity = "Common",
		},
		Carrot = {
			id = "Carrot",
			name = "Carrot",
			growTime = 14,
			sellValue = 55,
			color = Color3.fromRGB(230, 130, 60),
			rarity = "Common",
		},
		Berry = {
			id = "Berry",
			name = "Berry Bush",
			growTime = 22,
			sellValue = 140,
			color = Color3.fromRGB(180, 60, 90),
			rarity = "Uncommon",
		},
		Melon = {
			id = "Melon",
			name = "Melon",
			growTime = 35,
			sellValue = 360,
			color = Color3.fromRGB(80, 170, 90),
			rarity = "Uncommon",
		},
		Crystal = {
			id = "Crystal",
			name = "Crystal Bloom",
			growTime = 50,
			sellValue = 1300,
			color = Color3.fromRGB(120, 200, 210),
			rarity = "Rare",
		},
	},

	Tools = {
		Basic = {
			id = "Basic",
			name = "Basic Hands",
			speedMult = 1,
			coinMult = 1,
			desc = "Starter tool",
		},
		IronSpade = {
			id = "IronSpade",
			name = "Iron Spade",
			speedMult = 1.15,
			coinMult = 1.25,
			desc = "+15% grow speed, +25% coins",
		},
		GoldShears = {
			id = "GoldShears",
			name = "Gold Shears",
			speedMult = 1.35,
			coinMult = 1.6,
			desc = "+35% grow speed, +60% coins",
		},
	},

	Zones = {
		Starter = {
			id = "Starter",
			name = "Starter Patch",
			cost = 0,
			plotCount = 6,
			color = Color3.fromRGB(90, 140, 70),
			origin = Vector3.new(0, 0.5, 16),
		},
		Meadow = {
			id = "Meadow",
			name = "Sunny Meadow",
			cost = 2500,
			plotCount = 6,
			color = Color3.fromRGB(120, 160, 70),
			origin = Vector3.new(50, 0.5, 16),
		},
		Greenhouse = {
			id = "Greenhouse",
			name = "Glass Greenhouse",
			cost = 12000,
			plotCount = 6,
			color = Color3.fromRGB(100, 150, 130),
			origin = Vector3.new(-50, 0.5, 16),
		},
	},

	-- Coin shop (~8 items) + greenhouse as 9th unlock
	ShopItems = {
		WheatPack = {
			id = "WheatPack",
			kind = "Seed",
			seedId = "Wheat",
			amount = 5,
			label = "Wheat Seeds x5",
			desc = "Fast grow, steady coins",
			price = 40,
		},
		CarrotPack = {
			id = "CarrotPack",
			kind = "Seed",
			seedId = "Carrot",
			amount = 4,
			label = "Carrot Seeds x4",
			desc = "Solid early profit",
			price = 120,
		},
		BerryPack = {
			id = "BerryPack",
			kind = "Seed",
			seedId = "Berry",
			amount = 3,
			label = "Berry Seeds x3",
			desc = "Uncommon crop",
			price = 240,
		},
		MelonPack = {
			id = "MelonPack",
			kind = "Seed",
			seedId = "Melon",
			amount = 2,
			label = "Melon Seeds x2",
			desc = "Big payout",
			price = 400,
		},
		CrystalPack = {
			id = "CrystalPack",
			kind = "Seed",
			seedId = "Crystal",
			amount = 1,
			label = "Crystal Seed",
			desc = "Rare bloom",
			price = 750,
		},
		IronSpade = {
			id = "IronSpade",
			kind = "Tool",
			toolId = "IronSpade",
			label = "Iron Spade",
			desc = "+15% grow, +25% coins",
			price = 400,
		},
		GoldShears = {
			id = "GoldShears",
			kind = "Tool",
			toolId = "GoldShears",
			label = "Gold Shears",
			desc = "+35% grow, +60% coins",
			price = 1500,
		},
		UnlockMeadow = {
			id = "UnlockMeadow",
			kind = "Zone",
			zoneId = "Meadow",
			label = "Unlock Meadow",
			desc = "+6 sunny plots",
			price = 2500,
		},
		UnlockGreenhouse = {
			id = "UnlockGreenhouse",
			kind = "Zone",
			zoneId = "Greenhouse",
			label = "Unlock Greenhouse",
			desc = "+6 premium plots",
			price = 12000,
		},
	},

	ShopOrder = {
		"WheatPack",
		"CarrotPack",
		"BerryPack",
		"MelonPack",
		"CrystalPack",
		"IronSpade",
		"GoldShears",
		"UnlockMeadow",
		"UnlockGreenhouse",
	},

	Monetization = {
		-- Replace 0 with real IDs from Creator Dashboard
		GamePassIds = {
			VIP = 0, -- +50% harvest coins
			DoubleSpeed = 0, -- 2x grow speed
			AutoCollect = 0, -- auto-harvest ready crops
		},
		DevProductIds = {
			CoinsSmall = 0, -- +2,500 coins
			CoinsBig = 0, -- +15,000 coins
			RareSeedPack = 0, -- Crystal + Melon seeds
			ZoneSkip = 0, -- unlock next locked zone
		},
	},

	PassEffects = {
		VIP = { coinMult = 1.5 },
		DoubleSpeed = { growMult = 2 },
		AutoCollect = { interval = 1.5 },
	},

	DevProductRewards = {
		CoinsSmall = 2500,
		CoinsBig = 15000,
		RareSeedPack = {
			seeds = {
				Crystal = 5,
				Melon = 3,
				Berry = 5,
			},
		},
	},

	Palette = {
		Grass = Color3.fromRGB(86, 140, 72),
		Dirt = Color3.fromRGB(110, 80, 50),
		Path = Color3.fromRGB(145, 120, 85),
		Wood = Color3.fromRGB(120, 85, 55),
		Panel = Color3.fromRGB(245, 242, 235),
		PanelDark = Color3.fromRGB(40, 48, 40),
		Button = Color3.fromRGB(80, 150, 90),
		ButtonRobux = Color3.fromRGB(0, 176, 111),
		Text = Color3.fromRGB(35, 40, 35),
		TextLight = Color3.fromRGB(245, 245, 240),
		Muted = Color3.fromRGB(100, 105, 100),
		Gold = Color3.fromRGB(220, 175, 60),
		Danger = Color3.fromRGB(190, 70, 70),
	},

	RemotesFolderName = "GardenRemotes",
	DataStoreName = "SurgeGarden_Player_v1",
}

-- Convenience aliases used by monetization services
Config.GamePassIds = Config.Monetization.GamePassIds
Config.DevProductIds = Config.Monetization.DevProductIds

return Config
