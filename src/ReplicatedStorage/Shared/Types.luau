--!strict

export type TowerId = "Pulse" | "Beam" | "Frost" | "Nova"
export type EnemyKind = "Runner" | "Tank" | "Swift" | "Boss"
export type GamePhase = "Lobby" | "Prep" | "Wave" | "Results"

export type HudSnapshot = {
	phase: GamePhase,
	wave: number,
	maxWaves: number,
	lives: number,
	cash: number,
	creditsBank: number,
	enemiesAlive: number,
	selectedTower: string?,
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
	ownsDoubleCredits: boolean,
	ownsStarterCash: boolean,
	ownsVipSkin: boolean,
	meta: { MetaUpgradeView },
}

return {}
