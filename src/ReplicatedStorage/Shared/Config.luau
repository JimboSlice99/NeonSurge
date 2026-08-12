--!strict
-- Neon Surge — cyber district mission runner.

local Config = {
	GameName = "NEON SURGE",
	Tagline = "Style is survival.",

	Arena = {
		Radius = 60,
		FloorY = 0,
		Levels = 3,
		LevelHeight = 16,
	},

	Movement = {
		WalkSpeed = 28,
		SprintMul = 1.25,
		JumpPower = 55,
		DoubleJumpPower = 52,
		DashSpeed = 110,
		DashDuration = 0.13,
		DashCooldown = 0.95,
		DashIFrames = 0.22,
		SlamSpeed = 140,
		SlamRadius = 14,
		SlamDamage = 55,
		SlamCooldown = 1.8,
	},

	Combat = {
		MaxRange = 95,
		MagnetRadius = 18,
		PickupRadius = 5,
		XpBase = 34,
		XpGrowth = 1.18,
	},

	Director = {
		Countdown = 2,
		MissionSeconds = 180,
		IntensityRamp = 0.012,
		MaxAlive = 55,
		EliteEvery = 45,
	},

	Economy = {
		CreditKeepRatio = 0.45,
		StyleCreditBonus = 0.002,
		HighScoreBonus = 80,
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
		PackCredits = { Small = 500, Large = 2500 },
	},

	MetaUpgrades = {
		{ id = "maxHp", name = "Core Plating", desc = "+15 max HP", maxLevel = 8, baseCost = 40, costGrowth = 1.55 },
		{ id = "damage", name = "Rail Tuning", desc = "+12% damage", maxLevel = 8, baseCost = 50, costGrowth = 1.6 },
		{ id = "mobility", name = "Servo Legs", desc = "+6% move / dash", maxLevel = 6, baseCost = 45, costGrowth = 1.6 },
		{ id = "magnet", name = "Attractor", desc = "+20% gem pull", maxLevel = 5, baseCost = 35, costGrowth = 1.5 },
		{ id = "style", name = "Showboat Chip", desc = "+10% style score", maxLevel = 5, baseCost = 55, costGrowth = 1.65 },
	},

	Weapons = {
		Pulse = {
			id = "Pulse",
			name = "Pulse SMG",
			fireRate = 7.5,
			damage = 12,
			speed = 160,
			spread = 4,
			count = 1,
			pierce = 0,
			color = Color3.fromRGB(70, 210, 220),
		},
		Shatter = {
			id = "Shatter",
			name = "Shatter Cannon",
			fireRate = 1.35,
			damage = 16,
			speed = 120,
			spread = 18,
			count = 6,
			pierce = 0,
			color = Color3.fromRGB(220, 120, 80),
		},
		Rail = {
			id = "Rail",
			name = "Phase Rail",
			fireRate = 1.8,
			damage = 48,
			speed = 240,
			spread = 0,
			count = 1,
			pierce = 4,
			color = Color3.fromRGB(160, 110, 255),
		},
	},

	Sounds = {
		Shoot = "rbxassetid://9114224722",
		Hit = "rbxassetid://9119693934",
		Dash = "rbxassetid://9120386437",
		Slam = "rbxassetid://9114223563",
		LevelUp = "rbxassetid://9113815993",
		Pickup = "rbxassetid://9114221272",
		Hurt = "rbxassetid://9114223563",
		Style = "rbxassetid://9113816342",
	},

	Palette = {
		Cyan = Color3.fromRGB(72, 210, 220),
		Magenta = Color3.fromRGB(210, 70, 140),
		Violet = Color3.fromRGB(140, 105, 230),
		Orange = Color3.fromRGB(230, 130, 70),
		Lime = Color3.fromRGB(120, 210, 140),
		Gold = Color3.fromRGB(230, 195, 95),
		Floor = Color3.fromRGB(10, 12, 18),
		Panel = Color3.fromRGB(9, 11, 18),
		Wall = Color3.fromRGB(18, 22, 34),
		Danger = Color3.fromRGB(220, 70, 90),
		Text = Color3.fromRGB(232, 238, 246),
		Muted = Color3.fromRGB(130, 140, 160),
	},

	RemotesFolderName = "NeonSurgeRemotes",
	DataStoreName = "NeonSurge_Player_v3",
}

return Config
