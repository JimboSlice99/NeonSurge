--!strict
-- Surge — industrial tower defense. Defend the core.

local Config = {
	GameName = "SURGE",
	Tagline = "Hold the core.",

	Core = {
		MaxLives = 20,
		StartingCash = 220,
		InterestRate = 0, -- unused; reserved
	},

	Waves = {
		PrepSeconds = 12,
		Count = 25,
		BossEvery = 5,
	},

	Economy = {
		-- banked after a run
		CreditPerWave = 4,
		CreditWinBonus = 80,
		CreditLossBonus = 15,
		HighScoreBonus = 40,
	},

	Towers = {
		Pulse = {
			id = "Pulse",
			name = "Pulse Node",
			desc = "Fast single-target laser",
			cost = 60,
			range = 18,
			damage = 8,
			fireRate = 3.2,
			color = Color3.fromRGB(150, 145, 130),
			upgrades = {
				{ cost = 50, damage = 12, fireRate = 3.8, range = 20 },
				{ cost = 90, damage = 18, fireRate = 4.4, range = 22 },
			},
		},
		Beam = {
			id = "Beam",
			name = "Beam Spire",
			desc = "Heavy pierce shot",
			cost = 110,
			range = 24,
			damage = 28,
			fireRate = 1.1,
			pierce = 2,
			color = Color3.fromRGB(100, 110, 125),
			upgrades = {
				{ cost = 90, damage = 40, fireRate = 1.25, range = 26 },
				{ cost = 150, damage = 60, fireRate = 1.4, range = 28 },
			},
		},
		Frost = {
			id = "Frost",
			name = "Frost Coil",
			desc = "Slows enemies in range",
			cost = 90,
			range = 16,
			damage = 4,
			fireRate = 2.0,
			slow = 0.45,
			color = Color3.fromRGB(130, 145, 155),
			upgrades = {
				{ cost = 70, damage = 6, fireRate = 2.3, range = 18, slow = 0.55 },
				{ cost = 120, damage = 9, fireRate = 2.6, range = 20, slow = 0.65 },
			},
		},
		Nova = {
			id = "Nova",
			name = "Nova Mortar",
			desc = "Splash damage barrage",
			cost = 160,
			range = 22,
			damage = 22,
			fireRate = 0.85,
			splash = 10,
			color = Color3.fromRGB(160, 110, 70),
			upgrades = {
				{ cost = 120, damage = 32, fireRate = 0.95, range = 24, splash = 12 },
				{ cost = 200, damage = 48, fireRate = 1.05, range = 26, splash = 14 },
			},
		},
	},

	Enemies = {
		Runner = { health = 40, speed = 14, leak = 1, color = Color3.fromRGB(120, 115, 100), reward = 6 },
		Tank = { health = 160, speed = 8, leak = 2, color = Color3.fromRGB(90, 85, 80), reward = 14 },
		Swift = { health = 28, speed = 22, leak = 1, color = Color3.fromRGB(140, 125, 95), reward = 8 },
		Boss = { health = 900, speed = 7, leak = 5, color = Color3.fromRGB(70, 68, 72), reward = 80 },
	},

	Monetization = {
		Gamepasses = {
			DoubleCredits = 0,
			StarterCash = 0, -- +150 starting cash
			VipSkin = 0,
		},
		DevProducts = {
			CreditPackSmall = 0,
			CreditPackLarge = 0,
		},
		PackCredits = { Small = 500, Large = 2500 },
	},

	MetaUpgrades = {
		{ id = "startCash", name = "Reserve Cap", desc = "+25 starting cash", maxLevel = 8, baseCost = 35, costGrowth = 1.5 },
		{ id = "towerDmg", name = "Overclock", desc = "+8% tower damage", maxLevel = 8, baseCost = 45, costGrowth = 1.55 },
		{ id = "towerRange", name = "Focal Lenses", desc = "+5% tower range", maxLevel = 6, baseCost = 40, costGrowth = 1.55 },
		{ id = "coreHp", name = "Core Shield", desc = "+1 life", maxLevel = 5, baseCost = 60, costGrowth = 1.7 },
		{ id = "interest", name = "Market Chip", desc = "+3 cash each wave clear", maxLevel = 6, baseCost = 30, costGrowth = 1.45 },
	},

	Sounds = {
		Place = "rbxassetid://9114221272",
		Shoot = "rbxassetid://9114224722",
		Hit = "rbxassetid://9119693934",
		Wave = "rbxassetid://9113816342",
		Hurt = "rbxassetid://9114223563",
		Win = "rbxassetid://9113815993",
	},

	Palette = {
		-- Kept key names for compatibility; values are matte industrial, not neon.
		Cyan = Color3.fromRGB(200, 170, 120), -- warm accent (was cyan)
		Magenta = Color3.fromRGB(160, 90, 70),
		Violet = Color3.fromRGB(110, 120, 140),
		Orange = Color3.fromRGB(180, 120, 70),
		Lime = Color3.fromRGB(120, 140, 100),
		Gold = Color3.fromRGB(190, 160, 100),
		Path = Color3.fromRGB(55, 52, 48),
		Build = Color3.fromRGB(70, 68, 62),
		Floor = Color3.fromRGB(42, 40, 38),
		Panel = Color3.fromRGB(28, 28, 30),
		Danger = Color3.fromRGB(170, 60, 55),
		Text = Color3.fromRGB(230, 225, 215),
		Muted = Color3.fromRGB(140, 135, 125),
	},

	RemotesFolderName = "NeonSurgeRemotes",
	DataStoreName = "NeonSurge_TD_v1",
}

return Config
