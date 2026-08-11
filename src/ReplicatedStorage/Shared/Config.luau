--!strict
-- Neon Surge shared tuning. Keep numbers here so client/server stay aligned.

local Config = {
	GameName = "NEON SURGE",
	Tagline = "Dash. Survive. Surge.",

	Arena = {
		Radius = 70,
		FloorY = 0,
		WallHeight = 18,
		RingSegments = 48,
		SpawnClearance = 12,
	},

	Player = {
		MaxHealth = 100,
		WalkSpeed = 22,
		DashSpeed = 90,
		DashDuration = 0.18,
		DashCooldown = 1.35,
		DashIFrames = 0.28,
		RegenPerSecond = 2.5,
		RegenDelay = 4,
	},

	Combat = {
		FireRate = 5.5, -- shots per second
		ProjectileSpeed = 120,
		ProjectileLifetime = 1.6,
		ProjectileDamage = 18,
		ProjectileRadius = 0.55,
		MaxRange = 90,
		AutoAim = true,
	},

	Waves = {
		Countdown = 3,
		Intermission = 2.5,
		BaseEnemyCount = 4,
		EnemiesPerWave = 2,
		MaxAlive = 40,
		SpawnInterval = 0.55,
		BossEvery = 5,
	},

	Enemies = {
		Runner = {
			Name = "Pulse Runner",
			Health = 36,
			Speed = 14,
			Damage = 10,
			TouchCooldown = 0.7,
			Color = Color3.fromRGB(0, 255, 200),
			Size = Vector3.new(2.2, 2.2, 2.2),
			Score = 25,
		},
		Bruiser = {
			Name = "Volt Bruiser",
			Health = 90,
			Speed = 9,
			Damage = 18,
			TouchCooldown = 0.9,
			Color = Color3.fromRGB(255, 70, 180),
			Size = Vector3.new(3.2, 3.2, 3.2),
			Score = 55,
		},
		Boss = {
			Name = "Neon Overlord",
			Health = 520,
			Speed = 11,
			Damage = 28,
			TouchCooldown = 0.75,
			Color = Color3.fromRGB(170, 90, 255),
			Size = Vector3.new(6, 6, 6),
			Score = 400,
		},
	},

	Palette = {
		Cyan = Color3.fromRGB(0, 245, 255),
		Magenta = Color3.fromRGB(255, 45, 180),
		Violet = Color3.fromRGB(140, 80, 255),
		Lime = Color3.fromRGB(120, 255, 90),
		Floor = Color3.fromRGB(8, 10, 22),
		Wall = Color3.fromRGB(18, 24, 48),
		Accent = Color3.fromRGB(0, 200, 255),
	},

	RemotesFolderName = "NeonSurgeRemotes",
}

return Config
