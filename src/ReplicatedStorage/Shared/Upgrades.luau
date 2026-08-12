--!strict

local Types = require(script.Parent.Types)

type UpgradeOption = Types.UpgradeOption
type RunStats = Types.RunStats

local Upgrades = {}

local POOL: { UpgradeOption } = {
	{ id = "damage", name = "Overcharge", desc = "+20% damage", rarity = "Common" },
	{ id = "firerate", name = "Rapid Fire", desc = "+15% fire rate", rarity = "Common" },
	{ id = "speed", name = "Afterburners", desc = "+12% move speed", rarity = "Common" },
	{ id = "health", name = "Hardened Shell", desc = "+25 max HP & heal 25", rarity = "Common" },
	{ id = "magnet", name = "Gravity Well", desc = "+30% pickup radius", rarity = "Common" },
	{ id = "dash", name = "Blink Capacitor", desc = "-20% dash cooldown", rarity = "Rare" },
	{ id = "multi", name = "Split Beam", desc = "+1 projectile", rarity = "Rare" },
	{ id = "pierce", name = "Phase Rounds", desc = "+1 pierce", rarity = "Rare" },
	{ id = "vamp", name = "Leech Circuit", desc = "Heal 2 on every kill", rarity = "Epic" },
	{ id = "glass", name = "Glass Cannon", desc = "+45% damage, -15 max HP", rarity = "Epic" },
}

function Upgrades.defaultRunStats(): RunStats
	return {
		damageMul = 1,
		fireRateMul = 1,
		moveMul = 1,
		dashCooldownMul = 1,
		pickupMul = 1,
		projectileCount = 1,
		pierce = 0,
		maxHealthBonus = 0,
	}
end

function Upgrades.rollOptions(count: number, rng: Random?): { UpgradeOption }
	local random = rng or Random.new()
	local bag = table.clone(POOL)
	local picks: { UpgradeOption } = {}
	for _ = 1, math.min(count, #bag) do
		local index = random:NextInteger(1, #bag)
		table.insert(picks, bag[index])
		table.remove(bag, index)
	end
	return picks
end

function Upgrades.apply(stats: RunStats, id: string): (RunStats, number?)
	-- returns maybe heal amount
	if id == "damage" then
		stats.damageMul *= 1.2
	elseif id == "firerate" then
		stats.fireRateMul *= 1.15
	elseif id == "speed" then
		stats.moveMul *= 1.12
	elseif id == "health" then
		stats.maxHealthBonus += 25
		return stats, 25
	elseif id == "magnet" then
		stats.pickupMul *= 1.3
	elseif id == "dash" then
		stats.dashCooldownMul *= 0.8
	elseif id == "multi" then
		stats.projectileCount += 1
	elseif id == "pierce" then
		stats.pierce += 1
	elseif id == "vamp" then
		stats.maxHealthBonus += 0 -- flag via attribute elsewhere
		-- vamp tracked separately by caller via attribute
	elseif id == "glass" then
		stats.damageMul *= 1.45
		stats.maxHealthBonus -= 15
	end
	return stats, nil
end

function Upgrades.isVamp(id: string): boolean
	return id == "vamp"
end

return Upgrades
