--!strict

local Types = require(script.Parent.Types)

type UpgradeOption = Types.UpgradeOption
type RunStats = Types.RunStats
type WeaponId = Types.WeaponId

local Upgrades = {}

local POOL: { UpgradeOption } = {
	{ id = "damage", name = "Overcharge", desc = "+22% damage", rarity = "Common" },
	{ id = "firerate", name = "Hot Mag", desc = "+15% fire rate", rarity = "Common" },
	{ id = "speed", name = "Afterburn", desc = "+12% move speed", rarity = "Common" },
	{ id = "health", name = "Nano Mesh", desc = "+30 HP & heal 30", rarity = "Common" },
	{ id = "magnet", name = "Gravity Well", desc = "+35% gem pull", rarity = "Common" },
	{ id = "dash", name = "Blink Cap", desc = "-20% dash cooldown", rarity = "Rare" },
	{ id = "style", name = "Crowd Work", desc = "+25% style score", rarity = "Rare" },
	{ id = "shatter", name = "Unlock Shatter", desc = "Gain Shatter Cannon (1)", rarity = "Rare" },
	{ id = "rail", name = "Unlock Rail", desc = "Gain Phase Rail (2)", rarity = "Epic" },
	{ id = "vamp", name = "Leech Circuit", desc = "Heal 3 on kill", rarity = "Epic" },
	{ id = "glass", name = "Glass Protocol", desc = "+50% damage, -20 HP", rarity = "Epic" },
}

function Upgrades.defaultRunStats(): RunStats
	return {
		damageMul = 1,
		fireRateMul = 1,
		moveMul = 1,
		dashCooldownMul = 1,
		pickupMul = 1,
		styleMul = 1,
		maxHealthBonus = 0,
		weapons = { "Pulse" },
		activeWeapon = "Pulse",
	}
end

function Upgrades.rollOptions(count: number, owned: { [string]: boolean }, rng: Random?): { UpgradeOption }
	local random = rng or Random.new()
	local bag = {}
	for _, opt in POOL do
		if opt.id == "shatter" and owned.shatter then
			continue
		end
		if opt.id == "rail" and owned.rail then
			continue
		end
		table.insert(bag, opt)
	end
	local picks = {}
	for _ = 1, math.min(count, #bag) do
		local index = random:NextInteger(1, #bag)
		table.insert(picks, bag[index])
		table.remove(bag, index)
	end
	return picks
end

function Upgrades.apply(stats: RunStats, id: string): (RunStats, number?, boolean?)
	-- heal, unlockedWeapon flag
	if id == "damage" then
		stats.damageMul *= 1.22
	elseif id == "firerate" then
		stats.fireRateMul *= 1.15
	elseif id == "speed" then
		stats.moveMul *= 1.12
	elseif id == "health" then
		stats.maxHealthBonus += 30
		return stats, 30, nil
	elseif id == "magnet" then
		stats.pickupMul *= 1.35
	elseif id == "dash" then
		stats.dashCooldownMul *= 0.8
	elseif id == "style" then
		stats.styleMul *= 1.25
	elseif id == "shatter" then
		if not table.find(stats.weapons, "Shatter") then
			table.insert(stats.weapons, "Shatter")
		end
		return stats, nil, true
	elseif id == "rail" then
		if not table.find(stats.weapons, "Rail") then
			table.insert(stats.weapons, "Rail")
		end
		return stats, nil, true
	elseif id == "glass" then
		stats.damageMul *= 1.5
		stats.maxHealthBonus -= 20
	end
	return stats, nil, nil
end

function Upgrades.isVamp(id: string): boolean
	return id == "vamp"
end

return Upgrades
