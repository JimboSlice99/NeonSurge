--!strict

export type EnemyKind = "Wisp" | "Skitter" | "Gunner" | "Bruiser" | "Elite"

export type GamePhase = "Lobby" | "Countdown" | "Mission" | "LevelUp" | "Results"

export type WeaponId = "Pulse" | "Shatter" | "Rail"

export type StyleRank = "D" | "C" | "B" | "A" | "S" | "SS"

export type RunStats = {
	damageMul: number,
	fireRateMul: number,
	moveMul: number,
	dashCooldownMul: number,
	pickupMul: number,
	styleMul: number,
	maxHealthBonus: number,
	weapons: { WeaponId },
	activeWeapon: WeaponId,
}

export type UpgradeOption = {
	id: string,
	name: string,
	desc: string,
	rarity: "Common" | "Rare" | "Epic",
}

export type HudSnapshot = {
	phase: GamePhase,
	timeLeft: number,
	score: number,
	style: number,
	styleRank: StyleRank,
	level: number,
	xp: number,
	xpNeed: number,
	creditsRun: number,
	creditsBank: number,
	kills: number,
	health: number,
	maxHealth: number,
	enemiesAlive: number,
	weapon: string,
	combo: number,
	message: string?,
	countdown: number?,
	highScore: number,
}

export type MetaUpgradeView = {
	id: string,
	name: string,
	desc: string,
	level: number,
	maxLevel: number,
	cost: number,
	affordable: boolean,
}

export type LobbySnapshot = {
	credits: number,
	highScore: number,
	bestWave: number,
	bestRank: string,
	ownsDoubleCredits: boolean,
	ownsVipTrail: boolean,
	ownsExtraDash: boolean,
	meta: { MetaUpgradeView },
}

return {}
