--!strict

export type EnemyKind = "Runner" | "Shooter" | "Bruiser" | "Boss"

export type GamePhase = "Lobby" | "Countdown" | "Wave" | "LevelUp" | "Intermission" | "GameOver"

export type RunStats = {
	damageMul: number,
	fireRateMul: number,
	moveMul: number,
	dashCooldownMul: number,
	pickupMul: number,
	projectileCount: number,
	pierce: number,
	maxHealthBonus: number,
}

export type HudSnapshot = {
	phase: GamePhase,
	wave: number,
	score: number,
	level: number,
	xp: number,
	xpNeed: number,
	creditsRun: number,
	creditsBank: number,
	kills: number,
	health: number,
	maxHealth: number,
	enemiesAlive: number,
	combo: number,
	countdown: number?,
	message: string?,
	highScore: number,
}

export type UpgradeOption = {
	id: string,
	name: string,
	desc: string,
	rarity: "Common" | "Rare" | "Epic",
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
	ownsDoubleCredits: boolean,
	ownsVipTrail: boolean,
	ownsExtraDash: boolean,
	meta: { MetaUpgradeView },
}

return {}
