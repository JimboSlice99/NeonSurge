--!strict
-- Surge Garden — full-size grow / idle farm simulator.
-- Paste Creator Dashboard IDs into Monetization before publishing.

local Config = {
	GameName = "SURGE GARDEN",
	Tagline = "Build the biggest farm on the block.",

	StartingCoins = 75,
	StartingWheat = 16,

	-- Soft prestige: rebirth multiplies all harvest coins
	Rebirth = {
		baseCost = 50000,
		costGrowth = 2.4,
		coinBonusPerRebirth = 0.35, -- +35% coins per rebirth
		maxDisplay = 99,
	},

	Seeds = {
		Wheat = {
			id = "Wheat",
			name = "Wheat",
			growTime = 6,
			sellValue = 14,
			color = Color3.fromRGB(230, 200, 95),
			leaf = Color3.fromRGB(110, 160, 70),
			rarity = "Common",
			shape = "stalk",
		},
		Carrot = {
			id = "Carrot",
			name = "Carrot",
			growTime = 11,
			sellValue = 42,
			color = Color3.fromRGB(235, 125, 45),
			leaf = Color3.fromRGB(70, 140, 60),
			rarity = "Common",
			shape = "root",
		},
		Tomato = {
			id = "Tomato",
			name = "Tomato",
			growTime = 16,
			sellValue = 85,
			color = Color3.fromRGB(210, 55, 50),
			leaf = Color3.fromRGB(60, 130, 55),
			rarity = "Common",
			shape = "bush",
		},
		Berry = {
			id = "Berry",
			name = "Berry Bush",
			growTime = 22,
			sellValue = 160,
			color = Color3.fromRGB(150, 45, 95),
			leaf = Color3.fromRGB(55, 120, 70),
			rarity = "Uncommon",
			shape = "bush",
		},
		Corn = {
			id = "Corn",
			name = "Golden Corn",
			growTime = 28,
			sellValue = 280,
			color = Color3.fromRGB(240, 200, 60),
			leaf = Color3.fromRGB(80, 150, 55),
			rarity = "Uncommon",
			shape = "stalk",
		},
		Melon = {
			id = "Melon",
			name = "Melon",
			growTime = 36,
			sellValue = 480,
			color = Color3.fromRGB(70, 175, 95),
			leaf = Color3.fromRGB(50, 120, 60),
			rarity = "Uncommon",
			shape = "round",
		},
		Moonbloom = {
			id = "Moonbloom",
			name = "Moonbloom",
			growTime = 48,
			sellValue = 1100,
			color = Color3.fromRGB(180, 200, 255),
			leaf = Color3.fromRGB(90, 110, 160),
			rarity = "Rare",
			shape = "flower",
		},
		Crystal = {
			id = "Crystal",
			name = "Crystal Bloom",
			growTime = 60,
			sellValue = 2200,
			color = Color3.fromRGB(90, 220, 210),
			leaf = Color3.fromRGB(60, 140, 150),
			rarity = "Legendary",
			shape = "crystal",
		},
	},

	SeedOrder = { "Wheat", "Carrot", "Tomato", "Berry", "Corn", "Melon", "Moonbloom", "Crystal" },

	Tools = {
		Basic = {
			id = "Basic",
			name = "Worn Gloves",
			speedMult = 1,
			coinMult = 1,
			desc = "Starter gloves",
		},
		IronSpade = {
			id = "IronSpade",
			name = "Iron Spade",
			speedMult = 1.2,
			coinMult = 1.3,
			desc = "+20% grow, +30% coins",
		},
		GoldShears = {
			id = "GoldShears",
			name = "Gold Shears",
			speedMult = 1.45,
			coinMult = 1.75,
			desc = "+45% grow, +75% coins",
		},
		DiamondScythe = {
			id = "DiamondScythe",
			name = "Diamond Scythe",
			speedMult = 1.8,
			coinMult = 2.4,
			desc = "+80% grow, +140% coins",
		},
	},

	Zones = {
		Homestead = {
			id = "Homestead",
			name = "Homestead Fields",
			cost = 0,
			plotCount = 12,
			cols = 4,
			color = Color3.fromRGB(92, 148, 74),
			origin = Vector3.new(0, 0.5, 40),
			groundSize = Vector3.new(72, 1, 56),
		},
		Riverbend = {
			id = "Riverbend",
			name = "Riverbend Farm",
			cost = 4500,
			plotCount = 12,
			cols = 4,
			color = Color3.fromRGB(110, 155, 80),
			origin = Vector3.new(95, 0.5, 40),
			groundSize = Vector3.new(72, 1, 56),
		},
		Orchard = {
			id = "Orchard",
			name = "Crystal Orchard",
			cost = 28000,
			plotCount = 16,
			cols = 4,
			color = Color3.fromRGB(85, 140, 120),
			origin = Vector3.new(-95, 0.5, 40),
			groundSize = Vector3.new(78, 1, 62),
		},
		SkyTerrace = {
			id = "SkyTerrace",
			name = "Sky Terrace",
			cost = 120000,
			plotCount = 16,
			cols = 4,
			color = Color3.fromRGB(100, 145, 95),
			origin = Vector3.new(0, 0.5, 130),
			groundSize = Vector3.new(78, 1, 62),
		},
	},

	ZoneOrder = { "Homestead", "Riverbend", "Orchard", "SkyTerrace" },

	ShopItems = {
		WheatPack = { id = "WheatPack", kind = "Seed", seedId = "Wheat", amount = 8, label = "Wheat x8", desc = "Fast starter crop", price = 55 },
		CarrotPack = { id = "CarrotPack", kind = "Seed", seedId = "Carrot", amount = 6, label = "Carrot x6", desc = "Early profit", price = 160 },
		TomatoPack = { id = "TomatoPack", kind = "Seed", seedId = "Tomato", amount = 5, label = "Tomato x5", desc = "Juicy mid-tier", price = 280 },
		BerryPack = { id = "BerryPack", kind = "Seed", seedId = "Berry", amount = 4, label = "Berry x4", desc = "Uncommon bush", price = 420 },
		CornPack = { id = "CornPack", kind = "Seed", seedId = "Corn", amount = 4, label = "Corn x4", desc = "Golden fields", price = 700 },
		MelonPack = { id = "MelonPack", kind = "Seed", seedId = "Melon", amount = 3, label = "Melon x3", desc = "Big payout", price = 1100 },
		MoonbloomPack = { id = "MoonbloomPack", kind = "Seed", seedId = "Moonbloom", amount = 2, label = "Moonbloom x2", desc = "Rare night flower", price = 2600 },
		CrystalPack = { id = "CrystalPack", kind = "Seed", seedId = "Crystal", amount = 1, label = "Crystal Bloom", desc = "Legendary crop", price = 5500 },
		IronSpade = { id = "IronSpade", kind = "Tool", toolId = "IronSpade", label = "Iron Spade", desc = "+20% grow, +30% coins", price = 900 },
		GoldShears = { id = "GoldShears", kind = "Tool", toolId = "GoldShears", label = "Gold Shears", desc = "+45% grow, +75% coins", price = 4500 },
		DiamondScythe = { id = "DiamondScythe", kind = "Tool", toolId = "DiamondScythe", label = "Diamond Scythe", desc = "+80% grow, +140% coins", price = 22000 },
		UnlockRiverbend = { id = "UnlockRiverbend", kind = "Zone", zoneId = "Riverbend", label = "Unlock Riverbend", desc = "+12 riverside plots", price = 4500 },
		UnlockOrchard = { id = "UnlockOrchard", kind = "Zone", zoneId = "Orchard", label = "Unlock Orchard", desc = "+16 crystal plots", price = 28000 },
		UnlockSky = { id = "UnlockSky", kind = "Zone", zoneId = "SkyTerrace", label = "Unlock Sky Terrace", desc = "+16 sky plots", price = 120000 },
	},

	ShopOrder = {
		"WheatPack",
		"CarrotPack",
		"TomatoPack",
		"BerryPack",
		"CornPack",
		"MelonPack",
		"MoonbloomPack",
		"CrystalPack",
		"IronSpade",
		"GoldShears",
		"DiamondScythe",
		"UnlockRiverbend",
		"UnlockOrchard",
		"UnlockSky",
	},

	Goals = {
		{ id = "firstHarvest", text = "Harvest your first crop", check = "harvested", need = 1 },
		{ id = "buyCarrot", text = "Buy Carrot seeds in the Shop", check = "ownSeed", seedId = "Carrot", need = 1 },
		{ id = "unlockRiver", text = "Unlock Riverbend Farm", check = "zone", zoneId = "Riverbend" },
		{ id = "toolUp", text = "Buy a better tool", check = "tool" },
		{ id = "rebirth", text = "Rebirth for permanent coin power", check = "rebirth", need = 1 },
	},

	DailyReward = {
		baseCoins = 400,
		rebirthBonus = 150,
	},

	-- Built-in engine sounds (work without Creator audio upload)
	Audio = {
		Click = "rbxasset://sounds/switch.wav",
		Plant = "rbxasset://sounds/impact_water.wav",
		Harvest = "rbxasset://sounds/electronicpingshort.wav",
		Coin = "rbxasset://sounds/snap.wav",
		Buy = "rbxasset://sounds/electronicpingshort.wav",
		Error = "rbxasset://sounds/collide.wav",
		Level = "rbxasset://sounds/snap.wav",
	},

	RateLimits = {
		BuyShopItem = 0.2,
		SelectSeed = 0.1,
		PlantAll = 0.75,
		HarvestAll = 0.75,
		Rebirth = 1.5,
		ClaimDaily = 1,
		Prompt = 0.5,
	},

	Monetization = {
		-- In Studio only: pretend passes are owned so you can test VIP/speed/auto
		StudioMockPasses = true,
		GamePassIds = {
			VIP = 0,
			DoubleSpeed = 0,
			AutoCollect = 0,
		},
		DevProductIds = {
			CoinsSmall = 0,
			CoinsBig = 0,
			RareSeedPack = 0,
			ZoneSkip = 0,
		},
	},

	PassEffects = {
		VIP = { coinMult = 1.5 },
		DoubleSpeed = { growMult = 2 },
		AutoCollect = { interval = 1.25 },
	},

	DevProductRewards = {
		CoinsSmall = 5000,
		CoinsBig = 35000,
		RareSeedPack = {
			seeds = {
				Crystal = 4,
				Moonbloom = 6,
				Melon = 8,
				Corn = 10,
			},
		},
	},

	Palette = {
		Grass = Color3.fromRGB(86, 140, 72),
		Dirt = Color3.fromRGB(118, 84, 52),
		Path = Color3.fromRGB(168, 145, 110),
		Stone = Color3.fromRGB(140, 138, 132),
		Wood = Color3.fromRGB(125, 88, 55),
		Water = Color3.fromRGB(70, 140, 180),
		Roof = Color3.fromRGB(160, 70, 55),
		Panel = Color3.fromRGB(248, 245, 238),
		PanelAccent = Color3.fromRGB(232, 240, 220),
		Button = Color3.fromRGB(76, 155, 88),
		ButtonDark = Color3.fromRGB(50, 110, 70),
		ButtonRobux = Color3.fromRGB(0, 176, 111),
		Text = Color3.fromRGB(32, 38, 32),
		TextLight = Color3.fromRGB(250, 250, 245),
		Muted = Color3.fromRGB(105, 110, 100),
		Gold = Color3.fromRGB(230, 180, 55),
		Danger = Color3.fromRGB(195, 70, 70),
		Rare = Color3.fromRGB(90, 140, 220),
		Legendary = Color3.fromRGB(90, 210, 200),
	},

	RemotesFolderName = "GardenRemotes",
	DataStoreName = "SurgeGarden_Player_v3",
}

Config.GamePassIds = Config.Monetization.GamePassIds
Config.DevProductIds = Config.Monetization.DevProductIds

return Config
