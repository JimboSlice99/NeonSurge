--!strict
-- Neon Surge — tuning + economy. Paste product IDs after publishing.

local Config = {
	GameName = "NEON SURGE",
	Tagline = "Hold the line.",

	Arena = {
		Radius = 52,
		FloorY = 0,
		WallHeight = 14,
		RingSegments = 40,
		SpawnClearance = 11,
	},

	Player = {
		BaseMaxHealth = 100,
		BaseWalkSpeed = 26,
		BaseFireRate = 5.2,
		BaseDamage = 18,
		BaseProjectileSpeed = 145,
		ProjectileLifetime = 1.25,
		ProjectileRadius = 0.42,
		MaxRange = 80,
		DashSpeed = 105,
		DashDuration = 0.14,
		DashCooldown = 1.05,
		DashIFrames = 0.28,
		PickupRadius = 5,
		MagnetRadius = 16,
		XpToLevelBase = 36,
		XpToLevelGrowth = 1.2,
	},

	Waves = {
		Countdown = 2,
		Intermission = 1.6,
		BaseEnemyCount = 7,
		EnemiesPerWave = 3,
		MaxAlive = 50,
		SpawnInterval = 0.38,
		BossEvery = 5,
	},

	Economy = {
		CreditKeepRatio = 0.4,
		BossCredit = 30,
		WaveClearBonus = 10,
		HighScoreBonus = 60,
	},

	Monetization = {
		Gamepasses = {
			DoubleCredits = 0,
			VipTrail = 0,
			ExtraDash = 0,
		},
		DevProducts = {
			CreditPackSmall = 0,
			CreditPackLarge = 0,
		},
		PackCredits = {
			Small = 500,
			Large = 2500,
		},
	},

	MetaUpgrades = {
		{ id = "maxHp", name = "Core Plating", desc = "+15 max HP", maxLevel = 8, baseCost = 40, costGrowth = 1.55 },
		{ id = "damage", name = "Plasma Rail", desc = "+12% damage", maxLevel = 8, baseCost = 50, costGrowth = 1.6 },
		{ id = "fireRate", name = "Cycle Boost", desc = "+8% fire rate", maxLevel = 6, baseCost = 55, costGrowth = 1.65 },
		{ id = "dash", name = "Phase Boots", desc = "-8% dash CD", maxLevel = 5, baseCost = 45, costGrowth = 1.7 },
		{ id = "magnet", name = "Attractor", desc = "+20% gem pull", maxLevel = 5, baseCost = 35, costGrowth = 1.5 },
	},

	-- Subtle built-in Roblox sounds (library IDs)
	Sounds = {
		Shoot = "rbxassetid://9114224722",
		Hit = "rbxassetid://9119693934",
		Dash = "rbxassetid://9120386437",
		LevelUp = "rbxassetid://9113815993",
		Pickup = "rbxassetid://9114221272",
		Hurt = "rbxassetid://9114223563",
		Wave = "rbxassetid://9113816342",
	},

	Palette = {
		Cyan = Color3.fromRGB(70, 220, 230),
		Magenta = Color3.fromRGB(220, 70, 150),
		Violet = Color3.fromRGB(130, 95, 220),
		Lime = Color3.fromRGB(120, 220, 140),
		Gold = Color3.fromRGB(230, 190, 90),
		Floor = Color3.fromRGB(12, 14, 22),
		Panel = Color3.fromRGB(10, 12, 20),
		Wall = Color3.fromRGB(22, 26, 40),
		Accent = Color3.fromRGB(40, 160, 170),
		Danger = Color3.fromRGB(220, 70, 90),
		Text = Color3.fromRGB(230, 236, 245),
		Muted = Color3.fromRGB(140, 150, 170),
	},

	RemotesFolderName = "NeonSurgeRemotes",
	DataStoreName = "NeonSurge_Player_v2",
}

return Config
