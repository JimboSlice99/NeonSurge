--!strict
-- Neon Surge — live-ops / economy / feel knobs.
-- Replace Monetization IDs after uploading the place & creating products.

local Config = {
	GameName = "NEON SURGE",
	Tagline = "One more wave.",

	Arena = {
		Radius = 55,
		FloorY = 0,
		WallHeight = 12,
		RingSegments = 36,
		SpawnClearance = 10,
	},

	Player = {
		BaseMaxHealth = 100,
		BaseWalkSpeed = 24,
		BaseFireRate = 4.5,
		BaseDamage = 16,
		BaseProjectileSpeed = 130,
		ProjectileLifetime = 1.4,
		ProjectileRadius = 0.5,
		MaxRange = 85,
		DashSpeed = 95,
		DashDuration = 0.16,
		DashCooldown = 1.2,
		DashIFrames = 0.3,
		PickupRadius = 6,
		MagnetRadius = 14,
		XpToLevelBase = 40,
		XpToLevelGrowth = 1.22,
	},

	Waves = {
		Countdown = 3,
		Intermission = 2,
		BaseEnemyCount = 6,
		EnemiesPerWave = 3,
		MaxAlive = 45,
		SpawnInterval = 0.45,
		BossEvery = 5,
	},

	Economy = {
		CreditKeepRatio = 0.35, -- fraction of run credits banked on death
		KillCredit = 1,
		BossCredit = 25,
		WaveClearBonus = 8,
		HighScoreBonus = 50,
	},

	-- Create these in Creator Dashboard, then paste IDs here.
	Monetization = {
		Gamepasses = {
			DoubleCredits = 0, -- 2x credits earned in-run
			VipTrail = 0, -- cosmetic trail
			ExtraDash = 0, -- shorter dash cooldown
		},
		DevProducts = {
			CreditPackSmall = 0, -- +500 credits
			CreditPackLarge = 0, -- +2500 credits
		},
		PackCredits = {
			Small = 500,
			Large = 2500,
		},
	},

	MetaUpgrades = {
		{
			id = "maxHp",
			name = "Overclocked Core",
			desc = "+15 max HP per level",
			maxLevel = 8,
			baseCost = 40,
			costGrowth = 1.55,
		},
		{
			id = "damage",
			name = "Plasma Injectors",
			desc = "+12% damage per level",
			maxLevel = 8,
			baseCost = 50,
			costGrowth = 1.6,
		},
		{
			id = "fireRate",
			name = "Rapid Capacitors",
			desc = "+8% fire rate per level",
			maxLevel = 6,
			baseCost = 55,
			costGrowth = 1.65,
		},
		{
			id = "dash",
			name = "Phase Boots",
			desc = "-8% dash cooldown per level",
			maxLevel = 5,
			baseCost = 45,
			costGrowth = 1.7,
		},
		{
			id = "magnet",
			name = "Surge Magnet",
			desc = "+20% pickup radius per level",
			maxLevel = 5,
			baseCost = 35,
			costGrowth = 1.5,
		},
	},

	Palette = {
		Cyan = Color3.fromRGB(0, 245, 255),
		Magenta = Color3.fromRGB(255, 55, 180),
		Violet = Color3.fromRGB(150, 90, 255),
		Lime = Color3.fromRGB(140, 255, 90),
		Gold = Color3.fromRGB(255, 210, 70),
		Floor = Color3.fromRGB(24, 32, 64),
		Wall = Color3.fromRGB(48, 58, 110),
		Danger = Color3.fromRGB(255, 70, 90),
	},

	RemotesFolderName = "NeonSurgeRemotes",
	DataStoreName = "NeonSurge_Player_v1",
}

return Config
